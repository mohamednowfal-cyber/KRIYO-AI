"""
Authentication endpoints: OTP dispatch, verification, resend, JWT token issuance, and logout.
Follows the KRIYO architecture:
- POST /api/v1/auth/otp/send
- POST /api/v1/auth/otp/verify
- POST /api/v1/auth/otp/resend
- POST /api/v1/auth/logout
"""

from fastapi import APIRouter, Depends, HTTPException, Request, status
from sqlalchemy.orm import Session

from app.auth.dependencies import get_current_active_user
from app.auth.otp_service import otp_service
from app.auth.redis_service import redis_otp_service
from app.auth.session_service import session_service
from app.auth.token_service import token_service
from app.config.settings import settings
from app.database.session import get_db
from app.middleware.rate_limit import limiter
from app.models.user import User
from app.schemas.auth import (
    LogoutResponse,
    OtpResendRequest,
    OtpResendResponse,
    OtpSendRequest,
    OtpSendResponse,
    OtpVerifyRequest,
    OtpVerifyResponse,
    RefreshTokenRequest,
    TokenResponse,
)
from app.schemas.user import UserResponse
from app.utils.phone import normalize_phone_number

router = APIRouter(prefix="/auth", tags=["Authentication"])


@router.post(
    "/otp/send",
    response_model=OtpSendResponse,
    summary="Request a verification OTP via SMS",
    description="Validates rate limits and resend cooldown, generates 6-digit OTP, and dispatches via MSG91.",
)
@router.post(
    "/send-otp",
    response_model=OtpSendResponse,
    include_in_schema=False,
)
@limiter.limit(settings.AUTH_RATE_LIMIT_PER_MINUTE)
async def send_otp(
    request: Request,
    payload: OtpSendRequest,
    db: Session = Depends(get_db),
):
    email = payload.target_email
    normalized_phone = None

    if not email:
        try:
            normalized_phone = normalize_phone_number(payload.target_phone)
        except ValueError as e:
            raise HTTPException(
                status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
                detail=str(e),
            )

    # Validate role
    role = payload.role.lower()
    if role not in ["artisan", "customer"]:
        role = "customer"

    try:
        session, message, mock_otp, request_id = await otp_service.initiate_otp(
            db=db,
            phone_number=normalized_phone,
            email=email,
            role=role,
            purpose="login",
            is_resend=False,
        )
    except ValueError as e:
        err_str = str(e)
        if "SMS Provider Error" in err_str:
            raise HTTPException(
                status_code=status.HTTP_502_BAD_GATEWAY,
                detail=err_str,
            )
        raise HTTPException(
            status_code=status.HTTP_429_TOO_MANY_REQUESTS,
            detail=err_str,
        )

    return OtpSendResponse(
        success=True,
        message=message,
        request_id=request_id,
        expires_in=settings.MSG91_OTP_EXPIRY_MINUTES * 60,
        resend_available_in=settings.OTP_RESEND_COOLDOWN_SECONDS,
        mock_otp=mock_otp,
    )


