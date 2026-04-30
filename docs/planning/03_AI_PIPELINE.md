# 03 — AI 파이프라인 상세 설계

## 전체 파이프라인 흐름

```
이미지/PDF 업로드
       │
       ▼
  PDF → 이미지 변환 (pdf2image)
       │
       ▼
  ┌──────────────────────────────┐
  │   Step 1: OCR                │
  │   Primary: Clova General OCR │──폴백──▶  Google Lens OCR
  │   말풍선 + 텍스트 영역 감지   │
  │   번호 자동 라벨링 (①②③...)  │
  └──────────────────────────────┘
       │
       ▼ [(x1,y1,x2,y2), text, confidence, label_index]
  ┌──────────────────────────────┐
  │   Step 2: 화자 매칭          │
  │   말풍선 꼬리 분석(OpenCV)   │
  │   + Groq LLM 추론            │
  └──────────────────────────────┘
       │
       ▼ [bubble_id, speaker, text]
       ↕ 번역가 라벨링 검수 (UI에서 화자 수정)
  ┌──────────────────────────────┐
  │   Step 3: 컨텍스트 기반 번역  │
  │   Primary: DeepL API         │──폴백──▶  Groq LLM (llama-3.3-70b)
  │   작품/회차/캐릭터 컨텍스트   │
  │   주입 → 후보 3~4개 반환      │
  └──────────────────────────────┘
       │
       ▼ [bubble_id, candidates[]]
       ↕ 번역가 Survey형 선택 (UI)
  ┌──────────────────────────────┐
  │   Step 4: AI 일관성 검수      │
  │   Groq LLM                   │
  │   어투 일관성 + 오역 + 자연스러움│
  └──────────────────────────────┘
       │
       ▼ [검수 제안 목록]
       ↕ 번역가 제안 수락/거절 (UI)
  ┌──────────────────────────────┐
  │   Step 5: 렌더링 & 출력      │
  │   인페인팅(OpenCV/LAMA)       │
  │   + 번역 텍스트 합성(PIL)     │
  └──────────────────────────────┘
       │
       ▼
  최종 이미지/PDF 출력
```

---

## Step 1: OCR 파이프라인

```python
# pipeline/ocr_pipeline.py

from services.key_rotator import KeyRotator, QuotaExceededError
from services.clova_ocr import ClovaOCRClient
from services.google_lens import GoogleLensClient

class OCRPipeline:
    def __init__(self):
        self.clova_rotator = KeyRotator.from_env("CLOVA")
        self.lens_client = GoogleLensClient()

    async def process_page(self, image_bytes: bytes) -> list[dict]:
        """
        Returns:
            [{"id": uuid, "x1": int, "y1": int, "x2": int, "y2": int,
              "text": str, "confidence": float, "type": "dialogue|sfx|narration",
              "label_index": int}]  ← 라벨링 번호 자동 부여
        """
        # 1차: Clova OCR
        try:
            key_info = self.clova_rotator.get_key()
            result = await ClovaOCRClient.request(image_bytes, key_info)
            boxes = self._parse_clova_result(result)
            self.clova_rotator.report_success(key_info)
        except QuotaExceededError:
            self.clova_rotator.report_quota_exceeded(key_info)
            # 폴백: Google Lens
            result = await self.lens_client.request(image_bytes)
            boxes = self._parse_lens_result(result)
        except Exception as e:
            self.clova_rotator.report_error(key_info, e)
            raise

        # 라벨 번호 부여 (읽기 순서: 위→아래, 좌→우)
        boxes = self._sort_reading_order(boxes)
        for i, box in enumerate(boxes):
            box["label_index"] = i + 1

        return boxes

    def _sort_reading_order(self, boxes: list[dict]) -> list[dict]:
        """웹툰 읽기 순서: 위에서 아래, 같은 행은 오른쪽에서 왼쪽 (일본어 기준)"""
        # y축 기준 행 구분 후 x축 정렬
        return sorted(boxes, key=lambda b: (b["y1"] // 50, -b["x1"]))

    def _merge_nearby_boxes(self, boxes, threshold=30) -> list[dict]:
        """
        수직으로 인접한 박스들을 하나의 말풍선 단위로 병합
        Toonslator의 yakın_kelimeleri_bul 로직 개선 버전
        """
        if not boxes:
            return []

        boxes = sorted(boxes, key=lambda b: (b["x1"] // threshold, b["y1"]))
        merged = []
        used = set()

        for i, box in enumerate(boxes):
            if i in used:
                continue
            group = [box]
            used.add(i)

            for j, other in enumerate(boxes):
                if j in used:
                    continue
                x_overlap = max(0, min(box["x2"], other["x2"]) - max(box["x1"], other["x1"]))
                y_dist = abs(other["y1"] - box["y2"])
                if x_overlap > 0 and y_dist < threshold:
                    group.append(other)
                    used.add(j)

            merged.append({
                "text": " ".join(b["text"] for b in group),
                "confidence": min(b["confidence"] for b in group),
                "x1": min(b["x1"] for b in group),
                "y1": min(b["y1"] for b in group),
                "x2": max(b["x2"] for b in group),
                "y2": max(b["y2"] for b in group),
            })

        return merged
```

