## ⚙️ Codex 공통 운영 규칙 (매 작업 필수)

### 작업 시작 전 반드시
1. 프로젝트 현재 구조 확인:
```bash
tree -a -L 5 \
-I 'node_modules|.next|out|dist|build|coverage|.turbo|.vercel|.cache|.vite|__pycache__|.pytest_cache|.mypy_cache|.venv|venv|env|*.pyc|*.pyo|*.log|*.lock|package-lock.json|yarn.lock|pnpm-lock.yaml|poetry.lock|*.jpg|*.jpeg|*.png|*.gif|*.webp|*.svg|*.ico|*.bmp|*.tiff|*.mp4|*.mov|*.webm|*.zip|*.tar|*.gz|*.7z|*.pdf|*.ttf|*.otf|*.woff|*.woff2|*.wasm'
```
2. `docs/planning/` 에서 이번 작업 관련 설계 문서 읽기
   - 관련 문서: `03_AI_PIPELINE.md`, `04_API_KEY_STRATEGY.md`
3. `docs/tasks/logs/LOG_P01A_backend_db_crud.md` 확인

### 작업 완료 후 반드시
1. `docs/tasks/logs/LOG_P01B_backend_upload_ocr_keyrotator.md` 작성
2. git commit:
   ```bash
   git add .
   git commit -m "feat: [P01B] 파일 업로드 + OCR 파이프라인 + KeyRotator"
   ```

---

# [P01B] Phase 1-B: 파일 업로드 + OCR 파이프라인 + KeyRotator 구현

## 전제 조건
Phase 0, 1-A 완료: JWT 인증, 전체 DB 모델, 프로젝트/회차 CRUD API 완료.

## 작업 목표
파일 업로드(이미지/PDF), Clova OCR 실행, 말풍선 감지 + 번호 라벨링까지 완성.

---

## 작업 1: KeyRotator (backend/services/key_rotator.py)

```python
@dataclass
class KeyInfo:
  key: str
  extra: dict          # Clova는 {"url": "..."} 포함
  is_active: bool = True
  fail_count: int = 0
  quota_reset_at: Optional[float] = None  # epoch 시각

class QuotaExceededError(Exception): pass

class KeyRotator:
  def __init__(self, keys: list[KeyInfo], service_name: str): ...

  @classmethod
  def from_env(cls, service: str):
    # CLOVA:  CLOVA_KEYS=k1,k2  / CLOVA_URLS=url1,url2  → extra={"url": url}
    # DEEPL:  DEEPL_KEYS=k1,k2
    # GROQ:   GROQ_KEYS=k1,k2,k3

  def get_key(self) → KeyInfo:
    # 1. 만료된 비활성 Key 중 quota_reset_at <= now인 것 재활성화
    # 2. deque에서 라운드로빈으로 active Key 반환
    # 3. 전부 비활성 시 QuotaExceededError raise

  def report_success(self, key_info): ...
  def report_quota_exceeded(self, key_info, reset_hours=24):
    # is_active=False, reset_at 설정
  def report_error(self, key_info, error):
    # fail_count += 1, 3회 이상이면 5분 비활성화

  @property
  def status(self) → dict:
    # total, active, keys 목록 (key 끝 4자리만 노출)
```

---

## 작업 2: Clova OCR 클라이언트 (backend/services/clova_ocr.py)

```python
class ClovaOCRClient:
  @staticmethod
  async def request(image_bytes: bytes, key_info: KeyInfo) → dict:
    # aiohttp로 Clova General OCR API 호출
    # payload: { images: [{format:"jpg", name:"image"}], requestId: uuid4, version:"V2", timestamp: ms }
    # multipart/form-data: "message" 필드(JSON), "file" 필드(이미지 bytes)
    # 헤더: X-OCR-SECRET: key_info.key
    # URL: key_info.extra["url"]
    # 429 응답 → QuotaExceededError raise
```

---

## 작업 3: OCR 파이프라인 (backend/pipeline/ocr_pipeline.py)

```python
class OCRPipeline:
  async def process_page(self, image_bytes: bytes) → list[dict]:
    # 반환: [{"id": uuid, "x1", "y1", "x2", "y2", "text", "confidence", "type", "label_index"}]
    # type: "dialogue" | "sfx" | "narration"

    # 1. Clova OCR 호출 → 429/QuotaExceededError → Google Lens stub 호출
    # 2. _parse_clova_result(result) → boxes 리스트
    #    images[0].fields 에서 inferText, boundingPoly 파싱
    # 3. _merge_nearby_boxes(boxes, threshold=30):
    #    x축 overlap + y축 거리 threshold 미만인 박스 병합
    #    병합: text 공백 연결, 좌표 합집합, confidence 최소값
    # 4. _sort_reading_order(boxes):
    #    웹툰 읽기 순서: y1 // 50 기준 행 구분, 같은 행은 x1 내림차순
    # 5. label_index 부여 (1부터), uuid id 부여

  async def _google_lens_fallback(self, image_bytes) → list[dict]:
    # stub: 빈 리스트 반환 + 로그 출력
```

---

## 작업 4: 파일 업로드 API (backend/routers/upload.py)

```
POST   /episodes/{ep_id}/pages/upload
  - UploadFile 리스트 (multipart, 다중 파일)
  - PDF → pdf2image로 각 페이지 JPEG 변환
  - 저장 경로: {UPLOAD_DIR}/{episode_id}/page_{order:03d}.jpg
  - Page 레코드 생성 (order 자동 부여)

GET    /episodes/{ep_id}/pages            → Page 목록 (order 오름차순)
DELETE /episodes/{ep_id}/pages/{page_id} → 파일 + DB 레코드 삭제
```

---

## 작업 5: OCR Job API (backend/routers/ocr.py)

인메모리 `job_store = {}` 사용 (MVP).

```
POST /episodes/{ep_id}/jobs/ocr          → Job 레코드 생성 + BackgroundTasks 실행
GET  /jobs/{job_id}/status               → { status, progress, error? }
GET  /pages/{page_id}/bubbles            → Bubble 목록 (label_index 오름차순)
PATCH /bubbles/{bubble_id}              → 부분 업데이트 (text, 좌표, type, speaker)
DELETE /bubbles/{bubble_id}             → 삭제
POST  /pages/{page_id}/bubbles          → Bubble 생성 (label_index 자동 부여)
```

```python
async def run_ocr_job(job_id, episode_id, db):
  # job_store 상태 업데이트하며 진행
  # 페이지별 OCRPipeline.process_page() 호출
  # Bubble 레코드 DB 저장
  # bubble_type 판별: 가타카나 多 or 2글자 이하 → "sfx"
  # Episode.status = "ocr_done" 업데이트
  # APIUsageLog 저장 (service="clova_ocr", request_count=1)
```

---

## 완료 기준
- [ ] POST /episodes/{ep_id}/pages/upload → Page 레코드 생성 확인
- [ ] POST /episodes/{ep_id}/jobs/ocr → job_id 반환 확인
- [ ] GET /jobs/{job_id}/status → progress 증가 폴링 확인
- [ ] OCR 완료 후 GET /pages/{page_id}/bubbles → label_index 포함 Bubble 목록 확인
- [ ] KeyRotator: GROQ_KEYS 미설정 시 ValueError 발생 확인
- [ ] KeyRotator: report_quota_exceeded 후 get_key() 시 해당 Key 제외 확인
