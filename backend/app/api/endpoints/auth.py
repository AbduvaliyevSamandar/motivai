# app/api/endpoints/auth.py
from fastapi import APIRouter, HTTPException, Depends
from app.schemas.auth import RegisterRequest, LoginRequest, TokenResponse, ChangePasswordRequest, UpdateProfileRequest
from app.services.user_service import create_user, get_user_by_email, get_user_by_id, safe_user_dict, update_streak_and_xp
from app.core.security import verify_password, create_access_token
from app.api.dependencies import get_current_user
from app.db.database import get_db
from bson import ObjectId
from datetime import datetime

router = APIRouter(prefix="/auth", tags=["Authentication"])

@router.post("/register", response_model=dict)
async def register(data: RegisterRequest):
    existing = await get_user_by_email(data.email)
    if existing:
        raise HTTPException(status_code=409, detail="Email already registered")
    
    user = await create_user(data.model_dump())
    token = create_access_token({"sub": user["_id"]})
    
    return {
        "success": True,
        "message": "Registration successful",
        "data": {
            "token": token,
            "token_type": "bearer",
            "user": await safe_user_dict(user)
        }
    }

@router.post("/login", response_model=dict)
async def login(data: LoginRequest):
    user = await get_user_by_email(data.email)
    if not user or not verify_password(data.password, user["hashed_password"]):
        raise HTTPException(status_code=401, detail="Invalid email or password")
    if not user.get("is_active"):
        raise HTTPException(status_code=403, detail="Account deactivated")
    
    await update_streak_and_xp(user["_id"], xp_gained=5)
    token = create_access_token({"sub": user["_id"]})
    
    updated_user = await get_user_by_id(user["_id"])
    return {
        "success": True,
        "message": "Login successful",
        "data": {
            "token": token,
            "token_type": "bearer",
            "user": await safe_user_dict(updated_user)
        }
    }

@router.get("/me", response_model=dict)
async def get_me(current_user: dict = Depends(get_current_user)):
    return {"success": True, "data": {"user": await safe_user_dict(current_user)}}

@router.put("/profile", response_model=dict)
async def update_profile(data: UpdateProfileRequest, current_user: dict = Depends(get_current_user)):
    db = get_db()
    update_data = {k: v for k, v in data.model_dump().items() if v is not None}
    update_data["updated_at"] = datetime.utcnow()
    
    if update_data:
        await db.users.update_one(
            {"_id": ObjectId(current_user["_id"])},
            {"$set": update_data}
        )
    
    user = await get_user_by_id(current_user["_id"])
    return {"success": True, "message": "Profile updated", "data": {"user": await safe_user_dict(user)}}

@router.put("/change-password", response_model=dict)
async def change_password(data: ChangePasswordRequest, current_user: dict = Depends(get_current_user)):
    if not verify_password(data.current_password, current_user["hashed_password"]):
        raise HTTPException(status_code=401, detail="Current password is incorrect")
    
    db = get_db()
    from app.core.security import get_password_hash
    await db.users.update_one(
        {"_id": ObjectId(current_user["_id"])},
        {"$set": {"hashed_password": get_password_hash(data.new_password), "updated_at": datetime.utcnow()}}
    )
    return {"success": True, "message": "Password changed successfully"}
