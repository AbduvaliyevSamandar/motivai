"""
Tasks Router
  GET  /tasks/               — Barcha vazifalar
  GET  /tasks/daily          — Bugungi vazifalar
  GET  /tasks/recommended    — AI tavsiyalar
  POST /tasks/complete        — Bajarish (ball, streak, yutuq)
  POST /tasks/from-chat      — Chat'dan vazifa qo'shish
  POST /tasks/               — Yangi vazifa (admin)
  PUT  /tasks/{id}           — Tahrirlash (admin)
  DELETE /tasks/{id}         — O'chirish (admin)
"""
from __future__ import annotations

import math
import random
from datetime import datetime, timezone

from bson import ObjectId
from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel

from config.database import get_db
from middleware.auth_middleware import get_authenticated_user, require_admin

router = APIRouter(prefix="/tasks", tags=["Tasks"])

UTC = timezone.utc

# ── SCHEMAS ───────────────────────────────────────────────────────────────────
class TaskCreate(BaseModel):
    title:             str
    description:       str
    category:          str = "study"
    difficulty:        str = "medium"
    points:            int = 50
    duration_minutes:  int = 30
    tags:              list[str] = []
    is_global_challenge: bool = False
    is_daily:          bool = True
    target_level_min:  int = 1
    target_level_max:  int = 20

class TaskComplete(BaseModel):
    task_id:            str
    notes:              str | None = None
    time_spent_minutes: int | None = None
    rating:             int | None = None

class ChatTasksRequest(BaseModel):
    tasks: list[dict]


# ── GET /tasks/ ───────────────────────────────────────────────────────────────
@router.get("/")
async def get_tasks(
    category: str | None = None,
    difficulty: str | None = None,
    limit: int = 20,
    current_user: dict = Depends(get_authenticated_user),
    db=Depends(get_db),
):
    filt: dict = {"is_active": True}
    if category:   filt["category"]   = category
    if difficulty: filt["difficulty"] = difficulty

    tasks = await db.tasks.find(filt).limit(limit).to_list(limit)
    return {"tasks": [_fmt(t) for t in tasks]}


# ── GET /tasks/daily ──────────────────────────────────────────────────────────
@router.get("/daily")
async def daily_tasks(
    current_user: dict = Depends(get_authenticated_user),
    db=Depends(get_db),
):
    uid   = str(current_user["_id"])
    level = current_user.get("level", 1)
    today_start = datetime.now(UTC).replace(
        hour=0, minute=0, second=0, microsecond=0)

    # Bugun bajariladigan vazifalar ID lari
    done_docs = await db.progress.find(
        {"user_id": uid, "completed_at": {"$gte": today_start}}
    ).to_list(200)
    done_ids = {d["task_id"] for d in done_docs}

    # 1. Chat'dan qo'shilgan (faqat shu foydalanuvchi)
    chat_tasks = await db.tasks.find({
        "is_active": True,
        "is_from_chat": True,
        "target_user_id": uid,
        "created_at": {"$gte": today_start},
    }).to_list(10)

    # 2. Global kundalik vazifalar
    global_tasks = await db.tasks.find({
        "is_active": True,
        "is_daily":  True,
        "is_from_chat": {"$ne": True},
        "target_level_min": {"$lte": level},
        "target_level_max": {"$gte": level},
    }).limit(7).to_list(7)

    all_tasks = chat_tasks + global_tasks
    result = []
    for t in all_tasks:
        tid  = str(t["_id"])
        done = tid in done_ids
        result.append({**_fmt(t), "is_completed": done,
                       "completed_at": None if not done else
                       next((d["completed_at"].isoformat() for d in done_docs
                             if d["task_id"] == tid), None)})

    return {"tasks": result, "completed_count": sum(1 for t in result if t["is_completed"])}


# ── GET /tasks/recommended ────────────────────────────────────────────────────
@router.get("/recommended")
async def recommended_tasks(
    limit: int = 5,
    current_user: dict = Depends(get_authenticated_user),
    db=Depends(get_db),
):
    uid   = str(current_user["_id"])
    level = current_user.get("level", 1)
    prefs = current_user.get("preferences", {})
    diff_pref = prefs.get("difficulty", "medium")

    today_start = datetime.now(UTC).replace(
        hour=0, minute=0, second=0, microsecond=0)
    done_ids = {
        d["task_id"]
        for d in await db.progress.find(
            {"user_id": uid, "completed_at": {"$gte": today_start}}
        ).to_list(200)
    }

    tasks = await db.tasks.find({
        "is_active": True,
        "target_level_min": {"$lte": level},
        "target_level_max": {"$gte": level},
    }).to_list(50)

    # Filtr va tartib
    tasks = [t for t in tasks if str(t["_id"]) not in done_ids]
    random.shuffle(tasks)

    # Afzal qiyinchilik yuqoriroq ball oladi
    diff_order = {"easy": 0, "medium": 1, "hard": 2, "expert": 3}
    target     = diff_order.get(diff_pref, 1)
    tasks.sort(key=lambda t: abs(diff_order.get(t.get("difficulty", "medium"), 1) - target))

    return {"tasks": [_fmt(t) for t in tasks[:limit]]}


