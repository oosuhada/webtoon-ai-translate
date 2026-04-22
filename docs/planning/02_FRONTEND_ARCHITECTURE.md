# 02 — 프론트엔드 아키텍처 상세 설계

## 기술 스택

| 항목 | 선택 | 이유 |
|------|------|------|
| 프레임워크 | **Next.js 14** (App Router) | Vercel 공식 지원, SSR, 인증 통합 |
| 상태관리 | **Zustand** | Redux보다 가볍고 충분함 |
| 캔버스 편집기 | **Fabric.js** | Toonslator 레퍼런스 이식 가능, 텍스트 클릭 편집 지원 |
| UI 컴포넌트 | **shadcn/ui + Tailwind CSS** | 빠른 개발, 커스터마이징 용이 |
| 인증 | **NextAuth.js** | JWT + 세션 관리 통합 |
| HTTP 클라이언트 | **Axios + TanStack Query** | 캐싱, 폴링, 에러 핸들링 |
| 파일 업로드 | **react-dropzone** | 드래그앤드롭 지원 |

---

## 디렉토리 구조

```
frontend/
├── app/                              # Next.js App Router
│   ├── layout.tsx                    # 루트 레이아웃
│   ├── page.tsx                      # 랜딩 페이지
│   ├── (auth)/
│   │   ├── login/page.tsx
│   │   └── register/page.tsx
│   ├── dashboard/
│   │   └── page.tsx                  # 프로젝트 목록
│   └── projects/
│       └── [projectId]/
│           ├── page.tsx              # 프로젝트 개요 (회차 목록)
│           ├── episodes/
│           │   └── [episodeId]/
│           │       ├── upload/page.tsx       # 파일 업로드 + 회차 컨텍스트 입력
│           │       ├── labeling/page.tsx     # OCR 결과 확인 + 화자 매칭 검수
│           │       ├── translation/page.tsx  # 번역 편집기 (테이블 뷰 / 이미지 뷰)
│           │       ├── review/page.tsx       # AI 검수 제안 처리
│           │       └── export/page.tsx       # 최종 미리보기 + 다운로드
│
├── components/
│   ├── editor/
│   │   ├── FabricCanvas.tsx          # Fabric.js 캔버스 래퍼 (이미지 뷰)
│   │   ├── BubbleOverlay.tsx         # 말풍선 번호 + 번역 텍스트 오버레이
│   │   └── TranslationPanel.tsx      # 우측 번역 후보 선택 패널
│   ├── labeling/
│   │   ├── LabelingCanvas.tsx        # 라벨링용 캔버스 (말풍선 번호 표시)
│   │   ├── SpeakerPanel.tsx          # 화자 매칭 패널
│   │   └── BubbleList.tsx            # 말풍선 목록 사이드바
│   ├── translation/
│   │   ├── TranslationTable.tsx      # 테이블 뷰 (원문 + 후보 선택)
│   │   ├── CandidateSelector.tsx     # Survey형 번역 후보 선택 컴포넌트 ⭐
│   │   ├── AIReviewPanel.tsx         # AI 검수 제안 패널
│   │   └── ContextEditor.tsx         # 작품/회차 컨텍스트 편집
│   └── common/
│       ├── JobProgressBar.tsx        # 작업 진행률 표시
│       ├── FileUploader.tsx          # 파일 업로드 존 (dropzone)
│       └── PageNavigator.tsx         # 페이지 네비게이터
│
├── hooks/
│   ├── useJobPolling.ts              # Job 상태 폴링 훅
│   ├── useFabricCanvas.ts            # Fabric.js 초기화/관리
│   ├── useTranslation.ts             # 번역 상태 관리
│   └── useBubbles.ts                 # 말풍선 데이터 관리
│
├── store/
│   ├── projectStore.ts               # 프로젝트/에피소드 전역 상태
│   └── editorStore.ts                # 편집기 상태 (선택된 버블, 뷰 모드 등)
│
└── lib/
    ├── api.ts                        # Axios 인스턴스 + 인터셉터
    ├── types.ts                      # 공통 타입 정의
    └── utils.ts                      # 공통 유틸
```

