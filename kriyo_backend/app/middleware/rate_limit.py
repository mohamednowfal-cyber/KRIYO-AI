"""
Rate limiting middleware and utilities using SlowAPI.
Protects against brute force and denial of service attacks on auth endpoints.
"""

from slowapi import Limiter
from slowapi.util import get_remote_address
from slowapi.errors import RateLimitExceeded
from fastapi import Request, Response
from fastapi.responses import JSONResponse

from app.config.settings import settings

# Global Limiter initialized with client remote IP address
limiter = Limiter(
    key_func=get_remote_address,
    default_limits=[settings.RATE_LIMIT_PER_MINUTE],
    storage_uri="memory://",
)


def rate_limit_exceeded_handler(request: Request, exc: Exception) -> Response:
    """Custom response when client exceeds rate limit threshold."""
    detail = exc.detail if isinstance(exc, RateLimitExceeded) else str(exc)
    return JSONResponse(
        status_code=429,
        content={
            "detail": f"Rate limit exceeded: {detail}. Please wait before making further requests.",
            "error": "too_many_requests",
        },
    )
