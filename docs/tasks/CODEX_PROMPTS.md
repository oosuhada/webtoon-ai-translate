# Codex 작업 프롬프트 모음

> **사용 방법**: 아래 프롬프트를 Phase 순서대로 Codex에 입력한다.
> 각 Phase는 이전 Phase가 완료된 상태를 전제로 한다.
> 프롬프트 전체를 복사해서 그대로 입력할 것 (공통 컨텍스트가 각 Phase에 포함되어 있음).

---

## 📋 공통 컨텍스트 (각 프롬프트에 반복 포함됨)

```
프로젝트명: 웹툰 자동 번역 어시스턴트
핵심 개념: Reader용 번역기(단일 반환)가 아닌 Translator용 번역 어시스턴트.
  - AI가 번역 후보 3~4개를 Survey형(①②③ + ④직접입력)으로 제안
  - 번역가가 최종 선택권 보유
  - 작품 줄거리 + 회차 줄거리 + 캐릭터 어투 + 이전 회차 말투 샘플을 번역 프롬프트에 주입

기술 스택:
  Backend:  FastAPI (Python 3.11), SQLAlchemy 2.x, SQLite(개발)/PostgreSQL(프로덕션), Alembic
  Frontend: Next.js 14 (App Router), TypeScript, Tailwind CSS, shadcn/ui, Fabric.js, Zustand, TanStack Query
  AI/OCR:   Clova General OCR (Primary), Google Lens (Fallback), DeepL Free (번역 Primary), Groq LLM llama-3.3-70b-versatile (번역 후보 생성 + 화자매칭), llama-3.1-8b-instant (AI 검수)
  배포:     M1 맥미니 Docker + Vercel

디렉토리 구조:
  /backend   ← FastAPI
  /frontend  ← Next.js
```

---

---

## PHASE 0 — 프로젝트 초기 세팅 + 인증

```
[AI translate 프로젝트] Phase 0: 백엔드/프론트엔드 초기 세팅 및 JWT 인증 구현

━━━━ 프로젝트 개요 ━━━━
프로젝트명: 웹툰 자동 번역 어시스턴트
핵심 개념: Reader용 번역기(단일 반환)가 아닌 Translator용 번역 어시스턴트.
기술 스택:
  Backend:  FastAPI (Python 3.11), SQLAlchemy 2.x, SQLite(개발)/PostgreSQL(프로덕션), Alembic
  Frontend: Next.js 14 (App Router), TypeScript, Tailwind CSS, shadcn/ui, Zustand, TanStack Query
  배포:     M1 맥미니 Docker + Vercel

━━━━ Phase 0 작업 목표 ━━━━
백엔드/프론트엔드 뼈대 생성, DB 연결, JWT 인증 완료.

━━━━ 백엔드 작업 (backend/) ━━━━

1. 프로젝트 구조 생성
   다음 디렉토리/파일 구조를 생성한다:
   backend/
   ├── main.py
   ├── config.py
   ├── database.py
   ├── routers/auth.py
   ├── models/user.py
   ├── models/__init__.py
   ├── .env.example
   └── requirements.txt

2. requirements.txt
   fastapi==0.109.0
   uvicorn[standard]==0.27.0
   sqlalchemy==2.0.25
   alembic==1.13.1
   python-jose[cryptography]==3.3.0
   passlib[bcrypt]==1.7.4
   python-multipart==0.0.9
   aiohttp==3.9.3
   python-dotenv==1.0.0
   opencv-python-headless==4.9.0.80
   Pillow==10.2.0
   numpy==1.26.3
   pdf2image==1.17.0
   deepl==1.17.0
   groq==0.5.0

3. config.py — pydantic Settings로 환경변수 로드
   - ENVIRONMENT (default: "development")
   - DATABASE_URL (default: "sqlite:///./ailosy.db")
   - SECRET_KEY
   - ACCESS_TOKEN_EXPIRE_MINUTES (default: 60)
   - CLOVA_KEYS, CLOVA_URLS (콤마 구분 문자열)
   - DEEPL_KEYS, GROQ_KEYS (콤마 구분 문자열)
   - UPLOAD_DIR (default: "./data/uploads")
   - OUTPUT_DIR (default: "./data/outputs")

4. database.py
   - SQLAlchemy engine, SessionLocal, Base, get_db() 구현
   - SQLite: connect_args={"check_same_thread": False}
   - PostgreSQL: 별도 connect_args 없음
   조건: DATABASE_URL에 "sqlite" 포함 여부로 자동 분기

5. models/user.py
   class User(Base):
     __tablename__ = "users"
     id, email (unique), hashed_password, name, is_active, is_admin (Boolean, default=False), created_at
   - is_admin 필드는 관리자 대시보드 접근 권한 제어에 사용됨

6. JWT 인증 구현 (routers/auth.py)
   POST /auth/register   { email, password, name } → User 생성 + JWT 반환
   POST /auth/login      { email, password } → JWT 반환
   POST /auth/refresh    { refresh_token } → 새 access_token 반환
   GET  /auth/me         현재 로그인 유저 정보 반환
   - 비밀번호 해싱: passlib bcrypt
   - 토큰: python-jose, HS256, exp 포함
   - get_current_user(token) 의존성 함수 구현
   - get_admin_user(token): is_admin=True 유저만 허용하는 의존성 함수 (관리자 API에 사용)

7. main.py
   - FastAPI 앱, CORS 미들웨어 (개발: *, 프로덕션: Vercel 도메인만)
   - 요청 로깅 미들웨어 (method, path, status, 응답시간)
   - Alembic 대신 startup 이벤트에서 Base.metadata.create_all() 호출 (개발 편의)
   - /auth 라우터 등록

8. .env.example
   ENVIRONMENT=development
   DATABASE_URL=sqlite:///./ailosy.db
   SECRET_KEY=change-this-secret
   ACCESS_TOKEN_EXPIRE_MINUTES=60
   CLOVA_KEYS=key1,key2
   CLOVA_URLS=url1,url2
   DEEPL_KEYS=key1,key2
   GROQ_KEYS=key1,key2,key3
   UPLOAD_DIR=./data/uploads
   OUTPUT_DIR=./data/outputs

━━━━ 프론트엔드 작업 (frontend/) ━━━━

1. Next.js 14 프로젝트 생성
   npx create-next-app@latest frontend --typescript --tailwind --app --no-src-dir
   그 후 shadcn/ui 초기화: npx shadcn-ui@latest init
   추가 패키지: axios, @tanstack/react-query, zustand, next-auth

2. lib/api.ts — Axios 인스턴스
   - baseURL: process.env.NEXT_PUBLIC_API_URL
   - timeout: 60000
   - 요청 인터셉터: localStorage의 access_token을 Authorization: Bearer로 자동 첨부
   - 응답 인터셉터: 401 응답 시 access_token 삭제 + /login으로 리다이렉트

3. lib/types.ts — 공통 TypeScript 타입 정의
   interface User { id, email, name, isAdmin }
   interface JobStatus { status: 'pending'|'processing'|'done'|'failed', progress: number, error?: string }
   interface Character { id, name, description, speechStyle, speechExamples }
   interface Episode { id, number, title, synopsis, status, characterSituations }
   interface Bubble {
     id, pageId, labelIndex, x1, y1, x2, y2,
     originalText, speaker, speakerIsConfirmed,
     bubbleType: 'dialogue'|'sfx'|'narration',
     candidates: TranslationCandidate[]
   }
   interface TranslationCandidate { id, rank, text, rationale, isSelected, customText }

4. app/(auth)/login/page.tsx
   - 이메일 + 비밀번호 입력 폼
   - POST /auth/login 호출 → access_token을 localStorage에 저장
   - 로그인 성공 시 /dashboard로 이동

5. app/(auth)/register/page.tsx
   - 이름 + 이메일 + 비밀번호 입력 폼
   - POST /auth/register 호출 → 성공 시 /login으로 이동

6. middleware.ts (루트)
   - 로그인 안 된 상태에서 /dashboard, /projects/* 접근 시 /login으로 리다이렉트
   - localStorage access_token 존재 여부로 판단 (Next.js 미들웨어는 쿠키 기반으로 변경 필요 시 쿠키 사용)

━━━━ 완료 기준 ━━━━
- [ ] uvicorn main:app --reload 실행 후 GET /docs 에서 Swagger UI 접근 가능
- [ ] POST /auth/register → POST /auth/login → access_token 반환 확인
- [ ] GET /auth/me 에서 로그인된 유저 정보 반환 확인
- [ ] npm run dev 실행 후 /login 페이지 렌더링, 로그인 후 /dashboard 이동 확인
```

