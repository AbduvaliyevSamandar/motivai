from fastapi import APIRouter, HTTPException, status, Depends
from bson import ObjectId
from app.database import get_database
from app.utils.auth import decode_token
from datetime import datetime
import logging

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/tasks", tags=["Tasks"])


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


@router.post("/create")
async def create_task(request: dict, authorization: str = None, db=Depends(get_database)):
    """Create a new task (Admin only)"""
    try:
        user = await get_current_user(authorization, db)
        
        if user["role"] != "admin":
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Only admins can create tasks"
            )
        
        # Validate required fields
        required_fields = ["title", "description", "category", "difficulty", "points_reward", "duration_minutes"]
        if not all(f in request for f in required_fields):
            raise HTTPException(
                status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
                detail="Missing required fields"
            )
        
        task_data = {
            "title": request["title"],
            "description": request["description"],
            "category": request["category"],
            "difficulty": request["difficulty"],
            "points_reward": request["points_reward"],
            "duration_minutes": request["duration_minutes"],
            "created_by": str(user["_id"]),
            "is_active": True,
            "completion_count": 0,
            "created_at": datetime.utcnow()
        }
        
        result = await db.tasks.insert_one(task_data)
        logger.info(f"Task created: {request['title']}")
        
        return {
            "message": "Task created successfully",
            "task_id": str(result.inserted_id)
        }
    
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error creating task: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Error creating task"
        )


@router.get("")
async def list_tasks(category: str = None, difficulty: str = None, skip: int = 0, limit: int = 20, db=Depends(get_database)):
    """List all tasks"""
    try:
        query = {"is_active": True}
        
        if category:
            query["category"] = category
        if difficulty:
            query["difficulty"] = difficulty
        
        tasks = []
        cursor = db.tasks.find(query).skip(skip).limit(limit)
        
        async for task in cursor:
            tasks.append({
                "id": str(task["_id"]),
                "title": task["title"],
                "description": task["description"],
                "category": task["category"],
                "difficulty": task["difficulty"],
                "points_reward": task["points_reward"],
                "duration_minutes": task["duration_minutes"],
                "created_at": task.get("created_at")
            })
        
        total = await db.tasks.count_documents(query)
        
        return {
            "total": total,
            "skip": skip,
            "limit": limit,
            "tasks": tasks
        }
    
    except Exception as e:
        logger.error(f"Error listing tasks: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Error listing tasks"
        )


@router.get("/{task_id}")
async def get_task(task_id: str, db=Depends(get_database)):
    """Get task details"""
    try:
        if not ObjectId.is_valid(task_id):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Invalid task ID"
            )
        
        task = await db.tasks.find_one({"_id": ObjectId(task_id)})
        if not task:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Task not found"
            )
        
        return {
            "id": str(task["_id"]),
            "title": task["title"],
            "description": task["description"],
            "category": task["category"],
            "difficulty": task["difficulty"],
            "points_reward": task["points_reward"],
            "duration_minutes": task["duration_minutes"],
            "created_at": task.get("created_at"),
            "completion_count": task.get("completion_count", 0)
        }
    
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error getting task: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Error getting task"
        )


@router.put("/{task_id}")
async def update_task(task_id: str, request: dict, authorization: str = None, db=Depends(get_database)):
    """Update task (Admin only)"""
    try:
        user = await get_current_user(authorization, db)
        
        if user["role"] != "admin":
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Only admins can update tasks"
            )
        
        if not ObjectId.is_valid(task_id):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Invalid task ID"
            )
        
        update_data = {}
        if "title" in request:
            update_data["title"] = request["title"]
        if "description" in request:
            update_data["description"] = request["description"]
        if "category" in request:
            update_data["category"] = request["category"]
        if "difficulty" in request:
            update_data["difficulty"] = request["difficulty"]
        if "points_reward" in request:
            update_data["points_reward"] = request["points_reward"]
        if "duration_minutes" in request:
            update_data["duration_minutes"] = request["duration_minutes"]
        
        result = await db.tasks.update_one(
            {"_id": ObjectId(task_id)},
            {"$set": update_data}
        )
        
        if result.matched_count == 0:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Task not found"
            )
        
        logger.info(f"Task updated: {task_id}")
        
        return {"message": "Task updated successfully"}
    
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error updating task: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Error updating task"
        )


@router.delete("/{task_id}")
async def delete_task(task_id: str, authorization: str = None, db=Depends(get_database)):
    """Delete task (Admin only)"""
    try:
        user = await get_current_user(authorization, db)
        
        if user["role"] != "admin":
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Only admins can delete tasks"
            )
        
        if not ObjectId.is_valid(task_id):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Invalid task ID"
            )
        
        result = await db.tasks.delete_one({"_id": ObjectId(task_id)})
        
        if result.deleted_count == 0:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Task not found"
            )
        
        logger.info(f"Task deleted: {task_id}")
        
        return {"message": "Task deleted successfully"}
    
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error deleting task: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Error deleting task"
        )
