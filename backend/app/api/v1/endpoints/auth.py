"""Authentication endpoints"""
from fastapi import APIRouter, HTTPException, Depends
from app.schemas.schemas import (
    RegisterRequest, LoginRequest, TokenResponse,
    RefreshRequest, ChangePasswordRequest, UpdateProfileRequest
)
from app.models.user import User
from app.core.security import (
    hash_password, verify_password,
    create_access_token, create_refresh_token,
    decode_token, get_current_user
)
from datetime import datetime

router = APIRouter()


@router.post("/register", status_code=201)
async def register(data: RegisterRequest):
    """Register new user"""
    existing = await User.find_one(User.email == data.email)
    if existing:
        raise HTTPException(status_code=409, detail="Email already registered")

    user = User(
        name=data.name,
        email=data.email,
        password_hash=hash_password(data.password),
        language=data.language,
        country=data.country
    )
    await user.insert()

    access_token = create_access_token(str(user.id))
    refresh_token = create_refresh_token(str(user.id))

    return {
        "success": True,
        "message": "Registration successful",
        "data": {
            "user": user.to_public(),
            "access_token": access_token,
            "refresh_token": refresh_token,
            "token_type": "bearer"
        }
    }


@router.post("/login")
async def login(data: LoginRequest):
    """Login user"""
    user = await User.find_one(User.email == data.email)
    if not user or not verify_password(data.password, user.password_hash):
        raise HTTPException(status_code=401, detail="Invalid credentials")

    if not user.is_active:
        raise HTTPException(status_code=403, detail="Account deactivated")

    user.update_streak()
    user.level = user.calculate_level()
    await user.save()

    access_token = create_access_token(str(user.id))
    refresh_token = create_refresh_token(str(user.id))

    return {
        "success": True,
        "message": "Login successful",
        "data": {
            "user": user.to_public(),
            "access_token": access_token,
            "refresh_token": refresh_token,
            "token_type": "bearer"
        }
    }


@router.get("/me")
async def get_me(current_user: User = Depends(get_current_user)):
    """Get current user profile"""
    return {"success": True, "data": {"user": current_user.to_public()}}


@router.put("/profile")
async def update_profile(
    data: UpdateProfileRequest,
    current_user: User = Depends(get_current_user)
):
    """Update user profile"""
    update_data = data.model_dump(exclude_none=True)
    for field, value in update_data.items():
        setattr(current_user, field, value)
    current_user.updated_at = datetime.utcnow()
    await current_user.save()

    return {
        "success": True,
        "message": "Profile updated",
        "data": {"user": current_user.to_public()}
    }


@router.post("/refresh")
async def refresh_token(data: RefreshRequest):
    """Refresh access token"""
    payload = decode_token(data.refresh_token)
    if payload.get("type") != "refresh":
        raise HTTPException(status_code=401, detail="Invalid refresh token")

    new_token = create_access_token(payload["sub"])
    return {"success": True, "data": {"access_token": new_token}}


@router.put("/change-password")
async def change_password(
    data: ChangePasswordRequest,
    current_user: User = Depends(get_current_user)
):
    """Change user password"""
    if not verify_password(data.current_password, current_user.password_hash):
        raise HTTPException(status_code=401, detail="Current password incorrect")

    current_user.password_hash = hash_password(data.new_password)
    await current_user.save()
    return {"success": True, "message": "Password changed successfully"}
