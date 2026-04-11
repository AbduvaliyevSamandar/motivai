"""Gamification service - XP, levels, badges, streaks"""
from datetime import datetime
from app.models.user import User
from app.models.progress import Progress, ProgressType
import logging

logger = logging.getLogger(__name__)

# Badge definitions
BADGES = {
    "first_plan": {
        "id": "first_plan",
        "name": "Birinchi Qadam",
        "icon": "🎯",
        "description": "Birinchi motivatsiya rejasini yaratdi"
    },
    "streak_7": {
        "id": "streak_7",
        "name": "Bir Hafta",
        "icon": "🔥",
        "description": "7 kunlik streak"
    },
    "streak_30": {
        "id": "streak_30",
        "name": "Oylik Champion",
        "icon": "👑",
        "description": "30 kunlik streak"
    },
    "streak_100": {
        "id": "streak_100",
        "name": "100 Kun Qahramoni",
        "icon": "💎",
        "description": "100 kunlik streak"
    },
    "tasks_10": {
        "id": "tasks_10",
        "name": "Ishchan",
        "icon": "⚡",
        "description": "10 ta vazifa bajardi"
    },
    "tasks_50": {
        "id": "tasks_50",
        "name": "Mashaqqatli",
        "icon": "🏅",
        "description": "50 ta vazifa bajardi"
    },
    "tasks_100": {
        "id": "tasks_100",
        "name": "Superstar",
        "icon": "⭐",
        "description": "100 ta vazifa bajardi"
    },
    "level_5": {
        "id": "level_5",
        "name": "Tajribali",
        "icon": "📚",
        "description": "5-darajaga yetdi"
    },
    "level_10": {
        "id": "level_10",
        "name": "Ekspert",
        "icon": "🎓",
        "description": "10-darajaga yetdi"
    },
    "plan_completed": {
        "id": "plan_completed",
        "name": "G'olib",
        "icon": "🏆",
        "description": "Birinchi rejani yakunladi"
    },
    "ai_user": {
        "id": "ai_user",
        "name": "AI Do'sti",
        "icon": "🤖",
        "description": "AI bilan 50 marta suhbatlashdi"
    }
}


async def award_xp(user: User, amount: int, reason: str, plan_id: str = None) -> dict:
    """Award XP to user and check for level up"""
    old_level = user.level
    user.xp += amount
    new_level = user.calculate_level()
    user.level = new_level
    level_up = new_level > old_level

    # Log progress
    await Progress(
        user_id=str(user.id),
        plan_id=plan_id,
        type=ProgressType.XP_GAINED,
        xp_earned=amount,
        details={"reason": reason, "level_up": level_up}
    ).insert()

    if level_up:
        await Progress(
            user_id=str(user.id),
            type=ProgressType.LEVEL_UP,
            xp_earned=0,
            details={"old_level": old_level, "new_level": new_level}
        ).insert()
        logger.info(f"User {user.name} leveled up: {old_level} -> {new_level}")

    # Check for badges
    new_badges = await check_and_award_badges(user)

    await user.save()

    return {
        "xp_earned": amount,
        "total_xp": user.xp,
        "level": new_level,
        "level_up": level_up,
        "new_badges": new_badges
    }


async def check_and_award_badges(user: User) -> list:
    """Check and award earned badges"""
    earned = [b["id"] for b in user.badges]
    new_badges = []

    def should_award(badge_id: str, condition: bool) -> bool:
        return condition and badge_id not in earned

    checks = [
        ("first_plan", user.total_plans_created >= 1),
        ("streak_7", user.streak >= 7),
        ("streak_30", user.streak >= 30),
        ("streak_100", user.streak >= 100),
        ("tasks_10", user.total_tasks_completed >= 10),
        ("tasks_50", user.total_tasks_completed >= 50),
        ("tasks_100", user.total_tasks_completed >= 100),
        ("level_5", user.level >= 5),
        ("level_10", user.level >= 10),
        ("plan_completed", user.total_plans_completed >= 1),
        ("ai_user", user.ai_messages_count >= 50),
    ]

    for badge_id, condition in checks:
        if should_award(badge_id, condition):
            badge = BADGES[badge_id].copy()
            badge["earned_at"] = datetime.utcnow().isoformat()
            user.badges.append(badge)
            new_badges.append(badge)

            await Progress(
                user_id=str(user.id),
                type=ProgressType.BADGE_EARNED,
                xp_earned=0,
                details={"badge": badge}
            ).insert()
            logger.info(f"Badge awarded to {user.name}: {badge_id}")

    return new_badges


async def complete_task(user: User, plan_id: str, task_id: str, study_minutes: int = 0) -> dict:
    """Mark task as completed and award XP"""
    from app.models.plan import Plan
    from datetime import datetime

    plan = await Plan.get(plan_id)
    if not plan or plan.user_id != str(user.id):
        raise ValueError("Plan not found")

    task_found = False
    xp_reward = 10

    for i, task in enumerate(plan.tasks):
        if task.get("id") == task_id or str(i) == task_id:
            if task.get("is_completed"):
                raise ValueError("Task already completed")
            plan.tasks[i]["is_completed"] = True
            plan.tasks[i]["completed_at"] = datetime.utcnow().isoformat()
            xp_reward = task.get("xp_reward", 10)
            task_found = True
            break

    if not task_found:
        raise ValueError("Task not found")

    # Update plan progress
    plan.progress = plan.calculate_progress()
    plan.total_xp_earned += xp_reward

    # Check if plan completed
    plan_completed = plan.progress >= 100
    if plan_completed and not plan.is_completed:
        plan.is_completed = True
        plan.completed_at = datetime.utcnow()
        user.total_plans_completed += 1
        xp_reward += 100  # Bonus for completing plan

    await plan.save()

    # Update user
    user.total_tasks_completed += 1
    if study_minutes > 0:
        user.total_study_minutes += study_minutes

    # Award XP
    result = await award_xp(
        user, xp_reward,
        f"Vazifa bajarildi: {task_id}",
        plan_id=plan_id
    )

    # Log progress
    await Progress(
        user_id=str(user.id),
        plan_id=plan_id,
        task_id=task_id,
        type=ProgressType.TASK_COMPLETED,
        xp_earned=xp_reward,
        details={"study_minutes": study_minutes, "plan_completed": plan_completed}
    ).insert()

    return {
        **result,
        "plan_progress": plan.progress,
        "plan_completed": plan_completed,
        "bonus_xp": 100 if plan_completed else 0
    }