---

## Step 2: 화자 매칭 (Speaker Matching)

```python
# pipeline/speaker_matcher.py

class SpeakerMatcher:
    """
    각 말풍선이 어떤 캐릭터의 대사인지 추론.

    전략:
    1. 말풍선 꼬리 방향 분석 (OpenCV) - 빠름
    2. Groq LLM 추론 (이미지 + 캐릭터 목록) - 복잡한 케이스
    3. 신뢰도 낮으면 "미확인"으로 표시 → UI에서 번역가가 수정
    """

    async def match_speakers(
        self,
        image_bytes: bytes,
        bubbles: list[dict],
        characters: list[dict]
    ) -> list[dict]:
        tail_results = self._analyze_bubble_tails(image_bytes, bubbles)
        unmatched = [b for b, r in zip(bubbles, tail_results) if r is None]

        llm_results = {}
        if unmatched:
            llm_results = await self._llm_speaker_matching(
                image_bytes, unmatched, characters
            )

        return self._merge_results(tail_results, llm_results, bubbles)

    async def _llm_speaker_matching(self, image_bytes, bubbles, characters):
        char_names = [c['name'] for c in characters]
        prompt = f"""이 웹툰 이미지에서 각 말풍선의 화자를 식별해주세요.

등장 캐릭터: {char_names}

말풍선 목록 (index: 텍스트):
{[{"idx": i, "text": b['text'], "pos": f"({b['x1']},{b['y1']})"} for i, b in enumerate(bubbles)]}

각 말풍선의 화자를 캐릭터 이름으로 답해주세요.
확실하지 않으면 "미확인"으로 표시하세요.
JSON으로만 응답: [{{"bubble_idx": 0, "speaker": "캐릭터명", "confidence": 0.8}}]"""

        response = await groq_client.chat(prompt)
        return parse_json(response)
```

---

## Step 3: 번역 파이프라인 (핵심 — 후보 복수 반환)

DeepL은 빠른 배치 번역에 사용. 후보 복수 반환은 Groq LLM이 담당.
DeepL은 단일 번역 반환이므로, 복수 후보 생성 시에는 항상 Groq 경로를 사용한다.

```python
# pipeline/translation_pipeline.py

class TranslationPipeline:
    def __init__(self):
        self.deepl_rotator = KeyRotator.from_env("DEEPL")
        self.groq_rotator = KeyRotator.from_env("GROQ")

    async def translate_with_candidates(
        self,
        project,
        episode,
        bubble,
        character
    ) -> list[dict]:
        """
        말풍선 하나에 대해 번역 후보 3~4개 반환 (Groq LLM 사용).
        DeepL은 후보 생성 불가 (단일 반환) → Groq가 주체.
        DeepL은 "빠른 단일 번역"이 필요한 경우에만 사용.
        """
        prompt = context_builder.build_candidate_prompt(project, episode, bubble, character)

        try:
            key_info = self.groq_rotator.get_key()
            response = await groq_client.chat(
                prompt,
                model="llama-3.3-70b-versatile",
                key=key_info.key
            )
            self.groq_rotator.report_success(key_info)
            result = parse_json(response)
            return result["candidates"]
        except Exception as e:
            self.groq_rotator.report_error(key_info, e)
            raise

    async def translate_batch_simple(
        self,
        bubbles: list,
        target_lang: str = "KO"
    ) -> list[dict]:
        """
        DeepL 배치 번역 (단일 번역, 빠름).
        Groq 쿼터 절약을 위해 DeepL 가능한 경우 활용.
        이 결과는 후보 중 rank-1로 표시.
        """
        try:
            key_info = self.deepl_rotator.get_key()
            texts = [b.original_text for b in bubbles]
            async with deepl.AsyncTranslator(key_info.key) as translator:
                results = await translator.translate_text(texts, target_lang=target_lang)
            self.deepl_rotator.report_success(key_info)
            return [
                {"bubble_id": b.id, "candidates": [
                    {"rank": 1, "text": r.text, "rationale": "DeepL 번역"}
                ]}
                for b, r in zip(bubbles, results)
            ]
        except QuotaExceededError:
            self.deepl_rotator.report_quota_exceeded(key_info)
            # Groq 폴백
            return await self._translate_batch_with_groq(bubbles, target_lang)

    async def _translate_batch_with_groq(self, bubbles, target_lang):
        """Groq LLM 배치 번역 (컨텍스트 주입, 10개씩)"""
        BATCH_SIZE = 10
        all_results = []

        for i in range(0, len(bubbles), BATCH_SIZE):
            batch = bubbles[i:i + BATCH_SIZE]
            prompt = self._build_batch_prompt(batch, target_lang)
            key_info = self.groq_rotator.get_key()
            response = await groq_client.chat(prompt, key=key_info.key)
            all_results.extend(parse_json(response))

        return all_results

    def _build_batch_prompt(self, bubbles, target_lang):
        lang_name = {"KO": "한국어", "EN": "영어", "JA": "일본어"}.get(target_lang, target_lang)
        return f"""웹툰 번역 전문가로서 아래 텍스트를 {lang_name}로 번역하세요.
캐릭터 말투 일관성을 유지하세요.

번역 대상:
{chr(10).join(f'{i+1}. [{b.speaker}] {b.original_text}' for i, b in enumerate(bubbles))}

JSON으로만 응답: [{{"idx": 1, "translation": "번역문"}}]"""
```

