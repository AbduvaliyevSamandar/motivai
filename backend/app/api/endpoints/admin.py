# app/api/endpoints/admin.py
"""Lightweight maintenance endpoints. Protected by ADMIN_SECRET env var.

Use these to inspect / clean up the user table when the in-app UI isn't
enough — e.g. deleting a duplicate display name that survived the
auto-merge migration because its email differs slightly.
"""
from typing import Optional

from bson import ObjectId
from fastapi import APIRouter, Header, HTTPException, Query

from app.core.config import settings
from app.db.database import get_db


router = APIRouter(prefix="/admin", tags=["Admin"])


def _check_secret(header_value: Optional[str]) -> None:
    if not settings.ADMIN_SECRET:
        raise HTTPException(status_code=503, detail="Admin disabled")
    if header_value != settings.ADMIN_SECRET:
        raise HTTPException(status_code=401, detail="Bad admin secret")


@router.get("/users", response_model=dict)
async def list_users(
    x_admin_secret: Optional[str] = Header(default=None),
    name: Optional[str] = Query(default=None, description="Filter by name substring"),
    email: Optional[str] = Query(default=None, description="Filter by email substring"),
    limit: int = 100,
):
    _check_secret(x_admin_secret)
    db = get_db()
    query: dict = {}
    if name:
        query["name"] = {"$regex": name, "$options": "i"}
    if email:
        query["email"] = {"$regex": email, "$options": "i"}

    cursor = db.users.find(
        query,
        {
            "_id": 1, "name": 1, "email": 1, "xp": 1, "level": 1,
            "auth_provider": 1, "email_verified": 1, "created_at": 1,
            "total_tasks_completed": 1,
        },
    ).limit(limit)

    out = []
    async for u in cursor:
        out.append({
            "id": str(u["_id"]),
            "name": u.get("name"),
            "email": u.get("email"),
            "xp": u.get("xp", 0),
            "level": u.get("level", 1),
            "auth_provider": u.get("auth_provider"),
            "email_verified": u.get("email_verified", False),
            "tasks": u.get("total_tasks_completed", 0),
            "created_at": (
                u.get("created_at").isoformat()
                if u.get("created_at") else None
            ),
        })
    return {"success": True, "data": {"users": out, "count": len(out)}}


@router.delete("/users/{user_id}", response_model=dict)
async def delete_user(
    user_id: str,
    x_admin_secret: Optional[str] = Header(default=None),
):
    _check_secret(x_admin_secret)
    db = get_db()
    try:
        oid = ObjectId(user_id)
    except Exception:
        raise HTTPException(status_code=400, detail="Bad user id")

    user = await db.users.find_one({"_id": oid})
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    # Cascade: drop the user's plans, chat, progress, leaderboard entries.
    id_strs = [user_id, oid]
    for coll in ("plans", "chat_messages", "progress", "leaderboard"):
        try:
            await db[coll].delete_many({"user_id": {"$in": id_strs}})
        except Exception:
            pass
    await db.users.delete_one({"_id": oid})
    return {
        "success": True,
        "message": "User deleted",
        "data": {"id": user_id, "email": user.get("email")},
    }


@router.post("/merge-by-name", response_model=dict)
async def merge_by_name(
    name: str = Query(..., description="Display name to collapse"),
    keep: Optional[str] = Query(default=None, description="ID of the user to keep (optional, defaults to highest xp)"),
    x_admin_secret: Optional[str] = Header(default=None),
):
    """Collapse users sharing a display name into one. Useful when the
    same person has 2 entries because they used different email addresses
    (e.g. work + personal). All XP / tasks / plans get re-pointed to the
    kept user."""
    _check_secret(x_admin_secret)
    db = get_db()
    docs = []
    async for u in db.users.find({"name": name}):
        docs.append(u)
    if len(docs) < 2:
        return {"success": True, "message": f"Found {len(docs)} users — nothing to merge", "data": {}}

    if keep:
        try:
            keep_oid = ObjectId(keep)
        except Exception:
            raise HTTPException(status_code=400, detail="Bad keep id")
        winner = next((d for d in docs if d["_id"] == keep_oid), None)
        if not winner:
            raise HTTPException(status_code=404, detail="Keep id not in this name group")
    else:
        winner = max(docs, key=lambda d: (d.get("xp", 0), d.get("total_tasks_completed", 0)))

    losers = [d for d in docs if d["_id"] != winner["_id"]]
    winner_id_str = str(winner["_id"])

    extra_xp = sum(d.get("xp", 0) for d in losers)
    extra_tasks = sum(d.get("total_tasks_completed", 0) for d in losers)

    for coll in ("plans", "chat_messages", "progress", "leaderboard"):
        try:
            await db[coll].update_many(
                {"user_id": {"$in": [str(d["_id"]) for d in losers] + [d["_id"] for d in losers]}},
                {"$set": {"user_id": winner_id_str}},
            )
        except Exception:
            pass

    patch = {}
    if extra_xp:
        patch["xp"] = winner.get("xp", 0) + extra_xp
    if extra_tasks:
        patch["total_tasks_completed"] = winner.get("total_tasks_completed", 0) + extra_tasks
    if patch:
        await db.users.update_one({"_id": winner["_id"]}, {"$set": patch})

    await db.users.delete_many({"_id": {"$in": [d["_id"] for d in losers]}})

    return {
        "success": True,
        "message": f"Merged {len(losers)} into {winner.get('name')}",
        "data": {
            "kept_id": winner_id_str,
            "kept_email": winner.get("email"),
            "removed_count": len(losers),
            "removed_emails": [d.get("email") for d in losers],
            "xp_total": winner.get("xp", 0) + extra_xp,
        },
    }
