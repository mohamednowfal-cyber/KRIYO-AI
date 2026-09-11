"""
Customer Email OTP Authentication Endpoints.
Provides dedicated SMTP-based email OTP verification exclusively for Customers:
- POST /auth/customer/send-email-otp
- POST /auth/customer/verify-email-otp
- POST /auth/customer/resend-email-otp

Secured with cryptographic OTP generation (secrets), salted hashing,
5-minute TTL, max 5 attempts, and 60s resend cooldown.
"""

import secrets
from datetime import datetime, timedelta, timezone
from fastapi import APIRouter, Depends, HTTPException, Request, status
from fastapi.responses import JSONResponse
from sqlalchemy.orm import Session

from app.auth.redis_service import redis_otp_service
from app.auth.session_service import session_service
from app.auth.token_service import token_service
from app.config.security import get_hash, verify_hash
from app.config.settings import settings
from app.database.session import get_db
from app.middleware.rate_limit import limiter
from app.models.otp_session import OtpSession
from app.schemas.customer_auth import (
    CustomerEmailOtpResendRequest,
    CustomerEmailOtpSendRequest,
    CustomerEmailOtpSendResponse,
    CustomerEmailOtpVerifyRequest,
    CustomerEmailOtpVerifyResponse,
)
from app.schemas.user import UserResponse
from app.services.email_service import email_service
from app.utils.logger import logger

router = APIRouter(prefix="/auth/customer", tags=["Customer Authentication"])

EMAIL_OTP_EXPIRY_MINUTES = getattr(settings, "EMAIL_OTP_EXPIRY_MINUTES", 5)
EMAIL_OTP_RESEND_COOLDOWN_SECONDS = getattr(settings, "EMAIL_OTP_RESEND_COOLDOWN_SECONDS", 60)
EMAIL_OTP_MAX_ATTEMPTS = getattr(settings, "EMAIL_OTP_MAX_ATTEMPTS", 5)


def generate_secure_otp() -> str:
    """Generate cryptographically secure 6-digit numeric OTP using secrets."""
    return f"{secrets.randbelow(900000) + 100000}"


@router.post(
    "/send-email-otp",
    response_model=CustomerEmailOtpSendResponse,
    summary="Send Email Verification OTP to Customer",
    description="Generates a cryptographically secure 6-digit OTP and dispatches it via SMTP email. Enforces a 60-second cooldown.",
)
@limiter.limit(settings.AUTH_RATE_LIMIT_PER_MINUTE)
async def send_customer_email_otp(
    request: Request,
    payload: CustomerEmailOtpSendRequest,
    db: Session = Depends(get_db),
):
    email = payload.email.strip().lower()
    cooldown_key = f"email_cooldown:{email}"

    # 1. Check resend cooldown
    remaining_cooldown = redis_otp_service.check_resend_cooldown(cooldown_key)
    if remaining_cooldown is not None and remaining_cooldown > 0:
        return JSONResponse(
            status_code=status.HTTP_429_TOO_MANY_REQUESTS,
            content={
                "success": False,
                "detail": f"Please wait {remaining_cooldown} seconds before requesting another verification code.",
                "message": f"Please wait {remaining_cooldown} seconds before requesting another verification code.",
                "remaining_cooldown": remaining_cooldown,
            },
        )

    # 2. Invalidate any previous unverified OTP sessions for this email
    db.query(OtpSession).filter(
        OtpSession.email == email,
        OtpSession.is_verified.is_(False),
    ).update({"attempts": 99})
    db.commit()

    # 3. Generate secure 6-digit OTP
    otp_code = generate_secure_otp()
    otp_hash = get_hash(otp_code)
    expires_at = datetime.now(timezone.utc) + timedelta(minutes=EMAIL_OTP_EXPIRY_MINUTES)

    # 4. Create and persist OTP session
    session = OtpSession(
        email=email,
        otp_code_hash=otp_hash,
        role="customer",
        purpose="email_verification",
        expires_at=expires_at,
        max_attempts=EMAIL_OTP_MAX_ATTEMPTS,
    )
    db.add(session)
    db.commit()
    db.refresh(session)

    # 5. Set resend cooldown
    redis_otp_service.set_resend_cooldown(
        phone=cooldown_key,
        seconds=EMAIL_OTP_RESEND_COOLDOWN_SECONDS,
    )

    # 6. Dispatch email via SMTP service
    try:
        await email_service.send_otp_email(
            to_email=email,
            otp_code=otp_code,
            expiry_minutes=EMAIL_OTP_EXPIRY_MINUTES,
        )
    except RuntimeError as e:
        logger.error(f"Failed to dispatch customer OTP email: {e}")
        return JSONResponse(
            status_code=status.HTTP_502_BAD_GATEWAY,
            content={
                "success": False,
                "detail": str(e),
                "message": str(e),
            },
        )

    return CustomerEmailOtpSendResponse(
        success=True,
        message="Verification code sent to your email",
        expires_in=EMAIL_OTP_EXPIRY_MINUTES * 60,
        resend_cooldown=EMAIL_OTP_RESEND_COOLDOWN_SECONDS,
    )


