"""
User ORM model representing both Artisans and Customers.
"""

from datetime import datetime, timezone
from typing import TYPE_CHECKING, List, Optional
from sqlalchemy import Boolean, DateTime, Integer, String
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.database.database import Base

if TYPE_CHECKING:
    from app.models.artisan_profile import ArtisanProfile
    from app.models.otp_session import OtpSession


def utc_now():
    return datetime.now(timezone.utc)


class User(Base):
    __tablename__ = "users"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)
    phone_number: Mapped[Optional[str]] = mapped_column(String(32), unique=True, index=True, nullable=True)
    email: Mapped[Optional[str]] = mapped_column(String(128), unique=True, index=True, nullable=True)
    role: Mapped[str] = mapped_column(String(32), nullable=False, default="customer", index=True)  # 'artisan', 'customer', 'admin'
    full_name: Mapped[Optional[str]] = mapped_column(String(128), nullable=True)
    preferred_language: Mapped[str] = mapped_column(String(16), default="en", nullable=False)     # 'en', 'ta', 'hi'
    is_active: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)
    is_verified: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    email_verified: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    profile_completed: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)

    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utc_now, nullable=False)
    updated_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utc_now, onupdate=utc_now, nullable=False)

    # Relationships
    artisan_profile: Mapped[Optional["ArtisanProfile"]] = relationship(
        "ArtisanProfile",
        back_populates="user",
        uselist=False,
        cascade="all, delete-orphan",
    )
    otp_sessions: Mapped[List["OtpSession"]] = relationship(
        "OtpSession",
        back_populates="user",
        cascade="all, delete-orphan",
    )

    def __repr__(self) -> str:
        return f"<User(id={self.id}, phone='{self.phone_number}', role='{self.role}')>"