---

## PHASE 1-A — 백엔드: DB 모델 전체 + 프로젝트/회차 CRUD

```
[AI translate 프로젝트] Phase 1-A: DB 전체 모델 생성 + 프로젝트·캐릭터·회차 CRUD API

━━━━ 프로젝트 개요 ━━━━
프로젝트명: 웹툰 자동 번역 어시스턴트
기술 스택: FastAPI (Python 3.11), SQLAlchemy 2.x, SQLite/PostgreSQL
Phase 0 완료 상태: FastAPI 앱, JWT 인증, User 모델, database.py 구현 완료.

━━━━ Phase 1-A 작업 목표 ━━━━
프로젝트에 필요한 모든 DB 모델 생성 + 프로젝트/캐릭터/회차 CRUD API 구현.

━━━━ 작업 1: DB 모델 전체 생성 (backend/models/) ━━━━

아래 파일들을 생성한다. 각 모델의 필드는 명세 그대로 구현한다.

[models/project.py]
class Project(Base):
  __tablename__ = "projects"
  id, owner_id (FK→users.id), title, genre, synopsis, source_lang (default:"JA"), target_lang (default:"KO")
  created_at, updated_at (onupdate)
  relationships: owner→User, episodes→Episode (order_by number), characters→Character

class Character(Base):
  __tablename__ = "characters"
  id, project_id (FK→projects.id), name, description, speech_style, speech_examples
  relationships: project→Project, episode_situations→EpisodeCharacterSituation
  speech_samples relationship → CharacterSpeechSample (order_by desc created_at)

  메서드 get_past_speech_samples(limit=5) → list[dict]:
    # is_edited=True 항목 우선 정렬, episode_number 내림차순
    # 반환: [{"original": str, "translated": str, "episode_number": int, "is_edited": bool}]

class CharacterSpeechSample(Base):
  __tablename__ = "character_speech_samples"
  id, character_id (FK→characters.id), episode_number, original_text, translated_text
  is_edited (Boolean, default=False), created_at
  # is_edited=True: 번역가가 직접 수정하거나 입력한 것
  # is_edited=False: AI 후보 원안 그대로 선택

[models/episode.py]
class Episode(Base):
  __tablename__ = "episodes"
  id, project_id (FK→projects.id), number, title, synopsis
  status (default:"created")
  # status 값: created → uploaded → ocr_done → labeled → translating → translated → reviewed → done
  created_at, updated_at
  relationships: project→Project, pages→Page (order_by order), character_situations→EpisodeCharacterSituation, jobs→Job

  메서드 get_character_situation(character_name: str) → str:
    # 해당 캐릭터의 이번 회차 상황 반환, 없으면 "미지정"

class EpisodeCharacterSituation(Base):
  __tablename__ = "episode_character_situations"
  id, episode_id (FK→episodes.id), character_id (FK→characters.id), situation (Text)
  relationships: episode→Episode, character→Character

[models/page.py]
class Page(Base):
  __tablename__ = "pages"
  id, episode_id (FK→episodes.id), order, original_filename, image_path, rendered_path
  ocr_status (default:"pending")  # pending / done / failed
  relationships: episode→Episode, bubbles→Bubble (order_by label_index)

[models/bubble.py]
from sqlalchemy import Float  # 추가 필요
class Bubble(Base):
  __tablename__ = "bubbles"
  id (String PK, default=uuid4), page_id (FK→pages.id)
  label_index, x1, y1, x2, y2 (Integer)
  original_text (Text), ocr_confidence (Float)
  speaker, speaker_confidence (Float), speaker_is_confirmed (Boolean, default=False)
  bubble_type (default:"dialogue")  # dialogue / sfx / narration
  font_family (default:"NanumGothic"), font_size (Integer), text_color (default:"#000000")
  relationships: page→Page, candidates→TranslationCandidate (order_by rank), review_suggestions→ReviewSuggestion
  properties: width, height (x2-x1, y2-y1)
  property confirmed_translation: candidates 중 is_selected=True인 것의 custom_text 또는 text 반환

class TranslationCandidate(Base):
  __tablename__ = "translation_candidates"
  id, bubble_id (FK→bubbles.id), rank, text (Text), rationale (Text), translation_engine
  is_selected (Boolean, default=False), custom_text (Text)
  created_at, updated_at

[models/review_suggestion.py]
class ReviewSuggestion(Base):
  __tablename__ = "review_suggestions"
  id, bubble_id (FK→bubbles.id)
  issue_type  # consistency / mistranslation / unnatural / sfx
  original_translation, suggested_translation, reason (Text)
  status (default:"pending")  # pending / accepted / rejected
  created_at

[models/job.py]
class Job(Base):
  __tablename__ = "jobs"
  id (String PK, default=uuid4), episode_id (FK→episodes.id)
  job_type  # ocr / speaker_match / translate / ai_review / render
  status (default:"pending")  # pending / processing / done / failed
  progress (Integer, default=0)
  error_message (Text), started_at, completed_at, created_at

[models/api_usage_log.py]
class APIUsageLog(Base):
  __tablename__ = "api_usage_logs"
  id, user_id (FK→users.id), episode_id (FK→episodes.id, nullable=True)
  service (String)  # clova_ocr / google_lens / deepl / groq_translate / groq_review / groq_speaker
  request_count (Integer, default=1), char_count (Integer, default=0), token_count (Integer, default=0)
  status (default:"success")  # success / failed / quota_exceeded
  used_key_suffix (String)  # 어느 API Key 끝 4자리
  created_at (DateTime, index=True)

[models/__init__.py]
모든 모델 import 후 __all__ 정의

main.py의 startup 이벤트에서 Base.metadata.create_all(bind=engine) 호출하여 전체 테이블 자동 생성.

━━━━ 작업 2: 프로젝트/캐릭터 CRUD API (backend/routers/projects.py) ━━━━

모든 엔드포인트는 get_current_user 의존성으로 인증 필수.
본인 소유 프로젝트만 접근 가능 (owner_id 검증).

POST   /projects
  Body: { title, genre, source_lang, target_lang, synopsis,
          characters: [{name, description, speech_style, speech_examples}] }
  → Project + Character 일괄 생성, 생성된 프로젝트 반환

GET    /projects
  → 내 프로젝트 목록 반환 { items: [...], total: N }

GET    /projects/{id}
  → 프로젝트 상세 (characters 포함)

PATCH  /projects/{id}
  Body: { title?, genre?, synopsis?, source_lang?, target_lang? }

DELETE /projects/{id}
  → 프로젝트 + 하위 리소스 cascade 삭제

POST   /projects/{id}/characters
  Body: { name, description, speech_style, speech_examples }

PATCH  /projects/{id}/characters/{char_id}
  Body: { name?, description?, speech_style?, speech_examples? }

DELETE /projects/{id}/characters/{char_id}

━━━━ 작업 3: 회차 관리 API (backend/routers/episodes.py) ━━━━

POST   /projects/{id}/episodes
  Body: { number, title, synopsis,
          character_situations: [{character_id, situation}] }
  → Episode + EpisodeCharacterSituation 일괄 생성

GET    /projects/{id}/episodes
  → 회차 목록 (number 오름차순)

GET    /projects/{id}/episodes/{ep_id}
  → 회차 상세 (character_situations 포함)

PATCH  /projects/{id}/episodes/{ep_id}
  Body: { title?, synopsis?, character_situations? }
  character_situations가 포함된 경우 기존 것 삭제 후 재생성

━━━━ 에러 핸들링 원칙 ━━━━
- 존재하지 않는 리소스: HTTPException(404)
- 권한 없음 (남의 프로젝트): HTTPException(403)
- 모든 응답은 Pydantic 스키마로 직렬화 (schemas/ 폴더 생성)

━━━━ 완료 기준 ━━━━
- [ ] 모든 테이블이 DB에 생성됨 (startup 로그 확인)
- [ ] POST /projects → GET /projects/{id} → 캐릭터 포함 응답 확인
- [ ] POST /projects/{id}/episodes → GET 응답에 character_situations 포함 확인
```

