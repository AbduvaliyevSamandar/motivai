from fastapi import APIRouter, HTTPException, status, Depends
from bson import ObjectId
from app.database import get_database
from app.utils.auth import decode_token
import logging

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/leaderboard", tags=["Leaderboard"])


async def get_current_user(authorization: str = None, db=None):
    """Get current user from token"""
    if authorization:
        token = authorization.replace("Bearer ", "")
        payload = decode_token(token)
        
        if payload:
            user_id = payload.get("sub")
            user = await db.users.find_one({"_id": ObjectId(user_id)})
            return user
    
    return None


@router.get("/global")
async def get_global_leaderboard(limit: int = 100, db=Depends(get_database)):
    """Get global leaderboard"""
    try:
        leaderboard = []
        cursor = db.users.find().sort("points", -1).limit(limit)
        
        rank = 1
        async for user in cursor:
            leaderboard.append({
                "rank": rank,
                "user_id": str(user["_id"]),
                "username": user["username"],
                "points": user.get("points", 0),
                "level": user.get("level", 1),
                "avatar_url": user.get("avatar_url"),
                "total_tasks_completed": user.get("total_tasks_completed", 0)
            })
            rank += 1
        
        return {
            "leaderboard": leaderboard,
            "total_entries": len(leaderboard)
        }
    
    except Exception as e:
        logger.error(f"Error getting leaderboard: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Error getting leaderboard"
        )


@router.get("/user-rank")
async def get_user_rank(authorization: str = None, db=Depends(get_database)):
    """Get user's position in leaderboard"""
    try:
        if not authorization:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Authorization required"
            )
        
        token = authorization.replace("Bearer ", "")
        payload = decode_token(token)
        
        if not payload:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid token"
            )
        
        user_id = payload.get("sub")
        user = await db.users.find_one({"_id": ObjectId(user_id)})
        
        if not user:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="User not found"
            )
        
        # Get user rank
        rank = await db.users.count_documents({
            "points": {"$gt": user.get("points", 0)}
        }) + 1
        
        total_users = await db.users.count_documents({})
        completion_rate = user.get("total_tasks_completed", 0)
        
        return {
            "rank": rank,
            "total_users": total_users,
            "user_id": str(user["_id"]),
            "username": user["username"],
            "points": user.get("points", 0),
            "level": user.get("level", 1),
            "completion_rate": completion_rate,
            "percentage": round((rank / total_users * 100), 2)
        }
    
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error getting user rank: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Error getting user rank"
        )


@router.get("/nearby")
async def get_nearby_users(range: int = 10, authorization: str = None, db=Depends(get_database)):
    """Get users near current user in leaderboard"""
    try:
        if not authorization:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Authorization required"
            )
        
        token = authorization.replace("Bearer ", "")
        payload = decode_token(token)
        
        if not payload:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid token"
            )
        
        user_id = payload.get("sub")
        user = await db.users.find_one({"_id": ObjectId(user_id)})
        
        if not user:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="User not found"
            )
        
        user_points = user.get("points", 0)
        
        # Get nearby users
        nearby = []
        cursor = db.users.find({
            "points": {
                "$gte": max(0, user_points - 1000),
                "$lte": user_points + 1000
            }
        }).sort("points", -1).limit(range)
        
        async for nearby_user in cursor:
            rank = await db.users.count_documents({
                "points": {"$gt": nearby_user.get("points", 0)}
            }) + 1
            
            nearby.append({
                "rank": rank,
                "user_id": str(nearby_user["_id"]),
                "username": nearby_user["username"],
                "points": nearby_user.get("points", 0),
                "level": nearby_user.get("level", 1),
                "is_current_user": str(nearby_user["_id"]) == user_id
            })
        
        return {
            "nearby_users": nearby
        }
    
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error getting nearby users: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Error getting nearby users"
        )


@router.get("/by-level/{level}")
async def get_leaderboard_by_level(level: int, db=Depends(get_database)):
    """Get leaderboard filtered by level"""
    try:
        leaderboard = []
        cursor = db.users.find({"level": level}).sort("points", -1).limit(100)
        
        rank = 1
        async for user in cursor:
            leaderboard.append({
                "rank": rank,
                "user_id": str(user["_id"]),
                "username": user["username"],
                "points": user.get("points", 0),
                "level": user.get("level", 1),
                "avatar_url": user.get("avatar_url"),
                "total_tasks_completed": user.get("total_tasks_completed", 0)
            })
            rank += 1
        
        return {
            "level": level,
            "leaderboard": leaderboard,
            "total_entries": len(leaderboard)
        }
    
    except Exception as e:
        logger.error(f"Error getting leaderboard by level: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Error getting leaderboard"
        )
