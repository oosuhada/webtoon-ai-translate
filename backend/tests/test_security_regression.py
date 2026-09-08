from __future__ import annotations

import pytest

from security import LoginFailureLimiter, validate_jwt_secret


def test_production_rejects_default_or_short_jwt_secret() -> None:
    with pytest.raises(RuntimeError):
        validate_jwt_secret("production", "change-this-secret")
    with pytest.raises(RuntimeError):
        validate_jwt_secret("production", "short-secret")
    validate_jwt_secret("production", "a" * 32)


def test_failed_login_budget_blocks_sixth_attempt_and_expires() -> None:
    limiter = LoginFailureLimiter(max_failures=5, window_seconds=60)
    key = "127.0.0.1:translator@example.com"
    for second in range(5):
        assert limiter.retry_after(key, now=float(second)) == 0
        limiter.record_failure(key, now=float(second))

    assert limiter.retry_after(key, now=5.0) == 55
    assert limiter.retry_after(key, now=65.0) == 0


def test_success_reset_clears_failure_budget() -> None:
    limiter = LoginFailureLimiter(max_failures=3, window_seconds=60)
    key = "127.0.0.1:translator@example.com"
    for second in range(3):
        limiter.record_failure(key, now=float(second))
    assert limiter.retry_after(key, now=3.0) > 0
    limiter.reset(key)
    assert limiter.retry_after(key, now=3.0) == 0
