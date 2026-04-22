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
   git commit -m "feat: [P07] Docker + Vercel 배포 설정 + 코드 주석 + 문서화"
   ```

---

# [P07] Phase 7: 배포 + 코드 주석 + 프로젝트 문서화

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

## 작업 5: 코드 주석 — Backend (backend/ 전체 .py 파일)

`backend/` 아래 모든 `.py` 파일을 순회하면서 한국어 주석을 추가한다.
기존 코드는 수정하지 않는다. 주석만 추가한다.

### 공통 규칙

**① 파일 상단 헤더 (모든 .py 파일 필수)**
```python
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 파일 경로: backend/routers/auth.py
# 역할: JWT 기반 인증 엔드포인트 모음.
#       회원가입·로그인·토큰 갱신·내 정보 조회를 처리한다.
#       이 파일에서 발급된 access_token이 이후 모든 API 요청의 인증 수단이 된다.
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

**② 함수/클래스마다 다른 맥락의 주석**
같은 패턴의 주석을 반복하지 않는다. 각 함수가 "왜" 존재하는지, "어떤 흐름에서 호출되는지"를 이 파일의 맥락에서 구체적으로 설명한다.

❌ 나쁜 예:
```python
# 사용자를 생성합니다
async def register(...):
    # DB에 저장합니다
    db.add(user)
```

✅ 좋은 예:
```python
# [회원가입] 이메일 중복 확인 후 bcrypt로 비밀번호를 해싱해서 저장한다.
# 가입 즉시 access_token을 발급하므로, 클라이언트는 별도 로그인 없이 바로 대시보드 진입 가능.
async def register(...):
    # 동일 이메일 존재 시 409 반환 — 프론트의 "이미 사용 중인 이메일" 안내 문구용
    existing = db.query(User).filter(User.email == body.email).first()
```

**③ 엔드포인트마다 호출 출처 명시**
```python
# [호출 출처] 프론트의 [OCR 시작 →] 버튼 클릭 시 호출됨 (upload/page.tsx)
@router.post("/episodes/{ep_id}/jobs/ocr")
```

### 파일별 주석 포인트

**`config.py`**
- 각 환경변수가 어디서 어떻게 쓰이는지 인라인으로 설명
- CLOVA_KEYS 등 콤마 구분 문자열이 KeyRotator에서 어떻게 파싱되는지 언급

**`database.py`**
- SQLite/PostgreSQL 자동 분기 로직의 이유 (개발/프로덕션 환경 차이)
- `get_db()` yield 패턴이 왜 필요한지 (요청마다 세션 격리, 요청 종료 시 자동 close)

**`services/key_rotator.py`**
- 클래스 상단에 KeyRotator 전체 동작 원리 서술 (라운드로빈 + 비활성화 + 재활성화)
- `get_key()`: 라운드로빈 + 재활성화 조건 흐름 설명
- `report_quota_exceeded` vs `report_error` 차이점
  (쿼터 소진 = 24시간 비활성화 / 일시 오류 = 3회 후 5분 비활성화)

**`pipeline/ocr_pipeline.py`**
- `process_page()` 상단에 전체 처리 단계를 번호로 서술 (1.OCR → 2.파싱 → 3.병합 → 4.정렬 → 5.라벨링)
- `_merge_nearby_boxes()`: Clova가 한 말풍선을 여러 박스로 쪼개는 문제를 해결하는 로직임을 명시
- `_sort_reading_order()`: 일반 문서(좌→우)와 달리 웹툰은 오른→왼 읽기 순서임을 명시

**`pipeline/context_builder.py`**
- `build_candidate_prompt()`에 주입되는 4가지 컨텍스트 블록 각각의 역할 설명
- `get_past_speech_samples()`의 `is_edited` 우선 정렬 이유
  (번역가 확정본 > AI 원안 순으로 신뢰도가 높기 때문)

**`pipeline/translation_pipeline.py`**
- `translate_with_candidates()` vs `translate_batch_simple()` 차이와 사용 시점
  (전자: 컨텍스트 풍부 / 후자: 속도 우선 + Groq 쿼터 절약)
