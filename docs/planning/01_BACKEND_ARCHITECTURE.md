# 01 — 백엔드 아키텍처 상세 설계

## 디렉토리 구조

```
backend/
├── main.py                    # FastAPI 앱 진입점, 미들웨어, CORS 설정
├── config.py                  # 환경변수, 설정값 (pydantic Settings)
├── database.py                # DB 연결, 세션, Base
│
├── routers/                   # API 라우터 (각 도메인별 분리)
│   ├── auth.py                # 로그인/회원가입/토큰 갱신
│   ├── projects.py            # 프로젝트 CRUD
│   ├── episodes.py            # 회차 관리 (회차별 컨텍스트 포함)
│   ├── upload.py              # 파일 업로드 (이미지/PDF)
│   ├── ocr.py                 # OCR 작업 시작/상태
│   ├── labeling.py            # 화자 매칭/라벨링 검수
│   ├── translation.py         # 번역 실행, 후보 조회, 선택
│   ├── review.py              # AI 검수 실행/제안 관리
│   ├── export.py              # 최종 이미지 렌더링 및 다운로드
│   └── admin.py               # API Key 상태 모니터링 (내부용)
│
├── pipeline/
│   ├── ocr_pipeline.py        # OCR 파이프라인 (Clova → Google Lens 폴백)
│   ├── translation_pipeline.py # 번역 파이프라인 (DeepL → Groq 폴백)
│   ├── inpaint_pipeline.py    # 인페인팅 (OpenCV → Simple-LAMA)
│   ├── speaker_matcher.py     # 화자 매칭 AI
│   ├── context_builder.py     # 번역 프롬프트 컨텍스트 생성
│   └── review_pipeline.py     # AI 검수 파이프라인
│
├── services/
│   ├── key_rotator.py         # API Key 로테이션 매니저 ⭐ 핵심
│   ├── clova_ocr.py           # Clova OCR 클라이언트
│   ├── google_lens.py         # Google Lens OCR 클라이언트 (폴백)
│   ├── deepl_client.py        # DeepL 번역 클라이언트
│   └── groq_client.py         # Groq LLM 클라이언트 (번역 폴백 + 검수)
│
├── models/                    # SQLAlchemy ORM 모델
│   ├── user.py
│   ├── project.py
│   ├── episode.py             # 회차 (컨텍스트 포함)
│   ├── character.py           # 캐릭터 프로필
│   ├── page.py
│   ├── bubble.py              # 말풍선 (OCR 결과 + 화자 + 좌표)
│   ├── translation.py         # 번역 결과 + 후보 목록
│   ├── review_suggestion.py   # AI 검수 제안
│   └── job.py                 # 비동기 작업 상태
│
└── utils/
    ├── image_utils.py         # 이미지 처리 공통 함수
    ├── pdf_utils.py           # PDF → 이미지 변환
    └── font_utils.py          # 폰트 크기 자동 계산, 렌더링
```

---

## API 엔드포인트 명세

### 인증
```
POST   /auth/register           회원가입
POST   /auth/login              로그인 (JWT 발급)
POST   /auth/refresh            토큰 갱신
GET    /auth/me                 현재 로그인 유저 정보
```

### 프로젝트 & 캐릭터 관리
```
POST   /projects                프로젝트 생성
                                Body: { title, genre, source_lang, target_lang,
                                        synopsis, characters: [{name, description, speech_style, speech_examples}] }
GET    /projects                내 프로젝트 목록
GET    /projects/{id}           프로젝트 상세 (캐릭터 목록 포함)
PATCH  /projects/{id}           프로젝트 수정 (줄거리, 캐릭터 추가/수정)
DELETE /projects/{id}           프로젝트 삭제

POST   /projects/{id}/characters           캐릭터 추가
PATCH  /projects/{id}/characters/{char_id} 캐릭터 수정
DELETE /projects/{id}/characters/{char_id} 캐릭터 삭제
```

### 회차(Episode) 관리
```
POST   /projects/{id}/episodes             회차 생성
                                           Body: { number, title, synopsis,
                                                   character_situations: [{ character_id, situation }] }
GET    /projects/{id}/episodes             회차 목록
GET    /projects/{id}/episodes/{ep_id}     회차 상세
PATCH  /projects/{id}/episodes/{ep_id}     회차 컨텍스트 수정
```

### 파일 업로드 & 페이지 관리
```
POST   /episodes/{ep_id}/pages/upload      이미지/PDF 업로드 (멀티파일)
GET    /episodes/{ep_id}/pages             페이지 목록 (썸네일 포함)
DELETE /episodes/{ep_id}/pages/{page_id}  페이지 삭제
```

