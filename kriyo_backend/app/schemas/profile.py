"""
Artisan and Customer profile schemas.
"""

from datetime import datetime
from typing import Optional
from pydantic import BaseModel, ConfigDict, Field

from app.schemas.user import UserResponse


class ArtisanProfileBase(BaseModel):
    craft_specialty: str = Field(default="Pottery & Terracotta", max_length=128)
    studio_name: Optional[str] = Field(default=None, max_length=128)
    state: Optional[str] = Field(default=None, max_length=64)
    district: Optional[str] = Field(default=None, max_length=64)
    pincode: Optional[str] = Field(default=None, max_length=16)
    years_of_experience: int = Field(default=0, ge=0)
    bio: Optional[str] = Field(default=None)
    heritage_story: Optional[str] = Field(default=None)
    aadhaar_last_four: Optional[str] = Field(default=None, min_length=4, max_length=4)


class ArtisanProfileCreate(ArtisanProfileBase):
    pass


class ArtisanProfileUpdate(BaseModel):
    craft_specialty: Optional[str] = Field(default=None, max_length=128)
    studio_name: Optional[str] = Field(default=None, max_length=128)
    state: Optional[str] = Field(default=None, max_length=64)
    district: Optional[str] = Field(default=None, max_length=64)
    pincode: Optional[str] = Field(default=None, max_length=16)
    years_of_experience: Optional[int] = Field(default=None, ge=0)
    bio: Optional[str] = None
    heritage_story: Optional[str] = None
    aadhaar_last_four: Optional[str] = Field(default=None, min_length=4, max_length=4)
    profile_photo_url: Optional[str] = None


class ArtisanProfileResponse(ArtisanProfileBase):
    model_config = ConfigDict(from_attributes=True)

    id: int
    user_id: int
    is_aadhaar_verified: bool
    profile_photo_url: Optional[str]
    created_at: datetime
    updated_at: datetime
    user: Optional[UserResponse] = None
