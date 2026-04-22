# 05 — 데이터베이스 스키마

## ERD 개요

```
User ──< Project ──< Episode ──< Page ──< Bubble ──< TranslationCandidate
   │                │                            │
   │                └──< Character               └──< ReviewSuggestion
   │                │         │
   │                │         └──< CharacterSpeechSample   ← 이전 회차 말투 히스토리
   │                │
   │                └──< EpisodeCharacterSituation
   │                │
   │                └──< Job
   │
   └──< APIUsageLog   ← 관리자 대시보드용 사용량 로그
```

---

## SQLAlchemy 모델

```python
# models/user.py
from sqlalchemy import Column, Integer, String, DateTime, Boolean
from sqlalchemy.orm import relationship
from database import Base
import datetime

class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    email = Column(String, unique=True, index=True, nullable=False)
    hashed_password = Column(String, nullable=False)
    name = Column(String, nullable=False)
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime, default=datetime.datetime.utcnow)

    projects = relationship("Project", back_populates="owner")
```

```python
# models/project.py
from sqlalchemy import Column, Integer, String, Text, DateTime, ForeignKey
from sqlalchemy.orm import relationship
from database import Base
import datetime

class Project(Base):
    __tablename__ = "projects"

    id = Column(Integer, primary_key=True, index=True)
    owner_id = Column(Integer, ForeignKey("users.id"), nullable=False)

    title = Column(String, nullable=False)        # 작품 제목
    genre = Column(String)                         # 장르
    synopsis = Column(Text)                        # 전체 줄거리 (번역 컨텍스트)
    source_lang = Column(String, default="JA")     # 원본 언어
    target_lang = Column(String, default="KO")     # 번역 언어

    created_at = Column(DateTime, default=datetime.datetime.utcnow)
    updated_at = Column(DateTime, onupdate=datetime.datetime.utcnow)

    owner = relationship("User", back_populates="projects")
    episodes = relationship("Episode", back_populates="project", order_by="Episode.number")
    characters = relationship("Character", back_populates="project")


class Character(Base):
    __tablename__ = "characters"

    id = Column(Integer, primary_key=True)
    project_id = Column(Integer, ForeignKey("projects.id"), nullable=False)

    name = Column(String, nullable=False)          # 캐릭터 이름
    description = Column(Text)                     # 성격 설명
    speech_style = Column(String)                  # 말투 스타일 (반말/격식체 등)
    speech_examples = Column(Text)                 # 말투 예시 문장

    project = relationship("Project", back_populates="characters")
    episode_situations = relationship("EpisodeCharacterSituation", back_populates="character")
    speech_samples = relationship(
        "CharacterSpeechSample",
        back_populates="character",
        order_by="desc(CharacterSpeechSample.created_at)"
    )

    def get_past_speech_samples(self, limit: int = 5) -> list[dict]:
        """
        이전 회차에서 이 캐릭터의 번역 확정본 샘플 반환.
        번역가가 직접 수정한 항목(is_edited=True)을 우선 정렬.
        AI 프롬프트 컨텍스트 주입에 사용.
        """
        sorted_samples = sorted(
            self.speech_samples,
            key=lambda s: (not s.is_edited, -s.episode_number)
        )
        return [
            {
                "original": s.original_text,
                "translated": s.translated_text,
                "episode_number": s.episode_number,
                "is_edited": s.is_edited,
            }
            for s in sorted_samples[:limit]
        ]


class CharacterSpeechSample(Base):
    """
    캐릭터별 이전 회차 번역 히스토리.
    번역가가 최종 확정한 번역문을 저장 → 다음 회차 AI 프롬프트 컨텍스트로 주입.
    번역가가 후보를 선택하거나 직접 입력할 때 자동으로 적재됨.
    """
    __tablename__ = "character_speech_samples"

    id = Column(Integer, primary_key=True)
    character_id = Column(Integer, ForeignKey("characters.id"), nullable=False)
    episode_number = Column(Integer, nullable=False)    # 어느 회차에서 나온 대사인지

    original_text = Column(Text, nullable=False)        # 원문
    translated_text = Column(Text, nullable=False)      # 번역가 최종 확정 번역문
    is_edited = Column(Boolean, default=False)
    # True: 번역가가 AI 후보를 수정하거나 직접 입력한 것
    # False: AI 후보 그대로 선택

    created_at = Column(DateTime, default=datetime.datetime.utcnow)

    character = relationship("Character", back_populates="speech_samples")
```

