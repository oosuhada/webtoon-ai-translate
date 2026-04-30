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
