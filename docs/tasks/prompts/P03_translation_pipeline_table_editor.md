## ⚙️ Codex 공통 운영 규칙 (매 작업 필수)

### 작업 시작 전 반드시
1. 프로젝트 현재 구조 확인:
```bash
tree -a -L 5 \
-I 'node_modules|.next|out|dist|build|coverage|.turbo|.vercel|.cache|.vite|__pycache__|.pytest_cache|.mypy_cache|.venv|venv|env|*.pyc|*.pyo|*.log|*.lock|package-lock.json|yarn.lock|pnpm-lock.yaml|poetry.lock|*.jpg|*.jpeg|*.png|*.gif|*.webp|*.svg|*.ico|*.bmp|*.tiff|*.mp4|*.mov|*.webm|*.zip|*.tar|*.gz|*.7z|*.pdf|*.ttf|*.otf|*.woff|*.woff2|*.wasm'
```
2. `docs/planning/` 에서 이번 작업 관련 설계 문서 읽기
   - 관련 문서: `03_AI_PIPELINE.md`, `02_FRONTEND_ARCHITECTURE.md`
3. `docs/tasks/logs/LOG_P02_speaker_matching_labeling.md` 확인

### 작업 완료 후 반드시
1. `docs/tasks/logs/LOG_P03_translation_pipeline_table_editor.md` 작성
2. git commit:
   ```bash
   git add .
   git commit -m "feat: [P03] 번역 파이프라인 + 테이블 뷰 편집기"
   ```

---

# [P03] Phase 3: 번역 파이프라인 (컨텍스트 기반 후보 생성) + 테이블 뷰 편집기

## 핵심 개념
AI가 번역 후보 3~4개를 Survey형(①②③ + ④직접입력)으로 제안.
프롬프트에 [작품줄거리 + 회차줄거리 + 캐릭터어투 + 이전회차말투샘플] 주입.

## 전제 조건
Phase 0~2 완료: 인증, DB 모델, OCR, 화자 매칭 완료.

---

## 백엔드 작업

### services/deepl_client.py
```python
class DeepLClient:
  async def translate_batch(self, texts: list[str], target_lang: str = "KO") → list[str]:
    # deepl.AsyncTranslator 사용, 50개씩 분할 배치 처리
    # 429 → rotator.report_quota_exceeded + QuotaExceededError re-raise
```

### pipeline/context_builder.py
```python
def build_candidate_prompt(project, episode, bubble, character) → str:
  """
  포함 내용:
  [작품 전체 컨텍스트] 제목, 줄거리
  [이번 회차 컨텍스트] 회차 줄거리 + episode.get_character_situation(character.name)
  [화자 캐릭터 프로필] name, speech_style, speech_examples
  [이전 회차 말투 샘플] character.get_past_speech_samples(5)
    원문: {s.original} → 번역: {s.translated} (EP.{N} / {"번역가 수정" if is_edited else "AI 원안"})
    샘플 없으면 해당 섹션 생략
  [번역할 원문] bubble.original_text

  응답 형식:
  {"candidates": [{"rank":1,"text":"번역문","rationale":"이유"},{"rank":2,...},{"rank":3,...}]}
  """

def build_past_speech_block(character, limit=5) → str:
  """character.get_past_speech_samples(limit) → 프롬프트 블록으로 변환"""
```

### pipeline/translation_pipeline.py
```python
class TranslationPipeline:
  async def translate_with_candidates(self, project, episode, bubble, character) → list[dict]:
    # context_builder.build_candidate_prompt() → groq_client.chat() → parse_json()
    # 파싱 실패 시 fallback: 최소 1개 후보 반환

  async def translate_batch_simple(self, bubbles, target_lang="KO") → list[dict]:
    # DeepL 배치 번역 (단일 후보) → 실패 시 Groq 폴백
```

### routers/translation.py
```
POST /episodes/{ep_id}/jobs/translate          → Job 생성 + BackgroundTasks
GET  /bubbles/{bubble_id}/candidates           → 후보 목록 + 선택 상태
PATCH /bubbles/{bubble_id}/translation         → 후보 선택 또는 직접 입력 확정
POST /bubbles/{bubble_id}/candidates/regenerate → 후보 재생성
GET  /episodes/{ep_id}/translation-status      → { total, selected, pending, progress_pct }
```

PATCH /bubbles/{bubble_id}/translation Body:
```json
{ "selected_candidate_rank": 1, "custom_text": null }
```
처리:
1. 기존 is_selected=True → False
2. selected_candidate_rank 있으면 해당 candidate.is_selected=True
3. custom_text 있으면 rank=0 candidate 생성/업데이트
4. CharacterSpeechSample 저장:
   - is_edited = (custom_text is not None)

---

## 프론트엔드 작업

### store/editorStore.ts (Zustand)
```typescript
// viewMode: 'table' | 'image'
// selectedBubbleId: string | null
// currentPage: number
// filterMode: 'all' | 'pending'
```

### components/translation/CandidateSelector.tsx ⭐ 핵심
```typescript
// props: { bubbleId, candidates, selectedRank, customText, onConfirm }
// UI:
//   원문 텍스트 표시
//   후보 라디오 버튼: ● ① [번역문] / 아래 작게 [이유]
//   ④ 직접 입력 Input (값 입력 시 자동 선택)
//   [🔄 후보 재생성] → additional_context 입력 모달 → POST regenerate
//   [이 번역 확정 →] → PATCH /bubbles/{id}/translation
//   선택된 행: bg-blue-50 border-blue-500
```

### components/translation/TranslationTable.tsx
```typescript
// GET /episodes/{ep_id}/translation-status → 진행률 표시
// 컬럼: 위치(페이지-번호) | 화자 | 원문 | [CandidateSelector]
// filterMode='pending': is_selected=False bubble만
// 하단: 진행률 바 + "87/120 완료" + [⚠️ 미선택만 보기] 토글
```

### app/.../translation/page.tsx
- 상단 탭: [테이블 뷰] / [이미지 뷰]
- viewMode=table: TranslationTable
- viewMode=image: "이미지 뷰는 Phase 4에서 구현 예정" 플레이스홀더
- 진입 시 번역 Job 없으면 자동 POST + JobProgressBar

---

## 완료 기준
- [ ] 번역 Job 완료 후 GET /bubbles/{id}/candidates → candidates 3개 반환 확인
- [ ] ① 클릭 → PATCH selected_candidate_rank=1 전송 확인
- [ ] ④ 직접 입력 후 확정 → PATCH custom_text 전송 확인
- [ ] CharacterSpeechSample 레코드 생성 확인 (is_edited 플래그 포함)
- [ ] GET /episodes/{ep_id}/translation-status → progress_pct 정확히 계산 확인
- [ ] filterMode 토글로 미선택 bubble만 필터링 확인
