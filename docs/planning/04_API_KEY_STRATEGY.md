# 04 — API Key 로테이션 전략

## 설계 원칙

- **무료 플랜 우선**: 복수 계정의 Key를 라운드 로빈으로 사용해 소진 속도 분산
- **자동 폴백**: Primary Key 전부 소진 시 Fallback 서비스로 자동 전환
- **소진 감지**: 429/402 응답 코드 자동 감지 → 해당 Key 일시 비활성화
- **자동 재활성화**: 쿼터 리셋 예상 시각에 Key 자동 복구

---

## KeyRotator 핵심 구현

```python
# services/key_rotator.py
import os, time, threading
from dataclasses import dataclass, field
from typing import Optional
from collections import deque

@dataclass
class KeyInfo:
    key: str
    extra: dict = field(default_factory=dict)   # Clova는 URL도 필요
    is_active: bool = True
    fail_count: int = 0
    quota_reset_at: Optional[float] = None       # 재활성화 예정 시각 (epoch)

class QuotaExceededError(Exception):
    """모든 Key의 쿼터가 소진된 경우 — 폴백 서비스로 전환"""
    pass

class KeyRotator:
    def __init__(self, keys: list[KeyInfo], service_name: str):
        self.service_name = service_name
        self._keys = deque(keys)
        self._lock = threading.Lock()

    @classmethod
    def from_env(cls, service: str) -> "KeyRotator":
        """
        환경변수에서 Key 목록 로드.

        Clova:  CLOVA_KEYS=key1,key2,key3
                CLOVA_URLS=url1,url2,url3
        DeepL:  DEEPL_KEYS=key1,key2,key3
        Groq:   GROQ_KEYS=key1,key2,key3,key4,key5
        """
        keys_str = os.getenv(f"{service}_KEYS", "")
        urls_str = os.getenv(f"{service}_URLS", "")

        keys_list = [k.strip() for k in keys_str.split(",") if k.strip()]
        urls_list = [u.strip() for u in urls_str.split(",") if u.strip()]

        if not keys_list:
            raise ValueError(f"{service}_KEYS 환경변수가 설정되지 않았습니다.")

        key_infos = []
        for i, key in enumerate(keys_list):
            extra = {}
            if urls_list and i < len(urls_list):
                extra["url"] = urls_list[i]
            key_infos.append(KeyInfo(key=key, extra=extra))

        return cls(key_infos, service_name=service)

    def get_key(self) -> KeyInfo:
        """
        사용 가능한 Key를 라운드 로빈으로 반환.
        모든 Key 소진 시 QuotaExceededError 발생 → 폴백 서비스로 전환.
        """
        with self._lock:
            now = time.time()

            # 리셋 시간 지난 Key 재활성화
            for key_info in self._keys:
                if (not key_info.is_active
                        and key_info.quota_reset_at
                        and now >= key_info.quota_reset_at):
                    key_info.is_active = True
                    key_info.quota_reset_at = None
                    print(f"[{self.service_name}] Key 재활성화: ...{key_info.key[-4:]}")

            for _ in range(len(self._keys)):
                key_info = self._keys[0]
                self._keys.rotate(-1)
                if key_info.is_active:
                    return key_info

            raise QuotaExceededError(
                f"[{self.service_name}] 모든 Key 소진 → 폴백 서비스로 전환합니다."
            )

    def report_success(self, key_info: KeyInfo):
        key_info.fail_count = 0

    def report_quota_exceeded(self, key_info: KeyInfo, reset_hours: int = 24):
        with self._lock:
            key_info.is_active = False
            key_info.quota_reset_at = time.time() + (reset_hours * 3600)
            print(f"[{self.service_name}] Key 쿼터 소진: ...{key_info.key[-4:]} "
                  f"({reset_hours}시간 후 재활성화)")

    def report_error(self, key_info: KeyInfo, error: Exception):
        with self._lock:
            key_info.fail_count += 1
            if key_info.fail_count >= 3:
                key_info.is_active = False
                key_info.quota_reset_at = time.time() + 300  # 5분 후 재시도
                print(f"[{self.service_name}] Key 오류 3회 → 5분 비활성화: ...{key_info.key[-4:]}")

    @property
    def status(self) -> dict:
        return {
            "service": self.service_name,
            "total": len(self._keys),
            "active": sum(1 for k in self._keys if k.is_active),
            "keys": [
                {
                    "suffix": f"...{k.key[-4:]}",
                    "active": k.is_active,
                    "fail_count": k.fail_count,
                    "reset_at": k.quota_reset_at,
                }
                for k in self._keys
            ]
        }
```

---

## 서비스별 전략 상세