---

## 핵심 화면별 상세 설계

### 화면 1: 프로젝트 생성 (번역 컨텍스트 등록)

```
┌─────────────────────────────────────────────────────────┐
│  새 프로젝트 만들기                                       │
├─────────────────────────────────────────────────────────┤
│  작품 제목   [                                         ] │
│  원본 언어   [일본어 ▼]  번역 언어 [한국어 ▼]            │
│  장르        [판타지 ▼]                                   │
│                                                         │
│  ── 작품 전체 줄거리 ──────────────────────────────────  │
│  (시리즈 전반의 세계관·갈등 구조를 입력하세요)            │
│  ┌─────────────────────────────────────────────────┐   │
│  │ 이세계로 전이된 평범한 고등학생 주인공이 ...       │   │
│  └─────────────────────────────────────────────────┘   │
│                                                         │
│  ── 등장 캐릭터 프로필 ─────────────────────────────── │
│  ┌──────────┬──────────────┬──────────────────────┬──┐ │
│  │ 이름      │ 성격         │ 말투 스타일           │  │ │
│  ├──────────┼──────────────┼──────────────────────┼──┤ │
│  │ 주인공    │ 활발, 직설적 │ 반말, 감탄사 많음     │🗑│ │
│  │          │              │ 예) "뭐야!", "진짜?"   │  │ │
│  ├──────────┼──────────────┼──────────────────────┼──┤ │
│  │ 라이벌    │ 냉정, 냉소적 │ 격식체, 짧고 날카롭게 │🗑│ │
│  │          │              │ 예) "그렇군.", "됐어." │  │ │
│  └──────────┴──────────────┴──────────────────────┴──┘ │
│                              [캐릭터 추가 +]            │
│                                                         │
│              [프로젝트 생성하기 →]                      │
└─────────────────────────────────────────────────────────┘
```

---

### 화면 2: 회차 업로드 + 회차별 컨텍스트 입력

```
┌─────────────────────────────────────────────────────────┐
│  파일 업로드 — 23화                                      │
├─────────────────────────────────────────────────────────┤
│  ── 파일 업로드 ──────────────────────────────────────── │
│  ┌─────────────────────────────────────────────────┐   │
│  │  📄 이미지(jpg/png) 또는 PDF를 여기에 드롭하세요  │   │
│  │      또는 [파일 선택]                             │   │
│  └─────────────────────────────────────────────────┘   │
│  업로드된 파일: page01.jpg, page02.jpg ... (24개)       │
│                                                         │
│  ── 이번 회차 컨텍스트 (번역 품질에 직접 영향) ─────── │
│                                                         │
│  회차 제목   [패배의 이유]                               │
│                                                         │
│  이번 회차 줄거리                                        │
│  ┌─────────────────────────────────────────────────┐   │
│  │ 주인공이 라이벌에게 처음으로 패배한 직후,         │   │
│  │ 자신의 무력함을 인정하고 훈련을 결심하는 장면.    │   │
│  └─────────────────────────────────────────────────┘   │
│                                                         │
│  캐릭터별 이번 회차 상황                                  │
│  ┌──────────┬────────────────────────────────────┐     │
│  │ 주인공    │ 패배 직후, 분하고 자존심 상한 상태  │     │
│  ├──────────┼────────────────────────────────────┤     │
│  │ 라이벌    │ 여유롭지만 내심 주인공을 인정하기 시작│    │
│  └──────────┴────────────────────────────────────┘     │
│                                                         │
│              [저장 & OCR 시작 →]                        │
└─────────────────────────────────────────────────────────┘
```

---

### 화면 3: 라벨링 검수 (OCR 결과 + 화자 매칭 확인)

번역가가 수동으로 하던 라벨링을 자동으로 처리하고 검수만 하도록 한다.
말풍선 번호는 이미지 위에 자동으로 표시된다.

