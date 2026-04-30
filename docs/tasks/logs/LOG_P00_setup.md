# 작업 로그 — P00: 프로젝트 초기 세팅 + JWT 인증

## 메타
- 작업일: 2026-04-30
- 작업자: Codex
- 소요시간: 약 1h
- Commit: 미생성 (현재 폴더가 Git 저장소가 아님)

## 완료된 작업
- [x] Homebrew `python@3.11` 설치 및 백엔드 `.venv` 구성
- [x] FastAPI 백엔드 기본 구조 생성
- [x] SQLAlchemy DB 연결, SQLite/PostgreSQL connect_args 분기 구현
- [x] User 모델 생성 (`is_admin` 포함)
- [x] JWT access/refresh 인증 API 구현
- [x] `get_current_user`, `get_admin_user` 의존성 구현
- [x] CORS, 요청 로깅, startup DB create_all 구현
- [x] Next.js 14 + TypeScript + Tailwind 프론트엔드 초기 구조 생성
- [x] shadcn/ui 기본 설정 파일과 UI primitive 구성
- [x] Axios 인스턴스, 공통 타입, 로그인/회원가입/대시보드 화면 구현
- [x] 쿠키 기반 Next middleware 보호 라우트 구현
- [x] 백엔드/프론트 검증 완료

## 작업한 파일 목록
```
.gitignore
backend/.env.example
backend/config.py
backend/database.py
backend/main.py
backend/models/__init__.py
backend/models/user.py
backend/requirements.txt
backend/routers/__init__.py
backend/routers/auth.py
frontend/.env.example
frontend/.eslintrc.json
frontend/app/(auth)/login/page.tsx
frontend/app/(auth)/register/page.tsx
frontend/app/dashboard/page.tsx
frontend/app/globals.css
frontend/app/layout.tsx
frontend/app/page.tsx
frontend/app/providers.tsx
frontend/components.json
frontend/components/ui/button.tsx
frontend/components/ui/input.tsx
frontend/components/ui/label.tsx
frontend/lib/api.ts
frontend/lib/types.ts
frontend/lib/utils.ts
frontend/middleware.ts
frontend/next-env.d.ts
frontend/next.config.mjs
frontend/package-lock.json
frontend/package.json
frontend/postcss.config.js
frontend/tailwind.config.ts
frontend/tsconfig.json
```

## 변경 사항 요약
- 백엔드는 `backend` 디렉토리에서 `uvicorn main:app --reload`로 실행 가능한 구조로 작성했다.
- 환경변수는 `pydantic.v1.BaseSettings` 기반으로 로드한다. Python 3.9 호환성을 고려해 `str | None`, `match/case`는 사용하지 않았다.
- `POST /auth/register`, `POST /auth/login`, `POST /auth/refresh`, `GET /auth/me`를 구현했다.
- `passlib==1.7.4`와 최신 `bcrypt==5.x`가 충돌해 해싱이 실패하므로 `bcrypt==4.0.1`을 명시 고정했다.
- 프론트엔드는 Next.js 14 App Router 기반으로 로그인/회원가입/대시보드 최소 흐름을 만들었다.
- 로그인 성공 시 `access_token`, `refresh_token`은 `localStorage`에 저장하고, middleware 보호 라우트용 `access_token` 쿠키도 함께 설정한다.
- `NEXT_PUBLIC_API_URL` 기본값은 `http://localhost:8000`으로 두었다.

## 다음 작업 시 주의사항
- 현재 루트는 Git 저장소가 아니므로 P00의 `git add . && git commit ...`는 실행하지 못했다. 커밋이 필요하면 먼저 `git init` 여부를 결정해야 한다.
- `frontend/node_modules`, `frontend/.next`, `backend/.venv`, SQLite DB, 업로드/출력 폴더는 `.gitignore`에 포함했다.
- `npm install` 후 `npm audit`에서 7개 취약점 경고가 나왔다. `audit fix --force`는 Next/NextAuth 계열 메이저 변경 가능성이 있어 적용하지 않았다.
- FastAPI 0.109 + Starlette 0.35 조합에서 `TestClient`는 최신 `httpx`와 충돌할 수 있으므로 현재는 uvicorn + HTTP 요청 방식으로 검증했다.
- 프로덕션에서는 `SECRET_KEY`를 반드시 강한 값으로 교체해야 한다.
- Docker는 계획대로 Python 3.11 이미지를 쓰는 것이 가장 안정적이다.

## 미완료 / 이슈
- Git commit 미완료: `/Users/gabriel/Development/webtoon-ai-translate`에 `.git` 디렉토리가 없다.
- shadcn CLI 자체는 실행하지 않고, shadcn/ui 호환 설정과 기본 UI primitive를 직접 구성했다.