@router.post(
    "/otp/verify",
    response_model=OtpVerifyResponse,
    summary="Verify OTP and obtain JWT session tokens",
    description="Validates OTP. Enforces max 5 attempts. Determines existing-user vs new-user, creates/updates session, and returns JWT tokens.",
)
@router.post(
    "/verify-otp",
    response_model=OtpVerifyResponse,
    include_in_schema=False,
)
@limiter.limit(settings.AUTH_RATE_LIMIT_PER_MINUTE)
async def verify_otp(
    request: Request,
    payload: OtpVerifyRequest,
    db: Session = Depends(get_db),
):
    email = payload.target_email
    normalized_phone = None

    if payload.target_phone:
        try:
            normalized_phone = normalize_phone_number(payload.target_phone)
        except ValueError as e:
            if not email:
                raise HTTPException(
                    status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
                    detail=str(e),
                )
            normalized_phone = payload.target_phone

    is_valid, msg, otp_session = await otp_service.verify_otp(
        db=db,
        phone_number=normalized_phone,
        email=email,
        otp_code=payload.target_otp,
        request_id=payload.request_id,
    )

    if not is_valid:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=msg,
        )

    # Provision or update user account
    user, is_new_user = session_service.get_or_create_user(
        db=db,
        phone_number=normalized_phone,
        email=email,
        role=payload.role.lower(),
        full_name=payload.full_name,
    )

    # Associate user with the verified session
    if otp_session and not otp_session.user_id:
        otp_session.user_id = user.id
        db.commit()

    # Generate JWT credentials
    token_data = token_service.generate_tokens_for_user(user)

    return OtpVerifyResponse(
        success=True,
        is_new_user=is_new_user,
        user=UserResponse.model_validate(user),
        access_token=token_data["access_token"],
        refresh_token=token_data["refresh_token"],
        token_type=token_data["token_type"],
    )


@router.post(
    "/otp/resend",
    response_model=OtpResendResponse,
    summary="Resend verification OTP",
    description="Resends OTP to the specified phone number subject to cooldown (30-60s).",
)
@limiter.limit(settings.AUTH_RATE_LIMIT_PER_MINUTE)
async def resend_otp(
    request: Request,
    payload: OtpResendRequest,
    db: Session = Depends(get_db),
):
    email = payload.target_email
    normalized_phone = None

    if not email:
        try:
            normalized_phone = normalize_phone_number(payload.target_phone)
        except ValueError as e:
            raise HTTPException(
                status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
                detail=str(e),
            )

    role = payload.role.lower()
    if role not in ["artisan", "customer"]:
        role = "customer"

    try:
        session, message, mock_otp, request_id = await otp_service.initiate_otp(
            db=db,
            phone_number=normalized_phone,
            email=email,
            role=role,
            purpose="login",
            is_resend=True,
        )
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_429_TOO_MANY_REQUESTS,
            detail=str(e),
        )

    return OtpResendResponse(
        success=True,
        message=message,
        request_id=request_id,
        expires_in=settings.MSG91_OTP_EXPIRY_MINUTES * 60,
        resend_available_in=settings.OTP_RESEND_COOLDOWN_SECONDS,
        mock_otp=mock_otp,
    )


@router.post(
    "/refresh",
    response_model=TokenResponse,
    summary="Refresh access token",
    description="Exchanges an unexpired refresh token for a newly minted access token.",
)
async def refresh_access_token(
    payload: RefreshTokenRequest,
    db: Session = Depends(get_db),
):
    decoded = token_service.verify_refresh_token(payload.refresh_token)
    if not decoded:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or expired refresh token.",
        )

    sub = decoded.get("sub")
    if sub is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or malformed refresh token payload.",
        )

    try:
        user_id = int(sub)
    except (ValueError, TypeError):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid user identifier in refresh token.",
        )

    user = db.query(User).filter(User.id == user_id).first()
    if not user or not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="User associated with refresh token is invalid or inactive.",
        )

    token_data = token_service.generate_tokens_for_user(user)

    return TokenResponse(
        access_token=token_data["access_token"],
        refresh_token=payload.refresh_token,
        token_type=token_data["token_type"],
        expires_in_seconds=token_data["expires_in_seconds"],
        user=UserResponse.model_validate(user),
    )


@router.post(
    "/logout",
    response_model=LogoutResponse,
    summary="Logout user",
    description="Invalidates current client session.",
)
async def logout(
    current_user: User = Depends(get_current_active_user),
):
    # Clear any residual temporary Redis OTP state
    identifier = current_user.phone_number or current_user.email or str(current_user.id)
    redis_otp_service.clear_otp_state(identifier)
    return LogoutResponse(
        success=True,
        message=f"User {identifier} successfully logged out.",
    )