@router.post(
    "/verify-email-otp",
    response_model=CustomerEmailOtpVerifyResponse,
    summary="Verify Customer Email OTP",
    description="Validates the 6-digit OTP submitted by the customer. On success, marks email as verified and returns JWT tokens.",
)
@limiter.limit(settings.AUTH_RATE_LIMIT_PER_MINUTE)
async def verify_customer_email_otp(
    request: Request,
    payload: CustomerEmailOtpVerifyRequest,
    db: Session = Depends(get_db),
):
    email = payload.email.strip().lower()
    otp_code = payload.otp.strip()

    # Find the latest unverified OTP session for this email
    session = (
        db.query(OtpSession)
        .filter(
            OtpSession.email == email,
            OtpSession.is_verified.is_(False),
        )
        .order_by(OtpSession.created_at.desc())
        .first()
    )

    if not session:
        return JSONResponse(
            status_code=status.HTTP_400_BAD_REQUEST,
            content={
                "success": False,
                "verified": False,
                "message": "Invalid or expired verification code",
                "detail": "Invalid or expired verification code",
            },
        )

    # Check if session has expired
    if session.is_expired():
        return JSONResponse(
            status_code=status.HTTP_400_BAD_REQUEST,
            content={
                "success": False,
                "verified": False,
                "message": "Invalid or expired verification code",
                "detail": "Verification code has expired. Please request a new one.",
            },
        )

    # Check max attempts
    if session.attempts >= session.max_attempts:
        return JSONResponse(
            status_code=status.HTTP_400_BAD_REQUEST,
            content={
                "success": False,
                "verified": False,
                "message": "Maximum verification attempts exceeded. Please request a new code.",
                "detail": "Maximum verification attempts exceeded. Please request a new code.",
            },
        )

    # Increment attempt count
    session.attempts += 1
    db.commit()

    # Verify cryptographic hash of OTP
    is_valid = verify_hash(otp_code, session.otp_code_hash)
    if not is_valid:
        remaining = max(0, session.max_attempts - session.attempts)
        return JSONResponse(
            status_code=status.HTTP_400_BAD_REQUEST,
            content={
                "success": False,
                "verified": False,
                "message": "Invalid or expired verification code",
                "detail": f"Invalid verification code. {remaining} attempt(s) remaining.",
                "remaining_attempts": remaining,
            },
        )

    # Mark session as verified (cannot be reused)
    session.is_verified = True
    db.commit()

    # Clear cooldown key in redis
    cooldown_key = f"email_cooldown:{email}"
    redis_otp_service.clear_otp_state(cooldown_key)

    # Complete Customer account discovery / provisioning
    user, is_new_user = session_service.get_or_create_user(
        db=db,
        email=email,
        role="customer",
        full_name=payload.full_name,
        email_verified=True,
    )

    # Link session to user
    if not session.user_id:
        session.user_id = user.id
        db.commit()

    # Issue JWT credentials
    token_data = token_service.generate_tokens_for_user(user)

    return CustomerEmailOtpVerifyResponse(
        success=True,
        verified=True,
        message="Email verified successfully",
        access_token=token_data["access_token"],
        refresh_token=token_data["refresh_token"],
        token_type=token_data["token_type"],
        user=UserResponse.model_validate(user),
        is_new_user=is_new_user,
    )


@router.post(
    "/resend-email-otp",
    response_model=CustomerEmailOtpSendResponse,
    summary="Resend Email Verification OTP to Customer",
    description="Resends verification OTP to customer email subject to the 60-second cooldown.",
)
@limiter.limit(settings.AUTH_RATE_LIMIT_PER_MINUTE)
async def resend_customer_email_otp(
    request: Request,
    payload: CustomerEmailOtpResendRequest,
    db: Session = Depends(get_db),
):
    send_payload = CustomerEmailOtpSendRequest(email=payload.email)
    return await send_customer_email_otp(request=request, payload=send_payload, db=db)
