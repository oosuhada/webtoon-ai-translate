# 웹툰 자동 번역 웹툴 프로젝트 플래닝

> **목표**: 웹툰 이미지/PDF를 업로드하면 OCR → 화자 매칭 → 컨텍스트 기반 AI 번역 → 편집기 검수 → 완성본 출력까지 원스톱으로 처리하는 **프로 번역가용** 상용화 수준 웹 서비스

---

## 🎯 핵심 철학: "Reader용 번역기"가 아닌 "Translator용 번역 어시스턴트"

### 기존 번역 도구와의 차이

| 구분 | 기존 Reader용 번역 | AI translate (Translator용) |
|------|------------------|----------------------|
| 사용자 | 독자 (번역 결과 소비) | 프로 번역가 (번역 결과 생산) |
| 번역 요청 | `"안녕하세요"` → `"Hello"` 단일 반환 | 컨텍스트 주입 → 복수 후보 반환 |
| 반환 형식 | 결정된 번역문 1개 | `"Hello" / "Hi" / "How do you do?"` + 직접 입력 |
| 컨텍스트 | 없음 | 작품 줄거리 + 회차 줄거리 + 캐릭터 어투/상황 |
| 사후 편집 | 불가 | 번역가가 최종 결정권 보유 |
| 일관성 관리 | 없음 | 캐릭터별 어투 일관성 AI 검수 |
| 라벨링 | 없음 | 말풍선 자동 감지 + 번호 라벨링 + 화자 매칭 |

### 번역 후보 반환 UX (Survey형 선택)

이 프로젝트의 핵심 UX는 **설문조사처럼 번역 후보를 선택**하는 방식이다.
1번~3번 후보를 클릭해서 바로 선택하거나, "직접 입력"으로 번역가가 자유롭게 쓴다.

```
원문: "なんだよ、それ！"   [주인공 / 분노 상황 / 패배 직후]

AI 번역 후보:
  ① 뭐야, 그게!          ← 가장 자연스러운 구어체
  ② 그게 무슨 소리야!     ← 감정·당혹감 강조
  ③ 말도 안 돼!          ← 의역, 감탄 강조
  ④ 직접 입력: [__________________________]

                        [이 번역 확정 →]
```

---

## 📁 플래닝 파일 구성

| 파일 | 내용 |
|------|------|
| `00_PROJECT_OVERVIEW.md` | 전체 아키텍처, 기술 스택, 사용자 플로우 (이 파일) |
| `01_BACKEND_ARCHITECTURE.md` | FastAPI 백엔드 상세 설계, API 명세 |
| `02_FRONTEND_ARCHITECTURE.md` | Next.js 프론트엔드, Fabric.js 편집기 설계 |
| `03_AI_PIPELINE.md` | OCR → 화자매칭 → 번역 → 검수 파이프라인 |
| `04_API_KEY_STRATEGY.md` | 무료 API Key 로테이션 전략 및 백업 플랜 |
| `05_DATABASE_SCHEMA.md` | DB 스키마 및 작업 상태 관리 |
| `06_DEPLOYMENT.md` | M1 맥미니 백엔드 + Vercel 프론트엔드 배포 설정 |
| `07_CODEX_TASKS.md` | Codex 작업 지시서 (단계별 구현 태스크) |

---

## 🏗️ 전체 시스템 아키텍처

```
[클라이언트 브라우저]
        │
        ▼
[Vercel - Next.js 프론트엔드]
  - 인증 (NextAuth.js + JWT)
  - 번역 편집기 (Fabric.js)
  - 테이블 뷰 / 이미지 뷰 전환
        │  HTTPS API 호출
        ▼
[M1 맥미니 - FastAPI 백엔드]  ←── Cloudflare Tunnel (고정 도메인, 무료)
   ├── OCR 모듈
   │     Primary:  Clova General OCR (여러 네이버 아이디 로테이션)
   │     Fallback: Google Lens OCR (비공식 API, 비상용)
   ├── 번역 모듈
   │     Primary:  DeepL Free (여러 아이디 로테이션, 월 500,000자/계정)
   │     Fallback: Groq LLM (llama-3.3-70b-versatile, 무료, Rate limit만 존재)
   ├── 화자 매칭 모듈 (Groq LLM + OpenCV 말풍선 꼬리 분석)
   ├── AI 검수 모듈 (Groq LLM)
   ├── 인페인팅 모듈
   │     Primary:  OpenCV TELEA (빠름, CPU)
   │     High-Q:   Simple-LAMA (느림, M1 Metal 가속)
   ├── API Key 로테이터 (KeyRotator)
   └── PostgreSQL (Docker, 작업 상태 관리)
```

---

## ⚙️ 기술 스택 최종 결정

### 백엔드: **FastAPI (Python)**

**선정 이유:**
- AI/ML 라이브러리 (OpenCV, numpy, PIL) 생태계가 Python에 집중
- 레퍼런스 (Toonslator, TextPhantom) 모두 FastAPI 기반 → 코드 재사용 최대화
- Spring Boot는 JVM 오버헤드 + AI 파이프라인 연동 복잡
- NestJS는 Python AI 파이프라인 연동 시 별도 프로세스 필요
- M1 맥미니에서 uvicorn 가볍게 동작