# ── POST /tasks/complete ──────────────────────────────────────────────────────
@router.post("/complete")
async def complete_task(
    data: TaskComplete,
    current_user: dict = Depends(get_authenticated_user),
    db=Depends(get_db),
):
    uid = str(current_user["_id"])

    # Vazifani topish
    try:
        oid = ObjectId(data.task_id)
    except Exception:
        raise HTTPException(400, "task_id noto'g'ri format")

    task = await db.tasks.find_one({"_id": oid, "is_active": True})
    if not task:
        raise HTTPException(404, "Vazifa topilmadi")

    # Duplicate tekshirish
    today_start = datetime.now(UTC).replace(
        hour=0, minute=0, second=0, microsecond=0)
    already = await db.progress.find_one({
        "user_id": uid,
        "task_id": data.task_id,
        "completed_at": {"$gte": today_start},
    })
    if already:
        raise HTTPException(400, "Bugun allaqachon bajarilgan")

    # Ball hisoblash
    streak  = current_user.get("streak", 0)
    sb      = min(1.5, 1 + 0.05 * streak)
    diff_mult = {"easy": 1.0, "medium": 1.5, "hard": 2.5, "expert": 4.0}
    dm      = diff_mult.get(task.get("difficulty", "easy"), 1.0)
    pts_eff = int(task.get("points", 10) * sb * dm)

    now = datetime.now(UTC)

    # Progress yozuvi
    await db.progress.insert_one({
        "user_id":           uid,
        "task_id":           data.task_id,
        "task_title":        task.get("title", ""),
        "task_category":     task.get("category", "study"),
        "difficulty":        task.get("difficulty", "easy"),
        "points_earned":     pts_eff,
        "completed_at":      now,
        "time_spent_minutes":data.time_spent_minutes,
        "notes":             data.notes,
        "rating":            data.rating,
    })

    # completion_count ++
    await db.tasks.update_one({"_id": oid},
                              {"$inc": {"completion_count": 1}})

    # Foydalanuvchi yangilash
    new_pts  = current_user.get("points", 0) + pts_eff
    new_total= current_user.get("total_tasks_completed", 0) + 1
    new_streak, new_best = _calc_streak(current_user, now)
    new_level= _calc_level(new_pts)
    level_up = new_level > current_user.get("level", 1)

    # Yutuqlar
    new_achiev = _check_achievements(
        current_user, new_pts, new_total, new_streak, new_level, task)

    update = {
        "$set": {
            "points":               new_pts,
            "level":                new_level,
            "streak":               new_streak,
            "best_streak":         new_best,
            "total_tasks_completed":new_total,
            "last_active":          now,
            "last_streak_date":     now,
            "weekly_stats.tasks_completed":
                current_user.get("weekly_stats", {}).get("tasks_completed", 0) + 1,
            "weekly_stats.points_earned":
                current_user.get("weekly_stats", {}).get("points_earned", 0) + pts_eff,
        }
    }
    if new_achiev:
        update["$addToSet"] = {"achievements": {"$each": new_achiev}}

    await db.users.update_one({"_id": current_user["_id"]}, update)

    return {
        "success":        True,
        "points_earned":  pts_eff,
        "total_points":   new_pts,
        "new_level":      new_level,
        "level_up":       level_up,
        "current_streak": new_streak,
        "new_achievements":_achiev_details(new_achiev),
        "message":        f"+{pts_eff} ball! {'🎉 Yangi daraja!' if level_up else '💪 Zo\'r!'}",
    }


