from fastapi import APIRouter, HTTPException, status, Depends
from bson import ObjectId
from app.database import get_database
from app.utils.auth import decode_token
from datetime import datetime, timedelta
import random
import logging

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/ai", tags=["AI & Motivation"])


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


# AI Motivation Quotes
MOTIVATION_QUOTES = [
    "Success is 1% inspiration and 99% perspiration. Keep going!",
    "The only way to do great work is to love what you do.",
    "Don't watch the clock; do what it does. Keep going.",
    "Believe you can and you're halfway there.",
    "The future depends on what you do today.",
    "It always seems impossible until it's done.",
    "You are braver than you believe, stronger than you seem, and smarter than you think.",
    "Don't let yesterday take up too much of today.",
    "You have unlimited potential. Start now!",
    "Every accomplishment starts with the decision to try.",
]


def get_adaptive_difficulty(user_level: int, completion_rate: float) -> str:
    """Determine adaptive task difficulty"""
    if completion_rate > 0.8:  # User is doing great, give harder tasks
        if user_level >= 5:
            return random.choice(["hard", "hard", "medium"])
        else:
            return random.choice(["medium", "medium", "easy"])
    elif completion_rate > 0.5:  # Medium performance, stay at medium
        return random.choice(["medium", "easy", "medium"])
    else:  # Low performance, give easier tasks
        return random.choice(["easy", "easy", "medium"])


def generate_recommendation_reason(user_behavior: dict) -> str:
    """Generate AI recommendation reason"""
    times_of_day = [
        "morning",
        "afternoon",
        "evening"
    ]
    
    categories = [
        "learning",
        "health",
        "productivity",
        "creativity",
        "social",
        "exercise"
    ]
    
    reasons = [
        f"Based on your {user_behavior.get('preferred_category', 'recent')} preferences, this task will help you grow.",
        "This task matches your skill level and will keep you engaged.",
        "You've been doing great! Time for a new challenge.",
        "This task pairs well with your recent activities.",
        "Perfect for your current motivation level.",
        "This aligns with your goals and interests.",
        "Our AI recommends this based on your performance patterns.",
        "This will help you maintain your winning streak!"
    ]
    
    return random.choice(reasons)


@router.get("/motivation-plan")
async def get_daily_motivation_plan(authorization: str = None, db=Depends(get_database)):
    """Get AI-generated daily motivation plan"""
    try:
        user = await get_current_user(authorization, db)
        user_id = str(user["_id"])
        
        # Get user's completed tasks for analysis
        completed = await db.progress.find({
            "user_id": user_id,
            "status": "completed"
        }).to_list(None)
        
        # Calculate completion rate
        total_assigned = await db.progress.count_documents({"user_id": user_id})
        completion_rate = (len(completed) / total_assigned * 100) if total_assigned > 0 else 0
        
        # Get user's preferred category
        preferred_category = "productivity"
        if completed:
            categories = {}
            for progress in completed:
                task = await db.tasks.find_one({"_id": ObjectId(progress["task_id"])})
                if task:
                    cat = task["category"]
                    categories[cat] = categories.get(cat, 0) + 1
            
            preferred_category = max(categories, key=categories.get) if categories else "productivity"
        
        # Determine adaptive difficulty
        adaptive_difficulty = get_adaptive_difficulty(user.get("level", 1), completion_rate)
        
        # Get recommended tasks
        available_tasks = await db.tasks.find({
            "is_active": True,
            "difficulty": adaptive_difficulty,
            "category": preferred_category if random.random() > 0.3 else None  # 70% chance to match preference
        }).limit(5).to_list(None)
        
        if not available_tasks:
            # Fallback to any available
            available_tasks = await db.tasks.find({
                "is_active": True
            }).limit(5).to_list(None)
        
        if not available_tasks:
            return {
                "message": "No tasks available yet",
                "recommendation": None,
                "motivation_quote": random.choice(MOTIVATION_QUOTES)
            }
        
        # Select random task from recommendations
        recommended_task = random.choice(available_tasks)
        
        # Generate recommendation reason
        reason = generate_recommendation_reason({
            "preferred_category": preferred_category,
            "level": user.get("level", 1)
        })
        
        # Create motivation plan record
        plan_data = {
            "user_id": user_id,
            "task_id": str(recommended_task["_id"]),
            "reason": reason,
            "difficulty_adjusted": adaptive_difficulty != "medium",
            "created_at": datetime.utcnow(),
            "valid_until": datetime.utcnow() + timedelta(hours=24)
        }
        
        await db.motivation_plans.insert_one(plan_data)
        
        return {
            "task": {
                "id": str(recommended_task["_id"]),
                "title": recommended_task["title"],
                "description": recommended_task["description"],
                "category": recommended_task["category"],
                "difficulty": recommended_task["difficulty"],
                "points_reward": recommended_task["points_reward"],
                "duration_minutes": recommended_task["duration_minutes"]
            },
            "reason": reason,
            "motivation_quote": random.choice(MOTIVATION_QUOTES),
            "difficulty_adjusted": adaptive_difficulty,
            "user_level": user.get("level", 1),
            "completion_rate": round(completion_rate, 2)
        }
    
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error generating motivation plan: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Error generating motivation plan"
        )