---

## PHASE 1-B — 백엔드: 파일 업로드 + OCR 파이프라인 + KeyRotator

```
[AI translate 프로젝트] Phase 1-B: 파일 업로드 + OCR 파이프라인 + KeyRotator 구현

━━━━ 프로젝트 개요 ━━━━
프로젝트명: 웹툰 자동 번역 어시스턴트
기술 스택: FastAPI (Python 3.11), SQLAlchemy 2.x, OpenCV, Pillow, pdf2image, aiohttp
Phase 0, 1-A 완료 상태:
  - JWT 인증, 전체 DB 모델, 프로젝트/회차 CRUD API 구현 완료.
  - backend/models/ 에 모든 모델 존재.

━━━━ Phase 1-B 작업 목표 ━━━━
파일 업로드(이미지/PDF), Clova OCR 실행, 말풍선 감지 + 번호 라벨링까지 완성.

━━━━ 작업 1: KeyRotator 구현 (backend/services/key_rotator.py) ━━━━

아래 스펙을 정확히 구현한다:

@dataclass
class KeyInfo:
  key: str
  extra: dict  # Clova는 {"url": "..."} 포함
  is_active: bool = True
  fail_count: int = 0
  quota_reset_at: Optional[float] = None  # epoch 시각

class QuotaExceededError(Exception): pass

class KeyRotator:
  - __init__(keys: list[KeyInfo], service_name: str)
  - classmethod from_env(service: str):
      CLOVA:  CLOVA_KEYS=k1,k2  / CLOVA_URLS=url1,url2  → extra={"url": url}
      DEEPL:  DEEPL_KEYS=k1,k2
      GROQ:   GROQ_KEYS=k1,k2,k3
  - get_key() → KeyInfo:
      1. 만료된 비활성 Key 중 quota_reset_at <= now인 것 재활성화
      2. deque에서 라운드로빈으로 active Key 반환
      3. 전부 비활성 시 QuotaExceededError raise
  - report_success(key_info)
  - report_quota_exceeded(key_info, reset_hours=24): is_active=False, reset_at 설정
  - report_error(key_info, error): fail_count += 1, 3회 이상이면 5분 비활성화
  - property status → dict: total, active, keys 목록 (key 끝 4자리만 노출)

━━━━ 작업 2: Clova OCR 클라이언트 (backend/services/clova_ocr.py) ━━━━

class ClovaOCRClient:
  @staticmethod
  async def request(image_bytes: bytes, key_info: KeyInfo) -> dict:
    - aiohttp로 Clova General OCR API 호출
    - payload: { images: [{format:"jpg", name:"image"}], requestId: uuid4, version:"V2", timestamp: ms }
    - multipart/form-data: "message" 필드 (JSON), "file" 필드 (이미지 bytes)
    - 헤더: X-OCR-SECRET: key_info.key
    - URL: key_info.extra["url"]
    - 429 응답 → QuotaExceededError raise
    - 응답 JSON 반환

━━━━ 작업 3: OCR 파이프라인 (backend/pipeline/ocr_pipeline.py) ━━━━

class OCRPipeline:
  def __init__(self):
    self.clova_rotator = KeyRotator.from_env("CLOVA")

  async def process_page(self, image_bytes: bytes) -> list[dict]:
    """
    반환: [{"id": uuid, "x1", "y1", "x2", "y2", "text", "confidence", "type", "label_index"}]
    type: "dialogue" | "sfx" | "narration" (기본값 "dialogue")
    """
    1. Clova OCR 호출 (clova_rotator.get_key() → ClovaOCRClient.request)
       429/QuotaExceededError → 로그 출력 후 Google Lens stub 호출
       기타 에러 → report_error 후 re-raise
    2. _parse_clova_result(result) → boxes 리스트
       Clova 응답의 images[0].fields 에서 inferText, boundingPoly 파싱
    3. _merge_nearby_boxes(boxes, threshold=30):
       x축 overlap 있고 y축 거리 threshold 미만인 박스 병합
       병합된 박스: text 공백 연결, 좌표는 합집합, confidence는 최소값
    4. _sort_reading_order(boxes):
       웹툰 읽기 순서: y1 // 50 기준 행 구분, 같은 행은 x1 내림차순 (오른쪽→왼쪽)
    5. label_index 부여 (1부터)
    6. 각 박스에 uuid id 부여

  async def _google_lens_fallback(self, image_bytes) → list[dict]:
    # stub: 빈 리스트 반환 + 로그 출력 ("Google Lens fallback - not yet implemented")

━━━━ 작업 4: 파일 업로드 API (backend/routers/upload.py) ━━━━

POST /episodes/{ep_id}/pages/upload
  - UploadFile 리스트 받음 (multipart, 다중 파일)
  - 각 파일 처리:
    - PDF → pdf2image.convert_from_bytes() → 각 페이지를 JPEG로 변환
    - 이미지(jpg/png) → 그대로 저장
  - 저장 경로: {UPLOAD_DIR}/{episode_id}/page_{order:03d}.jpg
  - Page 레코드 생성 (order는 기존 페이지 수 기준으로 자동 부여)
  - 생성된 Page 목록 반환

GET /episodes/{ep_id}/pages
  → Page 목록 반환 (order 오름차순)

DELETE /episodes/{ep_id}/pages/{page_id}
  → 파일 삭제 + DB 레코드 삭제

━━━━ 작업 5: OCR Job API (backend/routers/ocr.py) ━━━━

인메모리 job_store = {} 사용 (MVP).

POST /episodes/{ep_id}/jobs/ocr
  - Job 레코드 DB 저장 (job_type="ocr", status="pending")
  - BackgroundTasks로 run_ocr_job 실행
  - { "job_id": str } 반환

GET /jobs/{job_id}/status
  - job_store에서 조회: { status, progress, error? } 반환

async def run_ocr_job(job_id, episode_id, db):
  - job_store 상태 업데이트하며 진행
  - 페이지별 OCRPipeline.process_page() 호출
  - 결과를 Bubble 레코드로 DB 저장
    - bubble_type 판별: 텍스트가 의성어 패턴(가타카나 多, 2글자 이하)이면 "sfx", 나레이션 박스면 "narration"
  - 완료 후 Episode.status = "ocr_done" 업데이트
  - 사용된 Key의 APIUsageLog 레코드 저장 (service="clova_ocr", request_count=1)

GET /pages/{page_id}/bubbles
  → 해당 페이지의 Bubble 목록 (label_index 오름차순)

PATCH /bubbles/{bubble_id}
  Body: { original_text?, x1?, y1?, x2?, y2?, bubble_type?, speaker? }
  → 부분 업데이트

DELETE /bubbles/{bubble_id}
  → 삭제

POST /pages/{page_id}/bubbles
  Body: { x1, y1, x2, y2, original_text, bubble_type }
  → 새 Bubble 생성, label_index는 현재 최대값 + 1

━━━━ 완료 기준 ━━━━
- [ ] POST /episodes/{ep_id}/pages/upload → Page 레코드 생성 확인
- [ ] POST /episodes/{ep_id}/jobs/ocr → job_id 반환 확인
- [ ] GET /jobs/{job_id}/status → progress 증가 폴링 확인
- [ ] OCR 완료 후 GET /pages/{page_id}/bubbles → label_index 포함 Bubble 목록 반환 확인
- [ ] KeyRotator: GROQ_KEYS 미설정 시 ValueError 발생 확인
- [ ] KeyRotator: report_quota_exceeded 후 get_key() 시 해당 Key 제외 확인
```

---

## PHASE 1-C — 프론트엔드: 대시보드 + 프로젝트 생성 + 업로드 화면

