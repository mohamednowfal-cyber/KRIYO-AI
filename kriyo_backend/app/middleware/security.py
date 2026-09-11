"""
Security headers and request performance logging middleware.
"""

import time
from starlette.middleware.base import BaseHTTPMiddleware
from starlette.requests import Request
from starlette.responses import Response

from app.utils.logger import logger


class SecurityHeadersMiddleware(BaseHTTPMiddleware):
    """Adds essential defense-in-depth HTTP security headers to all outbound responses."""

    async def dispatch(self, request: Request, call_next) -> Response:
        response: Response = await call_next(request)
        response.headers["X-Content-Type-Options"] = "nosniff"
        response.headers["X-Frame-Options"] = "DENY"
        response.headers["X-XSS-Protection"] = "1; mode=block"
        response.headers["Strict-Transport-Security"] = "max-age=31536000; includeSubDomains"
        response.headers["Referrer-Policy"] = "strict-origin-when-cross-origin"
        return response


class RequestLoggingMiddleware(BaseHTTPMiddleware):
    """Logs incoming HTTP requests with processing time."""

    async def dispatch(self, request: Request, call_next) -> Response:
        start_time = time.time()
        response = await call_next(request)
        process_time = (time.time() - start_time) * 1000  # milliseconds
        formatted_process_time = f"{process_time:.2f}ms"

        # Do not flood logs with health check probes
        if not request.url.path.endswith("/health"):
            logger.info(
                f"{request.method} {request.url.path} - {response.status_code} ({formatted_process_time})"
            )
        response.headers["X-Process-Time"] = formatted_process_time
        return response
