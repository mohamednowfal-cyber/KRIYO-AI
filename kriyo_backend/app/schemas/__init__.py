"""Pydantic schemas package."""
from app.schemas.auth import (
    OtpSendRequest,
    OtpSendResponse,
    OtpVerifyRequest,
    OtpVerifyResponse,
    OtpResendRequest,
    OtpResendResponse,
    TokenResponse,
    RefreshTokenRequest,
    LogoutResponse,
)
from app.schemas.user import UserBase, UserCreate, UserUpdate, UserResponse
from app.schemas.profile import (
    ArtisanProfileBase,
    ArtisanProfileCreate,
    ArtisanProfileUpdate,
    ArtisanProfileResponse,
)

__all__ = [
    "OtpSendRequest",
    "OtpSendResponse",
    "OtpVerifyRequest",
    "OtpVerifyResponse",
    "OtpResendRequest",
    "OtpResendResponse",
    "TokenResponse",
    "RefreshTokenRequest",
    "LogoutResponse",

    "UserBase",
    "UserCreate",
    "UserUpdate",
    "UserResponse",
    "ArtisanProfileBase",
    "ArtisanProfileCreate",
    "ArtisanProfileUpdate",
    "ArtisanProfileResponse",
]