### OCR & 라벨링 (비동기 Job 방식)
```
POST   /episodes/{ep_id}/jobs/ocr              OCR 작업 시작 → job_id 반환
GET    /jobs/{job_id}/status                   작업 상태 폴링 (pending/processing/done/failed + progress %)
GET    /pages/{page_id}/bubbles                말풍선 목록 (OCR 결과, 번호 포함)
PATCH  /bubbles/{bubble_id}                    말풍선 수동 수정 (박스 좌표, 텍스트, 분류)
DELETE /bubbles/{bubble_id}                    말풍선 삭제 (오감지 제거)
POST   /pages/{page_id}/bubbles               말풍선 수동 추가 (미감지 영역)

POST   /episodes/{ep_id}/jobs/speaker-match   화자 매칭 실행
PATCH  /bubbles/{bubble_id}/speaker           화자 수동 수정
POST   /episodes/{ep_id}/speaker-match/confirm-all  화자 전체 승인
```

### 번역 — 핵심: 후보 복수 반환 + Survey형 선택
```
POST   /episodes/{ep_id}/jobs/translate        번역 작업 시작
                                               → 말풍선별 후보 3~4개 생성
GET    /jobs/{job_id}/status                   진행 상태 (페이지 단위 progress %)

# 번역 후보 조회
GET    /bubbles/{bubble_id}/candidates
       Response: {
         "bubble_id": "uuid",
         "original_text": "なんだよ、それ！",
         "speaker": "주인공",
         "candidates": [
           {"rank": 1, "text": "뭐야, 그게!", "rationale": "가장 자연스러운 구어체"},
           {"rank": 2, "text": "그게 무슨 소리야!", "rationale": "감정·당혹감 강조"},
           {"rank": 3, "text": "말도 안 돼!", "rationale": "의역, 감탄 강조"}
         ],
         "selected_rank": null,
         "custom_text": null
       }

# 번역가가 최종 선택 or 직접 입력 (Survey 확정)
PATCH  /bubbles/{bubble_id}/translation
       Body (후보 선택): { "selected_candidate_rank": 2, "custom_text": null }
       Body (직접 입력): { "selected_candidate_rank": null, "custom_text": "번역가가 직접 쓴 번역" }

# 번역 후보 재생성 (추가 컨텍스트 주입 후 다시 생성)
POST   /bubbles/{bubble_id}/candidates/regenerate
       Body: { "additional_context": "이 장면은 슬픈 이별 장면입니다" }

# 에피소드 전체 번역 현황
GET    /episodes/{ep_id}/translation-status
       Response: { "total": 120, "selected": 87, "pending": 33, "progress_pct": 72 }
```

### AI 검수
```
POST   /episodes/{ep_id}/jobs/ai-review       AI 검수 실행
GET    /episodes/{ep_id}/review-suggestions   검수 제안 목록
PATCH  /review-suggestions/{id}/accept        제안 수락 (번역문 교체)
PATCH  /review-suggestions/{id}/reject        제안 거절 (현재 번역 유지)
```

### 최종 출력
```
POST   /episodes/{ep_id}/jobs/render           최종 이미지 렌더링 (인페인팅 + 번역 텍스트 합성)
GET    /episodes/{ep_id}/export                완성 파일 다운로드 (zip / PDF)
GET    /episodes/{ep_id}/preview/{page_id}     번역 오버레이 미리보기 이미지 반환
```

### 관리자 (내부용 — 관리자 계정 전용)
```
GET    /admin/api-status                         API Key 사용 현황 (Key 로테이터 상태)

# 사용량 대시보드
GET    /admin/usage/summary                      전체 사용량 요약 (오늘 / 이번 달 / 누적)
GET    /admin/usage/by-user                      유저별 사용량 집계
                                                 Query: ?from=YYYY-MM-DD&to=YYYY-MM-DD
GET    /admin/usage/by-user/{user_id}            특정 유저 사용 이력 (날짜·시간별)
GET    /admin/usage/timeseries                   시계열 사용량 (일별/시간별)
                                                 Query: ?granularity=day|hour&from=...&to=...
GET    /admin/usage/quota-warnings               쿼터 임박 경고 목록 (80% 이상 소진)
```

---

## 핵심: Job 비동기 처리 패턴

```python
# routers/ocr.py

from fastapi import APIRouter, BackgroundTasks, Depends
from sqlalchemy.orm import Session
from database import get_db
from services.key_rotator import KeyRotator, QuotaExceededError
from pipeline.ocr_pipeline import OCRPipeline
import uuid

router = APIRouter()
job_store = {}  # MVP: 인메모리 / 이후: Redis 또는 Job 테이블

@router.post("/episodes/{episode_id}/jobs/ocr")
async def start_ocr(episode_id: int, background_tasks: BackgroundTasks, db: Session = Depends(get_db)):
    job_id = str(uuid.uuid4())
    job_store[job_id] = {"status": "pending", "progress": 0, "episode_id": episode_id}
    background_tasks.add_task(run_ocr_job, job_id, episode_id, db)
    return {"job_id": job_id}

@router.get("/jobs/{job_id}/status")
async def get_job_status(job_id: str):
    return job_store.get(job_id, {"status": "not_found"})

async def run_ocr_job(job_id: str, episode_id: int, db: Session):
    try:
        job_store[job_id]["status"] = "processing"
        pages = get_episode_pages(episode_id, db)

        for i, page in enumerate(pages):
            await OCRPipeline.process_page(page)
            job_store[job_id]["progress"] = int((i + 1) / len(pages) * 100)

        job_store[job_id]["status"] = "done"
    except Exception as e:
        job_store[job_id] = {"status": "failed", "error": str(e)}
```