```
┌──────────────────────────────────────────────────────────────┐
│  [← 뒤로]  23화 > 라벨링 검수   [OCR 재실행] [다음 단계 →]  │
├────────────────────────────┬─────────────────────────────────┤
│  페이지 네비게이터          │  말풍선 목록                     │
│  [1][2][3]...[24]          ├─────────────────────────────────┤
│  현재: 1페이지              │  ① [주인공] "なんだよ、それ！"   │
├────────────────────────────┤       ✏️ 텍스트 수정              │
│                            │       🔄 화자 변경 [주인공 ▼]    │
│   [웹툰 이미지]             │                                  │
│                            │  ② [라이벌] "知らないふりを..."  │
│   ┌──①──┐                 │       ✏️ 텍스트 수정              │
│   │ ①   │  ┌──②──┐       │       🔄 화자 변경 [라이벌 ▼]    │
│   └─────┘  │ ②   │       │                                  │
│            └─────┘        │  ③ ⚠️ [미확인] "..."             │
│     ┌──③──┐               │       화자를 지정해주세요          │
│     │ ③   │               │       🔄 화자 지정 [선택 ▼]       │
│     └─────┘               │                                  │
│                            │  ④ [효과음] "ドカン"             │
│  ← 말풍선 클릭 시           │       ✏️ 텍스트 수정              │
│    우측 해당 항목 하이라이트  │                                  │
│                            │  [전체 승인] [AI 화자 재매칭]    │
└────────────────────────────┴─────────────────────────────────┘
```

**라벨링 검수 UI 동작:**
- 이미지 위 번호(①②③)는 Fabric.js로 렌더링, 클릭 시 우측 패널 해당 항목 스크롤
- ⚠️ 미확인 화자가 있으면 "다음 단계" 버튼 비활성화 (또는 경고만 표시)
- "전체 승인" 클릭 시 현재 매칭된 화자 전부 confirmed 처리

---

### 화면 4: 번역 작업 편집기 ⭐ 핵심 화면

> **AI는 후보를 제안하고, 최종 결정은 번역가가 한다.**
> Survey형: ①②③ 중 클릭하거나, ④ 직접 입력

두 가지 뷰 모드를 탭으로 전환한다.

#### 모드 A: 테이블 뷰 (전체 대사 흐름 일괄 작업)

```
┌──────────────────────────────────────────────────────────────────────┐
│  [테이블 뷰 ●] [이미지 뷰 ○]         [AI 검수 실행] [최종 출력 →]   │
├───────┬────────┬───────────────────┬─────────────────────────────────┤
│ 위치   │ 화자   │ 원문              │ 번역 후보 선택                   │
├───────┼────────┼───────────────────┼─────────────────────────────────┤
│ 1-①  │ 주인공 │ なんだよ、それ！  │ ● ① 뭐야, 그게!                 │
│       │        │                   │       가장 자연스러운 구어체      │
│       │        │                   │   ② 그게 무슨 소리야!            │
│       │        │                   │   ③ 말도 안 돼!                  │
│       │        │                   │   ④ 직접 입력: [          ]  ✏️  │
├───────┼────────┼───────────────────┼─────────────────────────────────┤
│ 1-②  │ 라이벌 │ 知らないふりを... │   ① 모르는 척 마.               │
│       │        │                   │ ● ② 모른 체하지 마라.            │
│       │        │                   │   ③ 못 본 척은 그만해.           │
│       │        │                   │   ④ 직접 입력: [          ]  ✏️  │
├───────┼────────┼───────────────────┼─────────────────────────────────┤
│ 1-③  │ [효과음]│ ドカン            │ ● ① 쾅!                         │
│       │        │                   │   ② 쿵!                          │
│       │        │                   │   ③ 펑!                          │
│       │        │                   │   ④ 직접 입력: [          ]  ✏️  │
├───────┼────────┼───────────────────┼─────────────────────────────────┤
│ 2-①  │ 주인공 │ まずい...         │ ⚠️ 미선택                        │
│       │        │                   │   ① 이거 큰일났는데...            │
│       │        │                   │   ② 망했다...                    │
│       │        │                   │   ③ 이거 안 되겠는데.            │
│       │        │                   │   ④ 직접 입력: [          ]  ✏️  │
│       │        │                   │   [🔄 후보 재생성]               │
└───────┴────────┴───────────────────┴─────────────────────────────────┘
  전체 120개 중 87개 완료  ████████████░░░░ 72%    [⚠️ 미선택만 보기]
```

