"""
Artisan profile ORM model holding heritage, craft specialty, and verification details.
"""

from datetime import datetime, timezone
from typing import TYPE_CHECKING, Optional
from sqlalchemy import Boolean, DateTime, ForeignKey, Integer, String, Text
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.database.database import Base

if TYPE_CHECKING:
    from app.models.user import User


def utc_now():
    return datetime.now(timezone.utc)


class ArtisanProfile(Base):
    __tablename__ = "artisan_profiles"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)
    user_id: Mapped[int] = mapped_column(Integer, ForeignKey("users.id", ondelete="CASCADE"), unique=True, nullable=False, index=True)

    craft_specialty: Mapped[str] = mapped_column(String(128), nullable=False, default="Pottery & Terracotta")
    studio_name: Mapped[Optional[str]] = mapped_column(String(128), nullable=True)
    state: Mapped[Optional[str]] = mapped_column(String(64), nullable=True)
    district: Mapped[Optional[str]] = mapped_column(String(64), nullable=True)
    pincode: Mapped[Optional[str]] = mapped_column(String(16), nullable=True)
    years_of_experience: Mapped[int] = mapped_column(Integer, default=0, nullable=False)

    bio: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    heritage_story: Mapped[Optional[str]] = mapped_column(Text, nullable=True)

    aadhaar_last_four: Mapped[Optional[str]] = mapped_column(String(4), nullable=True)
    is_aadhaar_verified: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)

    profile_photo_url: Mapped[Optional[str]] = mapped_column(String(512), nullable=True)

    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utc_now, nullable=False)
    updated_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utc_now, onupdate=utc_now, nullable=False)

    # Relationships
    user: Mapped["User"] = relationship("User", back_populates="artisan_profile")

    def __repr__(self) -> str:
        return f"<ArtisanProfile(id={self.id}, user_id={self.user_id}, craft='{self.craft_specialty}')>"
