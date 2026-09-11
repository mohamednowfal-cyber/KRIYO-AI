"""
OTP lifecycle service handling generation, secure hashing, validation, session state,
and Redis-backed throttling/cooldowns.
"""

import secrets
from datetime import datetime, timedelta, timezone
from typing import Optional, Tuple
from sqlalchemy.orm import Session


from app.auth.redis_service import redis_otp_service
from app.config.security import get_hash, verify_hash
from app.config.settings import settings
from app.models.otp_session import OtpSession
from app.providers.email_provider import email_provider
from app.providers.msg91_provider import msg91_provider
from app.utils.logger import logger


class OtpService:
    @staticmethod
    def generate_numeric_otp(length: int = 6) -> str:
        """Generate a cryptographically random numeric string."""
        digits = "0123456789"
        return "".join(secrets.choice(digits) for _ in range(length))

    @staticmethod
    async def initiate_otp(
        db: Session,
        phone_number: Optional[str] = None,
        email: Optional[str] = None,
        role: str = "customer",
        purpose: str = "login",
        is_resend: bool = False,
    ) -> Tuple[OtpSession, str, Optional[str], str]:
        """
        Validates rate limits and cooldown, generates OTP, persists in DB and Redis,
        and dispatches via Email or MSG91 SMS.
        Returns: (OtpSession, status_message, mock_otp_if_any, request_id)
        """
        identifier = (email or phone_number or "").strip()
        if not identifier:
            raise ValueError("Either phone number or email address must be provided.")

        is_email = bool(email)

        # 1. Check resend cooldown
        remaining_cooldown = redis_otp_service.check_resend_cooldown(identifier)
        if remaining_cooldown is not None and remaining_cooldown > 0:
            raise ValueError(
                f"Please wait {remaining_cooldown} seconds before requesting another OTP."
            )

        # 2. Check hourly rate limit (e.g. 5 requests per hour)
        is_allowed, count = redis_otp_service.check_and_increment_hourly_rate(
            identifier, max_requests=settings.OTP_MAX_REQUESTS_PER_HOUR
        )
        if not is_allowed:
            raise ValueError(
                f"Maximum hourly OTP requests reached for {identifier}. Please try again later."
            )

        # 3. Invalidate any previous unverified OTP sessions in DB
        if is_email:
            db.query(OtpSession).filter(
                OtpSession.email == email,
                OtpSession.is_verified.is_(False),
            ).update({"is_verified": False, "attempts": 99})
        else:
            db.query(OtpSession).filter(
                OtpSession.phone_number == phone_number,
                OtpSession.is_verified.is_(False),
            ).update({"is_verified": False, "attempts": 99})
        db.commit()

        # 4. Generate secure 6-digit numeric OTP
        otp_code = OtpService.generate_numeric_otp(settings.MSG91_OTP_LENGTH)
        otp_hash = get_hash(otp_code)

        expires_at = datetime.now(timezone.utc) + timedelta(
            minutes=settings.MSG91_OTP_EXPIRY_MINUTES
        )

        session = OtpSession(
            phone_number=phone_number,
            email=email,
            otp_code_hash=otp_hash,
            role=role,
            purpose=purpose,
            expires_at=expires_at,
        )
        db.add(session)
        db.commit()
        db.refresh(session)

        request_id = session.session_id

        # 5. Store temporary state and set resend cooldown in Redis
        ttl_seconds = settings.MSG91_OTP_EXPIRY_MINUTES * 60
        redis_otp_service.save_otp_state(
            phone=identifier,
            request_id=request_id,
            otp_hash=otp_hash,
            role=role,
            ttl_seconds=ttl_seconds,
        )
        redis_otp_service.set_resend_cooldown(
            phone=identifier, seconds=settings.OTP_RESEND_COOLDOWN_SECONDS
        )

        # 6. Dispatch via Email or MSG91 SMS
        mock_otp: Optional[str] = None

        if is_email:
            provider_result = await email_provider.send_email_otp(email, otp_code)
            if provider_result.get("mock_otp") or settings.MSG91_MOCK_MODE:
                mock_otp = otp_code

            if mock_otp:
                message: str = f"Demo Mode Active. Your OTP is: {mock_otp}"
            else:
                message = f"OTP sent successfully to {email}" if not is_resend else f"OTP resent successfully to {email}"

            return session, message, mock_otp, request_id

        # Phone / SMS Dispatch (MSG91)
        if not phone_number:
            raise ValueError("Phone number is required for SMS OTP dispatch.")

        if is_resend:
            provider_result = await msg91_provider.resend_otp(phone_number)
        else:
            provider_result = await msg91_provider.send_otp(phone_number, otp_code)

        # Check if provider returned an error
        if provider_result.get("type") == "error":
            err_msg = provider_result.get("message", "Failed to dispatch OTP via SMS provider.")
            logger.error(f"[OTP SERVICE] Provider failure for {phone_number}: {err_msg}")
            raise ValueError(f"SMS Provider Error: {err_msg}")

        # Use real MSG91 request ID if returned
        real_req_id = provider_result.get("request_id")
        if real_req_id:
            request_id = real_req_id
            session.session_id = real_req_id
            db.commit()
            db.refresh(session)

            redis_otp_service.save_otp_state(
                phone=identifier,
                request_id=request_id,
                otp_hash=otp_hash,
                role=role,
                ttl_seconds=ttl_seconds,
            )

        if provider_result.get("mock_otp") or settings.MSG91_MOCK_MODE:
            mock_otp = otp_code

        if mock_otp:
            message = f"Demo Mode Active. Your OTP is: {mock_otp}"
        else:
            message = "OTP sent successfully via SMS" if not is_resend else "OTP resent successfully via SMS"

        return session, message, mock_otp, request_id

    @staticmethod
    async def verify_otp(
        db: Session,
        phone_number: Optional[str] = None,
        email: Optional[str] = None,
        otp_code: str = "",
        request_id: Optional[str] = None,
    ) -> Tuple[bool, str, Optional[OtpSession]]:
        """
        Validates submitted OTP using Email hash verification or MSG91 verify API,
        Redis state, and DB session.
        Enforces maximum 5 attempts.
        Returns: (is_valid, reason_or_success_message, session)
        """
        identifier = (email or phone_number or "").strip()
        if not identifier:
            return False, "No phone number or email address provided.", None

        is_email = bool(email)

        # Check attempts in Redis
        attempt_count = redis_otp_service.increment_attempt_count(identifier)
        if attempt_count > settings.OTP_MAX_VERIFY_ATTEMPTS:
            redis_otp_service.clear_otp_state(identifier)
            return (
                False,
                "Too many failed verification attempts. Please request a new OTP.",
                None,
            )

        # Find active session in DB
        query = db.query(OtpSession).filter(OtpSession.is_verified.is_(False))
        if is_email:
            query = query.filter(OtpSession.email == email)
        else:
            query = query.filter(OtpSession.phone_number == phone_number)

        if request_id:
            query = query.filter(OtpSession.session_id == request_id)

        session = query.order_by(OtpSession.created_at.desc()).first()

        if not session:
            target_desc = f"email '{email}'" if is_email else f"phone number '{phone_number}'"
            return False, f"No active OTP request found for this {target_desc}.", None

        if session.is_expired():
            redis_otp_service.clear_otp_state(identifier)
            return False, "OTP has expired. Please request a new one.", session

        if session.attempts >= session.max_attempts:
            redis_otp_service.clear_otp_state(identifier)
            return False, "Too many failed attempts. Please request a new OTP.", session

        # Increment attempt counter in DB
        session.attempts += 1
        db.commit()

        # Verify OTP
        is_match = False
        if is_email:
            # Email OTP verification against cryptographically secure hash
            is_match = verify_hash(otp_code.strip(), session.otp_code_hash)
        else:
            if not phone_number:
                return False, "Phone number is required for SMS OTP verification.", session
            # SMS OTP: MSG91 API verification with fallback
            msg91_res = await msg91_provider.verify_otp(phone_number, otp_code)
            if msg91_res.get("type") == "success":
                is_match = True
            elif msg91_res.get("code") == "418" or settings.MSG91_MOCK_MODE:
                is_match = verify_hash(otp_code.strip(), session.otp_code_hash)
            else:
                is_match = False

        if not is_match:
            remaining = max(0, session.max_attempts - session.attempts)
            return False, f"Incorrect OTP code. {remaining} attempt(s) remaining.", session

        # Mark session as verified in DB and clear temporary Redis state
        session.is_verified = True
        db.commit()
        db.refresh(session)
        redis_otp_service.clear_otp_state(identifier)

        return True, "OTP verified successfully.", session


otp_service = OtpService()
