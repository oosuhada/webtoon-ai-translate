import os

os.environ.setdefault("DATABASE_URL", "sqlite:///./test_ailosy.db")
os.environ.setdefault("SECRET_KEY", "test-secret-key")

from routers.auth import normalize_email


def test_normalize_email_strips_and_lowercases() -> None:
    assert normalize_email("  Translator@Example.COM ") == "translator@example.com"
