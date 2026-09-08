from __future__ import annotations

import time
from collections import defaultdict, deque
from threading import Lock


DEFAULT_INSECURE_SECRET = "change-this-secret"


def validate_jwt_secret(environment: str, secret: str) -> None:
    """Fail closed when a production-like environment uses a weak JWT signing secret."""
    if environment.lower() == "development":
        return
    if secret == DEFAULT_INSECURE_SECRET or len(secret) < 32:
        raise RuntimeError("SECRET_KEY must be changed to a random value of at least 32 characters outside development")


class LoginFailureLimiter:
    """Small in-process sliding-window limiter for repeated failed logins."""

    def __init__(self, max_failures: int = 5, window_seconds: int = 60) -> None:
        self.max_failures = max_failures
        self.window_seconds = window_seconds
        self._failures: dict[str, deque[float]] = defaultdict(deque)
        self._lock = Lock()

    def _prune(self, key: str, now: float) -> deque[float]:
        attempts = self._failures[key]
        cutoff = now - self.window_seconds
        while attempts and attempts[0] <= cutoff:
            attempts.popleft()
        return attempts

    def retry_after(self, key: str, now: float | None = None) -> int:
        current = time.monotonic() if now is None else now
        with self._lock:
            attempts = self._prune(key, current)
            if len(attempts) < self.max_failures:
                return 0
            remaining = self.window_seconds - (current - attempts[0])
            return max(1, int(remaining + 0.999))

    def record_failure(self, key: str, now: float | None = None) -> None:
        current = time.monotonic() if now is None else now
        with self._lock:
            attempts = self._prune(key, current)
            attempts.append(current)

    def reset(self, key: str) -> None:
        with self._lock:
            self._failures.pop(key, None)

    def clear(self) -> None:
        with self._lock:
            self._failures.clear()