---

## Step 4: AI 검수 파이프라인

```python
# pipeline/review_pipeline.py

class AIReviewPipeline:
    """번역 완료 후 일관성·자연스러움 일괄 검수"""

    async def review_episode(self, project, episode) -> list[dict]:
        all_bubbles = get_confirmed_bubbles(episode.id)

        prompt = f"""당신은 전문 웹툰 번역 검수자입니다.

[작품 정보]
제목: {project.title}
캐릭터별 말투 프로필 + 이전 회차 번역 샘플:
{chr(10).join(
    f'- {c.name}: {c.speech_style}'
    + (f'\n  이전 말투 샘플: ' + ' / '.join(f'"{s["translated"]}"' for s in c.get_past_speech_samples(3))
       if c.get_past_speech_samples(3) else '')
    for c in project.characters
)}

[전체 번역 결과]
{chr(10).join(f'[{b.speaker}] 원문: {b.original_text} / 번역: {b.translated_text}' for b in all_bubbles)}

다음 기준으로 수정이 필요한 항목만 제안하세요:
1. 캐릭터별 말투 일관성 (프로필에 맞는지)
2. 번역 누락 또는 오역
3. 자연스럽지 않은 표현
4. 의성어/의태어 번역 적절성

JSON으로만 응답:
[{{
  "bubble_id": "uuid",
  "issue_type": "consistency|mistranslation|unnatural|sfx",
  "original_translation": "현재 번역",
  "suggested_translation": "제안 번역",
  "reason": "수정 이유 한 줄"
}}]"""

        key_info = groq_rotator.get_key()
        response = await groq_client.chat(
            prompt,
            model="llama-3.1-8b-instant",  # 검수는 빠른 모델 사용
            key=key_info.key
        )
        return parse_json(response)
```

---

## Step 5: 렌더링 파이프라인

```python
# pipeline/render_pipeline.py
import cv2
import numpy as np
from PIL import Image, ImageDraw, ImageFont

class RenderPipeline:
    """
    최종 이미지 합성:
    원본 이미지 → 원본 텍스트 영역 인페인팅 → 번역 텍스트 삽입
    """

    def render_page(
        self,
        image_bytes: bytes,
        bubbles: list,
        quality: str = "fast"
    ) -> bytes:
        img = self._bytes_to_cv2(image_bytes)
        mask = self._create_text_mask(img, bubbles)
        inpainted = self._inpaint(img, mask, quality)
        result = self._render_translations(inpainted, bubbles)
        return self._pil_to_bytes(result)

    def _inpaint(self, img, mask, quality: str = "fast"):
        if quality == "fast":
            # OpenCV TELEA: CPU 부담 적음, 빠름
            return cv2.inpaint(img, mask, inpaintRadius=3, flags=cv2.INPAINT_TELEA)
        else:
            # Simple-LAMA: 고품질, M1 Metal 가속 가능
            from simple_lama_inpainting import SimpleLama
            lama = SimpleLama()
            return np.array(lama(Image.fromarray(img), Image.fromarray(mask)))

    def _render_translations(self, img: np.ndarray, bubbles: list) -> Image.Image:
        pil_img = Image.fromarray(cv2.cvtColor(img, cv2.COLOR_BGR2RGB))
        draw = ImageDraw.Draw(pil_img)

        for bubble in bubbles:
            if not bubble.translated_text:
                continue

            font_size = self._fit_font_size(
                bubble.translated_text, bubble.width, bubble.height
            )

            try:
                font = ImageFont.truetype(f"fonts/{bubble.font_family}.ttf", font_size)
            except:
                font = ImageFont.load_default()

            bbox = draw.textbbox((0, 0), bubble.translated_text, font=font)
            text_w = bbox[2] - bbox[0]
            text_h = bbox[3] - bbox[1]
            x = bubble.x1 + (bubble.width - text_w) / 2
            y = bubble.y1 + (bubble.height - text_h) / 2

            draw.text((x, y), bubble.translated_text, fill=bubble.text_color, font=font)

        return pil_img

    def _fit_font_size(self, text: str, box_w: int, box_h: int) -> int:
        """박스 크기에 맞는 최적 폰트 크기 이진 탐색"""
        lo, hi = 8, 40
        while lo < hi:
            mid = (lo + hi + 1) // 2
            # 대략적 추정 (실제는 PIL로 측정)
            char_w = mid * 0.6
            lines = max(1, len(text) * char_w // box_w)
            if lines * mid * 1.2 <= box_h and len(text) * char_w / lines <= box_w:
                lo = mid
            else:
                hi = mid - 1
        return lo
```