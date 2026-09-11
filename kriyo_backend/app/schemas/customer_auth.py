"""
Schemas for Customer Email OTP Authentication flow.
Strictly decoupled from artisan SMS workflows.
"""

from typing import Optional
from pydantic import BaseModel, ConfigDict, EmailStr, Field, field_validator

from app.schemas.user import UserResponse


class CustomerEmailOtpSendRequest(BaseModel):
    email: EmailStr = Field(..., description="Customer email address for OTP delivery")
    full_name: Optional[str] = Field(default=None, max_length=128, description="Customer name if registering")
    password: Optional[str] = Field(default=None, description="Optional registration password field")

    @field_validator("email", mode="after")
    @classmethod
    def normalize_email(cls, v: str) -> str:
        return str(v).strip().lower()


class CustomerEmailOtpSendResponse(BaseModel):
    success: bool = Field(default=True, description="Indicates successful dispatch")
    message: str = Field(default="Verification code sent to your email")
    expires_in: int = Field(default=300, description="OTP validity in seconds (5 minutes)")
    resend_cooldown: int = Field(default=60, description="Cooldown in seconds before next resend")


class CustomerEmailOtpVerifyRequest(BaseModel):
    email: EmailStr = Field(..., description="Customer email address")
    otp: str = Field(..., min_length=6, max_length=6, description="6-digit verification code")
    full_name: Optional[str] = Field(default=None, max_length=128, description="Optional customer full name")

    @field_validator("email", mode="after")
    @classmethod
    def normalize_email(cls, v: str) -> str:
        return str(v).strip().lower()

    @field_validator("otp", mode="after")
    @classmethod
    def validate_otp_digits(cls, v: str) -> str:
        cleaned = v.strip()
        if not cleaned.isdigit() or len(cleaned) != 6:
            raise ValueError("OTP must be exactly 6 numeric digits")
        return cleaned


class CustomerEmailOtpVerifyResponse(BaseModel):
    success: bool = True
    verified: bool = True
    message: str = "Email verified successfully"
    access_token: Optional[str] = None
    refresh_token: Optional[str] = None
    token_type: Optional[str] = "bearer"
    user: Optional[UserResponse] = None
    is_new_user: bool = False


class CustomerEmailOtpResendRequest(BaseModel):
    email: EmailStr = Field(..., description="Customer email address")

    @field_validator("email", mode="after")
    @classmethod
    def normalize_email(cls, v: str) -> str:
        return str(v).strip().lower()
