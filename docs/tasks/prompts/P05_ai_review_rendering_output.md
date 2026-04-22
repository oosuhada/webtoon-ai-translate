## ⚙️ Codex 공통 운영 규칙 (매 작업 필수)

### 작업 시작 전 반드시
1. 프로젝트 현재 구조 확인:
```bash
tree -a -L 5 \
-I 'node_modules|.next|out|dist|build|coverage|.turbo|.vercel|.cache|.vite|__pycache__|.pytest_cache|.mypy_cache|.venv|venv|env|*.pyc|*.pyo|*.log|*.lock|package-lock.json|yarn.lock|pnpm-lock.yaml|poetry.lock|*.jpg|*.jpeg|*.png|*.gif|*.webp|*.svg|*.ico|*.bmp|*.tiff|*.mp4|*.mov|*.webm|*.zip|*.tar|*.gz|*.7z|*.pdf|*.ttf|*.otf|*.woff|*.woff2|*.wasm'
```
2. `docs/planning/` 에서 이번 작업 관련 설계 문서 읽기
   - 관련 문서: `03_AI_PIPELINE.md`, `02_FRONTEND_ARCHITECTURE.md`
3. `docs/tasks/logs/LOG_P04_image_editor_fabricjs.md` 확인

### 작업 완료 후 반드시
1. `docs/tasks/logs/LOG_P05_ai_review_rendering_output.md` 작성
2. git commit:
   ```bash
   git add .
   git commit -m "feat: [P05] AI 검수 + 렌더링 출력"
   ```

---

# [P05] Phase 5: AI 검수 파이프라인 + 렌더링 출력

## 전제 조건
Phase 0~4 완료: 번역 파이프라인, 이미지 뷰 편집기 완료.

---

## 백엔드 작업 A: AI 검수

### pipeline/review_pipeline.py
```python
class AIReviewPipeline:
  async def review_episode(self, project, episode, db) → list[dict]:
    # confirmed_translation 있는 Bubble 전체 조회
    # 프롬프트 구성:
    #   [작품 정보] 제목, 캐릭터별 말투 스타일 + 이전 회차 말투 샘플 3개
    #   [전체 번역 결과] speaker: 원문 / 번역 목록
    #   검수 기준: consistency / mistranslation / unnatural / sfx
    # groq_client.chat(prompt, model="llama-3.1-8b-instant")
    # parse_json() → ReviewSuggestion 레코드 DB 저장
    # APIUsageLog 저장 (service="groq_review")
```

### routers/review.py
```
POST /episodes/{ep_id}/jobs/ai-review           → Job 생성 + BackgroundTasks
GET  /episodes/{ep_id}/review-suggestions       → ReviewSuggestion 목록 (pending 먼저)
PATCH /review-suggestions/{id}/accept
  → suggestion.status = "accepted"
  → 기존 selected candidate → is_selected=False
  → suggested_translation으로 새 candidate (rank=0, is_selected=True)
  → CharacterSpeechSample 업데이트 (is_edited=True)
PATCH /review-suggestions/{id}/reject           → status = "rejected"
```

---

## 백엔드 작업 B: 렌더링 출력

### pipeline/render_pipeline.py
```python
class RenderPipeline:
  def render_page(self, image_bytes: bytes, bubbles: list, quality: str = "fast") → bytes:
    # 1. OpenCV로 이미지 로드
    # 2. _create_text_mask(img, bubbles): bubble 좌표에 흰 사각형 마스크
    # 3. _inpaint(img, mask, quality):
    #    "fast": cv2.inpaint(TELEA, inpaintRadius=3)
    #    "high": simple_lama_inpainting.SimpleLama() (없으면 fast 폴백)
    # 4. _render_translations(inpainted, bubbles):
    #    PIL 변환 → confirmed_translation 있는 bubble마다
    #    _fit_font_size(text, width, height) 이진 탐색 (8~40px)
    #    PIL ImageDraw.text() 중앙 정렬 (NanumGothic.ttf 없으면 기본 폰트)
    # 5. JPEG bytes 반환

  def _fit_font_size(self, text, box_w, box_h) → int:
    # lo=8, hi=40 이진 탐색, 글자 너비 ≈ font_size * 0.6
```

### routers/export.py
```
POST /episodes/{ep_id}/jobs/render
  Body: { "quality": "fast" | "high" }
  → Job 생성 + BackgroundTasks
  → 각 Page RenderPipeline.render_page() 호출
  → {OUTPUT_DIR}/{episode_id}/rendered_{order:03d}.jpg 저장
  → Page.rendered_path 업데이트, Episode.status = "done"

GET /episodes/{ep_id}/preview/{page_id}
  → rendered_path 이미지 FileResponse

GET /episodes/{ep_id}/export
  → 모든 rendered 이미지 ZIP StreamingResponse
  → 파일명: {ep_id}_{episode_number}화_번역완성.zip
```

---

## 프론트엔드 작업

### app/.../review/page.tsx
- [AI 검수 실행] → POST /episodes/{ep_id}/jobs/ai-review + JobProgressBar
- 검수 제안 카드:
  - issue_type 배지: consistency=노랑, mistranslation=빨강, unnatural=주황, sfx=파랑
  - 현재 번역(취소선) → 제안 번역(강조)
  - 이유 텍스트
  - [수락 ✓] / [거절 ✗] 버튼
- [전체 수락] / [전체 거절] 버튼
- 완료 후 [최종 출력 →] 버튼

### app/.../export/page.tsx
- 렌더링 방식 선택: [빠른 렌더링] / [고품질] 라디오
- [렌더링 시작] → POST + JobProgressBar
- 완료 후: 썸네일 미리보기 + [전체 다운로드 ZIP]
- 썸네일 클릭 → /translation 이동 (해당 페이지로 currentPage 설정)

---

## 완료 기준
- [ ] AI 검수 실행 후 ReviewSuggestion 레코드 생성 확인
- [ ] 수락 시 bubble 번역문 교체 + CharacterSpeechSample 업데이트 확인
- [ ] 렌더링 완료 후 GET /preview/{page_id} → 번역 합성 이미지 반환 확인
- [ ] ZIP 다운로드 시 모든 페이지 포함 확인