#### 모드 B: 이미지 뷰 (말풍선 위치·맥락 보며 작업)

```
┌──────────────────────────────────────────────────────────────────────┐
│  [테이블 뷰 ○] [이미지 뷰 ●]          [← 이전] 1 / 24 [다음 →]     │
├──────────────────────────┬───────────────────────────────────────────┤
│                          │  [선택된 말풍선 상세]  ①번               │
│  [웹툰 이미지]            │                                          │
│                          │  화자: 주인공  /  상황: 패배 직후 분노    │
│  ┌────────────┐          │                                          │
│  │ ①          │ ← 클릭  │  원문: "なんだよ、それ！"                 │
│  └────────────┘          │                                          │
│  ┌────────────┐          │  번역 후보:                              │
│  │ ②          │          │  ● ① 뭐야, 그게!                        │
│  └────────────┘          │       └ 가장 자연스러운 구어체            │
│  ③ 쾅!  (확정됨 ✅)      │    ② 그게 무슨 소리야!                   │
│                          │       └ 감정·당혹감 강조                 │
│  ← 이미지 위에           │    ③ 말도 안 돼!                        │
│    번역 확정된 말풍선은   │       └ 의역, 감탄 강조                  │
│    번역문이 오버레이됨    │    ④ 직접 입력:                         │
│    (최종 결과물 미리보기) │     [________________________]           │
│                          │                                          │
│                          │   [🔄 후보 재생성]  [이 번역 확정 →]    │
└──────────────────────────┴───────────────────────────────────────────┘
```

**이미지 뷰 동작:**
- 말풍선 번호(①②③)는 Fabric.js로 렌더링
- 번역 확정된 말풍선은 원본 텍스트 자리에 번역문이 오버레이되어 표시 (최종 결과물 미리보기)
- 말풍선 클릭 → 우측 패널에 해당 번역 후보 표시
- 우측 패널에서 확정(→) 클릭 시 이미지 위 오버레이 실시간 업데이트

#### 후보 재생성 모달 (추가 컨텍스트 주입)

```
┌─────────────────────────────────────────────────────────┐
│  🔄 번역 후보 재생성                                      │
│                                                          │
│  원문: "なんだよ、それ！"                                 │
│                                                          │
│  추가 컨텍스트 입력 (선택사항):                           │
│  ┌─────────────────────────────────────────────────┐    │
│  │ 이 장면은 주인공이 처음으로 눈물을 보이는 장면이에요│    │
│  └─────────────────────────────────────────────────┘    │
│                                                          │
│                  [취소]  [재생성 요청 →]                 │
└─────────────────────────────────────────────────────────┘
```

---

### 화면 5: AI 검수 결과 처리

```
┌──────────────────────────────────────────────────────────────┐
│  AI 검수 결과 — 23화                   [수정 제안 12건]       │
├──────────────────────────────────────────────────────────────┤
│  ① [일관성] 3-② 라이벌 대사                                  │
│     현재: "모른 체하지 마라."                                 │
│     제안: "모른 척하지 마세요."                               │
│     이유: 라이벌 캐릭터의 격식체 말투 프로필과 일치하지 않음   │
│                                    [수락 ✓] [거절 ✗]        │
├──────────────────────────────────────────────────────────────┤
│  ② [오역] 5-① 주인공 대사                                    │
│     현재: "이건 내 잘못이 아니야."                            │
│     제안: "이건 내 실수가 맞아."                              │
│     이유: "失敗した"는 "실수를 했다"는 인정의 표현             │
│                                    [수락 ✓] [거절 ✗]        │
├──────────────────────────────────────────────────────────────┤
│                        [전체 수락] [전체 거절]               │
│                        미처리: 10건   [다음 단계 →]          │
└──────────────────────────────────────────────────────────────┘
```

---