# ── POST /tasks/from-chat ─────────────────────────────────────────────────────
@router.post("/from-chat")
async def tasks_from_chat(
    req: ChatTasksRequest,
    current_user: dict = Depends(get_authenticated_user),
    db=Depends(get_db),
):
    uid  = str(current_user["_id"])
    now  = datetime.now(UTC)
    inserted = []
    for t in req.tasks[:5]:
        doc = {
            "title":           str(t.get("title", "Vazifa"))[:200],
            "description":     str(t.get("description", ""))[:500],
            "category":        t.get("category", "study"),
            "difficulty":      t.get("difficulty", "medium"),
            "points":          int(t.get("estimated_points", 50)),
            "duration_minutes":int(t.get("duration_minutes", 30)),
            "tags":            ["ai-generated"],
            "is_global_challenge": False,
            "is_daily":        True,
            "is_active":       True,
            "is_from_chat":    True,
            "target_user_id":  uid,
            "created_by":      uid,
            "created_at":      now,
            "completion_count":0,
            "target_level_min":1,
            "target_level_max":20,
        }
        res = await db.tasks.insert_one(doc)
        inserted.append(str(res.inserted_id))
    return {"inserted_count": len(inserted), "task_ids": inserted}


# ── ADMIN CRUD ────────────────────────────────────────────────────────────────
@router.post("/")
async def create_task(
    data: TaskCreate,
    current_user: dict = Depends(require_admin),
    db=Depends(get_db),
):
    doc = {
        **data.model_dump(),
        "is_active":       True,
        "is_from_chat":    False,
        "created_by":      str(current_user["_id"]),
        "created_at":      datetime.now(UTC),
        "completion_count":0,
    }
    res = await db.tasks.insert_one(doc)
    return {"id": str(res.inserted_id), **doc}


@router.put("/{task_id}")
async def update_task(
    task_id: str,
    data: TaskCreate,
    _: dict = Depends(require_admin),
    db=Depends(get_db),
):
    try:
        oid = ObjectId(task_id)
    except Exception:
        raise HTTPException(400, "task_id noto'g'ri")
    await db.tasks.update_one({"_id": oid}, {"$set": data.model_dump()})
    return {"success": True}


@router.delete("/{task_id}")
async def delete_task(
    task_id: str,
    _: dict = Depends(require_admin),
    db=Depends(get_db),
):
    try:
        oid = ObjectId(task_id)
    except Exception:
        raise HTTPException(400, "task_id noto'g'ri")
    await db.tasks.update_one({"_id": oid}, {"$set": {"is_active": False}})
    return {"success": True}


# ── HELPERS ───────────────────────────────────────────────────────────────────
def _fmt(t: dict) -> dict:
    t["id"] = str(t.pop("_id", ""))
    for k in ("created_at", "completed_at"):
        if k in t and hasattr(t[k], "isoformat"):
            t[k] = t[k].isoformat()
    return t


def _calc_level(pts: int) -> int:
    if pts <= 0: return 1
    return min(20, max(1, 1 + int(math.log(pts / 100 + 1, 1.5))))


def _calc_streak(user: dict, now: datetime) -> tuple[int, int]:
    streak      = user.get("streak", 0)
    best        = user.get("best_streak", 0)
    last_date   = user.get("last_streak_date")

    if last_date is None:
        return 1, max(1, best)

    if last_date.tzinfo is None:
        last_date = last_date.replace(tzinfo=UTC)

    diff = (now.date() - last_date.date()).days
    if diff == 0:    new_streak = streak  # bugun allaqachon
    elif diff == 1:  new_streak = streak + 1
    else:            new_streak = 1

    return new_streak, max(new_streak, best)


_ACHIEV_DEFS = {
    "first_step":       {"cond": lambda t, p, s, l, cat: t >= 1},
    "speed_runner":     {"cond": lambda t, p, s, l, cat: False},  # kunlik tekshirish
    "scholar":          {"cond": lambda t, p, s, l, cat: cat == "study"},
    "week_warrior":     {"cond": lambda t, p, s, l, cat: s >= 7},
    "point_master":     {"cond": lambda t, p, s, l, cat: p >= 1000},
    "level_5":          {"cond": lambda t, p, s, l, cat: l >= 5},
    "centurion":        {"cond": lambda t, p, s, l, cat: t >= 100},
    "consistency_king": {"cond": lambda t, p, s, l, cat: s >= 30},
}

def _check_achievements(user, pts, total, streak, level, task) -> list[str]:
    existing = set(user.get("achievements", []))
    cat = task.get("category", "")
    new = []
    for aid, adef in _ACHIEV_DEFS.items():
        if aid not in existing:
            try:
                if adef["cond"](total, pts, streak, level, cat):
                    new.append(aid)
            except Exception:
                pass
    return new


def _achiev_details(ids: list[str]) -> list[dict]:
    from backend.routers.ai_router import _ACHIEVEMENTS
    dmap = {a["id"]: a for a in _ACHIEVEMENTS}
    return [dmap[i] for i in ids if i in dmap]
