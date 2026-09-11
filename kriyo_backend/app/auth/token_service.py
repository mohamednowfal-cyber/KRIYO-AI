"""
JWT Token management service for generating, refreshing, and validating authentication tokens.
"""

from typing import Any, Dict, Optional
from jose import JWTError

from app.config.security import (
    create_access_token,
    create_refresh_token,
    decode_token,
)
from app.config.settings import settings
from app.models.user import User


class TokenService:
    @staticmethod
    def generate_tokens_for_user(user: User) -> Dict[str, Any]:
        """Generate a fresh pair of access and refresh tokens for an authenticated user."""
        access_token = create_access_token(
            subject=user.id,
            role=user.role,
            extra_claims={"phone": user.phone_number, "is_verified": user.is_verified},
        )
        refresh_token = create_refresh_token(
            subject=user.id,
            role=user.role,
        )
        return {
            "access_token": access_token,
            "refresh_token": refresh_token,
            "token_type": "bearer",
            "expires_in_seconds": settings.ACCESS_TOKEN_EXPIRE_MINUTES * 60,
        }

    @staticmethod
    def verify_refresh_token(token: str) -> Optional[Dict[str, Any]]:
        """Validate that a token is a legitimate, unexpired refresh token."""
        try:
            payload = decode_token(token)
            if payload.get("type") != "refresh":
                return None
            return payload
        except JWTError:
            return None


token_service = TokenService()