@router.get("/daily-insight")
async def get_daily_insight(authorization: str = None, db=Depends(get_database)):
    """Get daily insight and recommendations"""
    try:
        user = await get_current_user(authorization, db)
        user_id = str(user["_id"])
        
        # Get today's tasks
        today_start = datetime.utcnow().replace(hour=0, minute=0, second=0, microsecond=0)
        today_end = datetime.utcnow().replace(hour=23, minute=59, second=59, microsecond=999999)
        
        today_progress = await db.progress.find({
            "user_id": user_id,
            "created_at": {"$gte": today_start, "$lte": today_end}
        }).to_list(None)
        
        completed_today = len([p for p in today_progress if p["status"] == "completed"])
        total_today = len(today_progress)
        completion_rate = (completed_today / total_today * 100) if total_today > 0 else 0
        
        points_earned_today = sum([p.get("points_earned", 0) for p in today_progress if p["status"] == "completed"])
        
        # Generate motivation message
        motivation_messages = {
            0: f"Great start! Complete your first task to build momentum. 🚀",
            1: f"Awesome! You've completed {completed_today} task(s) today. Keep the streak alive!",
            3: f"Incredible focus! You're on fire today! 🔥",
            5: f"Amazing dedication! You're crushing your goals! 💪"
        }
        
        motivation_msg = motivation_messages.get(completed_today, f"Fantastic! You're on a roll with {completed_today} tasks completed!")
        
        # Get next recommended task
        next_recommendation = None
        if total_today < 3:  # Encourage more tasks
            available = await db.tasks.find({"is_active": True}).limit(1).to_list(None)
            if available:
                task = available[0]
                next_recommendation = {
                    "task_id": str(task["_id"]),
                    "title": task["title"],
                    "points_reward": task["points_reward"]
                }
        
        return {
            "date": today_start.isoformat(),
            "total_tasks": total_today,
            "completed_tasks": completed_today,
            "completion_rate": round(completion_rate, 2),
            "points_earned": points_earned_today,
            "motivation_message": motivation_msg,
            "next_recommendation": next_recommendation,
            "streak": user.get("streak", 0)
        }
    
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error getting daily insight: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Error getting daily insight"
        )


@router.get("/recommendations")
async def get_recommendations(count: int = 5, authorization: str = None, db=Depends(get_database)):
    """Get multiple AI recommendations"""
    try:
        user = await get_current_user(authorization, db)
        user_id = str(user["_id"])
        
        recommendations = []
        
        # Get multiple recommended tasks
        tasks = await db.tasks.find({"is_active": True}).limit(count).to_list(None)
        
        for task in tasks:
            reason = generate_recommendation_reason({
                "preferred_category": task.get("category", "general")
            })
            
            recommendations.append({
                "task": {
                    "id": str(task["_id"]),
                    "title": task["title"],
                    "category": task["category"],
                    "difficulty": task["difficulty"],
                    "points_reward": task["points_reward"]
                },
                "reason": reason
            })
        
        return {
            "recommendations": recommendations,
            "count": len(recommendations)
        }
    
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error getting recommendations: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Error getting recommendations"
        )


@router.get("/motivation-quote")
async def get_motivation_quote():
    """Get random motivation quote"""
    return {
        "quote": random.choice(MOTIVATION_QUOTES)
    }
