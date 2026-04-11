from fastapi import APIRouter, HTTPException, status, Depends, Body
from datetime import datetime, timedelta
from bson import ObjectId
from app.database import get_database
from app.utils.auth import hash_password, verify_password, create_access_token, create_refresh_token, decode_token
from app.models.models import UserRole
import logging

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/auth", tags=["Authentication"])


@router.post("/register")
async def register(request: dict = Body(...), db=Depends(get_database)):
    """Register a new user"""
    try:
        # Validate required fields
        if not all(k in request for k in ["email", "username", "password", "full_name"]):
            raise HTTPException(
                status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
                detail="Missing required fields"
            )
        
        email = request["email"]
        username = request["username"]
        password = request["password"]
        full_name = request["full_name"]
        
        # Check if user exists
        existing_user = await db.users.find_one({"$or": [{"email": email}, {"username": username}]})
        if existing_user:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Email or username already registered"
            )
        
        # Create new user
        user_data = {
            "email": email,
            "username": username,
            "full_name": full_name,
            "hashed_password": hash_password(password),
            "role": UserRole.STUDENT,
            "points": 0,
            "level": 1,
            "is_active": True,
            "total_tasks_completed": 0,
            "streak": 0,
            "created_at": datetime.utcnow(),
            "updated_at": datetime.utcnow()
        }
        
        result = await db.users.insert_one(user_data)
        user_id = str(result.inserted_id)
        
        logger.info(f"New user registered: {email}")
        
        return {
            "message": "User registered successfully",
            "user_id": user_id,
            "email": email,
            "username": username
        }
    
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Registration error: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Registration failed"
        )


@router.post("/login")
async def login(request: dict = Body(...), db=Depends(get_database)):
    """Login user"""
    try:
        if not all(k in request for k in ["email", "password"]):
            raise HTTPException(
                status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
                detail="Email and password required"
            )
        
        email = request["email"]
        password = request["password"]
        
        # Find user
        user = await db.users.find_one({"email": email})
        if not user:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid credentials"
            )
        
        # Verify password
        if not verify_password(password, user["hashed_password"]):
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid credentials"
            )
        
        if not user.get("is_active", True):
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="User account is inactive"
            )
        
        # Create tokens
        access_token = create_access_token({"sub": str(user["_id"])})
        refresh_token = create_refresh_token({"sub": str(user["_id"])})
        
        logger.info(f"User logged in: {email}")
        
        return {
            "access_token": access_token,
            "refresh_token": refresh_token,
            "token_type": "bearer",
            "user": {
                "id": str(user["_id"]),
                "email": user["email"],
                "username": user["username"],
                "full_name": user.get("full_name", "User"),
                "role": user.get("role", "student"),
                "points": user.get("points", 0),
                "level": user.get("level", 1),
                "avatar_url": user.get("avatar_url"),
                "bio": user.get("bio"),
                "total_tasks_completed": user.get("total_tasks_completed", 0),
                "streak": user.get("streak", 0),
                "created_at": user.get("created_at", str(datetime.utcnow()))
            }
        }
    
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Login error: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Login failed"
        )


@router.post("/refresh")
async def refresh_token(request: dict, db=Depends(get_database)):
    """Refresh access token"""
    try:
        if "refresh_token" not in request:
            raise HTTPException(
                status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
                detail="Refresh token required"
            )
        
        refresh_token_str = request["refresh_token"]
        payload = decode_token(refresh_token_str)
        
        if not payload:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid refresh token"
            )
        
        user_id = payload.get("sub")
        if not user_id:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid token payload"
            )
        
        # Verify user still exists
        user = await db.users.find_one({"_id": ObjectId(user_id)})
        if not user:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="User not found"
            )
        
        # Create new access token
        access_token = create_access_token({"sub": user_id})
        
        return {
            "access_token": access_token,
            "token_type": "bearer"
        }
    
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Token refresh error: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Token refresh failed"
        )


@router.post("/logout")
async def logout():
    """Logout user"""
    return {"message": "Logged out successfully"}


from datetime import datetime
