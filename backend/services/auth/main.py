from fastapi import FastAPI, HTTPException, Depends, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from pydantic import BaseModel, EmailStr
from typing import Optional, List
import firebase_admin
from firebase_admin import credentials, auth
import os
from datetime import datetime, timedelta
import jwt

# Initialize Firebase Admin
cred = credentials.ApplicationDefault()
firebase_admin.initialize_app(cred)

app = FastAPI(
    title="GeoDisha Auth Service",
    description="Authentication and Authorization Service",
    version="1.0.0"
)

# CORS Configuration
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Configure appropriately for production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

security = HTTPBearer()

# Models
class LoginRequest(BaseModel):
    email: EmailStr
    password: str

class RegisterRequest(BaseModel):
    email: EmailStr
    password: str
    name: str
    role: str
    phone: Optional[str] = None
    constituency_id: Optional[str] = None

class TokenResponse(BaseModel):
    access_token: str
    refresh_token: str
    user_id: str
    role: str
    expires_in: int

class UserProfile(BaseModel):
    user_id: str
    email: str
    name: str
    role: str
    constituency_id: Optional[str]
    created_at: datetime

# Helper Functions
def verify_firebase_token(credentials: HTTPAuthorizationCredentials = Depends(security)):
    """Verify Firebase ID token"""
    try:
        token = credentials.credentials
        decoded_token = auth.verify_id_token(token)
        return decoded_token
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=f"Invalid authentication token: {str(e)}"
        )

# Endpoints
@app.get("/")
def health_check():
    """Health check endpoint"""
    return {"status": "healthy", "service": "auth", "timestamp": datetime.utcnow().isoformat()}

@app.post("/api/v1/auth/register", response_model=TokenResponse)
async def register(request: RegisterRequest):
    """Register a new user"""
    try:
        # Create user in Firebase Auth
        user = auth.create_user(
            email=request.email,
            password=request.password,
            display_name=request.name,
        )
        
        # Set custom claims for role-based access
        auth.set_custom_user_claims(user.uid, {
            'role': request.role,
            'constituency_id': request.constituency_id
        })
        
        # Generate custom token
        custom_token = auth.create_custom_token(user.uid)
        
        # TODO: Store additional user data in Firestore
        
        return TokenResponse(
            access_token=custom_token.decode('utf-8'),
            refresh_token="",  # Implement refresh token logic
            user_id=user.uid,
            role=request.role,
            expires_in=3600
        )
    except auth.EmailAlreadyExistsError:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Email already exists"
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Registration failed: {str(e)}"
        )

@app.post("/api/v1/auth/login", response_model=TokenResponse)
async def login(request: LoginRequest):
    """Login user (handled client-side with Firebase, this validates)"""
    # Note: Actual login happens on client with Firebase SDK
    # This endpoint is for additional server-side validation if needed
    return {"message": "Use Firebase SDK for login"}

@app.get("/api/v1/auth/profile", response_model=UserProfile)
async def get_profile(current_user: dict = Depends(verify_firebase_token)):
    """Get current user profile"""
    try:
        user = auth.get_user(current_user['uid'])
        
        return UserProfile(
            user_id=user.uid,
            email=user.email,
            name=user.display_name or "",
            role=current_user.get('role', 'citizen'),
            constituency_id=current_user.get('constituency_id'),
            created_at=datetime.fromtimestamp(user.user_metadata.creation_timestamp / 1000)
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to fetch profile: {str(e)}"
        )

@app.post("/api/v1/auth/refresh")
async def refresh_token(current_user: dict = Depends(verify_firebase_token)):
    """Refresh authentication token"""
    try:
        # Generate new custom token
        new_token = auth.create_custom_token(current_user['uid'])
        
        return {
            "access_token": new_token.decode('utf-8'),
            "expires_in": 3600
        }
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Token refresh failed: {str(e)}"
        )

@app.post("/api/v1/auth/logout")
async def logout(current_user: dict = Depends(verify_firebase_token)):
    """Logout user (revoke tokens)"""
    try:
        auth.revoke_refresh_tokens(current_user['uid'])
        return {"message": "Successfully logged out"}
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Logout failed: {str(e)}"
        )

@app.delete("/api/v1/auth/user/{user_id}")
async def delete_user(user_id: str, current_user: dict = Depends(verify_firebase_token)):
    """Delete user account (admin only)"""
    if current_user.get('role') != 'admin':
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Admin access required"
        )
    
    try:
        auth.delete_user(user_id)
        return {"message": f"User {user_id} deleted successfully"}
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"User deletion failed: {str(e)}"
        )

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8080)
