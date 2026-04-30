## ⚙️ Codex 공통 운영 규칙 (매 작업 필수)

### 작업 시작 전 반드시
1. 프로젝트 현재 구조 확인:
```bash
tree -a -L 5 \
-I 'node_modules|.next|out|dist|build|coverage|.turbo|.vercel|.cache|.vite|__pycache__|.pytest_cache|.mypy_cache|.venv|venv|env|*.pyc|*.pyo|*.log|*.lock|package-lock.json|yarn.lock|pnpm-lock.yaml|poetry.lock|*.jpg|*.jpeg|*.png|*.gif|*.webp|*.svg|*.ico|*.bmp|*.tiff|*.mp4|*.mov|*.webm|*.zip|*.tar|*.gz|*.7z|*.pdf|*.ttf|*.otf|*.woff|*.woff2|*.wasm'
```
2. `docs/planning/` 에서 이번 작업 관련 설계 문서 읽기
   - 관련 문서: `03_AI_PIPELINE.md`, `02_FRONTEND_ARCHITECTURE.md`
3. `docs/tasks/logs/LOG_P01C_frontend_dashboard_upload.md` 확인

### 작업 완료 후 반드시
1. `docs/tasks/logs/LOG_P02_speaker_matching_labeling.md` 작성
2. git commit:
   ```bash
   git add .
   git commit -m "feat: [P02] 화자 매칭 + 라벨링 검수 UI"
   ```

---

# [P02] Phase 2: 화자 매칭 파이프라인 + 라벨링 검수 UI

## 전제 조건
Phase 0~1 완료: 인증, DB 모델, 프로젝트/회차 CRUD, 파일 업로드, OCR 파이프라인 완료.

## 작업 목표
각 말풍선의 화자를 자동 추론하고, 번역가가 이미지 위에서 검수하는 화면 완성.

---

## 백엔드 작업

### services/groq_client.py
```python
class GroqChatClient:
  def __init__(self, rotator: KeyRotator): ...

  async def chat(self, prompt: str, model: str = "llama-3.3-70b-versatile") → str:
    # rotator.get_key()로 Key 획득
    # groq SDK로 chat.completions.create 호출
    # 성공: report_success, 실패: report_error

  def parse_json(self, text: str) → any:
    # ```json ... ``` 펜스 제거 후 json.loads
    # 실패 시 ValueError("JSON 파싱 실패: {원본 텍스트}")
```

### pipeline/speaker_matcher.py
```python
class SpeakerMatcher:
  async def match_speakers(self, image_bytes, bubbles, characters) → list[dict]:
    # _llm_speaker_matching()으로 화자 추론
    # confidence < 0.6 이면 speaker = "미확인"

  async def _llm_speaker_matching(self, image_bytes, bubbles, characters) → list[dict]:
    # char_names = [c['name'] for c in characters] + ["효과음", "나레이션", "미확인"]
    # 텍스트 기반 위치 정보만 사용 (이미지는 직접 전달 안 함, 추후 vision 확장 예정)
    # 프롬프트: 말풍선 idx, text, pos(x1,y1) 목록 → 화자 추론
    # 반환: [{"bubble_idx", "speaker", "confidence"}]
```

### routers/labeling.py
```
POST /episodes/{ep_id}/jobs/speaker-match
  → Job 생성 + BackgroundTasks (run_speaker_match_job)

PATCH /bubbles/{bubble_id}/speaker
  Body: { speaker: str }
  → Bubble.speaker 업데이트, speaker_is_confirmed = True

POST /episodes/{ep_id}/speaker-match/confirm-all
  → 에피소드 전체 Bubble.speaker_is_confirmed = True
```

```python
async def run_speaker_match_job(job_id, episode_id, db):
  # 에피소드 전체 페이지 순회
  # SpeakerMatcher.match_speakers() 호출
  # Bubble.speaker, speaker_confidence 업데이트
  # APIUsageLog 저장 (service="groq_speaker")
  # Episode.status = "labeled"
```

---

## 프론트엔드 작업

### components/labeling/LabelingCanvas.tsx (Fabric.js)
- 웹툰 이미지를 배경으로 로드
- 각 Bubble의 좌표에 사각형 테두리:
  - 화자 확정: 초록(#22c55e), 미확인: 빨강(#ef4444), 기본: 파랑(#3b82f6)
- 좌상단 원형 배지 + label_index 숫자
- 말풍선 클릭 → `onBubbleClick(bubbleId)` 콜백

### components/labeling/BubbleList.tsx (사이드바)
- 각 항목: 번호 배지 | 화자 드롭다운 | 원문 텍스트 (인라인 편집)
- 화자 드롭다운: 프로젝트 캐릭터 + ["효과음", "나레이션", "미확인"]
- 변경 시 PATCH /bubbles/{id}/speaker
- ⚠️ 미확인 화자 경고 아이콘
- 선택된 bubbleId 하이라이트

### app/.../labeling/page.tsx
경로: `app/projects/[projectId]/episodes/[episodeId]/labeling/page.tsx`

레이아웃:
- 상단 바: [← 뒤로] 제목 [AI 화자 재매칭] [전체 승인] [다음 단계 →]
- 좌측 2/3: LabelingCanvas + PageNavigator
- 우측 1/3: BubbleList

동작:
- 진입 시 speaker-match Job 없으면 자동 실행
- 캔버스 클릭 → BubbleList 해당 항목 스크롤 + 하이라이트
- [전체 승인] → POST /episodes/{ep_id}/speaker-match/confirm-all
- [다음 단계 →] → /translation 이동 (미확인 화자 있으면 shadcn Alert 경고, 이동은 허용)

---

## 완료 기준
- [ ] POST /episodes/{ep_id}/jobs/speaker-match 실행 후 Bubble.speaker 업데이트 확인
- [ ] Fabric.js 캔버스에서 말풍선 번호 배지 렌더링 확인
- [ ] 화자 드롭다운 변경 → PATCH 전송 → 배지 색상 변경 확인
- [ ] [전체 승인] → 모든 bubble speaker_is_confirmed=True 확인
