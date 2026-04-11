from fastapi import APIRouter, HTTPException, status, Depends
from bson import ObjectId
from app.database import get_database
from app.utils.auth import decode_token
from datetime import datetime
import logging

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/progress", tags=["Progress"])


async def get_current_user(authorization: str = None, db=None):
    """Get current user from token"""
    if not authorization:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Authorization header missing"
        )
    
    token = authorization.replace("Bearer ", "")
    payload = decode_token(token)
    
    if not payload:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or expired token"
        )
    
    user_id = payload.get("sub")
    user = await db.users.find_one({"_id": ObjectId(user_id)})
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="User not found"
        )
    
    return user


@router.post("/start")
async def start_task(request: dict, authorization: str = None, db=Depends(get_database)):
    """Start a task"""
    try:
        user = await get_current_user(authorization, db)
        
        if "task_id" not in request:
            raise HTTPException(
                status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
                detail="task_id required"
            )
        
        task_id = request["task_id"]
        user_id = str(user["_id"])
        
        # Check if task exists
        task = await db.tasks.find_one({"_id": ObjectId(task_id)})
        if not task:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Task not found"
            )
        
        # Check if already started
        existing = await db.progress.find_one({
            "user_id": user_id,
            "task_id": task_id,
            "status": {"$in": ["in_progress", "completed"]}
        })
        
        if existing:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Task already started or completed"
            )
        
        # Create progress record
        progress_data = {
            "user_id": user_id,
            "task_id": task_id,
            "status": "in_progress",
            "started_at": datetime.utcnow(),
            "completed_at": None,
            "points_earned": 0,
            "created_at": datetime.utcnow(),
            "notes": None
        }
        
        result = await db.progress.insert_one(progress_data)
        logger.info(f"Task started by user {user_id}: {task_id}")
        
        return {
            "message": "Task started successfully",
            "progress_id": str(result.inserted_id),
            "task_id": task_id
        }
    
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error starting task: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Error starting task"
        )


@router.post("/complete")
async def complete_task(request: dict, authorization: str = None, db=Depends(get_database)):
    """Complete a task"""
    try:
        user = await get_current_user(authorization, db)
        
        if "task_id" not in request:
            raise HTTPException(
                status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
                detail="task_id required"
            )
        
        task_id = request["task_id"]
        user_id = str(user["_id"])
        notes = request.get("notes", "")
        
        # Get task
        task = await db.tasks.find_one({"_id": ObjectId(task_id)})
        if not task:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Task not found"
            )
        
        # Get progress
        progress = await db.progress.find_one({
            "user_id": user_id,
            "task_id": task_id,
            "status": "in_progress"
        })
        
        if not progress:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="No active task to complete"
            )
        
        points_earned = task.get("points_reward", 10)
        
        # Update progress
        await db.progress.update_one(
            {"_id": progress["_id"]},
            {
                "$set": {
                    "status": "completed",
                    "completed_at": datetime.utcnow(),
                    "points_earned": points_earned,
                    "notes": notes
                }
            }
        )
        
        # Update user points and stats
        await db.users.update_one(
            {"_id": user["_id"]},
            {
                "$inc": {
                    "points": points_earned,
                    "total_tasks_completed": 1,
                    "streak": 1
                },
                "$set": {"updated_at": datetime.utcnow()}
            }
        )
        
        # Check for level up
        new_user = await db.users.find_one({"_id": user["_id"]})
        points = new_user.get("points", 0)
        new_level = 1 + (points // 500)  # Level up every 500 points
        
        if new_level > new_user.get("level", 1):
            await db.users.update_one(
                {"_id": user["_id"]},
                {"$set": {"level": new_level}}
            )
            
            # Award achievement
            achievement_data = {
                "user_id": user_id,
                "title": f"Reached Level {new_level}",
                "description": f"Congratulations! You reached level {new_level}",
                "icon": "🎖️",
                "earned_at": datetime.utcnow(),
                "type": "milestone"
            }
            await db.achievements.insert_one(achievement_data)
        
        logger.info(f"Task completed by user {user_id}: {task_id}, earned {points_earned} points")
        
        return {
            "message": "Task completed successfully",
            "points_earned": points_earned,
            "new_total_points": new_user.get("points", 0) + points_earned,
            "level": new_level
        }
    
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error completing task: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Error completing task"
        )


@router.get("/user/me")
async def get_user_progress(authorization: str = None, skip: int = 0, limit: int = 20, db=Depends(get_database)):
    """Get user's progress history"""
    try:
        user = await get_current_user(authorization, db)
        user_id = str(user["_id"])
        
        user_progress = []
        cursor = db.progress.find({"user_id": user_id}).skip(skip).limit(limit).sort("created_at", -1)
        
        async for prog in cursor:
            user_progress.append({
                "id": str(prog["_id"]),
                "task_id": prog["task_id"],
                "status": prog["status"],
                "started_at": prog.get("started_at"),
                "completed_at": prog.get("completed_at"),
                "points_earned": prog.get("points_earned", 0),
                "created_at": prog.get("created_at")
            })
        
        total = await db.progress.count_documents({"user_id": user_id})
        
        return {
            "total": total,
            "skip": skip,
            "limit": limit,
            "progress": user_progress
        }
    
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error getting progress: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Error getting progress"
        )


@router.get("/stats/weekly")
async def get_weekly_stats(authorization: str = None, db=Depends(get_database)):
    """Get weekly statistics"""
    try:
        user = await get_current_user(authorization, db)
        user_id = str(user["_id"])
        
        # Get last 7 days of progress
        from datetime import timedelta
        seven_days_ago = datetime.utcnow() - timedelta(days=7)
        
        progress = await db.progress.find({
            "user_id": user_id,
            "status": "completed",
            "completed_at": {"$gte": seven_days_ago}
        }).to_list(None)
        
        # Calculate daily breakdown
        daily_breakdown = {}
        for prog in progress:
            day = prog["completed_at"].strftime("%Y-%m-%d")
            if day not in daily_breakdown:
                daily_breakdown[day] = 0
            daily_breakdown[day] += prog.get("points_earned", 0)
        
        total_points = sum(daily_breakdown.values())
        total_tasks = len(progress)
        
        return {
            "week_starting": (datetime.utcnow() - timedelta(days=7)).isoformat(),
            "tasks_completed": total_tasks,
            "total_points": total_points,
            "daily_breakdown": daily_breakdown
        }
    
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error getting weekly stats: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Error getting weekly stats"
        )


@router.get("/category-stats")
async def get_category_stats(authorization: str = None, db=Depends(get_database)):
    """Get statistics by category"""
    try:
        user = await get_current_user(authorization, db)
        user_id = str(user["_id"])
        
        # Get completed tasks with category info
        category_stats = {}
        
        progress = await db.progress.find({
            "user_id": user_id,
            "status": "completed"
        }).to_list(None)
        
        for prog in progress:
            task = await db.tasks.find_one({"_id": ObjectId(prog["task_id"])})
            if task:
                category = task["category"]
                if category not in category_stats:
                    category_stats[category] = {
                        "tasks_completed": 0,
                        "total_points": 0,
                        "last_completed": None
                    }
                
                category_stats[category]["tasks_completed"] += 1
                category_stats[category]["total_points"] += prog.get("points_earned", 0)
                
                if not category_stats[category]["last_completed"] or prog["completed_at"] > category_stats[category]["last_completed"]:
                    category_stats[category]["last_completed"] = prog["completed_at"]
        
        return {
            "categories": [
                {
                    "category": cat,
                    **stats
                } for cat, stats in category_stats.items()
            ]
        }
    
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error getting category stats: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Error getting category stats"
        )
