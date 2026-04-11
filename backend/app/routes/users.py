from fastapi import APIRouter, HTTPException, status, Depends, Header
from bson import ObjectId
from app.database import get_database
from app.utils.auth import decode_token
from datetime import datetime
import logging
from typing import Optional

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/users", tags=["Users"])


async def get_current_user(authorization: str = None, db=None):
    """Get current user from token"""
    if not authorization:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Authorization header missing"
        )
    
    if not authorization.startswith("Bearer "):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid authorization header"
        )
    
    token = authorization[7:]  # Remove "Bearer "
    payload = decode_token(token)
    
    if not payload:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or expired token"
        )
    
    user_id = payload.get("sub")
    if not user_id:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid token"
        )
    
    try:
        user = await db.users.find_one({"_id": ObjectId(user_id)})
        if not user:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="User not found"
            )
        return user
    except Exception as e:
        logger.error(f"Error fetching user: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Error fetching user"
        )


@router.get("/me")
async def get_profile(authorization: Optional[str] = Header(None), db=Depends(get_database)):
    """Get current user profile"""
    try:
        user = await get_current_user(authorization, db)
        
        return {
            "id": str(user["_id"]),
            "email": user["email"],
            "username": user["username"],
            "full_name": user["full_name"],
            "role": user["role"],
            "points": user.get("points", 0),
            "level": user.get("level", 1),
            "avatar_url": user.get("avatar_url"),
            "bio": user.get("bio"),
            "total_tasks_completed": user.get("total_tasks_completed", 0),
            "streak": user.get("streak", 0),
            "created_at": user.get("created_at")
        }
    
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error getting profile: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Error getting profile"
        )


@router.get("/{user_id}")
async def get_user_profile(user_id: str, db=Depends(get_database)):
    """Get user profile by ID"""
    try:
        if not ObjectId.is_valid(user_id):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Invalid user ID"
            )
        
        user = await db.users.find_one({"_id": ObjectId(user_id)})
        if not user:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="User not found"
            )
        
        return {
            "id": str(user["_id"]),
            "username": user["username"],
            "full_name": user["full_name"],
            "points": user.get("points", 0),
            "level": user.get("level", 1),
            "avatar_url": user.get("avatar_url"),
            "bio": user.get("bio"),
            "total_tasks_completed": user.get("total_tasks_completed", 0),
            "streak": user.get("streak", 0)
        }
    
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error getting user: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Error getting user"
        )


@router.put("/me")
async def update_profile(request: dict, authorization: str = None, db=Depends(get_database)):
    """Update user profile"""
    try:
        user = await get_current_user(authorization, db)
        
        update_data = {}
        if "full_name" in request:
            update_data["full_name"] = request["full_name"]
        if "bio" in request:
            update_data["bio"] = request["bio"]
        if "avatar_url" in request:
            update_data["avatar_url"] = request["avatar_url"]
        
        update_data["updated_at"] = datetime.utcnow()
        
        await db.users.update_one(
            {"_id": user["_id"]},
            {"$set": update_data}
        )
        
        logger.info(f"User profile updated: {user['email']}")
        
        return {"message": "Profile updated successfully"}
    
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error updating profile: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Error updating profile"
        )


@router.get("")
async def list_users(skip: int = 0, limit: int = 10, db=Depends(get_database)):
    """List all users (paginated)"""
    try:
        users = []
        cursor = db.users.find().skip(skip).limit(limit)
        
        async for user in cursor:
            users.append({
                "id": str(user["_id"]),
                "username": user["username"],
                "full_name": user["full_name"],
                "points": user.get("points", 0),
                "level": user.get("level", 1),
                "avatar_url": user.get("avatar_url")
            })
        
        total = await db.users.count_documents({})
        
        return {
            "total": total,
            "skip": skip,
            "limit": limit,
            "users": users
        }
    
    except Exception as e:
        logger.error(f"Error listing users: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Error listing users"
        )


@router.get("/stats/me")
async def get_user_stats(authorization: str = None, db=Depends(get_database)):
    """Get user statistics"""
    try:
        user = await get_current_user(authorization, db)
        user_id = str(user["_id"])
        
        # Get total tasks completed
        total_tasks = await db.progress.count_documents({
            "user_id": user_id,
            "status": "completed"
        })
        
        # Get achievements
        achievements = await db.achievements.count_documents({"user_id": user_id})
        
        # Get rank
        rank = await db.users.count_documents({
            "points": {"$gt": user.get("points", 0)}
        }) + 1
        
        # Calculate completion rate
        total_progress = await db.progress.count_documents({"user_id": user_id})
        completion_rate = (total_tasks / total_progress * 100) if total_progress > 0 else 0
        
        return {
            "total_points": user.get("points", 0),
            "current_level": user.get("level", 1),
            "total_tasks_completed": user.get("total_tasks_completed", 0),
            "current_streak": user.get("streak", 0),
            "completion_rate": round(completion_rate, 2),
            "rank": rank,
            "achievements_count": achievements,
            "last_activity": user.get("updated_at")
        }
    
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error getting stats: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Error getting stats"
        )