### 화면 6: 최종 미리보기 & 출력

```
┌──────────────────────────────────────────────────────────────┐
│  최종 미리보기 — 23화         [← 이전] 1 / 24 [다음 →]       │
├──────────────────────────────────────────────────────────────┤
│                                                              │
│   [번역 텍스트가 덮어써진 완성 이미지]                        │
│   (처음부터 읽으면서 맥락에 맞는지 최종 검수)                 │
│                                                              │
│   클릭 시 해당 말풍선 번역 편집기로 이동 가능                 │
│                                                              │
├──────────────────────────────────────────────────────────────┤
│  렌더링 방식:  ● 빠른 렌더링 (OpenCV TELEA)                  │
│                ○ 고품질 렌더링 (Simple-LAMA, 느림)            │
│                                                              │
│              [전체 다운로드 (ZIP)] [PDF로 다운로드]           │
└──────────────────────────────────────────────────────────────┘
```

---

## 핵심 컴포넌트 구현

### CandidateSelector.tsx — Survey형 번역 후보 선택 ⭐

```typescript
// components/translation/CandidateSelector.tsx
// 번역 편집기의 핵심 컴포넌트: Survey처럼 후보를 선택하거나 직접 입력

interface Candidate {
  rank: number;
  text: string;
  rationale: string;
}

interface CandidateSelectorProps {
  bubbleId: string;
  originalText: string;
  speaker: string;
  candidates: Candidate[];
  selectedRank: number | null;
  customText: string | null;
  onSelect: (rank: number) => void;
  onCustomInput: (text: string) => void;
  onConfirm: () => void;
  onRegenerate: (additionalContext: string) => void;
}

export function CandidateSelector({
  bubbleId, originalText, speaker, candidates,
  selectedRank, customText, onSelect, onCustomInput, onConfirm, onRegenerate
}: CandidateSelectorProps) {
  const [showRegenModal, setShowRegenModal] = useState(false);
  const [regenContext, setRegenContext] = useState('');
  const [directInput, setDirectInput] = useState(customText ?? '');
  const isDirectMode = selectedRank === null && directInput.length > 0;

  return (
    <div className="flex flex-col gap-3 p-4 border rounded-lg bg-white">
      {/* 원문 표시 */}
      <div className="text-sm text-gray-500">
        <span className="font-medium text-blue-600">[{speaker}]</span>
        &nbsp;{originalText}
      </div>

      {/* 후보 목록 - Survey형 라디오 버튼 */}
      <div className="flex flex-col gap-2">
        {candidates.map((c) => (
          <label
            key={c.rank}
            className={`flex items-start gap-2 p-2 rounded cursor-pointer border transition
              ${selectedRank === c.rank && !isDirectMode
                ? 'border-blue-500 bg-blue-50'
                : 'border-gray-200 hover:border-gray-300'
              }`}
            onClick={() => { onSelect(c.rank); setDirectInput(''); }}
          >
            <input
              type="radio"
              name={`candidate-${bubbleId}`}
              checked={selectedRank === c.rank && !isDirectMode}
              onChange={() => {}}
              className="mt-1"
            />
            <div>
              <span className="font-medium text-gray-800">
                {c.rank === 1 ? '①' : c.rank === 2 ? '②' : '③'} {c.text}
              </span>
              <p className="text-xs text-gray-400 mt-0.5">{c.rationale}</p>
            </div>
          </label>
        ))}

        {/* ④ 직접 입력 */}
        <div className={`flex items-start gap-2 p-2 rounded border transition
          ${isDirectMode ? 'border-blue-500 bg-blue-50' : 'border-gray-200'}`}>
          <input
            type="radio"
            name={`candidate-${bubbleId}`}
            checked={isDirectMode}
            onChange={() => {}}
            className="mt-1"
            onClick={() => onSelect(0)} // 직접 입력 모드
          />
          <div className="flex-1">
            <span className="text-sm text-gray-600">④ 직접 입력:</span>
            <input
              type="text"
              value={directInput}
              placeholder="번역을 직접 입력하세요"
              className="w-full mt-1 px-2 py-1 text-sm border border-gray-300 rounded"
              onChange={(e) => {
                setDirectInput(e.target.value);
                onCustomInput(e.target.value);
              }}
              onFocus={() => onSelect(0)}
            />
          </div>
        </div>
      </div>

      {/* 액션 버튼 */}
      <div className="flex gap-2 justify-between mt-1">
        <button
          className="text-xs text-gray-500 hover:text-gray-700 underline"
          onClick={() => setShowRegenModal(true)}
        >
          🔄 후보 재생성
        </button>
        <button
          className="px-4 py-1.5 bg-blue-600 text-white text-sm rounded hover:bg-blue-700 disabled:opacity-40"
          disabled={!selectedRank && !directInput}
          onClick={onConfirm}
        >
          이 번역 확정 →
        </button>
      </div>

      {/* 재생성 모달 */}
      {showRegenModal && (
        <div className="mt-2 p-3 bg-gray-50 rounded border">
          <p className="text-xs text-gray-600 mb-1">추가 컨텍스트 (선택사항):</p>
          <textarea
            className="w-full text-sm border border-gray-300 rounded p-2 resize-none"
            rows={2}
            value={regenContext}
            placeholder="예) 이 장면은 슬픈 이별 장면입니다"
            onChange={(e) => setRegenContext(e.target.value)}
          />
          <div className="flex gap-2 justify-end mt-2">
            <button className="text-xs text-gray-500" onClick={() => setShowRegenModal(false)}>취소</button>
            <button
              className="text-xs px-3 py-1 bg-blue-600 text-white rounded"
              onClick={() => { onRegenerate(regenContext); setShowRegenModal(false); }}
            >
              재생성 요청 →
            </button>
          </div>
        </div>
      )}
    </div>
  );
}
```