- DeepL → Groq 폴백 흐름 설명

**`pipeline/review_pipeline.py`**
- `llama-3.1-8b-instant`를 쓰는 이유 (번역보다 가벼운 검수 작업이므로 빠른 모델로 비용 절감)
- 검수 기준 4가지(consistency/mistranslation/unnatural/sfx)가 각각 무엇을 잡는지 설명

**`pipeline/render_pipeline.py`**
- `_inpaint()` fast vs high 차이 (OpenCV TELEA vs SimpleLama)
- `_fit_font_size()` 이진 탐색이 왜 필요한지 (말풍선 크기가 제각각이라 고정 폰트 크기 불가)

**`routers/` 각 파일**
- 각 엔드포인트마다 `[호출 출처]` 태그로 어떤 프론트 화면/버튼이 이 API를 호출하는지 명시

---

## 작업 6: 코드 주석 — Frontend (frontend/ 전체 .ts/.tsx 파일)

`frontend/` 아래 모든 `.ts` / `.tsx` 파일을 순회하면서 한국어 주석을 추가한다.
기존 코드는 수정하지 않는다. 주석만 추가한다.

### 공통 규칙

**① 파일 상단 헤더 (모든 파일 필수)**
```typescript
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// 파일 경로: frontend/app/projects/[projectId]/episodes/[episodeId]/labeling/page.tsx
// 역할: 라벨링 검수 화면. OCR로 감지된 말풍선을 Fabric.js로 이미지 위에 시각화하고,
//       화자를 드롭다운으로 확정하거나 AI 자동 매칭을 재실행할 수 있다.
//       이 화면을 통과해야 번역 단계(/translation)로 진행 가능하다.
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

**② 개념 태그 규칙**
아래 태그를 코드 흐름에 맞게 사용한다. 태그는 설명 없이 단독으로 쓰지 않는다. 반드시 이 파일의 맥락을 담은 설명과 함께 쓴다.

| 태그 | 사용 시점 |
|------|-----------|
| `[useState]` | 상태 정의 시. "어떤 데이터를 왜 상태로 관리하는지" |
| `[useEffect]` | 각 effect마다 다른 설명. "왜 있는지 / 언제 실행 / cleanup 이유" |
| `[useCallback]` | 함수가 자식 prop으로 내려가거나 effect dependency에 포함될 때 |
| `[Props/콜백]` | 부모-자식 state 소유 관계와 콜백 흐름 |
| `[TanStack Query]` | queryKey 설계 이유, refetchInterval 근거, invalidateQueries 타이밍 |
| `[Zustand]` | 어떤 상태를 전역으로 올린 이유 |
| `[Fabric.js]` | canvas 초기화/dispose 시점, renderAll() 호출 이유 |
| `[라우팅]` | useRouter / usePathname 사용 시 왜 이 시점에 이동하는지 |

**③ useEffect마다 반드시 다른 주석**

❌ 나쁜 예 (모든 useEffect에 같은 패턴):
```typescript
// useEffect: 렌더링 이후 부수 효과를 처리합니다
useEffect(() => { ... }, [jobId])
```

✅ 좋은 예 (이 파일의 맥락 반영):
```typescript
// [useEffect] Job 폴링 완료 감지
// isDone이 true로 바뀌는 순간 라벨링 페이지로 자동 이동한다.
// dependency: isDone만 넣는다 — true로 바뀔 때 한 번만 실행되면 충분.
// cleanup 불필요: 이동 후 이 컴포넌트는 언마운트되므로 폴링도 자동 중단됨.
useEffect(() => {
  if (isDone) router.push(`/projects/${projectId}/episodes/${episodeId}/labeling`)
}, [isDone])
```

### 파일별 주석 포인트

**`hooks/useJobPolling.ts`**
- `refetchInterval` 동적 설정 이유: 완료 후에도 폴링하면 불필요한 서버 부하 발생
- `queryKey`에 jobId를 넣는 이유: job마다 독립적인 캐시 관리 필요

**`components/labeling/LabelingCanvas.tsx`**
- `[Fabric.js]` canvas 초기화를 useEffect 안에서 하는 이유 (DOM 마운트 후에만 canvas 접근 가능)
- `[Fabric.js]` `dispose()` cleanup이 반드시 필요한 이유 (페이지 이동 후 인스턴스 메모리 잔류 시 이벤트 리스너 누수)
- `renderBubbles` 재호출 시점 (bubbles 배열 변경 시마다)
- 화자 확정/미확인에 따른 테두리 색상 분기 이유

**`components/translation/CandidateSelector.tsx`**
- 라디오 선택 상태와 직접 입력 Input 간 동기화 로직 설명
- `[useCallback]` onConfirm이 부모에서 내려오는 콜백이므로 deps 설계 주의점
- 후보 재생성 시 additional_context가 왜 필요한지 (번역가가 힌트를 직접 줄 수 있음)

**`store/editorStore.ts`**
- `[Zustand]` viewMode, selectedBubbleId, currentPage를 전역으로 올린 이유
  — 테이블 뷰 ↔ 이미지 뷰 전환 시에도 선택 상태 유지, 여러 컴포넌트에서 동시 접근 필요

**`store/projectStore.ts`**
- `[Zustand]` currentProjectId, currentEpisodeId를 전역으로 올린 이유
  — 중첩된 라우팅 구조에서 깊은 자식 컴포넌트까지 prop drilling 없이 접근 필요

**`lib/api.ts`**
- 요청 인터셉터: localStorage access_token 자동 첨부 이유 (모든 API 요청에 반복 코드 방지)
- 응답 인터셉터 401 처리: 토큰 만료 시 자동 로그아웃 + 리다이렉트 흐름 설명

**`app/` 각 page.tsx**
- 페이지 진입 시 자동으로 실행되는 Job(OCR/번역/화자매칭)이 있으면 그 흐름과 이유 설명
- 각 버튼 클릭이 어떤 API를 호출하고 어떤 상태 전환을 일으키는지 명시
- `[라우팅]` 다음 단계로 이동하는 조건과 시점 설명

---

## 작업 7: BACKEND_STRUCTURE.md 생성

`docs/` 에 `BACKEND_STRUCTURE.md` 파일을 생성한다.

**작성 순서**:
1. 아래 명령어로 실제 구조를 먼저 출력한다:
```bash
tree backend/ -a -L 4 \
-I '__pycache__|*.pyc|*.pyo|.venv|venv|*.egg-info|.pytest_cache|.mypy_cache'
```
2. 출력된 실제 구조를 기반으로 작성한다. 존재하지 않는 파일은 절대 작성하지 않는다.

**파일 형식**:
```markdown
# Backend Structure — AI Losy

