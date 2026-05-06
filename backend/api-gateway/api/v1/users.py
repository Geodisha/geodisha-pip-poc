"""Users API endpoints"""
from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel
from typing import Optional

# Optional imports for database functionality
try:
    from sqlalchemy import select
    from sqlalchemy.ext.asyncio import AsyncSession
    from core.database import get_db
    from models.database import User
    DATABASE_AVAILABLE = True
except ImportError:
    DATABASE_AVAILABLE = False
    select = None
    AsyncSession = None
    get_db = None
    User = None

from middleware.auth import get_current_user

router = APIRouter()


class UserProfileResponse(BaseModel):
    id: str
    email: str
    full_name: str
    role: str
    phone: Optional[str]
    constituency_id: Optional[str]
    constituency_name: Optional[str]
    party: Optional[str]
    state: Optional[str]
    profile_image_url: Optional[str]
    
    class Config:
        from_attributes = True


class UserProfileUpdate(BaseModel):
    full_name: Optional[str] = None
    phone: Optional[str] = None
    profile_image_url: Optional[str] = None


@router.get("/me", response_model=UserProfileResponse)
async def get_current_user_profile(
    current_user: dict = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Get current user profile"""
    try:
        result = await db.execute(
            select(User).where(User.id == current_user["user_id"])
        )
        user = result.scalar_one_or_none()
        
        if not user:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="User not found"
            )
        
        return user
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to fetch user profile: {str(e)}"
        )


@router.patch("/me", response_model=UserProfileResponse)
async def update_user_profile(
    update_data: UserProfileUpdate,
    current_user: dict = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Update current user profile"""
    try:
        result = await db.execute(
            select(User).where(User.id == current_user["user_id"])
        )
        user = result.scalar_one_or_none()
        
        if not user:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="User not found"
            )
        
        if update_data.full_name is not None:
            user.full_name = update_data.full_name
        if update_data.phone is not None:
            user.phone = update_data.phone
        if update_data.profile_image_url is not None:
            user.profile_image_url = update_data.profile_image_url
        
        await db.commit()
        await db.refresh(user)
        
        return user
        
    except Exception as e:
        await db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to update user profile: {str(e)}"
        )