---

### Job 폴링 훅

```typescript
// hooks/useJobPolling.ts
import { useQuery } from '@tanstack/react-query';
import api from '@/lib/api';

interface JobStatus {
  status: 'pending' | 'processing' | 'done' | 'failed';
  progress: number;
  error?: string;
}

export function useJobPolling(jobId: string | null) {
  const { data } = useQuery<JobStatus>({
    queryKey: ['job', jobId],
    queryFn: () => api.get(`/jobs/${jobId}/status`).then(r => r.data),
    enabled: !!jobId,
    refetchInterval: (query) => {
      const status = query.state.data?.status;
      if (status === 'done' || status === 'failed') return false;
      return 2000; // 2초마다 폴링
    },
  });

  return {
    status: data?.status ?? 'pending',
    progress: data?.progress ?? 0,
    isDone: data?.status === 'done',
    isFailed: data?.status === 'failed',
    error: data?.error,
  };
}
```

---

### Fabric.js 캔버스 (이미지 뷰 + 번역 오버레이)

```typescript
// components/editor/FabricCanvas.tsx

import { fabric } from 'fabric';
import { useEffect, useRef } from 'react';

interface Bubble {
  id: string;
  x1: number; y1: number;
  width: number; height: number;
  originalText: string;
  translatedText: string | null;
  speaker: string;
  isConfirmed: boolean;
  index: number; // 라벨링 번호 (1, 2, 3...)
}

export function useFabricCanvas(canvasRef: React.RefObject<HTMLCanvasElement>, imageUrl: string) {
  const fabricRef = useRef<fabric.Canvas | null>(null);

  useEffect(() => {
    const canvas = new fabric.Canvas(canvasRef.current!, { selection: false });
    fabricRef.current = canvas;

    fabric.Image.fromURL(imageUrl, (img) => {
      canvas.setWidth(img.width!);
      canvas.setHeight(img.height!);
      canvas.setBackgroundImage(img, canvas.renderAll.bind(canvas));
    });

    return () => canvas.dispose();
  }, [imageUrl]);

  const renderBubbles = (bubbles: Bubble[], onBubbleClick: (id: string) => void) => {
    const canvas = fabricRef.current!;
    canvas.getObjects().forEach(obj => canvas.remove(obj));

    bubbles.forEach((bubble) => {
      // 번호 라벨 원형 배지
      const badge = new fabric.Circle({
        left: bubble.x1 - 12,
        top: bubble.y1 - 12,
        radius: 12,
        fill: bubble.isConfirmed ? '#22c55e' : '#3b82f6',
        selectable: false,
      });

      const badgeText = new fabric.Text(String(bubble.index), {
        left: bubble.x1 - 12,
        top: bubble.y1 - 12,
        fontSize: 12,
        fill: 'white',
        textAlign: 'center',
        originX: 'center',
        originY: 'center',
        selectable: false,
      });

      // 번역 확정된 경우 오버레이 표시
      if (bubble.isConfirmed && bubble.translatedText) {
        const overlay = new fabric.Rect({
          left: bubble.x1,
          top: bubble.y1,
          width: bubble.width,
          height: bubble.height,
          fill: 'rgba(255, 255, 255, 0.9)',
          selectable: false,
        });

        const translatedTextObj = new fabric.Textbox(bubble.translatedText, {
          left: bubble.x1 + 4,
          top: bubble.y1 + 4,
          width: bubble.width - 8,
          fontSize: 13,
          fontFamily: 'NanumGothic',
          textAlign: 'center',
          fill: '#111111',
          selectable: false,
        });

        canvas.add(overlay, translatedTextObj);
      }

      // 말풍선 테두리
      const border = new fabric.Rect({
        left: bubble.x1,
        top: bubble.y1,
        width: bubble.width,
        height: bubble.height,
        fill: 'transparent',
        stroke: bubble.isConfirmed ? '#22c55e' : '#3b82f6',
        strokeWidth: 2,
        rx: 3, ry: 3,
        selectable: false,
        hoverCursor: 'pointer',
      });

      border.on('mousedown', () => onBubbleClick(bubble.id));
      canvas.add(border, badge, badgeText);
    });

    canvas.renderAll();
  };

  return { fabricRef, renderBubbles };
}
```

