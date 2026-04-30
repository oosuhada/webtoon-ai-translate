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