```
[AI translate 프로젝트] Phase 1-C: 프론트엔드 - 대시보드, 프로젝트 생성, 파일 업로드 화면

━━━━ 프로젝트 개요 ━━━━
프로젝트명: 웹툰 자동 번역 어시스턴트
기술 스택: Next.js 14 (App Router), TypeScript, Tailwind CSS, shadcn/ui, Zustand, TanStack Query, axios, react-dropzone
API Base URL: process.env.NEXT_PUBLIC_API_URL

Phase 0, 1-A, 1-B 완료 상태:
  - 백엔드 API: /auth/*, /projects/*, /projects/{id}/episodes/*, /episodes/{ep_id}/pages/upload,
                /episodes/{ep_id}/jobs/ocr, /jobs/{job_id}/status, /pages/{page_id}/bubbles 완성

━━━━ Phase 1-C 작업 목표 ━━━━
로그인 후 프로젝트를 생성하고, 회차를 만들고, 이미지를 업로드해서 OCR을 시작하는
전체 흐름을 UI로 완성한다.

━━━━ 작업 1: 공통 훅 및 컴포넌트 ━━━━

hooks/useJobPolling.ts:
  useJobPolling(jobId: string | null):
  - TanStack Query useQuery 사용
  - queryKey: ['job', jobId]
  - refetchInterval: done/failed이면 false, 그 외 2000ms
  - { status, progress, isDone, isFailed, error } 반환

components/common/JobProgressBar.tsx:
  props: { progress: number, status: string, label?: string }
  - Tailwind 기반 progress bar
  - status별 색상: processing=파랑, done=초록, failed=빨강

components/common/PageNavigator.tsx:
  props: { currentPage: number, totalPages: number, onPageChange: (n: number) => void }
  - 썸네일 없이 [← 이전] 1/24 [다음 →] 버튼 형태

store/projectStore.ts (Zustand):
  - currentProjectId: number | null
  - currentEpisodeId: number | null
  - setCurrentProject, setCurrentEpisode

━━━━ 작업 2: 대시보드 (app/dashboard/page.tsx) ━━━━

- GET /projects 호출 → 프로젝트 카드 목록 표시
- 각 카드: 프로젝트 제목, 장르, 원본→번역 언어, 회차 수, 최근 업데이트
- 카드 클릭 → /projects/{id} 이동
- 상단 우측 [+ 새 프로젝트] 버튼 → /projects/new 이동

━━━━ 작업 3: 프로젝트 생성 화면 (app/projects/new/page.tsx) ━━━━

아래 UI 구조로 구현한다:
  - 작품 제목 (Input)
  - 원본 언어 / 번역 언어 (Select, 기본값: 일본어 / 한국어)
  - 장르 (Select: 판타지/로맨스/액션/일상/기타)
  - 작품 전체 줄거리 (Textarea, placeholder: "시리즈 전반의 세계관·갈등 구조를 입력하세요")
  - 캐릭터 테이블:
    - 컬럼: 이름 | 성격 | 말투 스타일 | 말투 예시 | 삭제
    - 각 셀은 인라인 Input으로 편집 가능
    - [캐릭터 추가 +] 버튼으로 행 추가
    - 🗑 버튼으로 행 삭제
  - [프로젝트 생성하기 →] 버튼

제출 시:
  POST /projects 호출
  성공 시 /projects/{id} 이동

━━━━ 작업 4: 프로젝트 상세 (app/projects/[projectId]/page.tsx) ━━━━

- GET /projects/{id} 호출 → 프로젝트 정보 + 캐릭터 목록 표시
- GET /projects/{id}/episodes 호출 → 회차 목록 (카드 형태, status 배지 포함)
- [+ 새 회차 추가] 버튼 → 인라인 폼 또는 모달
  POST /projects/{id}/episodes
  Body: { number, title, synopsis, character_situations: [{character_id, situation}] }
- 회차 카드 클릭 → /projects/{id}/episodes/{ep_id}/upload 이동

━━━━ 작업 5: 파일 업로드 + 회차 컨텍스트 입력 화면 ━━━━
app/projects/[projectId]/episodes/[episodeId]/upload/page.tsx

상단: 프로젝트명 > 회차 제목 > 파일 업로드

섹션 1 — 파일 업로드:
  components/common/FileUploader.tsx
  - react-dropzone 사용
  - 허용: jpg, png, pdf
  - 드롭 시 미리보기 썸네일 목록 표시
  - [업로드 시작] 버튼 → POST /episodes/{ep_id}/pages/upload
  - 업로드 성공 후 "24개 페이지 업로드 완료" 표시

섹션 2 — 회차 컨텍스트 (회차 생성 시 입력했지만 여기서도 수정 가능):
  - 회차 제목 (Input)
  - 이번 회차 줄거리 (Textarea)
  - 캐릭터별 이번 회차 상황 테이블:
    - 프로젝트의 캐릭터 목록 자동 표시
    - 각 캐릭터 옆 상황 Input
  - [저장] 버튼 → PATCH /projects/{id}/episodes/{ep_id}

하단 [OCR 시작 →] 버튼:
  - POST /episodes/{ep_id}/jobs/ocr 호출
  - JobProgressBar 표시 (useJobPolling으로 폴링)
  - isDone=true 시 /projects/{id}/episodes/{ep_id}/labeling 이동

━━━━ 완료 기준 ━━━━
- [ ] /dashboard에서 프로젝트 목록 카드 렌더링 확인
- [ ] 프로젝트 생성 폼 제출 후 /projects/{id} 이동 확인
- [ ] 캐릭터 테이블 행 추가/삭제 동작 확인
- [ ] 파일 드롭 → 업로드 → OCR 시작 → 진행률 바 표시 확인
- [ ] OCR 완료 후 /labeling 자동 이동 확인
```

---

## PHASE 2 — 화자 매칭 + 라벨링 검수 (백엔드 + 프론트엔드)

