## ⚙️ Codex 공통 운영 규칙 (매 작업 필수)

### 작업 시작 전 반드시
1. 프로젝트 현재 구조 확인:
```bash
tree -a -L 5 \
-I 'node_modules|.next|out|dist|build|coverage|.turbo|.vercel|.cache|.vite|__pycache__|.pytest_cache|.mypy_cache|.venv|venv|env|*.pyc|*.pyo|*.log|*.lock|package-lock.json|yarn.lock|pnpm-lock.yaml|poetry.lock|*.jpg|*.jpeg|*.png|*.gif|*.webp|*.svg|*.ico|*.bmp|*.tiff|*.mp4|*.mov|*.webm|*.zip|*.tar|*.gz|*.7z|*.pdf|*.ttf|*.otf|*.woff|*.woff2|*.wasm'
```
2. `docs/planning/` 에서 이번 작업 관련 설계 문서 읽기
   - 관련 문서: `02_FRONTEND_ARCHITECTURE.md`
3. `docs/tasks/logs/LOG_P03_translation_pipeline_table_editor.md` 확인

### 작업 완료 후 반드시
1. `docs/tasks/logs/LOG_P04_image_editor_fabricjs.md` 작성
2. git commit:
   ```bash
   git add .
   git commit -m "feat: [P04] 이미지 뷰 편집기 (Fabric.js)"
   ```

---

# [P04] Phase 4: 이미지 뷰 편집기 — Fabric.js 캔버스 + 번역 오버레이

## 전제 조건
Phase 0~3 완료: 번역 파이프라인, 테이블 뷰 편집기 완료.

## 작업 목표
이미지 뷰 탭 완성: 웹툰 이미지 위 번호 배지 렌더링,
말풍선 클릭 → 우측 패널에서 번역 후보 선택 → 오버레이 즉시 업데이트.

---

## 작업

### hooks/useFabricCanvas.ts
```typescript
// useFabricCanvas(canvasRef: RefObject<HTMLCanvasElement>, imageUrl: string)
// useEffect로 fabric.Canvas 초기화, cleanup 시 canvas.dispose()
// fabric.Image.fromURL로 이미지 배경 로드

// renderBubbles(bubbles, onBubbleClick):
//   각 bubble:
//   1. 사각형 테두리 (isConfirmed: 초록, 미확정: 파랑)
//   2. 원형 배지 + label_index (좌상단)
//   3. isConfirmed && translatedText 있으면:
//      흰 반투명 Rect (fill: rgba(255,255,255,0.9))
//      Textbox 번역문 (fontSize:13, fontFamily:NanumGothic, center 정렬)
//   4. border.on('mousedown') → onBubbleClick(bubble.id)
//   5. canvas.renderAll()

// 반환: { fabricRef, renderBubbles }
```

### components/editor/FabricCanvas.tsx
```typescript
// props: { imageUrl, bubbles, selectedBubbleId, onBubbleClick }
// useFabricCanvas 훅 사용
// bubbles 변경 시 renderBubbles 재호출
// selectedBubbleId 변경 시 해당 bubble 테두리 강조 (strokeWidth: 4)
// 캔버스 컨테이너: overflow-hidden, 스크롤 가능
```

### components/editor/TranslationPanel.tsx
```typescript
// props: { bubble: Bubble | null }
// 선택된 bubble의 원문, 화자, CandidateSelector 표시
// bubble null → "말풍선을 클릭하세요" 안내
```

### translation/page.tsx — 이미지 뷰 탭 완성
```
viewMode=image 레이아웃:
  좌측 2/3: FabricCanvas + PageNavigator
  우측 1/3: TranslationPanel (selectedBubbleId 기반)

번역 확정(PATCH 성공) 후:
  TanStack Query invalidateQueries(['bubbles', pageId])
  renderBubbles 재호출 → 오버레이 즉시 업데이트

테이블 뷰 ↔ 이미지 뷰 전환 시 selectedBubbleId 상태 유지 (editorStore)
```

---

## 완료 기준
- [ ] 이미지 뷰에서 웹툰 이미지 + 번호 배지 렌더링 확인
- [ ] 말풍선 클릭 → 우측 패널 CandidateSelector 표시 확인
- [ ] 번역 확정 후 해당 위치에 번역문 오버레이 즉시 표시 확인
- [ ] 테이블 뷰 ↔ 이미지 뷰 전환 후 선택 상태 유지 확인
- [ ] 페이지 변경 시 새 이미지 + 해당 페이지 bubbles 로드 확인
