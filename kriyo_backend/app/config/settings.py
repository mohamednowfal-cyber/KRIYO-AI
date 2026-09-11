"""
Application settings configuration using Pydantic BaseSettings.
Loads from environment variables or .env file.
"""

from pathlib import Path
from typing import List, Union
from pydantic import AnyHttpUrl, field_validator
from pydantic_settings import BaseSettings, SettingsConfigDict

_BACKEND_DIR = Path(__file__).resolve().parent.parent.parent
_ENV_PATH = _BACKEND_DIR / ".env"


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=(str(_ENV_PATH), ".env"),
        env_file_encoding="utf-8",
        extra="ignore",
        case_sensitive=True,
    )

    # Application
    PROJECT_NAME: str = "KRIYO Artisan & Customer Backend"
    API_V1_STR: str = "/api/v1"
    ENVIRONMENT: str = "development"
    DEBUG: bool = True

    # Security & JWT
    SECRET_KEY: str = "kriyo_super_secret_jwt_key_artisan_customer_portal_2026"
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 1440  # 24 Hours
    REFRESH_TOKEN_EXPIRE_DAYS: int = 30     # 30 Days

    # Database
    DATABASE_URL: str = "sqlite:///./kriyo_dev.db"
    DB_ECHO: bool = False

    # MSG91 SMS & OTP Provider
    MSG91_AUTH_KEY: str = "your_msg91_auth_key_here"
    MSG91_WIDGET_ID: str = ""
    MSG91_TEMPLATE_ID: str = "your_msg91_dlt_template_id"
    MSG91_SENDER_ID: str = "KRIYO"
    MSG91_OTP_LENGTH: int = 6
    MSG91_OTP_EXPIRY_MINUTES: int = 5
    MSG91_MOCK_MODE: bool = True

    # Email & SMTP Configuration
    SMTP_HOST: str = ""
    SMTP_PORT: int = 587
    SMTP_USERNAME: str = ""
    SMTP_USER: str = ""
    SMTP_PASSWORD: str = ""
    SMTP_FROM_EMAIL: str = "noreply@kriyo.com"
    SMTP_FROM_NAME: str = "KRIYO Team"
    SMTP_USE_TLS: bool = True
    SMTP_USE_SSL: bool = False

    # Customer Email OTP Security Parameters
    EMAIL_OTP_EXPIRY_MINUTES: int = 5
    EMAIL_OTP_RESEND_COOLDOWN_SECONDS: int = 60
    EMAIL_OTP_MAX_ATTEMPTS: int = 5

    # Redis Temporary OTP State & Throttling
    REDIS_URL: str = "redis://localhost:6379/0"
    OTP_RESEND_COOLDOWN_SECONDS: int = 30
    OTP_MAX_REQUESTS_PER_HOUR: int = 5
    OTP_MAX_VERIFY_ATTEMPTS: int = 5

    # Rate Limiting
    RATE_LIMIT_PER_MINUTE: str = "60/minute"
    AUTH_RATE_LIMIT_PER_MINUTE: str = "5/minute"


    # CORS
    CORS_ORIGINS: List[str] = [
        "http://localhost:3000",
        "http://localhost:8080",
        "http://10.0.2.2:8000",
        "http://127.0.0.1:8000",
        "*",
    ]

    @field_validator("CORS_ORIGINS", mode="before")
    @classmethod
    def assemble_cors_origins(cls, v: Union[str, List[str]]) -> List[str]:
        if isinstance(v, str):
            if not v.startswith("["):
                return [i.strip() for i in v.split(",") if i.strip()]
            import json
            parsed = json.loads(v)
            if isinstance(parsed, list):
                return [str(i) for i in parsed]
            return [str(parsed)]
        elif isinstance(v, list):
            return [str(i) for i in v]
        raise ValueError(v)


settings = Settings()