```
[AI translate 프로젝트] Phase 2: 화자 매칭 파이프라인 + 라벨링 검수 UI

━━━━ 프로젝트 개요 ━━━━
프로젝트명: 웹툰 자동 번역 어시스턴트
기술 스택:
  Backend:  FastAPI, SQLAlchemy, Groq SDK (llama-3.3-70b-versatile)
  Frontend: Next.js 14, TypeScript, Tailwind, shadcn/ui, Fabric.js
Phase 0~1 완료 상태: 인증, DB 모델, 프로젝트/회차 CRUD, 파일 업로드, OCR 파이프라인 완료.

━━━━ Phase 2 작업 목표 ━━━━
각 말풍선의 화자를 자동으로 추론하고, 번역가가 이미지 위에서 검수하는 화면 완성.

━━━━ 백엔드 작업 ━━━━

[services/groq_client.py]
class GroqChatClient:
  def __init__(self, rotator: KeyRotator)
  async def chat(self, prompt: str, model: str = "llama-3.3-70b-versatile") → str:
    - rotator.get_key()로 Key 획득
    - groq SDK로 chat.completions.create 호출
    - 응답 텍스트 반환
    - 성공: report_success, 실패: report_error
  def parse_json(self, text: str) → any:
    - ```json ... ``` 펜스 제거 후 json.loads
    - 실패 시 ValueError("JSON 파싱 실패: {원본 텍스트}")

[pipeline/speaker_matcher.py]
class SpeakerMatcher:
  def __init__(self, groq_client: GroqChatClient)

  async def match_speakers(self, image_bytes: bytes, bubbles: list[dict], characters: list[dict]) → list[dict]:
    """각 bubble에 speaker 필드 추가하여 반환"""
    1. _llm_speaker_matching()으로 화자 추론
    2. 결과를 bubbles에 병합 → speaker, speaker_confidence 업데이트
    3. confidence < 0.6 이면 speaker = "미확인"

  async def _llm_speaker_matching(self, image_bytes, bubbles, characters) → list[dict]:
    char_names = [c['name'] for c in characters] + ["효과음", "나레이션", "미확인"]
    prompt = f"""웹툰 말풍선의 화자를 추론하세요.
등장 캐릭터: {char_names}
말풍선 목록 (idx: 텍스트 / 위치):
{[{"idx": i, "text": b['text'], "pos": f"({b['x1']},{b['y1']})"} for i, b in enumerate(bubbles)]}

각 말풍선의 화자를 위 캐릭터 중에서 선택하세요.
확실하지 않으면 "미확인"으로 표시하세요.
JSON으로만 응답: [{{"bubble_idx": 0, "speaker": "캐릭터명", "confidence": 0.8}}]"""
    response = await groq_client.chat(prompt)
    return groq_client.parse_json(response)

  이미지 bytes는 현재 LLM에 직접 전달하지 않음 (텍스트 기반 위치 정보만 사용).
  추후 vision 모델 연동 확장 예정.

[routers/labeling.py]
POST /episodes/{ep_id}/jobs/speaker-match
  - Job 생성 (job_type="speaker_match")
  - BackgroundTasks로 run_speaker_match_job 실행
  - { "job_id": str } 반환

  async def run_speaker_match_job(job_id, episode_id, db):
    - 에피소드의 모든 페이지 순회
    - 각 페이지 bubbles + characters로 SpeakerMatcher.match_speakers() 호출
    - Bubble.speaker, Bubble.speaker_confidence 업데이트
    - APIUsageLog 저장 (service="groq_speaker")
    - Episode.status = "labeled" 업데이트

PATCH /bubbles/{bubble_id}/speaker
  Body: { speaker: str }
  → Bubble.speaker 업데이트, speaker_is_confirmed = True

POST /episodes/{ep_id}/speaker-match/confirm-all
  → 해당 에피소드 모든 Bubble.speaker_is_confirmed = True

━━━━ 프론트엔드 작업 ━━━━

[components/labeling/LabelingCanvas.tsx]
Fabric.js 기반 캔버스:
- 웹툰 이미지를 배경으로 로드
- 각 Bubble의 x1,y1,x2,y2에 사각형 테두리 렌더링
  - 화자 확정: 초록(#22c55e), 미확인: 빨강(#ef4444), 기본: 파랑(#3b82f6)
- 말풍선 좌상단에 원형 배지 + 숫자 (label_index) 렌더링
- 말풍선 클릭 → onBubbleClick(bubbleId) 콜백 호출

[components/labeling/BubbleList.tsx]
사이드바 말풍선 목록:
- 각 항목: 번호 배지 | 화자 선택 드롭다운 | 원문 텍스트 (인라인 편집 가능)
- 화자 드롭다운: 프로젝트 캐릭터 목록 + ["효과음", "나레이션", "미확인"]
- 화자 변경 시 PATCH /bubbles/{id}/speaker 호출
- ⚠️ 미확인 화자 항목에 경고 아이콘 표시
- 현재 선택된 bubbleId에 해당하는 항목 하이라이트

[app/projects/[projectId]/episodes/[episodeId]/labeling/page.tsx]
레이아웃:
- 상단 바: [← 뒤로] 제목 [AI 화자 재매칭] [전체 승인] [다음 단계 →]
- 좌측 (2/3): LabelingCanvas + PageNavigator (하단)
- 우측 (1/3): BubbleList

동작:
- 페이지 진입 시 GET /jobs/{job_id}/status 폴링 (화자 매칭 Job이 있는 경우)
- 이미지 없으면 POST /episodes/{ep_id}/jobs/speaker-match 자동 실행
- LabelingCanvas에서 말풍선 클릭 → BubbleList 해당 항목으로 스크롤 + 하이라이트
- [전체 승인] → POST /episodes/{ep_id}/speaker-match/confirm-all
- [다음 단계 →] → /projects/{id}/episodes/{ep_id}/translation 이동
  미확인 화자가 있으면 shadcn Alert 경고 표시 (이동은 허용)

━━━━ 완료 기준 ━━━━
- [ ] POST /episodes/{ep_id}/jobs/speaker-match 실행 후 Bubble.speaker 업데이트 확인
- [ ] Fabric.js 캔버스에서 말풍선 번호 배지 렌더링 확인
- [ ] 화자 드롭다운 변경 → PATCH 전송 → 배지 색상 변경 확인
- [ ] [전체 승인] 클릭 → 모든 bubble speaker_is_confirmed=True 확인
```

---

## PHASE 3 — 번역 파이프라인 + 테이블 뷰 편집기

```
[AI translate 프로젝트] Phase 3: 번역 파이프라인 (컨텍스트 기반 후보 생성) + 테이블 뷰 편집기

━━━━ 프로젝트 개요 ━━━━
프로젝트명: 웹툰 자동 번역 어시스턴트
핵심: AI가 번역 후보 3~4개를 Survey형(①②③ + ④직접입력)으로 제안.
      프롬프트에 [작품줄거리 + 회차줄거리 + 캐릭터어투 + 이전회차말투샘플] 주입.
기술 스택:
  Backend:  FastAPI, Groq SDK (llama-3.3-70b-versatile), deepl SDK
  Frontend: Next.js 14, TypeScript, Tailwind, shadcn/ui, TanStack Query
Phase 0~2 완료 상태: 인증, DB 모델, OCR, 화자 매칭 완료.

━━━━ Phase 3 작업 목표 ━━━━
컨텍스트 기반 번역 후보 생성 + Survey형 선택 UI(테이블 뷰) 완성.

━━━━ 백엔드 작업 ━━━━

[services/deepl_client.py]
class DeepLClient:
  def __init__(self, rotator: KeyRotator)
  async def translate_batch(self, texts: list[str], target_lang: str = "KO") → list[str]:
    - deepl.AsyncTranslator 사용
    - 50개씩 분할 배치 처리
    - 429 → rotator.report_quota_exceeded + QuotaExceededError re-raise
    - 성공 → rotator.report_success

[pipeline/context_builder.py]
def build_candidate_prompt(project, episode, bubble, character) → str:
  """
  번역 후보 3~4개 생성 프롬프트.
  [작품 전체 컨텍스트] + [이번 회차 컨텍스트] + [화자 캐릭터 프로필]
  + [이 캐릭터의 이전 회차 번역 샘플 (character.get_past_speech_samples(5))]
  + [번역할 원문]
  를 모두 포함한다.

  이전 말투 샘플 블록 (샘플 없으면 해당 섹션 생략):
    [이 캐릭터의 이전 회차 번역 샘플] ← 말투 일관성 참고 (번역가 최종 확정본)
      원문: {s.original} → 번역: {s.translated}  (EP.{s.episode_number} / {"번역가 수정" if s.is_edited else "AI 원안"})
      ... (최대 5개)

  응답 형식 지정:
  반드시 아래 JSON으로만 응답:
  {"candidates": [{"rank":1,"text":"번역문","rationale":"이유"},{"rank":2,...},{"rank":3,...}]}
  """

def build_past_speech_block(character, limit=5) → str:
  """character.get_past_speech_samples(limit) 결과를 프롬프트 블록으로 변환"""

[pipeline/translation_pipeline.py]
class TranslationPipeline:
  def __init__(self, deepl_client, groq_client)

  async def translate_with_candidates(self, project, episode, bubble, character) → list[dict]:
    """말풍선 하나 → 후보 3~4개 반환 (Groq LLM 사용)"""
    - context_builder.build_candidate_prompt() 호출
    - groq_client.chat(prompt, model="llama-3.3-70b-versatile")
    - parse_json()으로 candidates 파싱
    - 파싱 실패 시 최소 1개 후보 반환 (fallback)

  async def translate_batch_simple(self, bubbles: list, target_lang: str = "KO") → list[dict]:
    """DeepL 배치 번역 (단일 후보, 빠름) - Groq 쿼터 절약용"""
    - DeepL 호출 → 실패 시 Groq 폴백
    - 반환: [{"bubble_id", "candidates": [{"rank":1,"text":"...","rationale":"DeepL 번역"}]}]

[routers/translation.py]
POST /episodes/{ep_id}/jobs/translate
  - Job 생성 (job_type="translate")
  - BackgroundTasks로 run_translate_job 실행
  - { "job_id": str } 반환

  async def run_translate_job(job_id, episode_id, db):
    - 에피소드의 모든 Bubble 조회
    - 각 Bubble에 대해 translate_with_candidates() 호출
    - TranslationCandidate 레코드 생성 (rank 1,2,3)
    - APIUsageLog 저장 (service="groq_translate", token_count 추정값)
    - Episode.status = "translated" 업데이트
    - 번역 완료된 Bubble의 CharacterSpeechSample은 아직 생성하지 않음
      (번역가가 후보 선택 시 생성)

GET /bubbles/{bubble_id}/candidates
  Response:
  {
    "bubble_id": str,
    "original_text": str,
    "speaker": str,
    "candidates": [{"rank", "text", "rationale", "is_selected"}],
    "selected_rank": int | null,
    "custom_text": str | null
  }

PATCH /bubbles/{bubble_id}/translation
  Body: { "selected_candidate_rank": int | null, "custom_text": str | null }
  처리:
    1. 기존 is_selected=True인 TranslationCandidate → is_selected=False
    2. selected_candidate_rank 있으면 해당 candidate.is_selected=True
    3. custom_text 있으면 rank=0 candidate 생성 또는 업데이트
    4. CharacterSpeechSample 저장:
       - original_text = bubble.original_text
       - translated_text = 선택된 번역문
       - episode_number = episode.number
       - is_edited = (custom_text is not None) or (번역가가 후보 텍스트를 수정한 경우)
    5. 수정된 candidates 반환

POST /bubbles/{bubble_id}/candidates/regenerate
  Body: { "additional_context": str }
  - 기존 candidates 삭제 후 translate_with_candidates() 재실행
  - additional_context를 프롬프트 말미에 추가
  - 새 candidates 반환

GET /episodes/{ep_id}/translation-status
  Response: { "total": int, "selected": int, "pending": int, "progress_pct": float }
  - selected = is_selected=True인 candidate를 가진 bubble 수

━━━━ 프론트엔드 작업 ━━━━

[store/editorStore.ts] (Zustand)
interface EditorStore:
  viewMode: 'table' | 'image'
  selectedBubbleId: string | null
  currentPage: number
  filterMode: 'all' | 'pending'
  + setter 함수들

[components/translation/CandidateSelector.tsx] ⭐ 핵심 컴포넌트
props: { bubbleId, candidates, selectedRank, customText, onConfirm }
UI:
  - 원문 텍스트 표시
  - 후보 목록 (라디오 버튼):
    각 후보: ● ① [번역문] 아래 작게 [이유 텍스트]
  - ④ 직접 입력: 텍스트 Input (값 입력 시 자동으로 선택 상태)
  - [🔄 후보 재생성] 버튼 → 모달에서 additional_context 입력 후 POST regenerate 호출
  - [이 번역 확정 →] 버튼 → PATCH /bubbles/{id}/translation 호출
  선택 상태: 선택된 행은 배경 강조 (bg-blue-50 border-blue-500)

[components/translation/TranslationTable.tsx]
- GET /episodes/{ep_id}/translation-status로 진행률 표시
- GET /pages/{page_id}/bubbles + GET /bubbles/{id}/candidates로 데이터 조회
- 컬럼: 위치(페이지-번호) | 화자 | 원문 | [CandidateSelector]
- filterMode='pending': is_selected=False인 bubble만 표시
- 하단: 진행률 바 + "87/120 완료" + [⚠️ 미선택만 보기] 토글

[app/projects/[projectId]/episodes/[episodeId]/translation/page.tsx]
- 상단 탭: [테이블 뷰] / [이미지 뷰]
- 상단 우측: [AI 검수 실행] [최종 출력 →]
- viewMode=table: TranslationTable
- viewMode=image: Phase 4에서 구현 (현재는 "이미지 뷰는 Phase 4에서 구현 예정" 플레이스홀더)
- 페이지 진입 시 번역 Job이 없으면 자동으로 POST /episodes/{ep_id}/jobs/translate 실행
  + JobProgressBar 표시

━━━━ 완료 기준 ━━━━
- [ ] 번역 Job 완료 후 GET /bubbles/{id}/candidates → candidates 3개 반환 확인
- [ ] CandidateSelector에서 ① 클릭 → PATCH selected_candidate_rank=1 전송 확인
- [ ] ④ 직접 입력 후 확정 → PATCH custom_text 전송 확인
- [ ] CharacterSpeechSample 레코드 생성 확인 (is_edited 플래그 포함)
- [ ] GET /episodes/{ep_id}/translation-status → progress_pct 정확히 계산 확인
- [ ] filterMode 토글로 미선택 bubble만 필터링 확인
```