AI Losy 백엔드는 FastAPI 기반의 비동기 REST API 서버다.
업로드된 웹툰 이미지에 대해 OCR → 화자 매칭 → 번역 후보 생성 → AI 검수 → 렌더링 출력
파이프라인을 순차적으로 처리한다.

## 읽는 법
- `main.py`: FastAPI 앱 진입점. 라우터 등록과 startup 이벤트(테이블 자동 생성)를 담당한다.
- `config.py`: 환경변수 로드. KeyRotator가 여기서 API Key를 읽는다.
- `database.py`: DB 세션 관리. DATABASE_URL로 SQLite(개발)/PostgreSQL(프로덕션) 자동 분기.
- `models/`: SQLAlchemy ORM 모델. DB 테이블 정의.
- `routers/`: FastAPI 라우터. HTTP 엔드포인트 정의.
- `services/`: 외부 API 클라이언트 (Clova OCR, DeepL, Groq). KeyRotator 포함.
- `pipeline/`: OCR → 화자매칭 → 번역 → 검수 → 렌더링 비즈니스 로직.
- `schemas/`: Pydantic 요청/응답 스키마.

## 디렉토리 구조
[tree 출력 결과 그대로 삽입]

## 파일별 역할 상세

### 루트 파일
| 파일 | 역할 |
|------|------|
| main.py | FastAPI 앱 초기화, 라우터 등록, CORS/로깅 미들웨어, startup에서 DB 테이블 자동 생성 |
| config.py | pydantic Settings로 .env 로드. CLOVA_KEYS 등 콤마 구분 문자열 관리 |
| database.py | SQLAlchemy engine/SessionLocal/get_db(). DATABASE_URL로 SQLite/PG 분기 |

