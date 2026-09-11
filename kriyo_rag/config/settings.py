"""
KRIYO RAG Engine Configuration Settings
Resolves paths dynamically relative to the kriyo_rag root directory,
with support for environment variable overrides.
"""

import os
from pathlib import Path
from pydantic_settings import BaseSettings, SettingsConfigDict

BASE_DIR = Path(__file__).resolve().parent.parent


class Settings(BaseSettings):
    PROJECT_NAME: str = "KRIYO RAG Knowledge Service"
    VERSION: str = "1.0.0"
    ENVIRONMENT: str = "development"

    # Directory Paths
    BASE_DIR: Path = BASE_DIR
    DATA_DIR: Path = BASE_DIR / "data"
    STRUCTURED_DIR: Path = BASE_DIR / "data" / "01_structured"
    DOCS_DIR: Path = BASE_DIR / "data" / "02_knowledge_documents"
    EVIDENCE_PATH: Path = BASE_DIR / "data" / "03_evidence" / "KRIYO_Evidence_Registry.xlsx"
    METADATA_DIR: Path = BASE_DIR / "data" / "03_metadata"
    STORAGE_DIR: Path = BASE_DIR / "storage"
    INDEX_DIR: Path = BASE_DIR / "storage" / "index"
    CHROMA_DB_DIR: Path = BASE_DIR / "storage" / "index" / "chroma_db"

    # Embedding & Retrieval Settings
    COLLECTION_NAME: str = "kriyo_synthetic_corpus"
    EMBEDDING_MODEL_NAME: str = "sentence-transformers/all-MiniLM-L6-v2"
    EMBEDDING_DIMENSION: int = 384
    TOP_K: int = 8
    MIN_RETRIEVAL_CONFIDENCE: float = 0.20
    MIN_EVIDENCE_COVERAGE: float = 0.20

    # API Server Settings
    API_HOST: str = "0.0.0.0"
    API_PORT: int = 8001
    CORS_ORIGINS: list[str] = ["*"]

    model_config = SettingsConfigDict(
        env_file=str(BASE_DIR / ".env"),
        env_file_encoding="utf-8",
        extra="ignore"
    )


settings = Settings()