---

## 번역 컨텍스트 프롬프트 설계 (핵심)

**단일 번역 반환(Reader용)이 아닌 복수 후보 반환(Translator용).**
컨텍스트를 풍부하게 주입할수록 후보 품질이 높아진다.

```python
# pipeline/context_builder.py

def build_candidate_prompt(project, episode, bubble, character):
    """
    번역 후보 3~4개 생성 프롬프트.
    각 후보는 뉘앙스가 달라야 함 (직역 / 구어체 / 감정강조 / 의역).
    """
    return f"""당신은 웹툰 전문 번역 어시스턴트입니다.
번역가가 최종 번역을 선택하거나 참고할 수 있도록,
아래 컨텍스트를 반영한 번역 후보를 3~4개 제시하세요.

━━━━━━━━━━━━━━━━━━━━━━
[작품 전체 컨텍스트]
제목: {project.title}
장르: {project.genre}
전체 줄거리: {project.synopsis}

[이번 회차 컨텍스트]
회차: {episode.number}화 — {episode.title}
이번 회차 줄거리: {episode.synopsis}
이번 회차에서 이 캐릭터의 상황: {episode.get_character_situation(character.name)}

[화자 캐릭터 프로필]
이름: {character.name}
성격: {character.description}
말투 스타일: {character.speech_style}
말투 예시: {character.speech_examples}

{context_builder.build_past_speech_block(character)}

[번역할 원문]
"{bubble.original_text}"
━━━━━━━━━━━━━━━━━━━━━━

위 원문을 {project.target_lang}로 번역한 후보를 3~4개 제시하세요.
각 후보는 뉘앙스나 어감이 서로 달라야 합니다.
(예: 직역, 자연스러운 구어체, 감정 강조, 의역 등)

반드시 아래 JSON 형식으로만 응답하세요:
{{
  "candidates": [
    {{"rank": 1, "text": "번역문", "rationale": "이 후보를 선택하는 이유 한 줄"}},
    {{"rank": 2, "text": "번역문", "rationale": "이 후보를 선택하는 이유 한 줄"}},
    {{"rank": 3, "text": "번역문", "rationale": "이 후보를 선택하는 이유 한 줄"}}
  ]
}}"""


def build_past_speech_block(character, limit: int = 5) -> str:
    """
    이전 회차에서 이 캐릭터가 사용한 번역 샘플 최대 5개를 블록으로 구성.
    번역가가 수정한 버전을 우선 포함 (is_edited=True 우선).
    번역가가 직접 수정한 말투를 일관성 참고용으로 AI에 주입.
    """
    past_lines = character.get_past_speech_samples(limit=limit)
    if not past_lines:
        return ""

    lines = "\n".join(
        f'  원문: {s["original"]} → 번역: {s["translated"]}'
        f'  (EP.{s["episode_number"]} / {"번역가 수정" if s["is_edited"] else "AI 원안"})'
        for s in past_lines
    )
    return f"""[이 캐릭터의 이전 회차 번역 샘플] ← 말투 일관성 참고 (번역가 최종 확정본)
{lines}
"""
```

---

## CORS 및 보안 설정

```python
# main.py

import os
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

app = FastAPI(title="AI translate API")

ENVIRONMENT = os.getenv("ENVIRONMENT", "development")

if ENVIRONMENT == "production":
    origins = [
        "https://ailosy.vercel.app",
        "https://ailosy.com",  # 커스텀 도메인 확정 후 변경
    ]
else:
    origins = ["*"]

app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,
    allow_credentials=True,
    allow_methods=["GET", "POST", "PATCH", "DELETE"],
    allow_headers=["Authorization", "Content-Type"],
)
```

---

## 환경변수 (.env)

```env
# 환경
ENVIRONMENT=development

# DB
DATABASE_URL=sqlite:///./ailosy.db
# 프로덕션: DATABASE_URL=postgresql://user:pass@localhost/ailosy

# JWT
SECRET_KEY=your-secret-key-here
ACCESS_TOKEN_EXPIRE_MINUTES=60

# Clova OCR Keys (로테이션, 쉼표 구분)
CLOVA_KEYS=key1,key2,key3
CLOVA_URLS=https://...ntruss.com/custom/v1/.../general,https://...,https://...

# DeepL Keys (로테이션)
DEEPL_KEYS=key1,key2,key3

# Groq Keys (번역 폴백 + AI검수 + 화자매칭)
GROQ_KEYS=key1,key2,key3,key4,key5

# Google Lens (OCR 폴백)
GOOGLE_LENS_ENABLED=true

# 파일 저장 경로
UPLOAD_DIR=/data/uploads
OUTPUT_DIR=/data/outputs
```