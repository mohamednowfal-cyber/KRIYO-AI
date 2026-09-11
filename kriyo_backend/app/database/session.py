"""
Database session dependency for FastAPI route injection.
"""

from typing import Generator
from sqlalchemy.orm import Session
from app.database.database import SessionLocal


def get_db() -> Generator[Session, None, None]:
    """
    FastAPI dependency yielding a thread-local SQLAlchemy database session.
    Automatically rolls back on exceptions and closes when the request finishes.
    """
    db = SessionLocal()
    try:
        yield db
    except Exception:
        db.rollback()
        raise
    finally:
        db.close()
