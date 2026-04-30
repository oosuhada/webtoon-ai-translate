from functools import lru_cache
from typing import List

from pydantic.v1 import BaseSettings


class Settings(BaseSettings):
    ENVIRONMENT: str = "development"
    DATABASE_URL: str = "sqlite:///./ailosy.db"
    SECRET_KEY: str = "change-this-secret"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60
    CLOVA_KEYS: str = ""
    CLOVA_URLS: str = ""
    DEEPL_KEYS: str = ""
    GROQ_KEYS: str = ""
    UPLOAD_DIR: str = "./data/uploads"
    OUTPUT_DIR: str = "./data/outputs"

    class Config:
        env_file = ".env"
        case_sensitive = True

    @staticmethod
    def _csv(value: str) -> List[str]:
        return [item.strip() for item in value.split(",") if item.strip()]

    @property
    def clova_keys(self) -> List[str]:
        return self._csv(self.CLOVA_KEYS)

    @property
    def clova_urls(self) -> List[str]:
        return self._csv(self.CLOVA_URLS)

    @property
    def deepl_keys(self) -> List[str]:
        return self._csv(self.DEEPL_KEYS)

    @property
    def groq_keys(self) -> List[str]:
        return self._csv(self.GROQ_KEYS)

    @property
    def is_development(self) -> bool:
        return self.ENVIRONMENT.lower() == "development"


@lru_cache
def get_settings() -> Settings:
    return Settings()


settings = get_settings()
