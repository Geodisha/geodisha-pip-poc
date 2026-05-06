"""
Authentication API endpoints
"""

from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from pydantic import BaseModel, EmailStr
from typing import Optional
from datetime import datetime, timedelta
from jose import jwt

from config import settings

# Optional imports for database and firebase
try:
    from core.firebase import verify_firebase_token
    FIREBASE_AVAILABLE = True
except ImportError:
    FIREBASE_AVAILABLE = False
    verify_firebase_token = None

try:
    from core.database import get_db, AsyncSession
    from models.database import User, UserRole
    from sqlalchemy import select
    DATABASE_AVAILABLE = True
except ImportError:
    DATABASE_AVAILABLE = False
    get_db = None
    AsyncSession = None
    User = None
    UserRole = None
    select = None

router = APIRouter()
security = HTTPBearer()


class LoginRequest(BaseModel):
    """Login request model"""
    firebase_token: str


class LoginResponse(BaseModel):
    """Login response model"""
    access_token: str
    refresh_token: str
    user: dict
    expires_in: int


class UserRegistration(BaseModel):
    """User registration model"""
    email: EmailStr
    phone: str
    full_name: str
    role: UserRole
    party: Optional[str] = None
    constituency_id: Optional[str] = None
    constituency_name: Optional[str] = None
    state: Optional[str] = None


def create_access_token(user_id: str, email: str, role: str) -> str:
    """Create JWT access token"""
    expires = datetime.utcnow() + timedelta(minutes=settings.JWT_ACCESS_TOKEN_EXPIRE_MINUTES)
    
    payload = {
        "sub": user_id,
        "email": email,
        "role": role,
        "exp": expires,
        "iat": datetime.utcnow(),
        "type": "access"
    }
    
    token = jwt.encode(payload, settings.JWT_SECRET_KEY, algorithm=settings.JWT_ALGORITHM)
    return token


def create_refresh_token(user_id: str) -> str:
    """Create JWT refresh token"""
    expires = datetime.utcnow() + timedelta(days=settings.JWT_REFRESH_TOKEN_EXPIRE_DAYS)
    
    payload = {
        "sub": user_id,
        "exp": expires,
        "iat": datetime.utcnow(),
        "type": "refresh"
    }
    
    token = jwt.encode(payload, settings.JWT_SECRET_KEY, algorithm=settings.JWT_ALGORITHM)
    return token


@router.post("/login", response_model=LoginResponse)
async def login(
    request: LoginRequest,
    db: AsyncSession = Depends(get_db) if DATABASE_AVAILABLE else None
):
    """
    Login with Firebase token
    """
    if not FIREBASE_AVAILABLE or not DATABASE_AVAILABLE:
        raise HTTPException(
            status_code=status.HTTP_501_NOT_IMPLEMENTED,
            detail="Authentication requires Firebase and Database services"
        )
    
    try:
        # Verify Firebase token
        decoded_token = await verify_firebase_token(request.firebase_token)
        firebase_uid = decoded_token["uid"]
        email = decoded_token.get("email")
        
        # Check if user exists
        result = await db.execute(select(User).where(User.id == firebase_uid))
        user = result.scalar_one_or_none()
        
        if not user:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="User not found. Please register first."
            )
        
        if not user.is_active:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="User account is inactive"
            )
        
        # Update last login
        user.last_login = datetime.utcnow()
        await db.commit()
        
        # Create tokens
        access_token = create_access_token(user.id, user.email, user.role.value)
        refresh_token = create_refresh_token(user.id)
        
        return LoginResponse(
            access_token=access_token,
            refresh_token=refresh_token,
            user={
                "id": user.id,
                "email": user.email,
                "full_name": user.full_name,
                "role": user.role.value,
                "constituency_id": user.constituency_id,
                "profile_image_url": user.profile_image_url
            },
            expires_in=settings.JWT_ACCESS_TOKEN_EXPIRE_MINUTES * 60
        )
        
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=str(e)
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Login failed: {str(e)}"
        )


@router.post("/register")
async def register(
    firebase_token: str,
    user_data: UserRegistration,
    db: AsyncSession = Depends(get_db) if DATABASE_AVAILABLE else None
):
    """
    Register a new user
    """
    if not FIREBASE_AVAILABLE or not DATABASE_AVAILABLE:
        raise HTTPException(
            status_code=status.HTTP_501_NOT_IMPLEMENTED,
            detail="Registration requires Firebase and Database services"
        )
    
    try:
        # Verify Firebase token
        decoded_token = await verify_firebase_token(firebase_token)
        firebase_uid = decoded_token["uid"]
        
        # Check if user already exists
        result = await db.execute(select(User).where(User.id == firebase_uid))
        existing_user = result.scalar_one_or_none()
        
        if existing_user:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="User already registered"
            )
        
        # Create new user
        new_user = User(
            id=firebase_uid,
            email=user_data.email,
            phone=user_data.phone,
            full_name=user_data.full_name,
            role=user_data.role,
            party=user_data.party,
            constituency_id=user_data.constituency_id,
            constituency_name=user_data.constituency_name,
            state=user_data.state,
            is_active=True,
            is_verified=False
        )
        
        db.add(new_user)
        await db.commit()
        await db.refresh(new_user)
        
        return {
            "message": "User registered successfully",
            "user_id": new_user.id,
            "email": new_user.email
        }
        
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=str(e)
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Registration failed: {str(e)}"
        )


@router.post("/refresh")
async def refresh_token(
    refresh_token: str,
    db: AsyncSession = Depends(get_db) if DATABASE_AVAILABLE else None
):
    """
    Refresh access token using refresh token
    """
    if not DATABASE_AVAILABLE:
        raise HTTPException(
            status_code=status.HTTP_501_NOT_IMPLEMENTED,
            detail="Token refresh requires Database service"
        )
    
    try:
        # Decode refresh token
        payload = jwt.decode(
            refresh_token,
            settings.JWT_SECRET_KEY,
            algorithms=[settings.JWT_ALGORITHM]
        )
        
        if payload.get("type") != "refresh":
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid token type"
            )
        
        user_id = payload.get("sub")
        
        # Get user
        result = await db.execute(select(User).where(User.id == user_id))
        user = result.scalar_one_or_none()
        
        if not user or not user.is_active:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid user"
            )
        
        # Create new access token
        new_access_token = create_access_token(user.id, user.email, user.role.value)
        
        return {
            "access_token": new_access_token,
            "expires_in": settings.JWT_ACCESS_TOKEN_EXPIRE_MINUTES * 60
        }
        
    except jwt.ExpiredSignatureError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Refresh token expired"
        )
    except jwt.InvalidTokenError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid refresh token"
        )
