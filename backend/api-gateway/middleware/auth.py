"""
Authentication middleware
"""

from fastapi import Request, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from starlette.middleware.base import BaseHTTPMiddleware
from jose import jwt
from typing import Optional

from config import settings

security = HTTPBearer()


async def get_current_user(
    credentials: HTTPAuthorizationCredentials = security
) -> dict:
    """
    Get current user from JWT token
    """
    token = credentials.credentials
    
    try:
        payload = jwt.decode(
            token,
            settings.JWT_SECRET_KEY,
            algorithms=[settings.JWT_ALGORITHM]
        )
        
        if payload.get("type") != "access":
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid token type"
            )
        
        return {
            "user_id": payload.get("sub"),
            "email": payload.get("email"),
            "role": payload.get("role"),
            "constituency_id": payload.get("constituency_id")
        }
        
    except jwt.ExpiredSignatureError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token expired"
        )
    except jwt.InvalidTokenError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid token"
        )


async def get_optional_user(
    request: Request
) -> Optional[dict]:
    """
    Get current user if token is provided, otherwise return None
    """
    auth_header = request.headers.get("Authorization")
    
    if not auth_header or not auth_header.startswith("Bearer "):
        return None
    
    token = auth_header.replace("Bearer ", "")
    
    try:
        payload = jwt.decode(
            token,
            settings.JWT_SECRET_KEY,
            algorithms=[settings.JWT_ALGORITHM]
        )
        
        return {
            "user_id": payload.get("sub"),
            "email": payload.get("email"),
            "role": payload.get("role"),
            "constituency_id": payload.get("constituency_id")
        }
    except:
        return None


class AuthMiddleware(BaseHTTPMiddleware):
    """
    Authentication middleware
    """
    
    async def dispatch(self, request: Request, call_next):
        # Skip auth for public endpoints
        public_paths = [
            "/health",
            "/",
            "/api/docs",
            "/api/redoc",
            "/openapi.json",
            "/api/v1/auth/login",
            "/api/v1/auth/register"
        ]
        
        if request.url.path in public_paths:
            return await call_next(request)
        
        # Add user to request state if authenticated
        user = await get_optional_user(request)
        request.state.user = user
        
        response = await call_next(request)
        return response