```python
# models/episode.py
class Episode(Base):
    __tablename__ = "episodes"

    id = Column(Integer, primary_key=True, index=True)
    project_id = Column(Integer, ForeignKey("projects.id"), nullable=False)

    number = Column(Integer, nullable=False)       # 회차 번호
    title = Column(String)                         # 회차 제목
    synopsis = Column(Text)                        # 이번 회차 줄거리 (번역 컨텍스트)

    status = Column(String, default="created")
    # created → uploaded → ocr_done → labeled → translating → translated → reviewed → done

    created_at = Column(DateTime, default=datetime.datetime.utcnow)
    updated_at = Column(DateTime, onupdate=datetime.datetime.utcnow)

    project = relationship("Project", back_populates="episodes")
    pages = relationship("Page", back_populates="episode", order_by="Page.order")
    character_situations = relationship("EpisodeCharacterSituation", back_populates="episode")
    jobs = relationship("Job", back_populates="episode")

    def get_character_situation(self, character_name: str) -> str:
        """특정 캐릭터의 이번 회차 상황 반환"""
        for s in self.character_situations:
            if s.character.name == character_name:
                return s.situation
        return "미지정"


class EpisodeCharacterSituation(Base):
    """회차별 캐릭터 상황 (번역 컨텍스트 주입용)"""
    __tablename__ = "episode_character_situations"

    id = Column(Integer, primary_key=True)
    episode_id = Column(Integer, ForeignKey("episodes.id"), nullable=False)
    character_id = Column(Integer, ForeignKey("characters.id"), nullable=False)
    situation = Column(Text, nullable=False)       # 예) "패배 직후, 분하고 자존심 상한 상태"

    episode = relationship("Episode", back_populates="character_situations")
    character = relationship("Character", back_populates="episode_situations")
```

```python
# models/page.py
class Page(Base):
    __tablename__ = "pages"

    id = Column(Integer, primary_key=True)
    episode_id = Column(Integer, ForeignKey("episodes.id"), nullable=False)

    order = Column(Integer, nullable=False)           # 페이지 순서
    original_filename = Column(String)
    image_path = Column(String)                       # 원본 이미지 경로
    rendered_path = Column(String)                    # 번역 합성 이미지 경로

    ocr_status = Column(String, default="pending")    # pending / done / failed

    episode = relationship("Episode", back_populates="pages")
    bubbles = relationship("Bubble", back_populates="page", order_by="Bubble.label_index")
```

