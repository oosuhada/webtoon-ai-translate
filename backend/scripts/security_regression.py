from __future__ import annotations

import json
import subprocess
from datetime import datetime, timezone

from security import LoginFailureLimiter, validate_jwt_secret


def main() -> None:
    limiter = LoginFailureLimiter(max_failures=5, window_seconds=60)
    key = "attack-client:victim@example.com"
    decisions: list[dict[str, int | str]] = []
    for attempt in range(1, 7):
        retry_after = limiter.retry_after(key, now=float(attempt - 1))
        if retry_after:
            decisions.append({"attempt": attempt, "result": "blocked", "retry_after_seconds": retry_after})
            continue
        limiter.record_failure(key, now=float(attempt - 1))
        decisions.append({"attempt": attempt, "result": "credential_rejected", "retry_after_seconds": 0})

    weak_secret_rejected = False
    try:
        validate_jwt_secret("production", "change-this-secret")
    except RuntimeError:
        weak_secret_rejected = True

    result = {
        "experiment": "webtoon-auth-abuse-regression-v1",
        "git_sha": subprocess.check_output(["git", "rev-parse", "HEAD"], text=True).strip(),
        "generated_at": datetime.now(timezone.utc).isoformat(),
        "attack": "six repeated failed login attempts from one client+identity within 60 seconds",
        "decisions": decisions,
        "sixth_attempt_blocked": decisions[-1]["result"] == "blocked",
        "production_default_secret_rejected": weak_secret_rejected,
        "limitations": [
            "The limiter is process-local; multi-instance deployment requires a shared rate-limit store or edge enforcement.",
            "Client+identity bucketing limits one guessing path but does not replace IP/reputation controls at the reverse proxy.",
            "This regression covers the implemented authentication surface, not the planned OCR/translation pipeline.",
        ],
    }
    print(json.dumps(result, indent=2))


if __name__ == "__main__":
    main()
