# app/api/endpoints/user_data.py
"""Generic per-user JSON-blob storage.

Used by the mobile client to back up "local-only" state (coins, habits,
flashcards, rituals, journey, pinned task ids, friends list, streak
freezes, etc.) so that re-installing the app doesn't wipe them.

The backend deliberately treats the blob as opaque — no schema, no
indexing. Whatever the client puts in it comes back unchanged.
"""

import json
import logging
from datetime import datetime
from typing import Any

from bson import ObjectId
from fastapi import APIRouter, Depends, HTTPException

from app.api.dependencies import get_current_user
from app.db.database import get_db

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/users/me", tags=["UserData"])

# Hard cap on the serialised blob to keep documents small and prevent
# abuse. 256 KB is plenty for the kind of state we sync.
_MAX_BLOB_BYTES = 256 * 1024


def _iso(dt: Any) -> str | None:
    if dt is None:
        return None
    if isinstance(dt, datetime):
        return dt.isoformat()
    return str(dt)


@router.get("/data", response_model=dict)
async def get_user_data(current_user: dict = Depends(get_current_user)):
    """Return the user's JSON blob (or an empty object on first call)."""
    db = get_db()
    doc = await db.users.find_one(
        {"_id": ObjectId(current_user["_id"])},
        {"user_data": 1, "user_data_updated_at": 1},
    )
    blob = (doc or {}).get("user_data") or {}
    updated_at = _iso((doc or {}).get("user_data_updated_at"))
    return {
        "success": True,
        "data": blob,
        "updated_at": updated_at,
    }


@router.put("/data", response_model=dict)
async def put_user_data(
    body: dict,
    current_user: dict = Depends(get_current_user),
):
    """Replace the user's JSON blob.

    Body must be ``{"data": <json>}``. ``<json>`` can be any JSON-
    serialisable value (object, list, string, etc.) — we store it
    verbatim. Total serialised size is capped at 256 KB.
    """
    if not isinstance(body, dict) or "data" not in body:
        raise HTTPException(
            status_code=400,
            detail="Request body must be {'data': <json>}",
        )

    blob = body["data"]
    # Make sure it's actually JSON-serialisable and check size.
    try:
        encoded = json.dumps(blob, ensure_ascii=False, default=str)
    except (TypeError, ValueError) as exc:
        raise HTTPException(
            status_code=400,
            detail=f"Body is not JSON-serialisable: {exc}",
        )

    if len(encoded.encode("utf-8")) > _MAX_BLOB_BYTES:
        raise HTTPException(
            status_code=413,
            detail=f"user_data exceeds {_MAX_BLOB_BYTES} byte cap",
        )

    now = datetime.utcnow()
    db = get_db()
    await db.users.update_one(
        {"_id": ObjectId(current_user["_id"])},
        {
            "$set": {
                "user_data": blob,
                "user_data_updated_at": now,
                "updated_at": now,
            }
        },
    )
    return {"success": True, "ok": True, "updated_at": now.isoformat()}