---

### Zustand 에디터 스토어

```typescript
// store/editorStore.ts
import { create } from 'zustand';

type ViewMode = 'table' | 'image';

interface EditorStore {
  viewMode: ViewMode;
  setViewMode: (mode: ViewMode) => void;

  selectedBubbleId: string | null;
  setSelectedBubble: (id: string | null) => void;

  currentPage: number;
  setCurrentPage: (page: number) => void;

  filterMode: 'all' | 'pending';
  setFilterMode: (mode: 'all' | 'pending') => void;
}

export const useEditorStore = create<EditorStore>((set) => ({
  viewMode: 'table',
  setViewMode: (mode) => set({ viewMode: mode }),

  selectedBubbleId: null,
  setSelectedBubble: (id) => set({ selectedBubbleId: id }),

  currentPage: 1,
  setCurrentPage: (page) => set({ currentPage: page }),

  filterMode: 'all',
  setFilterMode: (mode) => set({ filterMode: mode }),
}));
```

---

### Axios 인스턴스 설정

```typescript
// lib/api.ts
import axios from 'axios';

const api = axios.create({
  baseURL: process.env.NEXT_PUBLIC_API_URL,
  timeout: 60000, // 이미지 처리 작업이 길 수 있어 60초
});

// JWT 자동 첨부
api.interceptors.request.use((config) => {
  const token = typeof window !== 'undefined'
    ? localStorage.getItem('access_token')
    : null;
  if (token) config.headers.Authorization = `Bearer ${token}`;
  return config;
});

// 401 시 로그인 페이지 리다이렉트
api.interceptors.response.use(
  (res) => res,
  (err) => {
    if (err.response?.status === 401) {
      localStorage.removeItem('access_token');
      window.location.href = '/login';
    }
    return Promise.reject(err);
  }
);

export default api;
```

---

## Vercel 배포 설정

```json
// vercel.json
{
  "env": {
    "NEXT_PUBLIC_API_URL": "https://api.ailosy.com"
  },
  "rewrites": [
    {
      "source": "/api/:path*",
      "destination": "https://api.ailosy.com/:path*"
    }
  ]
}
```