---

## PHASE 4 — 이미지 뷰 편집기 (Fabric.js)

```
[AI translate 프로젝트] Phase 4: 이미지 뷰 편집기 — Fabric.js 캔버스 + 번역 오버레이

━━━━ 프로젝트 개요 ━━━━
프로젝트명: 웹툰 자동 번역 어시스턴트
기술 스택: Next.js 14, TypeScript, Tailwind, Fabric.js, Zustand, TanStack Query
Phase 0~3 완료 상태: 번역 파이프라인, 테이블 뷰 편집기 완료.

━━━━ Phase 4 작업 목표 ━━━━
이미지 뷰 탭 완성: 웹툰 이미지 위에 번호 배지를 렌더링하고,
말풍선 클릭 시 우측 패널에서 번역 후보를 선택하면 즉시 오버레이 업데이트.

━━━━ 작업 ━━━━

[hooks/useFabricCanvas.ts]
useFabricCanvas(canvasRef: RefObject<HTMLCanvasElement>, imageUrl: string):
  - useEffect로 fabric.Canvas 초기화, cleanup 시 canvas.dispose()
  - fabric.Image.fromURL로 이미지 배경 로드
  - renderBubbles(bubbles: Bubble[], onBubbleClick: (id: string) => void):
    각 bubble에 대해:
    1. 사각형 테두리 (isConfirmed: 초록, 미확정: 파랑)
    2. 원형 배지 + label_index 텍스트 (좌상단)
    3. isConfirmed && translatedText 있으면:
       - 흰 반투명 Rect 오버레이 (fill: rgba(255,255,255,0.9))
       - Textbox로 번역문 표시 (fontSize: 13, fontFamily: NanumGothic, center 정렬)
    4. border.on('mousedown') → onBubbleClick(bubble.id)
    5. canvas.renderAll()
  - { fabricRef, renderBubbles } 반환

[components/editor/FabricCanvas.tsx]
props: { imageUrl: string, bubbles: Bubble[], selectedBubbleId: string | null, onBubbleClick: (id: string) => void }
- useFabricCanvas 훅 사용
- bubbles 변경 시 renderBubbles 재호출
- selectedBubbleId 변경 시 해당 bubble 테두리 강조 (strokeWidth: 4)
- 캔버스 컨테이너: overflow-hidden, 스크롤 가능

[components/editor/TranslationPanel.tsx]
props: { bubble: Bubble | null }
- 선택된 bubble의 원문, 화자, CandidateSelector 표시
- bubble null이면 "말풍선을 클릭하세요" 안내 표시

[translation/page.tsx — 이미지 뷰 탭 완성]
- viewMode=image일 때:
  좌측 (2/3): FabricCanvas + PageNavigator
  우측 (1/3): TranslationPanel (selectedBubbleId 기반)
- 번역 확정(PATCH 성공) 후:
  - TanStack Query invalidateQueries(['bubbles', pageId])
  - renderBubbles 재호출 → 오버레이 즉시 업데이트
- 테이블 뷰 ↔ 이미지 뷰 전환 시 selectedBubbleId 상태 유지 (editorStore)

━━━━ 완료 기준 ━━━━
- [ ] 이미지 뷰에서 웹툰 이미지 + 번호 배지 렌더링 확인
- [ ] 말풍선 클릭 → 우측 패널에 해당 CandidateSelector 표시 확인
- [ ] 번역 확정 후 해당 말풍선 위치에 번역문 오버레이 즉시 표시 확인
- [ ] 테이블 뷰 ↔ 이미지 뷰 전환 후 선택 상태 유지 확인
- [ ] 페이지 변경 시 새 이미지 + 해당 페이지 bubbles 로드 확인
```

---

## PHASE 5 — AI 검수 + 렌더링 출력 (백엔드 + 프론트엔드)

