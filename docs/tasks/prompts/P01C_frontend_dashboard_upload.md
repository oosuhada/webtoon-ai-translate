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
