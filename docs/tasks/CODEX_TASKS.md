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
