#!/bin/bash
# docs/tasks/ 에서 실행할 것
# 사용법: bash generate_tasks.sh

set -e

TREE_CMD='tree -a -L 5 \
-I '"'"'node_modules|.next|out|dist|build|coverage|.turbo|.vercel|.cache|.vite|__pycache__|.pytest_cache|.mypy_cache|.venv|venv|env|*.pyc|*.pyo|*.log|*.lock|package-lock.json|yarn.lock|pnpm-lock.yaml|poetry.lock|*.jpg|*.jpeg|*.png|*.gif|*.webp|*.svg|*.ico|*.bmp|*.tiff|*.mp4|*.mov|*.webm|*.zip|*.tar|*.gz|*.7z|*.pdf|*.ttf|*.otf|*.woff|*.woff2|*.wasm'"'"

mkdir -p prompts logs

# ──────────────────────────────────────────────
# HEADER: 각 프롬프트 파일 상단에 반복 삽입되는 공통 블록
# ──────────────────────────────────────────────
COMMON_HEADER='## ⚙️ Codex 공통 운영 규칙 (매 작업 필수)

### 작업 시작 전 반드시
1. 프로젝트 현재 구조 확인:
```bash
'"$TREE_CMD"'
```
2. `docs/planning/` 에서 이번 작업 관련 설계 문서 읽기
3. `docs/tasks/logs/` 에서 이전 작업 로그 확인

### 작업 완료 후 반드시
1. `docs/tasks/logs/LOG_[이번Phase].md` 작성
   - 작업한 파일 목록
   - 변경 사항 요약
   - 다음 작업 시 주의사항
2. git commit:
   ```bash
   git add .
   git commit -m "feat: [PXX] 작업명"
   ```

---
'

# ──────────────────────────────────────────────
# CODEX_TASKS.md — 마스터 지시문 + 전체 목차
# ──────────────────────────────────────────────
cat > CODEX_TASKS.md << 'MASTER'
# Codex 마스터 지시문 + 작업 목차

> **이 파일의 목적**: Codex가 프로젝트를 처음 받았을 때 가장 먼저 읽는 파일.
> Phase 순서와 규칙을 숙지한 뒤, `prompts/` 의 각 파일을 순서대로 실행한다.

---

## 🔰 Codex 필독 운영 규칙

### 매 작업 시작 시 반드시
1. 프로젝트 현재 구조 확인 (아래 명령어 그대로 실행):
```bash
tree -a -L 5 \
-I 'node_modules|.next|out|dist|build|coverage|.turbo|.vercel|.cache|.vite|__pycache__|.pytest_cache|.mypy_cache|.venv|venv|env|*.pyc|*.pyo|*.log|*.lock|package-lock.json|yarn.lock|pnpm-lock.yaml|poetry.lock|*.jpg|*.jpeg|*.png|*.gif|*.webp|*.svg|*.ico|*.bmp|*.tiff|*.mp4|*.mov|*.webm|*.zip|*.tar|*.gz|*.7z|*.pdf|*.ttf|*.otf|*.woff|*.woff2|*.wasm'
```
2. `docs/planning/` 에서 해당 작업 관련 설계 문서 확인
3. `docs/tasks/logs/` 에서 이전 작업 로그 확인 (처음이면 생략)

### 매 작업 완료 시 반드시
1. `docs/tasks/logs/LOG_P0X_이름.md` 작성
   - 작업한 파일 목록
   - 변경 사항 요약
   - 다음 작업 시 주의사항
2. git commit:
   ```bash
   git add .
   git commit -m "feat: [P0X] 작업명"
   ```

### 작업 단위 원칙
- 프롬프트 파일 1개 = 1개 Phase (최대 10개 태스크)
- 다음 Phase로 넘어가기 전 로그 작성 + commit 완료 필수
- 막히는 경우: 해당 Phase 프롬프트 맨 앞에 `"이전에 시작한 작업을 이어서 진행. 현재 완료 상태:"` + 완성된 부분 목록을 붙여서 재입력

---

## 📋 공통 프로젝트 컨텍스트

```
프로젝트명: 웹툰 자동 번역 어시스턴트
핵심 개념: Reader용 번역기(단일 반환)가 아닌 Translator용 번역 어시스턴트.
  - AI가 번역 후보 3~4개를 Survey형(①②③ + ④직접입력)으로 제안
  - 번역가가 최종 선택권 보유
  - 작품 줄거리 + 회차 줄거리 + 캐릭터 어투 + 이전 회차 말투 샘플을 번역 프롬프트에 주입

기술 스택:
  Backend:  FastAPI (Python 3.11), SQLAlchemy 2.x, SQLite(개발)/PostgreSQL(프로덕션), Alembic
  Frontend: Next.js 14 (App Router), TypeScript, Tailwind CSS, shadcn/ui, Fabric.js, Zustand, TanStack Query
  AI/OCR:   Clova General OCR (Primary), Google Lens (Fallback), DeepL Free (번역 Primary),
            Groq LLM llama-3.3-70b-versatile (번역 후보 생성 + 화자매칭), llama-3.1-8b-instant (AI 검수)
  배포:     M1 맥미니 Docker + Vercel

디렉토리 구조:
  /backend   ← FastAPI
  /frontend  ← Next.js

설계 문서 위치:
  docs/planning/00_PROJECT_OVERVIEW.md   — 전체 개요
  docs/planning/01_BACKEND_ARCHITECTURE.md
  docs/planning/02_FRONTEND_ARCHITECTURE.md
  docs/planning/03_AI_PIPELINE.md
  docs/planning/04_API_KEY_STRATEGY.md
  docs/planning/05_DATABASE_SCHEMA.md
  docs/planning/06_DEPLOYMENT.md
```

---

## 📂 Phase 목록 및 실행 순서

