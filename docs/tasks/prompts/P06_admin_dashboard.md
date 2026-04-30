## ⚙️ Codex 공통 운영 규칙 (매 작업 필수)

### 작업 시작 전 반드시
1. 프로젝트 현재 구조 확인:
```bash
tree -a -L 5 \
-I 'node_modules|.next|out|dist|build|coverage|.turbo|.vercel|.cache|.vite|__pycache__|.pytest_cache|.mypy_cache|.venv|venv|env|*.pyc|*.pyo|*.log|*.lock|package-lock.json|yarn.lock|pnpm-lock.yaml|poetry.lock|*.jpg|*.jpeg|*.png|*.gif|*.webp|*.svg|*.ico|*.bmp|*.tiff|*.mp4|*.mov|*.webm|*.zip|*.tar|*.gz|*.7z|*.pdf|*.ttf|*.otf|*.woff|*.woff2|*.wasm'
```
2. `docs/planning/` 에서 이번 작업 관련 설계 문서 읽기
   - 관련 문서: `01_BACKEND_ARCHITECTURE.md`, `02_FRONTEND_ARCHITECTURE.md`
3. `docs/tasks/logs/LOG_P05_ai_review_rendering_output.md` 확인

### 작업 완료 후 반드시
1. `docs/tasks/logs/LOG_P06_admin_dashboard.md` 작성
2. git commit:
   ```bash
   git add .
   git commit -m "feat: [P06] 관리자 대시보드"
   ```

---

# [P06] Phase 6: 관리자 대시보드 — API 사용량 모니터링

## 전제 조건
Phase 0~5 완료. APIUsageLog 모델 기존 구현됨.
관리자 접근: User.is_admin=True + get_admin_user 의존성으로 보호.

---

## 백엔드 작업 (routers/admin.py)

모든 엔드포인트: `get_admin_user` 의존성 (is_admin=False이면 403).

```
GET /admin/api-status
  → KeyRotator 상태 (clova, deepl, groq 각각 total/active/keys)

GET /admin/usage/summary
  Response: { "today": [...], "this_month": [...], "quota_warning_count": N }

GET /admin/usage/by-user
  Query: from (YYYY-MM-DD), to (YYYY-MM-DD)
  → [{ userId, userEmail, service, requests, chars, tokens }]

GET /admin/usage/by-user/{user_id}
  → 최근 100건 사용 이력

GET /admin/usage/timeseries
  Query: granularity ("day"|"hour"), from, to
  PostgreSQL: DATE_TRUNC / SQLite: strftime('%Y-%m-%d', created_at)
  → [{ period, service, requests }]

GET /admin/usage/quota-warnings
  Response:
  {
    "warnings": [{ service, keySuffix, status, resetAt, upgradeRecommended }],
    "count": N,
    "upgradeLinks": {
      "deepl": "https://www.deepl.com/pro",
      "groq": "https://console.groq.com/settings/billing",
      "clova": "https://www.ncloud.com/product/aiService/ocr"
    }
  }
```

---

## 프론트엔드 작업

```bash
npm install recharts
```

### app/admin/page.tsx
레이아웃:
1. **오늘/이번 달 요약 카드** (4개):
   총 OCR 요청 수 | 총 번역 요청 수 | 총 AI 검수 요청 수 | 활성 API Key 수

2. **쿼터 경고 배너** (GET /admin/usage/quota-warnings):
   - 경고 있으면: ⚠️ 노란 배너 + [유료 플랜 업그레이드 →] 링크 (upgradeLinks[service])
   - 경고 없으면: ✅ 모든 API Key 정상 동작 중

3. **서비스별 일별 Bar 차트** (Recharts BarChart):
   - GET /admin/usage/timeseries?granularity=day
   - 색상: clova_ocr=파랑, deepl=초록, groq_translate=보라, groq_review=주황, groq_speaker=빨강

4. **유저별 사용량 테이블**:
   - GET /admin/usage/by-user
   - 컬럼: 이메일 | 서비스 | 요청 수 | 문자 수 | 토큰 수
   - 행 클릭 → 상세 모달 (GET /admin/usage/by-user/{id})

5. **API Key 상태** (GET /admin/api-status):
   - 서비스별 Key (끝 4자리): 활성=초록 / 비활성=빨강 배지
   - 비활성 Key: 재활성화 예정 시각 표시

### app/admin/layout.tsx
- 비관리자 접근 시 /dashboard 리다이렉트

### middleware.ts 업데이트
- /admin/* 경로: access_token의 isAdmin 클레임 확인
- isAdmin=false → /dashboard 리다이렉트

---

## 완료 기준
- [ ] 관리자 계정 /admin 접근 → 대시보드 렌더링 확인
- [ ] 일반 계정 /admin 접근 → /dashboard 리다이렉트 확인
- [ ] 일별 Bar 차트 렌더링 확인 (Recharts)
- [ ] 쿼터 경고 배너: Key 비활성 상태일 때 경고 표시 확인
- [ ] 유저 테이블 행 클릭 → 상세 모달 확인
- [ ] quota-warnings 응답에 upgradeLinks 포함 확인
