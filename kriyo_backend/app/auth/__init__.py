"""Authentication package."""
from app.auth.otp_service import OtpService, otp_service
from app.auth.token_service import TokenService, token_service
from app.auth.session_service import SessionService, session_service
from app.auth.dependencies import (
    get_current_user,
    get_current_active_user,
    get_current_artisan,
    get_current_customer,
)

__all__ = [
    "OtpService",
    "otp_service",
    "TokenService",
    "token_service",
    "SessionService",
    "session_service",
    "get_current_user",
    "get_current_active_user",
    "get_current_artisan",
    "get_current_customer",
]
