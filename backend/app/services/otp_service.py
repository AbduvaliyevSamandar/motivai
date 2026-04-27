# app/services/otp_service.py
"""6-digit OTP issuance + verification stored in MongoDB.

Codes expire after 10 minutes and are single-use. Per-email rate limiting
is enforced — at most 5 codes per 10 minutes.
"""
from __future__ import annotations

import secrets
from datetime import datetime, timedelta
from typing import Optional

from app.core.security import get_password_hash, verify_password
from app.db.database import get_db


_OTP_COLL = "email_otps"
_TTL_MIN = 10
_RATE_LIMIT = 5  # max active codes per email per window


def _now() -> datetime:
    return datetime.utcnow()


def _gen_code() -> str:
    # Cryptographically random 6-digit code, leading zeros allowed.
    return f"{secrets.randbelow(1_000_000):06d}"


async def issue_otp(*, email: str, purpose: str) -> str:
    """Generate a code, persist its hash, return the plain code for delivery."""
    db = get_db()
    coll = db[_OTP_COLL]

    # Rate-limit: count active codes in the last window
    window_start = _now() - timedelta(minutes=_TTL_MIN)
    recent = await coll.count_documents(
        {"email": email, "purpose": purpose, "created_at": {"$gte": window_start}}
    )
    if recent >= _RATE_LIMIT:
        raise PermissionError("rate_limited")

    code = _gen_code()
    doc = {
        "email": email.lower(),
        "purpose": purpose,
        "code_hash": get_password_hash(code),
        "created_at": _now(),
        "expires_at": _now() + timedelta(minutes=_TTL_MIN),
        "used": False,
        "attempts": 0,
    }
    await coll.insert_one(doc)
    return code


async def verify_otp(*, email: str, purpose: str, code: str) -> bool:
    """Returns True iff the code matches the most recent unused code and
    has not expired. Marks it as used on success."""
    db = get_db()
    coll = db[_OTP_COLL]

    record = await coll.find_one(
        {"email": email.lower(), "purpose": purpose, "used": False},
        sort=[("created_at", -1)],
    )
    if not record:
        return False
    if record.get("expires_at") and record["expires_at"] < _now():
        return False
    if record.get("attempts", 0) >= 5:
        return False

    matched = verify_password(code, record["code_hash"])
    if matched:
        await coll.update_one(
            {"_id": record["_id"]},
            {"$set": {"used": True, "used_at": _now()}},
        )
    else:
        await coll.update_one(
            {"_id": record["_id"]},
            {"$inc": {"attempts": 1}},
        )
    return matched


async def has_recent_verified(*, email: str, purpose: str) -> bool:
    """True if the user verified an OTP for ``purpose`` within the last
    15 minutes — used to gate /register-with-otp etc."""
    db = get_db()
    coll = db[_OTP_COLL]
    cutoff = _now() - timedelta(minutes=15)
    rec = await coll.find_one(
        {
            "email": email.lower(),
            "purpose": purpose,
            "used": True,
            "used_at": {"$gte": cutoff},
        },
        sort=[("used_at", -1)],
    )
    return rec is not None