### OCR: Clova General OCR → Google Lens (폴백)

```python
# services/clova_ocr.py

class ClovaOCRClient:
    """
    Naver Clova General OCR
    - 무료: 네이버 클라우드 플랫폼 계정당 일정 건수
    - 여러 네이버 계정으로 URL+Key 쌍 등록해서 로테이션
    - 환경변수: CLOVA_KEYS=key1,key2  / CLOVA_URLS=url1,url2
    """

    @staticmethod
    async def request(image_bytes: bytes, key_info: KeyInfo) -> dict:
        import aiohttp, json, uuid, time

        url = key_info.extra.get("url")
        if not url:
            raise ValueError("Clova OCR URL 미설정")

        payload = {
            "images": [{"format": "jpg", "name": "image"}],
            "requestId": str(uuid.uuid4()),
            "version": "V2",
            "timestamp": int(time.time() * 1000)
        }

        async with aiohttp.ClientSession() as session:
            form = aiohttp.FormData()
            form.add_field("message", json.dumps(payload))
            form.add_field("file", image_bytes, content_type="image/jpeg")

            async with session.post(
                url,
                data=form,
                headers={"X-OCR-SECRET": key_info.key}
            ) as resp:
                if resp.status == 429:
                    raise QuotaExceededError("Clova OCR 쿼터 초과")
                resp.raise_for_status()
                return await resp.json()
```

```python
# services/google_lens.py
# TextPhantom의 lens_core.py 방식 참고

class GoogleLensClient:
    """
    Google Lens 폴백 OCR (비공식 API)
    - Clova 전체 소진 시 사용
    - Rate limit 있음 → 요청 간 1초 딜레이
    - 상업적 이용 약관 주의 (비상용)
    """

    async def request(self, image_bytes: bytes) -> list[dict]:
        await asyncio.sleep(1)  # Rate limit 방지
        # lens_core.py 로직 포팅 예정
        pass
```

---

### 번역: DeepL → Groq LLM (폴백)

```
DeepL Free 플랜:
- 계정당 월 500,000자
- 배치 번역 지원 (최대 50개 동시)
- 단일 번역 반환 (후보 복수 생성 불가)
- 환경변수: DEEPL_KEYS=key1:free,key2:free,key3:free

Groq Free 플랜 (2025년 기준):
- llama-3.3-70b-versatile: 분당 6,000 tokens (번역 후보 생성)
- llama-3.1-8b-instant:    분당 20,000 tokens (AI 검수, 빠름)
- 일일 토큰 한도 없음 (Rate limit만 존재)
- 환경변수: GROQ_KEYS=key1,key2,key3,key4,key5

역할 분담:
- 번역 후보 3~4개 생성 → Groq (llama-3.3-70b)
- 배치 단일 번역 (DeepL 절약 용도) → DeepL → Groq 폴백
- AI 검수 → Groq (llama-3.1-8b, 빠름)
- 화자 매칭 → Groq (llama-3.3-70b)
```

---

## 상태 모니터링 API

```python
# routers/admin.py

@router.get("/admin/api-status")
async def get_api_status(current_user: User = Depends(get_admin_user)):
    return {
        "ocr": {
            "clova": clova_rotator.status,
            "google_lens_enabled": lens_client.is_available(),
        },
        "translation": {
            "deepl": deepl_rotator.status,
            "groq": groq_rotator.status,
        }
    }
```

---

## Key 추가 운영 가이드

```bash
# .env 파일에 Key 추가 (쉼표 구분)
# 서버 재시작 필요 (추후 동적 추가 API 구현 예정)

# DeepL Key 3개 → 5개로 확장
DEEPL_KEYS=key1,key2,key3,key4,key5

# Clova Key + URL 추가 (URL과 Key 순서 반드시 일치)
CLOVA_KEYS=key1,key2,key3,key4
CLOVA_URLS=url1,url2,url3,url4

# Groq Key 추가
GROQ_KEYS=key1,key2,key3,key4,key5,key6
```

---

## 무료 처리 용량 추정 (계정 5개 기준)

| 서비스 | 계정당 무료 한도 | 5계정 월 처리량 |
|--------|----------------|---------------|
| Clova General OCR | ~월 1,000건 (추정) | ~5,000 페이지/월 |
| DeepL Free | 월 500,000자 | ~250만 자/월 |
| Groq (Rate limit) | 분당 6,000 tokens | 사실상 무제한 (속도 제한만) |
| Google Lens | 비공식, 불명확 | 비상용 |

→ 소규모 서비스 초기 운영은 무료로 충분히 커버 가능.
→ 규모 성장 시 DeepL Pro 또는 AWS Translate로 유료 전환.