```
[AI translate 프로젝트] Phase 5: AI 검수 파이프라인 + 렌더링 출력

━━━━ 프로젝트 개요 ━━━━
프로젝트명: 웹툰 자동 번역 어시스턴트
기술 스택:
  Backend:  FastAPI, Groq SDK (llama-3.1-8b-instant), OpenCV, Pillow
  Frontend: Next.js 14, TypeScript, Tailwind, shadcn/ui
Phase 0~4 완료 상태: 번역 파이프라인, 이미지 뷰 편집기 완료.

━━━━ Phase 5 작업 목표 ━━━━
번역 완료 후 AI 일관성 검수 + 인페인팅 + 번역 텍스트 합성 → 최종 이미지 출력.

━━━━ 백엔드 작업 A: AI 검수 ━━━━

[pipeline/review_pipeline.py]
class AIReviewPipeline:
  def __init__(self, groq_client: GroqChatClient)

  async def review_episode(self, project, episode, db) → list[dict]:
    - 에피소드의 모든 confirmed_translation 있는 Bubble 조회
    - 프롬프트 구성:
      [작품 정보] 제목, 캐릭터별 말투 스타일 + 이전 회차 말투 샘플 3개
      [전체 번역 결과] speaker: 원문 / 번역 목록
      검수 기준: consistency / mistranslation / unnatural / sfx
    - groq_client.chat(prompt, model="llama-3.1-8b-instant")
    - parse_json() → ReviewSuggestion 레코드 DB 저장
    - APIUsageLog 저장 (service="groq_review")
    - 반환: 생성된 ReviewSuggestion 목록

[routers/review.py]
POST /episodes/{ep_id}/jobs/ai-review
  - Job 생성 + BackgroundTasks 실행
  - { "job_id": str } 반환

GET /episodes/{ep_id}/review-suggestions
  → ReviewSuggestion 목록 (pending 먼저, issue_type 포함)

PATCH /review-suggestions/{id}/accept
  - suggestion.status = "accepted"
  - 해당 bubble의 기존 selected candidate → is_selected=False
  - suggested_translation으로 새 TranslationCandidate(rank=0, is_selected=True) 생성
  - CharacterSpeechSample 업데이트 (is_edited=True)

PATCH /review-suggestions/{id}/reject
  - suggestion.status = "rejected"

━━━━ 백엔드 작업 B: 렌더링 출력 ━━━━

[pipeline/render_pipeline.py]
class RenderPipeline:
  def render_page(self, image_bytes: bytes, bubbles: list, quality: str = "fast") → bytes:
    1. OpenCV로 이미지 로드
    2. _create_text_mask(img, bubbles): 각 bubble 좌표에 흰 사각형 마스크 생성
    3. _inpaint(img, mask, quality):
       - "fast": cv2.inpaint(TELEA, inpaintRadius=3)
       - "high": simple_lama_inpainting.SimpleLama() (없으면 fast로 폴백)
    4. _render_translations(inpainted, bubbles):
       - PIL로 변환
       - confirmed_translation 있는 bubble마다:
         _fit_font_size(text, width, height) → 이진 탐색 폰트 크기 (8~40px)
         PIL ImageDraw.text() 중앙 정렬 렌더링
       - NanumGothic.ttf 없으면 기본 폰트 사용
    5. JPEG bytes로 반환

  _fit_font_size(text, box_w, box_h) → int:
    - lo=8, hi=40 이진 탐색
    - 대략적 글자 너비: font_size * 0.6
    - 박스에 맞는 최대 폰트 크기 반환

[routers/export.py]
POST /episodes/{ep_id}/jobs/render
  Body: { "quality": "fast" | "high" }
  - Job 생성 + BackgroundTasks
  async def run_render_job(job_id, episode_id, quality, db):
    - 각 Page에 대해 RenderPipeline.render_page() 호출
    - 결과를 {OUTPUT_DIR}/{episode_id}/rendered_{order:03d}.jpg 저장
    - Page.rendered_path 업데이트
    - Episode.status = "done" 업데이트

GET /episodes/{ep_id}/preview/{page_id}
  → Page.rendered_path 이미지 파일 FileResponse 반환

GET /episodes/{ep_id}/export
  → 모든 rendered 이미지를 ZIP으로 묶어 StreamingResponse 반환
  파일명: {ep_id}_{episode_number}화_번역완성.zip

━━━━ 프론트엔드 작업 ━━━━

[app/.../review/page.tsx]
- 상단: [← 번역 편집기] [AI 검수 실행] 제목 [미처리 N건]
- POST /episodes/{ep_id}/jobs/ai-review → JobProgressBar
- 검수 제안 카드 목록:
  각 카드:
    - issue_type 뱃지 (consistency=노랑, mistranslation=빨강, unnatural=주황, sfx=파랑)
    - 현재 번역 (취소선) → 제안 번역 (강조)
    - 이유 텍스트
    - [수락 ✓] / [거절 ✗] 버튼
- 상단 [전체 수락] / [전체 거절] 버튼
- 검수 완료 후 [최종 출력 →] 버튼 표시

[app/.../export/page.tsx]
- 렌더링 방식 선택: [빠른 렌더링 (OpenCV)] / [고품질 (Simple-LAMA)] 라디오
- [렌더링 시작] → POST /episodes/{ep_id}/jobs/render + JobProgressBar
- 렌더링 완료 후:
  - 페이지 썸네일 미리보기 (GET /episodes/{ep_id}/preview/{page_id})
  - [전체 다운로드 ZIP] 버튼 → GET /episodes/{ep_id}/export
- 썸네일 클릭 → /translation 페이지로 이동 (해당 페이지로 currentPage 설정)

━━━━ 완료 기준 ━━━━
- [ ] AI 검수 실행 후 ReviewSuggestion 레코드 생성 확인
- [ ] 수락 클릭 시 해당 bubble의 번역문 교체 확인 + CharacterSpeechSample 업데이트 확인
- [ ] 렌더링 Job 완료 후 GET /preview/{page_id} → 번역 합성 이미지 반환 확인
- [ ] ZIP 다운로드 시 모든 페이지 포함 확인
```

---

## PHASE 6 — 관리자 대시보드

```
[AI translate 프로젝트] Phase 6: 관리자 대시보드 — API 사용량 모니터링

━━━━ 프로젝트 개요 ━━━━
프로젝트명: 웹툰 자동 번역 어시스턴트
기술 스택:
  Backend:  FastAPI, SQLAlchemy (APIUsageLog 모델 기존 구현됨)
  Frontend: Next.js 14, TypeScript, Tailwind, shadcn/ui, Recharts
Phase 0~5 완료 상태: 전체 번역 파이프라인 완료.
관리자 접근: User.is_admin=True + get_admin_user 의존성으로 보호됨.

━━━━ Phase 6 작업 목표 ━━━━
관리자 계정으로 접속 시 API 사용량을 시각화하고,
쿼터 소진 경고 + 유료 플랜 업그레이드 안내를 제공하는 대시보드 구현.

━━━━ 백엔드 작업 ━━━━

[routers/admin.py] — 기존 api-status에 아래 엔드포인트 추가

모든 엔드포인트는 get_admin_user 의존성 적용 (is_admin=False이면 403).

GET /admin/api-status
  → 기존: KeyRotator 상태 반환 (clova, deepl, groq 각각 total/active/keys)

GET /admin/usage/summary
  오늘 / 이번 달 사용량 요약
  Response:
  {
    "today": [{"service": "clova_ocr", "requests": 42, "chars": 0, "tokens": 0}, ...],
    "this_month": [...],
    "quota_warning_count": 2  // is_active=False Key 개수
  }

GET /admin/usage/by-user
  Query: from (YYYY-MM-DD, optional), to (YYYY-MM-DD, optional)
  SELECT user_id, user.email, service, COUNT(*) as requests,
         SUM(char_count) as chars, SUM(token_count) as tokens
  FROM api_usage_logs JOIN users GROUP BY user_id, service
  Response: [{"userId", "userEmail", "service", "requests", "chars", "tokens"}]

GET /admin/usage/by-user/{user_id}
  특정 유저의 날짜·시간별 사용 이력 (최근 100건)
  SELECT * FROM api_usage_logs WHERE user_id=? ORDER BY created_at DESC LIMIT 100

GET /admin/usage/timeseries
  Query: granularity ("day"|"hour", default="day"), from, to
  PostgreSQL: DATE_TRUNC / SQLite: strftime('%Y-%m-%d', created_at)
  Response: [{"period": "2025-01-15", "service": "groq_translate", "requests": 234}]

GET /admin/usage/quota-warnings
  Response:
  {
    "warnings": [
      {"service": "deepl", "keySuffix": "...1234", "status": "quota_exceeded",
       "resetAt": 1234567890, "upgradeRecommended": true}
    ],
    "count": 2,
    "upgradeLinks": {
      "deepl": "https://www.deepl.com/pro",
      "groq": "https://console.groq.com/settings/billing",
      "clova": "https://www.ncloud.com/product/aiService/ocr"
    }
  }

━━━━ 프론트엔드 작업 ━━━━

[app/admin/page.tsx] — 관리자 전용 페이지
- User.isAdmin=false이면 /dashboard 리다이렉트
- npm install recharts 추가

레이아웃:
  상단: "관리자 대시보드" 제목 + 날짜 범위 선택 (DatePicker or Input[date])
  
  섹션 1 — 오늘 / 이번 달 요약 카드 (4개):
    총 OCR 요청 수 / 총 번역 요청 수 / 총 AI 검수 요청 수 / 활성 API Key 수
    각 카드: 숫자 크게 + 아이콘 + 이번 달 누적

  섹션 2 — 쿼터 경고 배너:
    GET /admin/usage/quota-warnings 호출
    경고가 있으면:
      ⚠️ 노란 배너: "[서비스명] API Key N개가 쿼터 소진 상태입니다. [유료 플랜 업그레이드 →]"
      링크: upgradeLinks[service] 로 이동
    경고 없으면: "✅ 모든 API Key 정상 동작 중"

  섹션 3 — 서비스별 일별 사용량 Bar 차트 (Recharts BarChart):
    GET /admin/usage/timeseries?granularity=day 호출
    X축: 날짜, Y축: requests, 시리즈별 색상으로 서비스 구분
    (clova_ocr=파랑, deepl=초록, groq_translate=보라, groq_review=주황, groq_speaker=빨강)

  섹션 4 — 유저별 사용량 테이블 + Bar 차트:
    GET /admin/usage/by-user 호출
    테이블: 유저 이메일 | 서비스 | 요청 수 | 문자 수 | 토큰 수
    테이블 행 클릭 → 해당 유저 상세 모달 (GET /admin/usage/by-user/{id})
    상세 모달: 날짜별 사용 이력 테이블

  섹션 5 — API Key 상태 (GET /admin/api-status):
    각 서비스별 Key 목록 (끝 4자리): 활성(초록)/비활성(빨강) 배지
    비활성 Key: 재활성화 예정 시각 표시

[app/admin/layout.tsx]
  - 관리자 전용 레이아웃 (사이드바: 대시보드 / 설정 등)
  - 비관리자 접근 시 /dashboard 리다이렉트

[middleware.ts 업데이트]
  - /admin/* 경로: access_token의 isAdmin 클레임 확인
  - isAdmin=false이면 /dashboard 리다이렉트

━━━━ 완료 기준 ━━━━
- [ ] 관리자 계정 로그인 후 /admin 접근 → 대시보드 렌더링 확인
- [ ] 일반 계정으로 /admin 접근 → /dashboard 리다이렉트 확인
- [ ] 일별 Bar 차트 렌더링 확인 (Recharts)
- [ ] 쿼터 경고 배너: Key 비활성화 상태일 때 경고 표시 확인
- [ ] 유저별 테이블에서 행 클릭 → 상세 모달 확인
- [ ] /admin/usage/quota-warnings 응답에 upgradeLinks 포함 확인
```

