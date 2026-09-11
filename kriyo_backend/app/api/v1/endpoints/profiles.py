"""
Artisan profile management endpoints.
"""

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.auth.dependencies import get_current_active_user, get_current_artisan
from app.database.session import get_db
from app.models.artisan_profile import ArtisanProfile
from app.models.user import User
from app.schemas.profile import (
    ArtisanProfileCreate,
    ArtisanProfileResponse,
    ArtisanProfileUpdate,
)
from app.schemas.user import UserResponse
from app.utils.validators import validate_aadhaar_last_four

router = APIRouter(prefix="/profiles", tags=["Profiles"])


@router.get(
    "/artisan/me",
    response_model=ArtisanProfileResponse,
    summary="Get current artisan profile",
    description="Returns the craft and studio details for the authenticated artisan.",
)
async def get_my_artisan_profile(
    current_artisan: User = Depends(get_current_artisan),
    db: Session = Depends(get_db),
):
    profile = (
        db.query(ArtisanProfile)
        .filter(ArtisanProfile.user_id == current_artisan.id)
        .first()
    )
    if not profile:
        # Auto-create if not yet provisioned
        profile = ArtisanProfile(
            user_id=current_artisan.id,
            craft_specialty="Pottery & Terracotta",
        )
        db.add(profile)
        db.commit()
        db.refresh(profile)

    response = ArtisanProfileResponse.model_validate(profile)
    response.user = UserResponse.model_validate(current_artisan)
    return response


@router.post(
    "/artisan",
    response_model=ArtisanProfileResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Create or initialize artisan profile",
)
async def create_artisan_profile(
    payload: ArtisanProfileCreate,
    current_artisan: User = Depends(get_current_artisan),
    db: Session = Depends(get_db),
):
    existing = (
        db.query(ArtisanProfile)
        .filter(ArtisanProfile.user_id == current_artisan.id)
        .first()
    )
    if existing:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Artisan profile already exists for this account. Use PATCH to update.",
        )

    profile = ArtisanProfile(
        user_id=current_artisan.id,
        craft_specialty=payload.craft_specialty,
        studio_name=payload.studio_name,
        state=payload.state,
        district=payload.district,
        pincode=payload.pincode,
        years_of_experience=payload.years_of_experience,
        bio=payload.bio,
        heritage_story=payload.heritage_story,
        aadhaar_last_four=payload.aadhaar_last_four,
        is_aadhaar_verified=bool(payload.aadhaar_last_four and validate_aadhaar_last_four(payload.aadhaar_last_four)),
    )
    db.add(profile)
    db.commit()
    db.refresh(profile)

    response = ArtisanProfileResponse.model_validate(profile)
    response.user = UserResponse.model_validate(current_artisan)
    return response


@router.patch(
    "/artisan/me",
    response_model=ArtisanProfileResponse,
    summary="Update current artisan profile",
    description="Updates craft specialty, heritage story, studio location, or profile picture.",
)
async def update_my_artisan_profile(
    payload: ArtisanProfileUpdate,
    current_artisan: User = Depends(get_current_artisan),
    db: Session = Depends(get_db),
):
    profile = (
        db.query(ArtisanProfile)
        .filter(ArtisanProfile.user_id == current_artisan.id)
        .first()
    )
    if not profile:
        profile = ArtisanProfile(user_id=current_artisan.id)
        db.add(profile)

    if payload.craft_specialty is not None:
        profile.craft_specialty = payload.craft_specialty
    if payload.studio_name is not None:
        profile.studio_name = payload.studio_name
    if payload.state is not None:
        profile.state = payload.state
    if payload.district is not None:
        profile.district = payload.district
    if payload.pincode is not None:
        profile.pincode = payload.pincode
    if payload.years_of_experience is not None:
        profile.years_of_experience = payload.years_of_experience
    if payload.bio is not None:
        profile.bio = payload.bio
    if payload.heritage_story is not None:
        profile.heritage_story = payload.heritage_story
    if payload.profile_photo_url is not None:
        profile.profile_photo_url = payload.profile_photo_url

    if payload.aadhaar_last_four is not None:
        if validate_aadhaar_last_four(payload.aadhaar_last_four):
            profile.aadhaar_last_four = payload.aadhaar_last_four
            profile.is_aadhaar_verified = True
        else:
            raise HTTPException(
                status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
                detail="Aadhaar last 4 digits must contain exactly 4 numbers.",
            )

    db.commit()
    db.refresh(profile)

    response = ArtisanProfileResponse.model_validate(profile)
    response.user = UserResponse.model_validate(current_artisan)
    return response


@router.get(
    "/artisan/{artisan_id}",
    response_model=ArtisanProfileResponse,
    summary="Get public artisan profile",
    description="Returns public profile information of an artisan for customer showcase.",
)
async def get_public_artisan_profile(
    artisan_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    profile = (
        db.query(ArtisanProfile)
        .filter(ArtisanProfile.id == artisan_id)
        .first()
    )
    if not profile:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Artisan profile not found.",
        )

    user = db.query(User).filter(User.id == profile.user_id).first()
    response = ArtisanProfileResponse.model_validate(profile)
    if user:
        response.user = UserResponse.model_validate(user)
    return response
