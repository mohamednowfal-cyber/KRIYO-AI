"""
OTP session model for tracking verification attempts, expiry, and rate limits.
"""

import uuid
from datetime import datetime, timezone
from typing import TYPE_CHECKING, Optional
from sqlalchemy import Boolean, DateTime, ForeignKey, Integer, String
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.database.database import Base

if TYPE_CHECKING:
    from app.models.user import User


def utc_now():
    return datetime.now(timezone.utc)


def generate_session_id():
    return f"otp_{uuid.uuid4().hex[:16]}"



class OtpSession(Base):
    __tablename__ = "otp_sessions"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)
    session_id: Mapped[str] = mapped_column(String(64), unique=True, index=True, default=generate_session_id, nullable=False)
    phone_number: Mapped[Optional[str]] = mapped_column(String(32), index=True, nullable=True)
    email: Mapped[Optional[str]] = mapped_column(String(128), index=True, nullable=True)
    otp_code_hash: Mapped[str] = mapped_column(String(256), nullable=False)
    role: Mapped[str] = mapped_column(String(32), nullable=False, default="customer")
    purpose: Mapped[str] = mapped_column(String(32), nullable=False, default="login")  # 'login', 'signup', 'verify'

    is_verified: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    attempts: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    max_attempts: Mapped[int] = mapped_column(Integer, default=5, nullable=False)

    expires_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utc_now, nullable=False)

    user_id: Mapped[Optional[int]] = mapped_column(Integer, ForeignKey("users.id", ondelete="SET NULL"), nullable=True)
    user: Mapped[Optional["User"]] = relationship("User", back_populates="otp_sessions")

    def is_expired(self) -> bool:
        """Check if the OTP session has surpassed its expiry datetime."""
        now = datetime.now(timezone.utc)
        if self.expires_at.tzinfo is None:
            return now.replace(tzinfo=None) > self.expires_at
        return now > self.expires_at

    def can_attempt(self) -> bool:
        """Check if attempts remain and session has not expired."""
        return not self.is_verified and not self.is_expired() and self.attempts < self.max_attempts

    def __repr__(self) -> str:
        return f"<OtpSession(id={self.id}, phone='{self.phone_number}', verified={self.is_verified})>"