```python
# models/bubble.py
import uuid

class Bubble(Base):
    __tablename__ = "bubbles"

    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    page_id = Column(Integer, ForeignKey("pages.id"), nullable=False)

    # 라벨링 번호 (읽기 순서 기반 자동 부여)
    label_index = Column(Integer, nullable=False)     # 1, 2, 3, ...

    # 위치 (픽셀 좌표)
    x1 = Column(Integer, nullable=False)
    y1 = Column(Integer, nullable=False)
    x2 = Column(Integer, nullable=False)
    y2 = Column(Integer, nullable=False)

    # OCR 결과
    original_text = Column(Text)
    ocr_confidence = Column(Float)

    # 화자 매칭
    speaker = Column(String)                          # 캐릭터 이름 / "효과음" / "나레이션" / "미확인"
    speaker_confidence = Column(Float)
    speaker_is_confirmed = Column(Boolean, default=False)  # 번역가가 확인/수정 완료

    # 분류
    bubble_type = Column(String, default="dialogue")  # dialogue / sfx / narration

    # 폰트
    font_family = Column(String, default="NanumGothic")
    font_size = Column(Integer)
    text_color = Column(String, default="#000000")

    page = relationship("Page", back_populates="bubbles")
    candidates = relationship("TranslationCandidate", back_populates="bubble",
                              order_by="TranslationCandidate.rank")
    review_suggestions = relationship("ReviewSuggestion", back_populates="bubble")

    @property
    def width(self):
        return self.x2 - self.x1

    @property
    def height(self):
        return self.y2 - self.y1

    @property
    def confirmed_translation(self):
        """번역가가 최종 확정한 번역문"""
        for c in self.candidates:
            if c.is_selected:
                return c.custom_text if c.custom_text else c.text
        return None


class TranslationCandidate(Base):
    """번역 후보 (Survey형 선택의 각 옵션)"""
    __tablename__ = "translation_candidates"

    id = Column(Integer, primary_key=True)
    bubble_id = Column(String, ForeignKey("bubbles.id"), nullable=False)

    rank = Column(Integer, nullable=False)            # 1, 2, 3 (후보 순위)
    text = Column(Text, nullable=False)               # AI가 생성한 번역 후보
    rationale = Column(Text)                          # 이 후보를 선택하는 이유
    translation_engine = Column(String)               # deepl / groq

    is_selected = Column(Boolean, default=False)      # 번역가가 선택했는지
    custom_text = Column(Text)                        # ④ 직접 입력한 경우 (rank=0)

    created_at = Column(DateTime, default=datetime.datetime.utcnow)
    updated_at = Column(DateTime, onupdate=datetime.datetime.utcnow)

    bubble = relationship("Bubble", back_populates="candidates")
```

```python
# models/review_suggestion.py
class ReviewSuggestion(Base):
    __tablename__ = "review_suggestions"

    id = Column(Integer, primary_key=True)
    bubble_id = Column(String, ForeignKey("bubbles.id"))

    issue_type = Column(String)                       # consistency / mistranslation / unnatural / sfx
    original_translation = Column(Text)               # 검수 당시의 번역문
    suggested_translation = Column(Text)              # AI 제안 번역문
    reason = Column(Text)                             # 수정 이유

    status = Column(String, default="pending")        # pending / accepted / rejected

    created_at = Column(DateTime, default=datetime.datetime.utcnow)

    bubble = relationship("Bubble", back_populates="review_suggestions")
```

```python
# models/job.py
class Job(Base):
    __tablename__ = "jobs"

    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    episode_id = Column(Integer, ForeignKey("episodes.id"))

    job_type = Column(String)
    # ocr / speaker_match / translate / ai_review / render

    status = Column(String, default="pending")
    # pending / processing / done / failed

    progress = Column(Integer, default=0)             # 0~100
    error_message = Column(Text)

    started_at = Column(DateTime)
    completed_at = Column(DateTime)
    created_at = Column(DateTime, default=datetime.datetime.utcnow)

    episode = relationship("Episode", back_populates="jobs")
```

---

## 마이그레이션

```bash
pip install alembic
alembic init alembic
alembic revision --autogenerate -m "initial schema"
alembic upgrade head
```

```python
# models/api_usage_log.py

class APIUsageLog(Base):
    """
    관리자 대시보드용 API 사용량 로그.
    OCR / 번역 / AI 검수 / 화자 매칭 요청 시 자동으로 기록.
    유저별 · 날짜별 · 서비스별로 집계 가능.
    """
    __tablename__ = "api_usage_logs"

    id = Column(Integer, primary_key=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    episode_id = Column(Integer, ForeignKey("episodes.id"), nullable=True)

    # 어떤 서비스를 사용했는지
    service = Column(String, nullable=False)
    # clova_ocr / google_lens / deepl / groq_translate / groq_review / groq_speaker

    # 사용량 수치
    request_count = Column(Integer, default=1)       # 요청 횟수
    char_count = Column(Integer, default=0)          # 문자 수 (번역 서비스)
    token_count = Column(Integer, default=0)         # 토큰 수 (LLM 서비스)

    # 결과
    status = Column(String, default="success")       # success / failed / quota_exceeded
    used_key_suffix = Column(String)                 # 어느 Key가 사용됐는지 (끝 4자리)

    created_at = Column(DateTime, default=datetime.datetime.utcnow, index=True)

    user = relationship("User")
```