### models/ — ORM 모델
| 파일 | 테이블 | 핵심 내용 |
|------|--------|-----------|
| user.py | users | 이메일/비밀번호/is_admin 관리 |
| project.py | projects, characters, character_speech_samples | 작품·캐릭터·말투 샘플 |
| episode.py | episodes, episode_character_situations | 회차·캐릭터 상황 |
| page.py | pages | 업로드된 이미지 페이지 |
| bubble.py | bubbles, translation_candidates | 말풍선·번역 후보 |
| review_suggestion.py | review_suggestions | AI 검수 제안 |
| job.py | jobs | 비동기 작업 상태 추적 |
| api_usage_log.py | api_usage_logs | API 사용량 기록 |

### routers/ — HTTP 엔드포인트
| 파일 | 주요 엔드포인트 |
|------|----------------|
| auth.py | POST /auth/register, /auth/login, /auth/refresh, GET /auth/me |
| projects.py | CRUD /projects/*, /projects/{id}/characters/* |
| episodes.py | CRUD /projects/{id}/episodes/* |
| upload.py | POST /episodes/{ep_id}/pages/upload, GET/DELETE /pages |
| ocr.py | POST /episodes/{ep_id}/jobs/ocr, GET /jobs/{id}/status, CRUD /bubbles |
| labeling.py | POST /jobs/speaker-match, PATCH /bubbles/{id}/speaker |
| translation.py | POST /jobs/translate, GET/PATCH /bubbles/{id}/candidates |
| review.py | POST /jobs/ai-review, GET/PATCH /review-suggestions/* |
| export.py | POST /jobs/render, GET /preview/{page_id}, GET /export (ZIP) |
| admin.py | GET /admin/api-status, /admin/usage/* |

### services/ — 외부 API 클라이언트
| 파일 | 역할 |
|------|------|
| key_rotator.py | API Key 라운드로빈 + 쿼터 소진 시 자동 비활성화 |
| clova_ocr.py | Clova General OCR API 호출 클라이언트 |
| groq_client.py | Groq LLM chat 호출 + JSON 파싱 |
| deepl_client.py | DeepL 배치 번역 클라이언트 |

### pipeline/ — 비즈니스 파이프라인
| 파일 | 담당 단계 |
|------|-----------|
| ocr_pipeline.py | OCR 호출 → 박스 병합 → 읽기 순서 정렬 → 라벨 부여 |
| speaker_matcher.py | Groq LLM으로 말풍선별 화자 추론 |
| context_builder.py | 번역 프롬프트에 주입할 4가지 컨텍스트 블록 생성 |
| translation_pipeline.py | 번역 후보 생성 (Groq) + 배치 번역 (DeepL) |
| review_pipeline.py | AI 일관성 검수 (Groq llama-3.1-8b-instant) |
| render_pipeline.py | 인페인팅 (OpenCV) + 텍스트 합성 (PIL) → JPEG 출력 |
```

---

## 작업 8: FRONTEND_STRUCTURE.md 생성

`docs/` 에 `FRONTEND_STRUCTURE.md` 파일을 생성한다.

**작성 순서**:
1. 아래 명령어로 실제 구조를 먼저 출력한다:
```bash
tree frontend/ -a -L 5 \
-I 'node_modules|.next|out|dist|build|coverage|.turbo|.vercel|.cache|*.log|*.lock|package-lock.json|yarn.lock|pnpm-lock.yaml|*.jpg|*.jpeg|*.png|*.gif|*.webp|*.svg|*.ico|*.woff|*.woff2|*.ttf'
```
2. 출력된 실제 구조를 기반으로 작성한다. 존재하지 않는 파일은 절대 작성하지 않는다.

**파일 형식**:
```markdown
# Frontend Structure — AI Losy

AI Losy 프론트엔드는 Next.js 14 App Router 기반이다.
번역가가 웹툰 이미지를 보며 번역 후보를 선택하고 확정하는 인터랙티브 편집기가 핵심이다.

## 읽는 법
- `app/`: Next.js App Router의 실제 URL 진입점. 각 폴더가 URL 경로에 대응한다.
- `components/`: 재사용 UI 컴포넌트. 기능 도메인(labeling/translation/editor/common)별로 분류.
- `hooks/`: 상태·API 폴링 등 재사용 가능한 커스텀 훅.
- `store/`: Zustand 전역 상태. 페이지 간 공유가 필요한 상태만 올린다.
- `lib/`: Axios 인스턴스(api.ts), 공통 TypeScript 타입(types.ts).

## 라우팅 구조
| URL 경로 | 파일 위치 | 화면 역할 |
|----------|-----------|-----------|
| /login | app/(auth)/login/page.tsx | 이메일+비밀번호 로그인 |
| /register | app/(auth)/register/page.tsx | 회원가입 |
| /dashboard | app/dashboard/page.tsx | 프로젝트 목록 카드 |
| /projects/new | app/projects/new/page.tsx | 프로젝트+캐릭터 생성 폼 |
| /projects/[id] | app/projects/[projectId]/page.tsx | 프로젝트 상세 + 회차 목록 |
| /projects/[id]/episodes/[ep_id]/upload | .../upload/page.tsx | 파일 업로드 + OCR 시작 |
| /projects/[id]/episodes/[ep_id]/labeling | .../labeling/page.tsx | Fabric.js 화자 검수 |
| /projects/[id]/episodes/[ep_id]/translation | .../translation/page.tsx | 번역 후보 선택 (테이블/이미지 뷰) |
| /projects/[id]/episodes/[ep_id]/review | .../review/page.tsx | AI 검수 제안 수락/거절 |
| /projects/[id]/episodes/[ep_id]/export | .../export/page.tsx | 렌더링 출력 + ZIP 다운로드 |
| /admin | app/admin/page.tsx | 관리자 API 사용량 대시보드 |

## 디렉토리 구조
[tree 출력 결과 그대로 삽입]

## 파일별 역할 상세

### app/ — 페이지 컴포넌트
[각 page.tsx 파일의 역할, 진입 시 자동 실행되는 Job, 주요 API 호출 목록]

### components/ — UI 컴포넌트
| 파일 | 역할 |
|------|------|
| common/JobProgressBar.tsx | 비동기 Job 진행률 바. status별 색상 분기 |
| common/PageNavigator.tsx | 페이지 이전/다음 네비게이션 |
| common/FileUploader.tsx | react-dropzone 기반 이미지/PDF 업로드 + 썸네일 미리보기 |
| labeling/LabelingCanvas.tsx | Fabric.js 캔버스. 말풍선 테두리 + 번호 배지 렌더링 |
| labeling/BubbleList.tsx | 사이드바 말풍선 목록. 화자 드롭다운 + 원문 편집 |
| translation/CandidateSelector.tsx | 번역 후보 라디오 선택 + 직접 입력 UI ⭐ 핵심 컴포넌트 |
| translation/TranslationTable.tsx | 전체 말풍선 번역 현황 테이블 |
| editor/FabricCanvas.tsx | 이미지 뷰 편집기 캔버스. 번역 오버레이 표시 |
| editor/TranslationPanel.tsx | 이미지 뷰 우측 패널. 선택된 말풍선의 번역 후보 표시 |

### hooks/
| 파일 | 역할 |
|------|------|
| useJobPolling.ts | Job status를 2초 간격으로 폴링. done/failed 시 폴링 자동 중단 |
| useFabricCanvas.ts | Fabric.js canvas 초기화·렌더링·dispose 관리 |

### store/
| 파일 | 상태 | 전역으로 올린 이유 |
|------|------|-------------------|
| projectStore.ts | currentProjectId, currentEpisodeId | 중첩 라우팅에서 깊은 자식까지 prop drilling 없이 접근 |
| editorStore.ts | viewMode, selectedBubbleId, currentPage, filterMode | 테이블↔이미지 뷰 전환 시 선택 상태 유지 |

### lib/
| 파일 | 역할 |
|------|------|
| api.ts | Axios 인스턴스. 요청 인터셉터(토큰 자동 첨부) + 응답 인터셉터(401 자동 로그아웃) |
| types.ts | 프로젝트 전체 공통 TypeScript 인터페이스 정의 |
```

---

## 작업 9: README.md 생성

프로젝트 루트에 `README.md` 파일을 생성한다.
실제 구현된 내용을 반영해서 구체적으로 작성한다. 추상적인 설명은 지양한다.

```markdown
# AI Losy — 웹툰 자동 번역 어시스턴트

> Translator용 번역 어시스턴트. AI가 번역 후보 3~4개를 제안하고, 번역가가 최종 선택한다.

## 왜 만들었나

기존 번역 도구는 단일 번역문을 반환한다. 번역가는 그걸 그대로 쓰거나 처음부터 다시 쓴다.
AI Losy는 AI를 **초안 생성기**로 사용한다. 번역 후보 3개를 Survey형(①②③ + ④직접입력)으로
제안하고, 번역가가 최종 선택권을 갖는다. 작품 줄거리·캐릭터 어투·이전 회차 말투 샘플을
프롬프트에 주입해 말투 일관성을 유지한다.

## 주요 기능

- **자동 말풍선 감지**: 웹툰 이미지/PDF 업로드 → Clova General OCR → 읽기 순서 자동 정렬
- **AI 화자 매칭**: Groq LLM으로 말풍선별 화자 자동 추론 → Fabric.js 이미지 뷰 검수
- **Survey형 번역 후보**: 컨텍스트 주입 프롬프트 → Groq 후보 3개 생성 → 번역가 선택
- **테이블 뷰 / 이미지 뷰**: 효율적인 검수를 위한 두 가지 편집 모드
- **AI 일관성 검수**: 번역 완료 후 Groq가 일관성·오역·부자연스러움 자동 탐지
- **번역 합성 출력**: OpenCV 인페인팅 + PIL 텍스트 합성 → ZIP 다운로드
- **관리자 대시보드**: API 사용량 실시간 모니터링 + 쿼터 경고

## 기술 스택

| 영역 | 기술 |
|------|------|
| Backend | FastAPI (Python 3.11), SQLAlchemy 2.x, SQLite(개발)/PostgreSQL(프로덕션) |
| Frontend | Next.js 14 (App Router), TypeScript, Tailwind CSS, shadcn/ui, Fabric.js, Zustand, TanStack Query |
| AI/OCR | Clova General OCR, DeepL, Groq llama-3.3-70b-versatile / llama-3.1-8b-instant |
| 배포 | M1 맥미니 Docker + Vercel + Cloudflare Tunnel |

## 번역 파이프라인

```
웹툰 이미지/PDF 업로드
  ↓
Clova OCR → 말풍선 감지 → 읽기 순서 정렬 → 번호 라벨링
  ↓
Groq LLM → 화자 자동 매칭 → 번역가 검수 (Fabric.js)
  ↓
[작품줄거리 + 회차줄거리 + 캐릭터어투 + 이전말투샘플] 컨텍스트 주입
  ↓
Groq → 번역 후보 3개 생성 → 번역가 Survey형 선택
  ↓
Groq llama-3.1-8b-instant → AI 일관성 검수 → 번역가 수락/거절
  ↓
OpenCV 인페인팅 → PIL 텍스트 합성 → ZIP 출력
```

## 시작하기

### 사전 요구사항
- Python 3.11+
- Node.js 18+
- Docker & Docker Compose (프로덕션)
- Clova OCR / DeepL / Groq API Key

### 로컬 개발 환경

**백엔드**
```bash
cd backend
cp .env.example .env
# .env에 CLOVA_KEYS, DEEPL_KEYS, GROQ_KEYS 등 API Key 입력
pip install -r requirements.txt
uvicorn main:app --reload
# Swagger UI → http://localhost:8000/docs
```

**프론트엔드**
```bash
cd frontend
cp .env.local.example .env.local
# .env.local: NEXT_PUBLIC_API_URL=http://localhost:8000
npm install
npm run dev
# → http://localhost:3000
```

## 배포

### M1 맥미니 — 백엔드 (Docker)
```bash
cp backend/.env.production.example backend/.env
# .env 편집: SECRET_KEY, DB_PASSWORD, API Keys 입력
docker compose up -d
# → http://localhost:8000
```

### Vercel — 프론트엔드
1. GitHub 레포를 Vercel에 연결
2. 환경변수 설정: `NEXT_PUBLIC_API_URL=https://api.ailosy.com`
3. main 브랜치 push → 자동 배포

### Cloudflare Tunnel — 도메인 연결
```bash
bash scripts/setup_cloudflare_tunnel.sh
```
`api.ailosy.com` → M1 맥미니 localhost:8000 터널링.

## API Key 관리

`KeyRotator`가 `CLOVA_KEYS`, `DEEPL_KEYS`, `GROQ_KEYS`를 라운드로빈으로 순환한다.
- 쿼터 소진 시: 해당 Key 24시간 비활성화 → 다른 Key로 자동 전환
- 일시 오류 3회: 5분 비활성화 → 자동 복구
- 관리자 대시보드(`/admin`): Key 상태 실시간 확인 + 쿼터 소진 경고 + 유료 플랜 업그레이드 링크

## 환경변수

`backend/.env.example` 참고.

| 변수 | 설명 |
|------|------|
| `CLOVA_KEYS` | Clova OCR API Key (콤마 구분, 여러 개 가능) |
| `CLOVA_URLS` | Clova OCR Invoke URL (Key와 순서 일치) |
| `DEEPL_KEYS` | DeepL API Key (콤마 구분) |
| `GROQ_KEYS` | Groq API Key (콤마 구분) |
| `SECRET_KEY` | JWT 서명 키 |
| `DATABASE_URL` | SQLite(개발) 또는 PostgreSQL(프로덕션) |

## 프로젝트 구조

- [Backend 구조](docs/BACKEND_STRUCTURE.md)
- [Frontend 구조](docs/FRONTEND_STRUCTURE.md)

## 라이선스

[라이선스 명시]
```

---

## 완료 기준
- [ ] `docker compose up -d` 실행 후 `localhost:8000/docs` 접근 확인
- [ ] Dockerfile 빌드 성공 (M1 arm64 환경)
- [ ] CHECKLIST.md 생성 확인
- [ ] `backend/` 전체 `.py` 파일에 한국어 주석 추가 확인
  - 파일 상단 헤더 (경로 + 역할) 포함 여부
  - `useEffect` 동등물인 FastAPI startup/background task 주석이 각각 다른 맥락으로 작성됐는지
  - 각 엔드포인트에 `[호출 출처]` 태그 포함 여부
- [ ] `frontend/` 전체 `.ts/.tsx` 파일에 한국어 주석 추가 확인
  - 파일 상단 헤더 (경로 + 역할) 포함 여부
  - `useEffect` 마다 다른 맥락의 주석인지 (같은 주석 반복 금지)
  - `[useState]` `[useCallback]` `[TanStack Query]` `[Zustand]` `[Fabric.js]` 태그 사용 여부
- [ ] `docs/BACKEND_STRUCTURE.md` 생성 확인 (실제 tree 구조 반영, 테이블 형식 포함)
- [ ] `docs/FRONTEND_STRUCTURE.md` 생성 확인 (라우팅 표 + 실제 tree 구조 반영)
- [ ] 루트 `README.md` 생성 확인
  - 로컬 실행 명령어 실제로 동작하는지 검증
  - 번역 파이프라인 흐름도 포함 여부