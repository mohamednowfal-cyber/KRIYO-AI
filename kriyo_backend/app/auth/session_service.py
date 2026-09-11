"""
Session orchestration service managing user account discovery/provisioning upon OTP login.
"""

from typing import Optional, Tuple
from sqlalchemy.orm import Session

from app.models.artisan_profile import ArtisanProfile
from app.models.user import User
from app.utils.logger import logger


class SessionService:
    @staticmethod
    def get_or_create_user(
        db: Session,
        phone_number: Optional[str] = None,
        email: Optional[str] = None,
        role: str = "customer",
        full_name: Optional[str] = None,
        email_verified: bool = False,
    ) -> Tuple[User, bool]:
        """
        Retrieves existing user or provisions a new user profile upon verified OTP.
        Returns: (user, is_created)
        """
        user: Optional[User] = None

        if email:
            user = db.query(User).filter(User.email == email).first()

        if not user and phone_number:
            user = db.query(User).filter(User.phone_number == phone_number).first()

        is_created = False

        if not user:
            user = User(
                phone_number=phone_number,
                email=email,
                role=role,
                full_name=full_name,
                is_active=True,
                is_verified=True,
                email_verified=email_verified or bool(email),
            )
            db.add(user)
            db.commit()
            db.refresh(user)
            is_created = True

            # If user registered as an artisan, initialize their empty artisan profile
            if role == "artisan":
                profile = ArtisanProfile(
                    user_id=user.id,
                    craft_specialty="Pottery & Terracotta",
                )
                db.add(profile)
                db.commit()

            logger.info(f"Created new {role} account for {email or phone_number} (ID: {user.id})")
        else:
            # Update verification flag, email, phone, and full name if provided
            updated = False
            if not user.is_verified:
                user.is_verified = True
                updated = True
            if (email_verified or email) and not getattr(user, "email_verified", False):
                user.email_verified = True
                updated = True
            if email and not user.email:
                user.email = email
                updated = True
            if phone_number and not user.phone_number:
                user.phone_number = phone_number
                updated = True
            if full_name and not user.full_name:
                user.full_name = full_name
                updated = True
            if updated:
                db.commit()
                db.refresh(user)

        return user, is_created


session_service = SessionService()