---

## 관리자 대시보드 집계 쿼리 예시

```python
# routers/admin.py (사용량 대시보드)

from sqlalchemy import func

@router.get("/admin/usage/summary")
async def usage_summary(db: Session = Depends(get_db), _=Depends(get_admin_user)):
    today = datetime.date.today()
    month_start = today.replace(day=1)

    def _query(from_dt):
        return db.query(
            APIUsageLog.service,
            func.count(APIUsageLog.id).label("requests"),
            func.sum(APIUsageLog.char_count).label("chars"),
            func.sum(APIUsageLog.token_count).label("tokens"),
        ).filter(APIUsageLog.created_at >= from_dt).group_by(APIUsageLog.service).all()

    return {
        "today": _query(today),
        "this_month": _query(month_start),
    }


@router.get("/admin/usage/by-user")
async def usage_by_user(
    from_date: str = None,
    to_date: str = None,
    db: Session = Depends(get_db),
    _=Depends(get_admin_user)
):
    """
    유저별 사용량 집계.
    Response: [{ user_id, user_email, service, requests, chars, tokens }]
    프론트엔드에서 Bar 차트로 렌더링.
    """
    q = db.query(
        APIUsageLog.user_id,
        User.email.label("user_email"),
        APIUsageLog.service,
        func.count(APIUsageLog.id).label("requests"),
        func.sum(APIUsageLog.char_count).label("chars"),
        func.sum(APIUsageLog.token_count).label("tokens"),
    ).join(User, User.id == APIUsageLog.user_id)

    if from_date:
        q = q.filter(APIUsageLog.created_at >= from_date)
    if to_date:
        q = q.filter(APIUsageLog.created_at <= to_date)

    return q.group_by(APIUsageLog.user_id, User.email, APIUsageLog.service).all()


@router.get("/admin/usage/timeseries")
async def usage_timeseries(
    granularity: str = "day",   # "day" | "hour"
    from_date: str = None,
    to_date: str = None,
    db: Session = Depends(get_db),
    _=Depends(get_admin_user)
):
    """
    시계열 사용량 (일별/시간별).
    Response: [{ period, service, requests }]
    프론트엔드에서 Line 또는 Bar 차트로 렌더링.
    """
    trunc_fn = func.date_trunc(granularity, APIUsageLog.created_at)
    q = db.query(
        trunc_fn.label("period"),
        APIUsageLog.service,
        func.count(APIUsageLog.id).label("requests"),
    )
    if from_date:
        q = q.filter(APIUsageLog.created_at >= from_date)
    if to_date:
        q = q.filter(APIUsageLog.created_at <= to_date)
    return q.group_by("period", APIUsageLog.service).order_by("period").all()


@router.get("/admin/usage/quota-warnings")
async def quota_warnings(_=Depends(get_admin_user)):
    """
    쿼터 80% 이상 소진된 Key 목록 반환.
    프론트 대시보드에서 경고 배너 표시 + 유료 플랜 업그레이드 안내에 활용.
    """
    warnings = []
    for rotator in [clova_rotator, deepl_rotator, groq_rotator]:
        for key in rotator._keys:
            if not key.is_active:
                warnings.append({
                    "service": rotator.service_name,
                    "key_suffix": f"...{key.key[-4:]}",
                    "status": "quota_exceeded",
                    "reset_at": key.quota_reset_at,
                    "upgrade_recommended": True,
                })
    return {"warnings": warnings, "count": len(warnings)}
```

---

```python
# database.py
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, declarative_base
import os

DATABASE_URL = os.getenv("DATABASE_URL", "sqlite:///./ailosy.db")

engine = create_engine(
    DATABASE_URL,
    connect_args={"check_same_thread": False} if "sqlite" in DATABASE_URL else {}
)

SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
```