---

## PHASE 7 — 배포

```
[AI translate 프로젝트] Phase 7: M1 맥미니 Docker 배포 + Vercel 프론트엔드 배포

━━━━ 프로젝트 개요 ━━━━
프로젝트명: 웹툰 자동 번역 어시스턴트
Phase 0~6 완료 상태: 전체 기능 구현 완료.
배포 환경: M1 맥미니(백엔드) + Vercel(프론트엔드) + Cloudflare Tunnel(도메인)

━━━━ 작업 목표 ━━━━
프로덕션 배포 설정 파일 전체를 생성한다.

━━━━ 작업 1: 백엔드 Docker 설정 ━━━━

[backend/Dockerfile]
FROM python:3.11-slim
RUN apt-get update && apt-get install -y \
    libgl1-mesa-glx libglib2.0-0 libsm6 libxext6 libxrender-dev libgomp1 fonts-nanum \
    && rm -rf /var/lib/apt/lists/*
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY . .
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000", "--workers", "2"]

[docker-compose.yml]
services:
  api:
    build: ./backend
    ports: ["8000:8000"]
    volumes:
      - ./data/uploads:/data/uploads
      - ./data/outputs:/data/outputs
      - ./backend/.env:/app/.env
    environment:
      - ENVIRONMENT=production
      - DATABASE_URL=postgresql://ailosy:${DB_PASSWORD}@db:5432/ailosy
    depends_on: [db]
    restart: unless-stopped

  db:
    image: postgres:15-alpine
    environment:
      POSTGRES_USER: ailosy
      POSTGRES_PASSWORD: ${DB_PASSWORD}
      POSTGRES_DB: ailosy
    volumes: [postgres_data:/var/lib/postgresql/data]
    restart: unless-stopped

volumes:
  postgres_data:

[backend/.env.production.example]
ENVIRONMENT=production
DATABASE_URL=postgresql://ailosy:PASSWORD@db:5432/ailosy
SECRET_KEY=생성된-강력한-시크릿키
ACCESS_TOKEN_EXPIRE_MINUTES=60
CLOVA_KEYS=key1,key2
CLOVA_URLS=url1,url2
DEEPL_KEYS=key1,key2
GROQ_KEYS=key1,key2,key3
UPLOAD_DIR=/data/uploads
OUTPUT_DIR=/data/outputs

━━━━ 작업 2: Cloudflare Tunnel 설정 스크립트 ━━━━

[scripts/setup_cloudflare_tunnel.sh]
#!/bin/bash
# 1. cloudflared 설치 확인
# 2. cloudflared tunnel login 안내
# 3. cloudflared tunnel create ailosy-backend
# 4. ~/.cloudflared/config.yml 생성 (tunnel ID 자리표시자 포함)
# 5. cloudflared service install 안내
# 각 단계 설명 주석 포함

[~/.cloudflared/config.yml 템플릿]
tunnel: <TUNNEL_ID>
credentials-file: ~/.cloudflared/<TUNNEL_ID>.json
ingress:
  - hostname: api.ailosy.com
    service: http://localhost:8000
  - service: http_status:404

━━━━ 작업 3: Vercel 설정 ━━━━

[frontend/vercel.json]
{
  "buildCommand": "npm run build",
  "outputDirectory": ".next",
  "framework": "nextjs"
}

[frontend/.env.production]
NEXT_PUBLIC_API_URL=https://api.ailosy.com
NEXTAUTH_URL=https://ailosy.vercel.app
NEXTAUTH_SECRET=생성된-시크릿

[frontend/.env.local.example]
NEXT_PUBLIC_API_URL=http://localhost:8000

━━━━ 작업 4: 프로덕션 전환 체크리스트 (CHECKLIST.md) ━━━━

다음 내용의 CHECKLIST.md 파일을 루트에 생성:
- [ ] backend/.env에 ENVIRONMENT=production 설정
- [ ] backend/.env에 DATABASE_URL PostgreSQL로 변경
- [ ] backend/main.py CORS origins에 실제 Vercel 도메인 추가
- [ ] docker compose up -d 실행
- [ ] cloudflared tunnel run ailosy-backend 테스트
- [ ] cloudflared service install로 자동시작 등록
- [ ] Vercel 환경변수 NEXT_PUBLIC_API_URL=https://api.ailosy.com 설정
- [ ] GitHub main 브랜치 push → Vercel 자동 빌드 확인
- [ ] https://api.ailosy.com/docs 접근 확인
- [ ] https://ailosy.vercel.app 에서 로그인 → 프로젝트 생성 → OCR 실행 E2E 확인
- [ ] M1 맥미니 재부팅 후 자동 서비스 재시작 확인

━━━━ 완료 기준 ━━━━
- [ ] docker compose up -d 실행 후 localhost:8000/docs 접근 확인
- [ ] Dockerfile 빌드 성공 (M1 arm64 환경)
- [ ] CHECKLIST.md 생성 확인
```

---

## 📌 프롬프트 사용 팁

1. **순서 준수**: Phase 번호 순서대로 실행. 각 Phase는 이전 결과물을 전제로 함.
2. **완료 기준 확인**: 각 Phase 마지막의 `완료 기준` 체크리스트를 Codex가 직접 검증하도록 요청할 것.
3. **막히는 경우**: 해당 Phase 프롬프트 맨 앞에 `"이전에 시작한 작업을 이어서 진행한다. 현재 상태:"` + 완성된 부분 목록을 붙여서 재입력.
4. **파일 참조**: Codex에게 md 파일을 직접 읽히기보다, 이 프롬프트에 필요한 정보가 이미 포함되어 있으므로 이 프롬프트만으로 작업 가능.
5. **1-A, 1-B, 1-C 분리 이유**: Phase 1은 작업량이 많아 세 개로 분리. 백엔드 모델/API → 백엔드 OCR → 프론트엔드 순으로 진행.
