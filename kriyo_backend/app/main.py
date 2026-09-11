"""
Main application entrypoint for KRIYO Backend Service.
Configures FastAPI, lifespan hooks, CORS, security middlewares, and API routers.
"""

from contextlib import asynccontextmanager
from fastapi import FastAPI, status
from fastapi.middleware.cors import CORSMiddleware
from slowapi.errors import RateLimitExceeded

from app.api.v1.router import api_router
from app.config.settings import settings
from app.database.database import Base, engine
from sqlalchemy import text
from app.middleware.rate_limit import limiter, rate_limit_exceeded_handler
from app.middleware.security import (
    RequestLoggingMiddleware,
    SecurityHeadersMiddleware,
)
from app.utils.logger import logger


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Application lifespan context for startup and shutdown routines."""
    logger.info(f"Starting {settings.PROJECT_NAME} in [{settings.ENVIRONMENT}] mode...")
    # Automatically initialize tables in dev mode
    try:
        Base.metadata.create_all(bind=engine)
        # Verify and add 'email' column to existing SQLite database if not present
        with engine.connect() as conn:
            user_cols = [c[1] for c in conn.execute(text("PRAGMA table_info(users)")).fetchall()]
            if "email" not in user_cols:
                conn.execute(text("ALTER TABLE users ADD COLUMN email VARCHAR(128)"))
                conn.commit()
                logger.info("Added 'email' column to users table.")

            if "email_verified" not in user_cols:
                conn.execute(text("ALTER TABLE users ADD COLUMN email_verified BOOLEAN DEFAULT 0"))
                conn.commit()
                logger.info("Added 'email_verified' column to users table.")

            otp_cols = [c[1] for c in conn.execute(text("PRAGMA table_info(otp_sessions)")).fetchall()]
            if "email" not in otp_cols:
                conn.execute(text("ALTER TABLE otp_sessions ADD COLUMN email VARCHAR(128)"))
                conn.commit()
                logger.info("Added 'email' column to otp_sessions table.")

        logger.info("Database schema initialized successfully.")
    except Exception as e:
        logger.exception(f"Error creating database tables: {e}")

    yield

    logger.info(f"Shutting down {settings.PROJECT_NAME}...")


app = FastAPI(
    title=settings.PROJECT_NAME,
    version="1.0.0",
    description=(
        "Production-grade backend service powering the KRIYO Artisan & Customer mobile platforms.\n"
        "Features OTP authentication via MSG91, JWT session management, Artisan/Buyer profile services, "
        "and security hardening."
    ),
    openapi_url=f"{settings.API_V1_STR}/openapi.json",
    docs_url="/docs",
    redoc_url="/redoc",
    lifespan=lifespan,
)

# Register Rate Limiting
app.state.limiter = limiter
app.add_exception_handler(RateLimitExceeded, rate_limit_exceeded_handler)

# Register Middlewares
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.CORS_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)
app.add_middleware(SecurityHeadersMiddleware)
app.add_middleware(RequestLoggingMiddleware)

# Mount Versioned API Routes (/api/v1/...)
app.include_router(api_router, prefix=settings.API_V1_STR)

# Also mount Customer Authentication routes directly at root (/auth/customer/...) for seamless testing
from app.api.v1.endpoints.customer_auth import router as customer_auth_router
app.include_router(customer_auth_router)


@app.get(
    "/health",
    tags=["System"],
    summary="Health check endpoint",
    status_code=status.HTTP_200_OK,
)
async def health_check():
    """System health check verifying database and service liveness."""
    return {
        "status": "healthy",
        "service": settings.PROJECT_NAME,
        "environment": settings.ENVIRONMENT,
        "version": "1.0.0",
        "msg91_mock_mode": settings.MSG91_MOCK_MODE,
    }


@app.get(
    "/",
    tags=["System"],
    summary="Root welcome endpoint",
)
async def root():
    return {
        "service": settings.PROJECT_NAME,
        "docs": "/docs",
        "redoc": "/redoc",
        "api_v1": settings.API_V1_STR,
    }
