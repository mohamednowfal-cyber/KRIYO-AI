"""
Authentication schemas for OTP lifecycle, token responses, and session validation.
Supports both 'phone' / 'phone_number' and 'otp' / 'otp_code' for maximum client compatibility.
"""

from typing import Optional
from pydantic import BaseModel, Field, model_validator

from app.schemas.user import UserResponse


class OtpSendRequest(BaseModel):
    phone: Optional[str] = Field(default=None, description="Mobile number (e.g. +919876543210 or 9876543210)")
    phone_number: Optional[str] = Field(default=None, description="Alternative alias for phone")
    email: Optional[str] = Field(default=None, description="Email address for Email OTP")
    role: str = Field(default="customer", description="'artisan' or 'customer'")

    @model_validator(mode="after")
    def validate_identifier_presence(self):
        if not self.phone and not self.phone_number and not self.email:
            raise ValueError("Either 'phone', 'phone_number', or 'email' must be provided")
        return self

    @property
    def target_phone(self) -> str:
        return (self.phone or self.phone_number or "").strip()

    @property
    def target_email(self) -> Optional[str]:
        return self.email.strip().lower() if self.email else None

    @property
    def target_identifier(self) -> str:
        return self.target_email or self.target_phone


class OtpSendResponse(BaseModel):
    success: bool = True
    message: str
    request_id: str
    expires_in: int = 300
    resend_available_in: int = 30
    mock_otp: Optional[str] = Field(default=None, description="Only returned in mock/development mode")


class OtpVerifyRequest(BaseModel):
    phone: Optional[str] = Field(default=None, description="Mobile number")
    phone_number: Optional[str] = Field(default=None, description="Alternative alias for phone")
    email: Optional[str] = Field(default=None, description="Email address for Email OTP")
    full_name: Optional[str] = Field(default=None, description="Optional full name captured during signup")
    otp: Optional[str] = Field(default=None, description="6-digit OTP code")
    otp_code: Optional[str] = Field(default=None, description="Alternative alias for otp")
    request_id: Optional[str] = Field(default=None, description="Request identifier from send-otp")
    role: str = Field(default="customer", description="'artisan' or 'customer'")

    @model_validator(mode="after")
    def validate_inputs(self):
        if not self.phone and not self.phone_number and not self.email:
            raise ValueError("Either 'phone', 'phone_number', or 'email' must be provided")
        if not self.otp and not self.otp_code:
            raise ValueError("Either 'otp' or 'otp_code' must be provided")
        return self

    @property
    def target_phone(self) -> str:
        return (self.phone or self.phone_number or "").strip()

    @property
    def target_email(self) -> Optional[str]:
        return self.email.strip().lower() if self.email else None

    @property
    def target_identifier(self) -> str:
        return self.target_email or self.target_phone

    @property
    def target_otp(self) -> str:
        return (self.otp or self.otp_code or "").strip()


class OtpVerifyResponse(BaseModel):
    success: bool = True
    is_new_user: bool
    user: UserResponse
    access_token: str
    refresh_token: str
    token_type: str = "bearer"


class OtpResendRequest(BaseModel):
    phone: Optional[str] = Field(default=None, description="Mobile number")
    phone_number: Optional[str] = Field(default=None, description="Alternative alias for phone")
    email: Optional[str] = Field(default=None, description="Email address for Email OTP")
    role: str = Field(default="customer", description="'artisan' or 'customer'")
    request_id: Optional[str] = Field(default=None, description="Previous request ID")

    @model_validator(mode="after")
    def validate_identifier_presence(self):
        if not self.phone and not self.phone_number and not self.email:
            raise ValueError("Either 'phone', 'phone_number', or 'email' must be provided")
        return self

    @property
    def target_phone(self) -> str:
        return (self.phone or self.phone_number or "").strip()

    @property
    def target_email(self) -> Optional[str]:
        return self.email.strip().lower() if self.email else None

    @property
    def target_identifier(self) -> str:
        return self.target_email or self.target_phone


class OtpResendResponse(BaseModel):
    success: bool = True
    message: str
    request_id: str
    expires_in: int = 300
    resend_available_in: int = 30
    mock_otp: Optional[str] = Field(default=None, description="Only returned in mock/development mode")


class TokenResponse(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"
    expires_in_seconds: int
    user: UserResponse


class RefreshTokenRequest(BaseModel):
    refresh_token: str = Field(..., description="Valid refresh token")


class LogoutResponse(BaseModel):
    success: bool = True
    message: str
