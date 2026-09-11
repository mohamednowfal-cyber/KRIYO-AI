"""
User schemas for request validation and API serialization.
"""

from datetime import datetime
from typing import Optional
from pydantic import BaseModel, ConfigDict, Field


class UserBase(BaseModel):
    phone_number: Optional[str] = Field(default=None, description="E.164 formatted phone number")
    email: Optional[str] = Field(default=None, description="User email address")
    role: str = Field(default="customer", description="'artisan', 'customer', or 'admin'")
    full_name: Optional[str] = Field(default=None, max_length=128)
    preferred_language: str = Field(default="en", max_length=16)


class UserCreate(UserBase):
    pass


class UserUpdate(BaseModel):
    full_name: Optional[str] = Field(default=None, max_length=128)
    preferred_language: Optional[str] = Field(default=None, max_length=16)
    is_active: Optional[bool] = None


class UserResponse(UserBase):
    model_config = ConfigDict(from_attributes=True)

    id: int
    is_active: bool
    is_verified: bool
    email_verified: bool = False
    profile_completed: bool
    created_at: datetime
    updated_at: datetime