| 파일 | Phase | 내용 |
|------|-------|------|
| `prompts/P00_setup.md` | Phase 0 | 프로젝트 초기 세팅 + JWT 인증 |
| `prompts/P01A_backend_db_crud.md` | Phase 1-A | DB 모델 전체 + 프로젝트/회차 CRUD |
| `prompts/P01B_backend_upload_ocr_keyrotator.md` | Phase 1-B | 파일 업로드 + OCR 파이프라인 + KeyRotator |
| `prompts/P01C_frontend_dashboard_upload.md` | Phase 1-C | 대시보드 + 프로젝트 생성 + 업로드 화면 |
| `prompts/P02_speaker_matching_labeling.md` | Phase 2 | 화자 매칭 + 라벨링 검수 |
| `prompts/P03_translation_pipeline_table_editor.md` | Phase 3 | 번역 파이프라인 + 테이블 뷰 편집기 |
| `prompts/P04_image_editor_fabricjs.md` | Phase 4 | 이미지 뷰 편집기 (Fabric.js) |
| `prompts/P05_ai_review_rendering_output.md` | Phase 5 | AI 검수 + 렌더링 출력 |
| `prompts/P06_admin_dashboard.md` | Phase 6 | 관리자 대시보드 |
| `prompts/P07_deployment.md` | Phase 7 | 배포 (Docker + Vercel) |

---

## 📝 로그 파일 위치

완료된 작업 로그는 `logs/` 에 저장:
```
logs/LOG_P00_setup.md
logs/LOG_P01A_backend_db_crud.md
logs/LOG_P01B_backend_upload_ocr_keyrotator.md
logs/LOG_P01C_frontend_dashboard_upload.md
logs/LOG_P02_speaker_matching_labeling.md
logs/LOG_P03_translation_pipeline_table_editor.md
logs/LOG_P04_image_editor_fabricjs.md
logs/LOG_P05_ai_review_rendering_output.md
logs/LOG_P06_admin_dashboard.md
logs/LOG_P07_deployment.md
```
MASTER

echo "✅ CODEX_TASKS.md 생성 완료"

