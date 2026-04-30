# 06 — 배포 설정 (M1 맥미니 백엔드 + Vercel 프론트엔드)

## 전체 배포 구성

```
인터넷
  │
  ├──── Vercel (프론트엔드)
  │       Next.js 자동 빌드/배포
  │       도메인: ailosy.vercel.app (또는 커스텀 도메인)
  │       환경변수: NEXT_PUBLIC_API_URL=https://api.ailosy.com
  │
  └──── M1 맥미니 (백엔드)
          FastAPI + uvicorn (Docker Compose)
          DB: PostgreSQL (Docker)
          파일: 로컬 디스크 /data/
          외부 노출: Cloudflare Tunnel (무료, 고정 도메인, 자동 HTTPS)
```

---

## M1 맥미니 백엔드 설정

### 1. 외부 노출: Cloudflare Tunnel (권장, 무료)

ngrok 무료는 URL이 바뀌지만 Cloudflare Tunnel은 고정 도메인 + HTTPS 무료.

```bash
# cloudflared 설치 (M1 Mac)
brew install cloudflare/cloudflare/cloudflared

# Cloudflare 인증
cloudflared tunnel login

# 터널 생성
cloudflared tunnel create ailosy-backend

# 설정 파일 작성
cat > ~/.cloudflared/config.yml << EOF
tunnel: <TUNNEL_ID>
credentials-file: /Users/<username>/.cloudflared/<TUNNEL_ID>.json

ingress:
  - hostname: api.ailosy.com
    service: http://localhost:8000
  - service: http_status:404
EOF

# DNS 레코드 등록
cloudflared tunnel route dns ailosy-backend api.ailosy.com

# 시스템 서비스로 등록 (재부팅 후 자동 실행)
cloudflared service install
```

---

### 2. Docker Compose

```yaml
# docker-compose.yml
version: '3.8'

services:
  api:
    build: .
    ports:
      - "8000:8000"
    volumes:
      - ./data/uploads:/data/uploads
      - ./data/outputs:/data/outputs
      - ./.env:/app/.env
    environment:
      - ENVIRONMENT=production
      - DATABASE_URL=postgresql://ailosy:password@db:5432/ailosy
    depends_on:
      - db
    restart: unless-stopped

  db:
    image: postgres:15-alpine
    environment:
      POSTGRES_USER: ailosy
      POSTGRES_PASSWORD: strong_password_here   # 반드시 변경
      POSTGRES_DB: ailosy
    volumes:
      - postgres_data:/var/lib/postgresql/data
    ports:
      - "5432:5432"
    restart: unless-stopped

volumes:
  postgres_data:
```

```dockerfile
# Dockerfile
FROM python:3.11-slim

RUN apt-get update && apt-get install -y \
    libgl1-mesa-glx \
    libglib2.0-0 \
    libsm6 \
    libxext6 \
    libxrender-dev \
    libgomp1 \
    fonts-nanum \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000", "--workers", "2"]
```

```
# requirements.txt
fastapi==0.109.0
uvicorn[standard]==0.27.0
sqlalchemy==2.0.25
alembic==1.13.1
python-jose[cryptography]==3.3.0
passlib[bcrypt]==1.7.4
python-multipart==0.0.9
aiohttp==3.9.3
python-dotenv==1.0.0

# 이미지 처리
opencv-python-headless==4.9.0.80
Pillow==10.2.0
numpy==1.26.3
pdf2image==1.17.0

# OCR / 번역
deepl==1.17.0
groq==0.5.0

# (선택) 고품질 인페인팅
# simple-lama-inpainting==0.1.2
```

---

### 3. 맥미니 자동 시작 (Docker Compose + launchd)

```bash
# /Library/LaunchDaemons/com.ailosy.backend.plist
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>com.ailosy.backend</string>
  <key>ProgramArguments</key>
  <array>
    <string>/usr/local/bin/docker</string>
    <string>compose</string>
    <string>-f</string>
    <string>/Users/<username>/ailosy/docker-compose.yml</string>
    <string>up</string>
  </array>
  <key>RunAtLoad</key>
  <true/>
  <key>KeepAlive</key>
  <true/>
</dict>
</plist>
```

---

## Vercel 프론트엔드 배포

### 1. 초기 설정

```bash
npx create-next-app@latest frontend --typescript --tailwind --app
cd frontend

# Vercel CLI
npm install -g vercel
vercel login
vercel --prod
```

### 2. 환경변수 (Vercel 대시보드 > Settings > Environment Variables)

```bash
NEXT_PUBLIC_API_URL=https://api.ailosy.com
NEXTAUTH_URL=https://ailosy.vercel.app
NEXTAUTH_SECRET=your-nextauth-secret
```

### 3. 자동 배포

GitHub 연결 → main 브랜치 push 시 Vercel이 자동으로 빌드 & 배포.

```json
// vercel.json
{
  "buildCommand": "npm run build",
  "outputDirectory": ".next",
  "framework": "nextjs"
}
```

---

## 개발 환경 세팅 순서

```bash
# === 백엔드 ===
python -m venv venv && source venv/bin/activate
pip install -r requirements.txt

cp .env.example .env
# .env 편집: API Key, DB URL 등

alembic upgrade head
uvicorn main:app --reload --port 8000

# === 프론트엔드 ===
cd frontend
npm install
echo "NEXT_PUBLIC_API_URL=http://localhost:8000" > .env.local
npm run dev
# → http://localhost:3000
```

---

## 모니터링 & 로깅

```python
# main.py
import logging, time
from fastapi import Request

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('/data/logs/app.log'),
        logging.StreamHandler()
    ]
)

@app.middleware("http")
async def log_requests(request: Request, call_next):
    start = time.time()
    response = await call_next(request)
    logging.info(f"{request.method} {request.url.path} → {response.status_code} ({time.time()-start:.2f}s)")
    return response
```

---

## MVP 개발 마일스톤

| Phase | 내용 | 예상 기간 |
|-------|------|---------|
| 0 | 환경 세팅, DB 스키마, JWT 인증 | 1주 |
| 1 | 파일 업로드 + OCR 파이프라인 (Clova) + 라벨 번호 부여 | 1주 |
| 2 | DeepL/Groq 번역 파이프라인 + Key 로테이터 | 1주 |
| 3 | 프론트 기본 화면 (업로드, 테이블 뷰, CandidateSelector) | 1주 |
| 4 | 화자 매칭 + 라벨링 검수 UI (Fabric.js 캔버스) | 1주 |
| 5 | 이미지 뷰 편집기 + 번역 오버레이 + AI 검수 | 1.5주 |
| 6 | 렌더링 출력 (인페인팅 + 텍스트 합성) | 1주 |
| 7 | 맥미니 배포 (Cloudflare Tunnel) + Vercel 배포 | 0.5주 |
| **합계** | | **약 8주** |