**포기한 대안:**
- Spring Boot: JPA/Security 강점이나 이 프로젝트 핵심인 AI 파이프라인에서 불리
- NestJS: TypeScript 타입 안전성 좋지만 AI 파이프라인 오버헤드 발생

### 프론트엔드: **Next.js 14 (App Router)**

**선정 이유:**
- Vercel 공식 지원 (자동 빌드/배포)
- SSR/SSG 초기 로딩 최적화
- React + Fabric.js 코드 그대로 이식
- NextAuth.js 인증 통합

### 데이터베이스: **PostgreSQL + SQLite (개발용)**

- 개발: SQLite (설정 불필요, 즉시 시작)
- 프로덕션: PostgreSQL (Docker on M1 맥미니)

### 작업 큐: **FastAPI BackgroundTasks → Celery 확장 예정**

- MVP: FastAPI 내장 BackgroundTasks
- 이후: Celery + Redis (대용량 이미지 처리 큐잉)

---

## 🔄 핵심 사용자 플로우 (7단계)

```
Step 1. 로그인
         │
Step 2. 프로젝트 생성 (번역 컨텍스트 등록)
         ├── 작품 제목, 장르, 원본/번역 언어
         ├── 작품 전체 줄거리 (시리즈 전반 흐름)
         ├── 캐릭터별 어투·성격 프로필
         │     예) 주인공: 반말, 직설적, 감탄사 많음
         │         라이벌: 격식체, 냉소적, 짧은 문장
         └── 회차별 줄거리 + 해당 회차 캐릭터 상황 입력
               예) "주인공이 라이벌에게 처음으로 패배한 직후 장면"
         │
Step 3. 파일 업로드 (이미지 or PDF) + 회차 컨텍스트 입력
         │
Step 4. 자동 라벨링 단계  ← "번역가가 라벨링을 직접 하던 작업을 자동화"
         ├── OCR 실행 → 말풍선·텍스트 영역 자동 감지 + 번호 라벨 자동 부착
         ├── 화자 매칭 AI → 각 말풍선에 캐릭터 라벨 부착
         └── 라벨링 검수 UI → 번역가가 확인·수정 (화자 변경, 텍스트 수정)
         │
Step 5. 컨텍스트 기반 AI 번역 후보 생성  ⭐ 핵심
         ├── 프롬프트에 주입:
         │     [작품 줄거리] + [회차 줄거리] + [캐릭터 어투] + [현재 상황]
         └── 말풍선별 번역 후보 3~4개 반환 (Survey 방식)
               ① "뭐야, 그게!"  ② "그게 무슨 소리야!"  ③ "말도 안 돼!"
               ④ 직접 입력: [________________]
         │
Step 6. 번역가 선택 & 편집
         ├── 테이블 뷰: 전체 대사 흐름 보며 후보 클릭 선택 or 직접 입력
         └── 이미지 뷰: 실제 말풍선 위치·맥락 보며 선택 (Fabric.js)
         │
Step 7. AI 일관성 검수 (AI 검수 버튼)
         └── 선택 완료된 번역 전체를 AI가 재검토
               → 캐릭터 어투 일관성, 오역, 어색한 표현 제안
               → 번역가가 제안 수락/거절
         │
Step 8. 최종 렌더링 & 출력
         └── 인페인팅 + 번역 텍스트 합성 → 이미지 위에 번역문 오버레이
               → 이미지/PDF 다운로드
               (최종 검수: 번역된 텍스트가 이미지 위에 덮어써진 상태로 읽으면서 맥락 확인)
```

---

## 📦 인페인팅 전략 (GPU 없는 M1 맥미니)

| 방식 | 속도 | 품질 | M1 호환 |
|------|------|------|---------|
| OpenCV inpaint (TELEA) | ⚡ 빠름 | ⭐⭐⭐ | ✅ |
| Simple-LAMA (CPU 모드) | 🐢 느림 | ⭐⭐⭐⭐⭐ | ✅ (느림) |
| IOPaint API (외부 서비스) | ⚡ 빠름 | ⭐⭐⭐⭐ | ✅ |

**전략**: 기본은 OpenCV TELEA (빠름), 사용자가 "고품질 모드" 선택 시 Simple-LAMA CPU 사용.

---

## 💰 비용 전략 (무료 플랜 최대 활용)

| 서비스 | 역할 | 무료 한도 | 복수 계정 전략 |
|--------|------|---------|--------------|
| Clova General OCR | OCR Primary | 계정당 월 1,000건 추정 | 네이버 계정 N개로 로테이션 |
| Google Lens OCR | OCR Fallback | 비공식, 불명확 | Clova 소진 시 비상용 |
| DeepL Free | 번역 Primary | 계정당 월 500,000자 | 계정 N개로 로테이션 |
| Groq Free | 번역 Fallback + AI검수 + 화자매칭 | Rate limit만 (일일한도 없음) | 계정 N개로 로테이션 |

**운영 원칙**: Primary 무료 플랜 Key 로테이션 → 전부 소진 시 Fallback 자동 전환