# ──────────────────────────────────────────────
# LOG 템플릿 함수
# ──────────────────────────────────────────────
write_log_template() {
  local file=$1
  local phase=$2
  local title=$3
  cat > "$file" << EOF
# 작업 로그 — ${phase}: ${title}

## 메타
- 작업일: <!-- YYYY-MM-DD -->
- 작업자: <!-- Codex -->
- 소요시간: <!-- 예: 2h -->
- Commit: <!-- git commit hash -->

## 완료된 작업
- [ ] 

## 작업한 파일 목록
\`\`\`
\`\`\`

## 변경 사항 요약


## 다음 작업 시 주의사항


## 미완료 / 이슈
EOF
}

# ──────────────────────────────────────────────
# P00 — 프로젝트 초기 세팅 + JWT 인증
# ──────────────────────────────────────────────
cat > prompts/P00_setup.md << 'EOF'
## ⚙️ Codex 공통 운영 규칙 (매 작업 필수)

### 작업 시작 전 반드시
1. 프로젝트 현재 구조 확인:
```bash
tree -a -L 5 \
-I 'node_modules|.next|out|dist|build|coverage|.turbo|.vercel|.cache|.vite|__pycache__|.pytest_cache|.mypy_cache|.venv|venv|env|*.pyc|*.pyo|*.log|*.lock|package-lock.json|yarn.lock|pnpm-lock.yaml|poetry.lock|*.jpg|*.jpeg|*.png|*.gif|*.webp|*.svg|*.ico|*.bmp|*.tiff|*.mp4|*.mov|*.webm|*.zip|*.tar|*.gz|*.7z|*.pdf|*.ttf|*.otf|*.woff|*.woff2|*.wasm'
```
2. `docs/planning/` 에서 이번 작업 관련 설계 문서 읽기
   - 관련 문서: `00_PROJECT_OVERVIEW.md`, `01_BACKEND_ARCHITECTURE.md`, `02_FRONTEND_ARCHITECTURE.md`
3. `docs/tasks/logs/` 에서 이전 작업 로그 확인 (첫 작업이므로 생략)

### 작업 완료 후 반드시
1. `docs/tasks/logs/LOG_P00_setup.md` 작성
   - 작업한 파일 목록 / 변경 사항 요약 / 다음 작업 시 주의사항
2. git commit:
   ```bash
   git add .
   git commit -m "feat: [P00] 프로젝트 초기 세팅 + JWT 인증"
   ```

---

# [P00] Phase 0: 백엔드/프론트엔드 초기 세팅 및 JWT 인증 구현

## 프로젝트 개요
```
프로젝트명: 웹툰 자동 번역 어시스턴트
핵심 개념: Reader용 번역기(단일 반환)가 아닌 Translator용 번역 어시스턴트.
기술 스택:
  Backend:  FastAPI (Python 3.11), SQLAlchemy 2.x, SQLite(개발)/PostgreSQL(프로덕션), Alembic
  Frontend: Next.js 14 (App Router), TypeScript, Tailwind CSS, shadcn/ui, Zustand, TanStack Query
  배포:     M1 맥미니 Docker + Vercel
```

## 작업 목표
백엔드/프론트엔드 뼈대 생성, DB 연결, JWT 인증 완료.

---

## 백엔드 작업 (backend/)

### 1. 프로젝트 구조 생성
다음 디렉토리/파일 구조를 생성한다:
```
backend/
├── main.py
├── config.py
├── database.py
├── routers/auth.py
├── models/user.py
├── models/__init__.py
├── .env.example
└── requirements.txt
```

### 2. requirements.txt
```
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
```

### 3. config.py — pydantic Settings로 환경변수 로드
- ENVIRONMENT (default: "development")
- DATABASE_URL (default: "sqlite:///./ailosy.db")
- SECRET_KEY
- ACCESS_TOKEN_EXPIRE_MINUTES (default: 60)
- CLOVA_KEYS, CLOVA_URLS (콤마 구분 문자열)
- DEEPL_KEYS, GROQ_KEYS (콤마 구분 문자열)
- UPLOAD_DIR (default: "./data/uploads")
- OUTPUT_DIR (default: "./data/outputs")

### 4. database.py
- SQLAlchemy engine, SessionLocal, Base, get_db() 구현
- SQLite: connect_args={"check_same_thread": False}
- PostgreSQL: 별도 connect_args 없음
- 조건: DATABASE_URL에 "sqlite" 포함 여부로 자동 분기

### 5. models/user.py
```python
class User(Base):
  __tablename__ = "users"
  # id, email (unique), hashed_password, name,
  # is_active, is_admin (Boolean, default=False), created_at
  # is_admin: 관리자 대시보드 접근 권한 제어에 사용
```

### 6. JWT 인증 구현 (routers/auth.py)
```
POST /auth/register   { email, password, name } → User 생성 + JWT 반환
POST /auth/login      { email, password } → JWT 반환
POST /auth/refresh    { refresh_token } → 새 access_token 반환
GET  /auth/me         현재 로그인 유저 정보 반환
```
- 비밀번호 해싱: passlib bcrypt
- 토큰: python-jose, HS256, exp 포함
- `get_current_user(token)` 의존성 함수 구현
- `get_admin_user(token)`: is_admin=True 유저만 허용하는 의존성 함수

### 7. main.py
- FastAPI 앱, CORS 미들웨어 (개발: *, 프로덕션: Vercel 도메인만)
- 요청 로깅 미들웨어 (method, path, status, 응답시간)
- startup 이벤트에서 `Base.metadata.create_all()` 호출
- /auth 라우터 등록

### 8. .env.example
```
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
```

---

## 프론트엔드 작업 (frontend/)

### 1. Next.js 14 프로젝트 생성
```bash
npx create-next-app@latest frontend --typescript --tailwind --app --no-src-dir
npx shadcn-ui@latest init
npm install axios @tanstack/react-query zustand next-auth
```

### 2. lib/api.ts — Axios 인스턴스
- baseURL: `process.env.NEXT_PUBLIC_API_URL`
- timeout: 60000
- 요청 인터셉터: localStorage의 access_token을 `Authorization: Bearer`로 자동 첨부
- 응답 인터셉터: 401 응답 시 access_token 삭제 + /login으로 리다이렉트

### 3. lib/types.ts — 공통 TypeScript 타입 정의
```typescript
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
```

### 4. app/(auth)/login/page.tsx
- 이메일 + 비밀번호 입력 폼
- POST /auth/login 호출 → access_token을 localStorage에 저장
- 로그인 성공 시 /dashboard로 이동

### 5. app/(auth)/register/page.tsx
- 이름 + 이메일 + 비밀번호 입력 폼
- POST /auth/register 호출 → 성공 시 /login으로 이동

### 6. middleware.ts (루트)
- 로그인 안 된 상태에서 /dashboard, /projects/* 접근 시 /login으로 리다이렉트
- 쿠키 기반 토큰 확인 권장

---

## 완료 기준
- [ ] `uvicorn main:app --reload` 실행 후 GET /docs 에서 Swagger UI 접근 가능
- [ ] POST /auth/register → POST /auth/login → access_token 반환 확인
- [ ] GET /auth/me 에서 로그인된 유저 정보 반환 확인
- [ ] `npm run dev` 실행 후 /login 페이지 렌더링, 로그인 후 /dashboard 이동 확인
EOF

echo "✅ P00_setup.md 생성 완료"

# ──────────────────────────────────────────────
# P01A — DB 모델 전체 + 프로젝트/회차 CRUD
# ──────────────────────────────────────────────
cat > prompts/P01A_backend_db_crud.md << 'EOF'
## ⚙️ Codex 공통 운영 규칙 (매 작업 필수)

### 작업 시작 전 반드시
1. 프로젝트 현재 구조 확인:
```bash
tree -a -L 5 \
-I 'node_modules|.next|out|dist|build|coverage|.turbo|.vercel|.cache|.vite|__pycache__|.pytest_cache|.mypy_cache|.venv|venv|env|*.pyc|*.pyo|*.log|*.lock|package-lock.json|yarn.lock|pnpm-lock.yaml|poetry.lock|*.jpg|*.jpeg|*.png|*.gif|*.webp|*.svg|*.ico|*.bmp|*.tiff|*.mp4|*.mov|*.webm|*.zip|*.tar|*.gz|*.7z|*.pdf|*.ttf|*.otf|*.woff|*.woff2|*.wasm'
```
2. `docs/planning/` 에서 이번 작업 관련 설계 문서 읽기
   - 관련 문서: `01_BACKEND_ARCHITECTURE.md`, `05_DATABASE_SCHEMA.md`
3. `docs/tasks/logs/LOG_P00_setup.md` 확인

### 작업 완료 후 반드시
1. `docs/tasks/logs/LOG_P01A_backend_db_crud.md` 작성
2. git commit:
   ```bash
   git add .
   git commit -m "feat: [P01A] DB 모델 전체 + 프로젝트/회차 CRUD"
   ```

---

# [P01A] Phase 1-A: DB 전체 모델 생성 + 프로젝트·캐릭터·회차 CRUD API

## 전제 조건
Phase 0 완료 상태: FastAPI 앱, JWT 인증, User 모델, database.py 구현 완료.

## 작업 목표
프로젝트에 필요한 모든 DB 모델 생성 + 프로젝트/캐릭터/회차 CRUD API 구현.

---

## 작업 1: DB 모델 전체 생성 (backend/models/)

### models/project.py
```python
class Project(Base):
  __tablename__ = "projects"
  # id, owner_id (FK→users.id), title, genre, synopsis
  # source_lang (default:"JA"), target_lang (default:"KO")
  # created_at, updated_at (onupdate)
  # relationships: owner→User, episodes→Episode (order_by number), characters→Character

class Character(Base):
  __tablename__ = "characters"
  # id, project_id (FK→projects.id), name, description, speech_style, speech_examples
  # relationships: project→Project, episode_situations→EpisodeCharacterSituation
  # speech_samples relationship → CharacterSpeechSample (order_by desc created_at)

  # 메서드 get_past_speech_samples(limit=5) → list[dict]:
  #   is_edited=True 항목 우선 정렬, episode_number 내림차순
  #   반환: [{"original", "translated", "episode_number", "is_edited"}]

class CharacterSpeechSample(Base):
  __tablename__ = "character_speech_samples"
  # id, character_id (FK→characters.id), episode_number
  # original_text, translated_text
  # is_edited (Boolean, default=False)  ← True: 번역가 수정본, False: AI 원안
  # created_at
```

### models/episode.py
```python
class Episode(Base):
  __tablename__ = "episodes"
  # id, project_id (FK→projects.id), number, title, synopsis
  # status (default:"created")
  #   status 값: created→uploaded→ocr_done→labeled→translating→translated→reviewed→done
  # created_at, updated_at
  # relationships: project, pages (order_by order), character_situations, jobs

  # 메서드 get_character_situation(character_name: str) → str:
  #   해당 캐릭터의 이번 회차 상황 반환, 없으면 "미지정"

class EpisodeCharacterSituation(Base):
  __tablename__ = "episode_character_situations"
  # id, episode_id (FK), character_id (FK), situation (Text)
```

### models/page.py
```python
class Page(Base):
  __tablename__ = "pages"
  # id, episode_id (FK), order, original_filename, image_path, rendered_path
  # ocr_status (default:"pending")  → pending / done / failed
```

### models/bubble.py
```python
class Bubble(Base):
  __tablename__ = "bubbles"
  # id (String PK, default=uuid4), page_id (FK)
  # label_index, x1, y1, x2, y2 (Integer)
  # original_text (Text), ocr_confidence (Float)
  # speaker, speaker_confidence (Float), speaker_is_confirmed (Boolean, default=False)
  # bubble_type (default:"dialogue")  → dialogue / sfx / narration
  # font_family (default:"NanumGothic"), font_size (Integer), text_color (default:"#000000")
  # relationships: page, candidates (order_by rank), review_suggestions

  # property width, height: x2-x1, y2-y1
  # property confirmed_translation: is_selected=True candidate의 custom_text 또는 text

class TranslationCandidate(Base):
  __tablename__ = "translation_candidates"
  # id, bubble_id (FK), rank, text (Text), rationale (Text), translation_engine
  # is_selected (Boolean, default=False), custom_text (Text)
  # created_at, updated_at
```

### models/review_suggestion.py
```python
class ReviewSuggestion(Base):
  __tablename__ = "review_suggestions"
  # id, bubble_id (FK)
  # issue_type  → consistency / mistranslation / unnatural / sfx
  # original_translation, suggested_translation, reason (Text)
  # status (default:"pending")  → pending / accepted / rejected
  # created_at
```

### models/job.py
```python
class Job(Base):
  __tablename__ = "jobs"
  # id (String PK, default=uuid4), episode_id (FK)
  # job_type  → ocr / speaker_match / translate / ai_review / render
  # status (default:"pending")  → pending / processing / done / failed
  # progress (Integer, default=0)
  # error_message (Text), started_at, completed_at, created_at
```

### models/api_usage_log.py
```python
class APIUsageLog(Base):
  __tablename__ = "api_usage_logs"
  # id, user_id (FK), episode_id (FK, nullable)
  # service  → clova_ocr / google_lens / deepl / groq_translate / groq_review / groq_speaker
  # request_count (Integer, default=1), char_count (Integer, default=0), token_count (Integer, default=0)
  # status  → success / failed / quota_exceeded
  # used_key_suffix (String)  ← 어느 API Key 끝 4자리
  # created_at (DateTime, index=True)
```

### models/__init__.py
모든 모델 import 후 `__all__` 정의. `main.py` startup에서 `Base.metadata.create_all()` 호출.

---

## 작업 2: 프로젝트/캐릭터 CRUD API (backend/routers/projects.py)

모든 엔드포인트: `get_current_user` 의존성 + 본인 소유 프로젝트만 접근 (owner_id 검증).

```
POST   /projects                          → Project + Character 일괄 생성
GET    /projects                          → 내 프로젝트 목록 { items, total }
GET    /projects/{id}                     → 프로젝트 상세 (characters 포함)
PATCH  /projects/{id}                     → 부분 업데이트
DELETE /projects/{id}                     → cascade 삭제
POST   /projects/{id}/characters          → 캐릭터 추가
PATCH  /projects/{id}/characters/{cid}   → 캐릭터 수정
DELETE /projects/{id}/characters/{cid}   → 캐릭터 삭제
```

POST /projects Body:
```json
{
  "title", "genre", "source_lang", "target_lang", "synopsis",
  "characters": [{"name", "description", "speech_style", "speech_examples"}]
}
```

---

## 작업 3: 회차 관리 API (backend/routers/episodes.py)

```
POST  /projects/{id}/episodes             → Episode + EpisodeCharacterSituation 일괄 생성
GET   /projects/{id}/episodes             → 회차 목록 (number 오름차순)
GET   /projects/{id}/episodes/{ep_id}    → 회차 상세 (character_situations 포함)
PATCH /projects/{id}/episodes/{ep_id}    → 수정 (character_situations 포함 시 삭제 후 재생성)
```

---

## 에러 핸들링 원칙
- 존재하지 않는 리소스: `HTTPException(404)`
- 권한 없음: `HTTPException(403)`
- 모든 응답은 Pydantic 스키마로 직렬화 (`schemas/` 폴더 생성)

---

## 완료 기준
- [ ] 모든 테이블이 DB에 생성됨 (startup 로그 확인)
- [ ] POST /projects → GET /projects/{id} → 캐릭터 포함 응답 확인
- [ ] POST /projects/{id}/episodes → GET 응답에 character_situations 포함 확인
EOF

echo "✅ P01A_backend_db_crud.md 생성 완료"

# ──────────────────────────────────────────────
# P01B — 파일 업로드 + OCR + KeyRotator
# ──────────────────────────────────────────────
cat > prompts/P01B_backend_upload_ocr_keyrotator.md << 'EOF'
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
EOF

echo "✅ P01B_backend_upload_ocr_keyrotator.md 생성 완료"

# ──────────────────────────────────────────────
# P01C — 프론트엔드: 대시보드 + 업로드
# ──────────────────────────────────────────────
cat > prompts/P01C_frontend_dashboard_upload.md << 'EOF'
## ⚙️ Codex 공통 운영 규칙 (매 작업 필수)

### 작업 시작 전 반드시
1. 프로젝트 현재 구조 확인:
```bash
tree -a -L 5 \
-I 'node_modules|.next|out|dist|build|coverage|.turbo|.vercel|.cache|.vite|__pycache__|.pytest_cache|.mypy_cache|.venv|venv|env|*.pyc|*.pyo|*.log|*.lock|package-lock.json|yarn.lock|pnpm-lock.yaml|poetry.lock|*.jpg|*.jpeg|*.png|*.gif|*.webp|*.svg|*.ico|*.bmp|*.tiff|*.mp4|*.mov|*.webm|*.zip|*.tar|*.gz|*.7z|*.pdf|*.ttf|*.otf|*.woff|*.woff2|*.wasm'
```
2. `docs/planning/` 에서 이번 작업 관련 설계 문서 읽기
   - 관련 문서: `02_FRONTEND_ARCHITECTURE.md`
3. `docs/tasks/logs/LOG_P01B_backend_upload_ocr_keyrotator.md` 확인

### 작업 완료 후 반드시
1. `docs/tasks/logs/LOG_P01C_frontend_dashboard_upload.md` 작성
2. git commit:
   ```bash
   git add .
   git commit -m "feat: [P01C] 프론트엔드 대시보드 + 프로젝트 생성 + 업로드"
   ```

---

# [P01C] Phase 1-C: 프론트엔드 — 대시보드, 프로젝트 생성, 파일 업로드 화면

## 전제 조건
Phase 0, 1-A, 1-B 완료: 백엔드 API 전체 완성.
```
완성된 API: /auth/*, /projects/*, /projects/{id}/episodes/*,
            /episodes/{ep_id}/pages/upload, /episodes/{ep_id}/jobs/ocr,
            /jobs/{job_id}/status, /pages/{page_id}/bubbles
```

## 작업 목표
로그인 → 프로젝트 생성 → 회차 생성 → 이미지 업로드 → OCR 시작 전체 흐름 UI 완성.

---

## 작업 1: 공통 훅 및 컴포넌트

### hooks/useJobPolling.ts
```typescript
// useJobPolling(jobId: string | null)
// TanStack Query useQuery 사용
// queryKey: ['job', jobId]
// refetchInterval: done/failed이면 false, 그 외 2000ms
// 반환: { status, progress, isDone, isFailed, error }
```

### components/common/JobProgressBar.tsx
```typescript
// props: { progress: number, status: string, label?: string }
// Tailwind 기반 progress bar
// status별 색상: processing=파랑, done=초록, failed=빨강
```

### components/common/PageNavigator.tsx
```typescript
// props: { currentPage, totalPages, onPageChange }
// UI: [← 이전] 1/24 [다음 →]
```

### store/projectStore.ts (Zustand)
```typescript
// currentProjectId: number | null
// currentEpisodeId: number | null
// setCurrentProject, setCurrentEpisode
```

---

## 작업 2: 대시보드 (app/dashboard/page.tsx)
- GET /projects → 프로젝트 카드 목록
- 각 카드: 제목, 장르, 원본→번역 언어, 회차 수, 최근 업데이트
- 카드 클릭 → /projects/{id}
- [+ 새 프로젝트] 버튼 → /projects/new

---

## 작업 3: 프로젝트 생성 (app/projects/new/page.tsx)

UI 구조:
- 작품 제목 (Input)
- 원본 언어 / 번역 언어 (Select, 기본값: 일본어/한국어)
- 장르 (Select: 판타지/로맨스/액션/일상/기타)
- 작품 전체 줄거리 (Textarea)
- 캐릭터 테이블:
  - 컬럼: 이름 | 성격 | 말투 스타일 | 말투 예시 | 삭제
  - 각 셀 인라인 Input 편집
  - [캐릭터 추가 +] 버튼으로 행 추가
  - 🗑 버튼으로 행 삭제
- [프로젝트 생성하기 →] → POST /projects → 성공 시 /projects/{id}

---

## 작업 4: 프로젝트 상세 (app/projects/[projectId]/page.tsx)
- GET /projects/{id} → 프로젝트 정보 + 캐릭터 목록
- GET /projects/{id}/episodes → 회차 카드 (status 배지 포함)
- [+ 새 회차 추가] → POST /projects/{id}/episodes
- 회차 카드 클릭 → /projects/{id}/episodes/{ep_id}/upload

---

## 작업 5: 파일 업로드 + 회차 컨텍스트 (app/.../upload/page.tsx)

경로: `app/projects/[projectId]/episodes/[episodeId]/upload/page.tsx`

### 섹션 1 — 파일 업로드 (components/common/FileUploader.tsx)
- react-dropzone 사용, 허용: jpg, png, pdf
- 드롭 시 썸네일 미리보기
- [업로드 시작] → POST /episodes/{ep_id}/pages/upload

### 섹션 2 — 회차 컨텍스트 (PATCH /projects/{id}/episodes/{ep_id})
- 회차 제목 (Input)
- 이번 회차 줄거리 (Textarea)
- 캐릭터별 이번 회차 상황 테이블 (프로젝트 캐릭터 자동 표시)
- [저장] 버튼

### 하단 [OCR 시작 →]
- POST /episodes/{ep_id}/jobs/ocr
- JobProgressBar 표시 (useJobPolling)
- isDone=true 시 `/projects/{id}/episodes/{ep_id}/labeling` 이동

---

## 완료 기준
- [ ] /dashboard에서 프로젝트 목록 카드 렌더링 확인
- [ ] 프로젝트 생성 폼 제출 후 /projects/{id} 이동 확인
- [ ] 캐릭터 테이블 행 추가/삭제 동작 확인
- [ ] 파일 드롭 → 업로드 → OCR 시작 → 진행률 바 표시 확인
- [ ] OCR 완료 후 /labeling 자동 이동 확인
EOF

echo "✅ P01C_frontend_dashboard_upload.md 생성 완료"

# ──────────────────────────────────────────────
# P02 — 화자 매칭 + 라벨링 검수
# ──────────────────────────────────────────────
cat > prompts/P02_speaker_matching_labeling.md << 'EOF'
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
EOF

echo "✅ P02_speaker_matching_labeling.md 생성 완료"

# ──────────────────────────────────────────────
# P03 — 번역 파이프라인 + 테이블 뷰
# ──────────────────────────────────────────────
cat > prompts/P03_translation_pipeline_table_editor.md << 'EOF'
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
EOF

echo "✅ P03_translation_pipeline_table_editor.md 생성 완료"

# ──────────────────────────────────────────────
# P04 — 이미지 뷰 편집기 (Fabric.js)
# ──────────────────────────────────────────────
cat > prompts/P04_image_editor_fabricjs.md << 'EOF'
## ⚙️ Codex 공통 운영 규칙 (매 작업 필수)

### 작업 시작 전 반드시
1. 프로젝트 현재 구조 확인:
```bash
tree -a -L 5 \
-I 'node_modules|.next|out|dist|build|coverage|.turbo|.vercel|.cache|.vite|__pycache__|.pytest_cache|.mypy_cache|.venv|venv|env|*.pyc|*.pyo|*.log|*.lock|package-lock.json|yarn.lock|pnpm-lock.yaml|poetry.lock|*.jpg|*.jpeg|*.png|*.gif|*.webp|*.svg|*.ico|*.bmp|*.tiff|*.mp4|*.mov|*.webm|*.zip|*.tar|*.gz|*.7z|*.pdf|*.ttf|*.otf|*.woff|*.woff2|*.wasm'
```
2. `docs/planning/` 에서 이번 작업 관련 설계 문서 읽기
   - 관련 문서: `02_FRONTEND_ARCHITECTURE.md`
3. `docs/tasks/logs/LOG_P03_translation_pipeline_table_editor.md` 확인

### 작업 완료 후 반드시
1. `docs/tasks/logs/LOG_P04_image_editor_fabricjs.md` 작성
2. git commit:
   ```bash
   git add .
   git commit -m "feat: [P04] 이미지 뷰 편집기 (Fabric.js)"
   ```

---

# [P04] Phase 4: 이미지 뷰 편집기 — Fabric.js 캔버스 + 번역 오버레이

## 전제 조건
Phase 0~3 완료: 번역 파이프라인, 테이블 뷰 편집기 완료.

## 작업 목표
이미지 뷰 탭 완성: 웹툰 이미지 위 번호 배지 렌더링,
말풍선 클릭 → 우측 패널에서 번역 후보 선택 → 오버레이 즉시 업데이트.

---

## 작업

### hooks/useFabricCanvas.ts
```typescript
// useFabricCanvas(canvasRef: RefObject<HTMLCanvasElement>, imageUrl: string)
// useEffect로 fabric.Canvas 초기화, cleanup 시 canvas.dispose()
// fabric.Image.fromURL로 이미지 배경 로드

// renderBubbles(bubbles, onBubbleClick):
//   각 bubble:
//   1. 사각형 테두리 (isConfirmed: 초록, 미확정: 파랑)
//   2. 원형 배지 + label_index (좌상단)
//   3. isConfirmed && translatedText 있으면:
//      흰 반투명 Rect (fill: rgba(255,255,255,0.9))
//      Textbox 번역문 (fontSize:13, fontFamily:NanumGothic, center 정렬)
//   4. border.on('mousedown') → onBubbleClick(bubble.id)
//   5. canvas.renderAll()

// 반환: { fabricRef, renderBubbles }
```

### components/editor/FabricCanvas.tsx
```typescript
// props: { imageUrl, bubbles, selectedBubbleId, onBubbleClick }
// useFabricCanvas 훅 사용
// bubbles 변경 시 renderBubbles 재호출
// selectedBubbleId 변경 시 해당 bubble 테두리 강조 (strokeWidth: 4)
// 캔버스 컨테이너: overflow-hidden, 스크롤 가능
```

### components/editor/TranslationPanel.tsx
```typescript
// props: { bubble: Bubble | null }
// 선택된 bubble의 원문, 화자, CandidateSelector 표시
// bubble null → "말풍선을 클릭하세요" 안내
```

### translation/page.tsx — 이미지 뷰 탭 완성
```
viewMode=image 레이아웃:
  좌측 2/3: FabricCanvas + PageNavigator
  우측 1/3: TranslationPanel (selectedBubbleId 기반)

번역 확정(PATCH 성공) 후:
  TanStack Query invalidateQueries(['bubbles', pageId])
  renderBubbles 재호출 → 오버레이 즉시 업데이트

테이블 뷰 ↔ 이미지 뷰 전환 시 selectedBubbleId 상태 유지 (editorStore)
```

---

## 완료 기준
- [ ] 이미지 뷰에서 웹툰 이미지 + 번호 배지 렌더링 확인
- [ ] 말풍선 클릭 → 우측 패널 CandidateSelector 표시 확인
- [ ] 번역 확정 후 해당 위치에 번역문 오버레이 즉시 표시 확인
- [ ] 테이블 뷰 ↔ 이미지 뷰 전환 후 선택 상태 유지 확인
- [ ] 페이지 변경 시 새 이미지 + 해당 페이지 bubbles 로드 확인
EOF

echo "✅ P04_image_editor_fabricjs.md 생성 완료"

# ──────────────────────────────────────────────
# P05 — AI 검수 + 렌더링 출력
# ──────────────────────────────────────────────
cat > prompts/P05_ai_review_rendering_output.md << 'EOF'
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
EOF

echo "✅ P05_ai_review_rendering_output.md 생성 완료"

# ──────────────────────────────────────────────
# P06 — 관리자 대시보드
# ──────────────────────────────────────────────
cat > prompts/P06_admin_dashboard.md << 'EOF'
## ⚙️ Codex 공통 운영 규칙 (매 작업 필수)

### 작업 시작 전 반드시
1. 프로젝트 현재 구조 확인:
```bash
tree -a -L 5 \
-I 'node_modules|.next|out|dist|build|coverage|.turbo|.vercel|.cache|.vite|__pycache__|.pytest_cache|.mypy_cache|.venv|venv|env|*.pyc|*.pyo|*.log|*.lock|package-lock.json|yarn.lock|pnpm-lock.yaml|poetry.lock|*.jpg|*.jpeg|*.png|*.gif|*.webp|*.svg|*.ico|*.bmp|*.tiff|*.mp4|*.mov|*.webm|*.zip|*.tar|*.gz|*.7z|*.pdf|*.ttf|*.otf|*.woff|*.woff2|*.wasm'
```
2. `docs/planning/` 에서 이번 작업 관련 설계 문서 읽기
   - 관련 문서: `01_BACKEND_ARCHITECTURE.md`, `02_FRONTEND_ARCHITECTURE.md`
3. `docs/tasks/logs/LOG_P05_ai_review_rendering_output.md` 확인

### 작업 완료 후 반드시
1. `docs/tasks/logs/LOG_P06_admin_dashboard.md` 작성
2. git commit:
   ```bash
   git add .
   git commit -m "feat: [P06] 관리자 대시보드"
   ```

---

# [P06] Phase 6: 관리자 대시보드 — API 사용량 모니터링

## 전제 조건
Phase 0~5 완료. APIUsageLog 모델 기존 구현됨.
관리자 접근: User.is_admin=True + get_admin_user 의존성으로 보호.

---

## 백엔드 작업 (routers/admin.py)

모든 엔드포인트: `get_admin_user` 의존성 (is_admin=False이면 403).

```
GET /admin/api-status
  → KeyRotator 상태 (clova, deepl, groq 각각 total/active/keys)

GET /admin/usage/summary
  Response: { "today": [...], "this_month": [...], "quota_warning_count": N }

GET /admin/usage/by-user
  Query: from (YYYY-MM-DD), to (YYYY-MM-DD)
  → [{ userId, userEmail, service, requests, chars, tokens }]

GET /admin/usage/by-user/{user_id}
  → 최근 100건 사용 이력

GET /admin/usage/timeseries
  Query: granularity ("day"|"hour"), from, to
  PostgreSQL: DATE_TRUNC / SQLite: strftime('%Y-%m-%d', created_at)
  → [{ period, service, requests }]

GET /admin/usage/quota-warnings
  Response:
  {
    "warnings": [{ service, keySuffix, status, resetAt, upgradeRecommended }],
    "count": N,
    "upgradeLinks": {
      "deepl": "https://www.deepl.com/pro",
      "groq": "https://console.groq.com/settings/billing",
      "clova": "https://www.ncloud.com/product/aiService/ocr"
    }
  }
```

---

## 프론트엔드 작업

```bash
npm install recharts
```

### app/admin/page.tsx
레이아웃:
1. **오늘/이번 달 요약 카드** (4개):
   총 OCR 요청 수 | 총 번역 요청 수 | 총 AI 검수 요청 수 | 활성 API Key 수

2. **쿼터 경고 배너** (GET /admin/usage/quota-warnings):
   - 경고 있으면: ⚠️ 노란 배너 + [유료 플랜 업그레이드 →] 링크 (upgradeLinks[service])
   - 경고 없으면: ✅ 모든 API Key 정상 동작 중

3. **서비스별 일별 Bar 차트** (Recharts BarChart):
   - GET /admin/usage/timeseries?granularity=day
   - 색상: clova_ocr=파랑, deepl=초록, groq_translate=보라, groq_review=주황, groq_speaker=빨강

4. **유저별 사용량 테이블**:
   - GET /admin/usage/by-user
   - 컬럼: 이메일 | 서비스 | 요청 수 | 문자 수 | 토큰 수
   - 행 클릭 → 상세 모달 (GET /admin/usage/by-user/{id})

5. **API Key 상태** (GET /admin/api-status):
   - 서비스별 Key (끝 4자리): 활성=초록 / 비활성=빨강 배지
   - 비활성 Key: 재활성화 예정 시각 표시

### app/admin/layout.tsx
- 비관리자 접근 시 /dashboard 리다이렉트

### middleware.ts 업데이트
- /admin/* 경로: access_token의 isAdmin 클레임 확인
- isAdmin=false → /dashboard 리다이렉트

---

## 완료 기준
- [ ] 관리자 계정 /admin 접근 → 대시보드 렌더링 확인
- [ ] 일반 계정 /admin 접근 → /dashboard 리다이렉트 확인
- [ ] 일별 Bar 차트 렌더링 확인 (Recharts)
- [ ] 쿼터 경고 배너: Key 비활성 상태일 때 경고 표시 확인
- [ ] 유저 테이블 행 클릭 → 상세 모달 확인
- [ ] quota-warnings 응답에 upgradeLinks 포함 확인
EOF

echo "✅ P06_admin_dashboard.md 생성 완료"

# ──────────────────────────────────────────────
# P07 — 배포
# ──────────────────────────────────────────────
cat > prompts/P07_deployment.md << 'EOF'
## ⚙️ Codex 공통 운영 규칙 (매 작업 필수)

### 작업 시작 전 반드시
1. 프로젝트 현재 구조 확인:
```bash
tree -a -L 5 \
-I 'node_modules|.next|out|dist|build|coverage|.turbo|.vercel|.cache|.vite|__pycache__|.pytest_cache|.mypy_cache|.venv|venv|env|*.pyc|*.pyo|*.log|*.lock|package-lock.json|yarn.lock|pnpm-lock.yaml|poetry.lock|*.jpg|*.jpeg|*.png|*.gif|*.webp|*.svg|*.ico|*.bmp|*.tiff|*.mp4|*.mov|*.webm|*.zip|*.tar|*.gz|*.7z|*.pdf|*.ttf|*.otf|*.woff|*.woff2|*.wasm'
```
2. `docs/planning/` 에서 이번 작업 관련 설계 문서 읽기
   - 관련 문서: `06_DEPLOYMENT.md`
3. `docs/tasks/logs/LOG_P06_admin_dashboard.md` 확인

### 작업 완료 후 반드시
1. `docs/tasks/logs/LOG_P07_deployment.md` 작성
2. git commit:
   ```bash
   git add .
   git commit -m "feat: [P07] Docker + Vercel 배포 설정"
   ```

---

# [P07] Phase 7: M1 맥미니 Docker 배포 + Vercel 프론트엔드 배포

## 전제 조건
Phase 0~6 완료: 전체 기능 구현 완료.
배포 환경: M1 맥미니(백엔드) + Vercel(프론트엔드) + Cloudflare Tunnel(도메인)

---

## 작업 1: 백엔드 Docker 설정

### backend/Dockerfile
```dockerfile
FROM python:3.11-slim
RUN apt-get update && apt-get install -y \
    libgl1-mesa-glx libglib2.0-0 libsm6 libxext6 \
    libxrender-dev libgomp1 fonts-nanum \
    && rm -rf /var/lib/apt/lists/*
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY . .
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000", "--workers", "2"]
```

### docker-compose.yml
```yaml
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
```

### backend/.env.production.example
```
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
```

---

## 작업 2: Cloudflare Tunnel 설정

### scripts/setup_cloudflare_tunnel.sh
```bash
#!/bin/bash
# 1. cloudflared 설치 확인
# 2. cloudflared tunnel login 안내
# 3. cloudflared tunnel create ailosy-backend
# 4. ~/.cloudflared/config.yml 생성
# 5. cloudflared service install 안내
# 각 단계 설명 주석 포함
```

### ~/.cloudflared/config.yml 템플릿
```yaml
tunnel: <TUNNEL_ID>
credentials-file: ~/.cloudflared/<TUNNEL_ID>.json
ingress:
  - hostname: api.ailosy.com
    service: http://localhost:8000
  - service: http_status:404
```

---

## 작업 3: Vercel 설정

### frontend/vercel.json
```json
{
  "buildCommand": "npm run build",
  "outputDirectory": ".next",
  "framework": "nextjs"
}
```

### frontend/.env.production
```
NEXT_PUBLIC_API_URL=https://api.ailosy.com
NEXTAUTH_URL=https://ailosy.vercel.app
NEXTAUTH_SECRET=생성된-시크릿
```

### frontend/.env.local.example
```
NEXT_PUBLIC_API_URL=http://localhost:8000
```

---

## 작업 4: 프로덕션 전환 체크리스트 (CHECKLIST.md)

루트에 CHECKLIST.md 생성:
```markdown
- [ ] backend/.env에 ENVIRONMENT=production 설정
- [ ] DATABASE_URL PostgreSQL로 변경
- [ ] backend/main.py CORS origins에 실제 Vercel 도메인 추가
- [ ] docker compose up -d 실행
- [ ] cloudflared tunnel run ailosy-backend 테스트
- [ ] cloudflared service install로 자동시작 등록
- [ ] Vercel 환경변수 NEXT_PUBLIC_API_URL=https://api.ailosy.com 설정
- [ ] GitHub main 브랜치 push → Vercel 자동 빌드 확인
- [ ] https://api.ailosy.com/docs 접근 확인
- [ ] https://ailosy.vercel.app 에서 로그인 → 프로젝트 생성 → OCR 실행 E2E 확인
- [ ] M1 맥미니 재부팅 후 자동 서비스 재시작 확인
```

---

## 완료 기준
- [ ] docker compose up -d 실행 후 localhost:8000/docs 접근 확인
- [ ] Dockerfile 빌드 성공 (M1 arm64 환경)
- [ ] CHECKLIST.md 생성 확인
EOF

echo "✅ P07_deployment.md 생성 완료"

# ──────────────────────────────────────────────
# LOG 템플릿 파일 생성
# ──────────────────────────────────────────────
write_log_template "logs/LOG_P00_setup.md"                              "P00" "프로젝트 초기 세팅 + JWT 인증"
write_log_template "logs/LOG_P01A_backend_db_crud.md"                  "P01A" "DB 모델 전체 + 프로젝트/회차 CRUD"
write_log_template "logs/LOG_P01B_backend_upload_ocr_keyrotator.md"    "P01B" "파일 업로드 + OCR + KeyRotator"
write_log_template "logs/LOG_P01C_frontend_dashboard_upload.md"        "P01C" "프론트엔드 대시보드 + 업로드"
write_log_template "logs/LOG_P02_speaker_matching_labeling.md"         "P02"  "화자 매칭 + 라벨링 검수"
write_log_template "logs/LOG_P03_translation_pipeline_table_editor.md" "P03"  "번역 파이프라인 + 테이블 뷰"
write_log_template "logs/LOG_P04_image_editor_fabricjs.md"             "P04"  "이미지 뷰 편집기 (Fabric.js)"
write_log_template "logs/LOG_P05_ai_review_rendering_output.md"        "P05"  "AI 검수 + 렌더링 출력"
write_log_template "logs/LOG_P06_admin_dashboard.md"                   "P06"  "관리자 대시보드"
write_log_template "logs/LOG_P07_deployment.md"                        "P07"  "배포"

echo "✅ 모든 LOG 템플릿 생성 완료"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "생성 완료 목록:"
echo "  CODEX_TASKS.md (마스터 지시문)"
echo "  prompts/ (10개 Phase 파일)"
echo "  logs/    (10개 LOG 템플릿)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
