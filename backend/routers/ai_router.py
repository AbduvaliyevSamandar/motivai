"""
AI Router — OpenAI GPT-4o-mini asosida motivatsion chatbot
Endpointlar:
  POST /ai/chat              — Suhbat
  GET  /ai/motivation-plan   — Haftalik reja
  GET  /ai/quote             — Kunlik iqtibos
  GET  /ai/insights          — Statistika
  GET  /ai/achievements      — Yutuqlar holati
"""
from __future__ import annotations

import json
import os
import random
from datetime import datetime, timedelta
from typing import Any

from fastapi import APIRouter, Depends, HTTPException
from openai import AsyncOpenAI
from pydantic import BaseModel

from middleware.auth_middleware import get_authenticated_user
from config.database import get_db

router = APIRouter(prefix="/ai", tags=["AI"])

# ── OpenAI client ──────────────────────────────────────────────────────────────
_client: AsyncOpenAI | None = None

def get_openai() -> AsyncOpenAI:
    global _client
    if _client is None:
        key = os.getenv("OPENAI_API_KEY", "")
        if not key:
            raise HTTPException(500, "OPENAI_API_KEY sozlanmagan")
        _client = AsyncOpenAI(api_key=key)
    return _client


# ── SCHEMAS ───────────────────────────────────────────────────────────────────
class ChatRequest(BaseModel):
    message: str
    history: list[dict] = []
    user_context: dict  = {}

class TaskSuggestion(BaseModel):
    title: str
    description: str
    category: str
    difficulty: str
    duration_minutes: int
    estimated_points: int

class AddChatTasksRequest(BaseModel):
    tasks: list[dict]


# ── SYSTEM PROMPT ─────────────────────────────────────────────────────────────
def _system_prompt(user: dict) -> str:
    name   = user.get("full_name") or user.get("username", "talaba")
    level  = user.get("level", 1)
    streak = user.get("streak", 0)
    points = user.get("points", 0)
    prefs  = user.get("preferences", {})
    subjects = prefs.get("subjects", [])

    return f"""Sen MotivAI — talabalar uchun AI motivatsion assistant.

FOYDALANUVCHI MA'LUMOTLARI:
- Ism: {name}
- Daraja: {level}/20  |  Ballar: {points}  |  Streak: {streak} kun
- Qiziqish sohalari: {', '.join(subjects) if subjects else 'belgilanmagan'}

ASOSIY QOIDALAR:
1. DOIMO o'zbek tilida javob ber.
2. Motivatsion, iliqlik bilan muloqot qil. Ismini qo'llab chaqir.
3. Har bir javob 2-4 qisqa paragrafdan iborat bo'lsin (150-300 so'z).
4. Amaliy maslahatlar ber — abstrakt emas.
5. Agar vazifa tavsiya qilsang — JSON formatda "suggested_tasks" qaytarilgan bo'lishi kerak.

VAZIFA TAVSIYA QOIDASI:
Agar foydalanuvchi reja, maqsad yoki vazifa so'rasa — albatta "suggested_tasks" qaytar.
Har bir vazifada: title, description, category (study/exercise/reading/meditation/social/creative/productivity/challenge), 
difficulty (easy/medium/hard/expert), duration_minutes (15-120), estimated_points (10-200).

Foydalanuvchi holati: daraja {level}, streak {streak} kun.
Streak > 0 bo'lsa — uni yo'qotmaslik muhimligini eslatib tur.

JAVOB FORMATI (DOIM JSON):
{{
  "response": "...(o'zbek tilidagi matn)...",
  "suggested_tasks": [
    {{
      "title": "Vazifa sarlavhasi",
      "description": "Batafsil tavsif",
      "category": "study",
      "difficulty": "medium",
      "duration_minutes": 30,
      "estimated_points": 50
    }}
  ]
}}
Agar vazifa tavsiya kerak bo'lmasa — "suggested_tasks": null yoki bo'sh ro'yxat qaytar.
FAQAT VALID JSON qaytargil. Markdown, kod bloki, izoh yo'q."""


# ── POST /ai/chat ─────────────────────────────────────────────────────────────
@router.post("/chat")
async def ai_chat(
    req: ChatRequest,
    current_user: dict = Depends(get_authenticated_user),
    db = Depends(get_db),
):
    try:
        client = get_openai()
    except HTTPException:
        # Fallback — OpenAI yo'q bo'lsa
        return _fallback_response(req.message, current_user)

    # History tozalash va limitlash
    history = [
        {"role": m["role"], "content": str(m.get("content", ""))}
        for m in req.history[-8:]
        if m.get("role") in ("user", "assistant")
    ]

    messages = [
        {"role": "system", "content": _system_prompt(current_user)},
        *history,
        {"role": "user", "content": req.message},
    ]

    try:
        resp = await client.chat.completions.create(
            model="gpt-4o-mini",
            messages=messages,
            temperature=0.8,
            max_tokens=800,
            response_format={"type": "json_object"},
        )
        raw = resp.choices[0].message.content or "{}"
        data = json.loads(raw)
    except json.JSONDecodeError:
        data = {"response": raw, "suggested_tasks": None}
    except Exception as e:
        return _fallback_response(req.message, current_user, str(e))

    return {
        "response":        data.get("response", "Javob generatsiya qilishda xato."),
        "suggested_tasks": data.get("suggested_tasks") or None,
        "motivation_plan": data.get("motivation_plan"),
    }


# ── POST /tasks/from-chat ─────────────────────────────────────────────────────
# (Bu router tasks_router.py ga ham qo'shilishi mumkin)
@router.post("/add-tasks")
async def add_chat_tasks(
    req: AddChatTasksRequest,
    current_user: dict = Depends(get_authenticated_user),
    db = Depends(get_db),
):
    """AI chat'dan kelgan vazifalarni foydalanuvchi kunlik ro'yxatiga qo'shish."""
    from bson import ObjectId
    inserted = []
    for t in req.tasks[:5]:  # Maksimum 5 ta
        task_doc = {
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
            "created_by":      str(current_user["_id"]),
            "target_user_id":  str(current_user["_id"]),  # Faqat shu foydalanuvchi uchun
            "created_at":      datetime.utcnow(),
            "completion_count":0,
            "target_level_min":1,
            "target_level_max":20,
        }
        result = await db.tasks.insert_one(task_doc)
        inserted.append(str(result.inserted_id))

    return {"inserted_count": len(inserted), "task_ids": inserted}


# ── GET /ai/motivation-plan ───────────────────────────────────────────────────
@router.get("/motivation-plan")
async def motivation_plan(
    current_user: dict = Depends(get_authenticated_user),
    db = Depends(get_db),
):
    level  = current_user.get("level", 1)
    streak = current_user.get("streak", 0)
    points = current_user.get("points", 0)
    name   = current_user.get("full_name") or current_user.get("username", "")
    prefs  = current_user.get("preferences", {})
    subjects = prefs.get("subjects", [])

    # Arxetip aniqlash
    archetype = _get_archetype(current_user)

    # Haftalik jadval
    schedule = _generate_schedule(level, archetype)

    # LLM bilan boyitish (ixtiyoriy)
    personal_msg = _default_message(name, archetype, streak)
    try:
        client = get_openai()
        prompt = (
            f"'{name}' ismli talaba uchun qisqa (2 jumlali) shaxsiy motivatsion xabar yoz. "
            f"Daraja: {level}, Streak: {streak} kun, Arxetip: {archetype}. "
            f"O'zbek tilida, iliq ohangda. FAQAT matn qaytar, JSON emas."
        )
        resp = await client.chat.completions.create(
            model="gpt-4o-mini",
            messages=[{"role": "user", "content": prompt}],
            max_tokens=150,
            temperature=0.9,
        )
        personal_msg = resp.choices[0].message.content.strip()
    except Exception:
        pass

    return {
        "archetype":       archetype,
        "personal_message":personal_msg,
        "weekly_schedule": schedule,
        "focus_areas":     subjects[:3] or ["Umumiy o'quv"],
        "streak":          streak,
        "level":           level,
        "points":          points,
        "today_action":    schedule[0]["tasks"][0] if schedule else "Bitta vazifadan boshlang!",
    }


# ── GET /ai/quote ─────────────────────────────────────────────────────────────
@router.get("/quote")
async def daily_quote(current_user: dict = Depends(get_authenticated_user)):
    streak = current_user.get("streak", 0)
    level  = current_user.get("level", 1)
    archetype = _get_archetype(current_user)

    quotes = _QUOTES.get(archetype, _QUOTES["Explorer"])
    quote  = random.choice(quotes)

    return {
        "quote":    quote,
        "archetype":archetype,
        "streak":   streak,
        "level":    level,
    }


# ── GET /ai/insights ──────────────────────────────────────────────────────────
@router.get("/insights")
async def insights(
    current_user: dict = Depends(get_authenticated_user),
    db = Depends(get_db),
):
    from bson import ObjectId
    uid = current_user["_id"]

    # So'nggi 30 kunlik progress
    since = datetime.utcnow() - timedelta(days=30)
    progress = await db.progress.find(
        {"user_id": str(uid), "completed_at": {"$gte": since}}
    ).to_list(500)

    # Haftalik ballar (7 kun)
    weekly_points = [0] * 7
    today = datetime.utcnow().date()
    for p in progress:
        try:
            d = p["completed_at"].date()
            diff = (today - d).days
            if 0 <= diff < 7:
                weekly_points[6 - diff] += p.get("points_earned", 0)
        except Exception:
            pass

    # Kategoriya taqsimoti
    cat_map: dict[str, int] = {}
    for p in progress:
        cat = p.get("task_category", "other")
        cat_map[cat] = cat_map.get(cat, 0) + 1

    # Keyingi daraja
    level  = current_user.get("level", 1)
    pts    = current_user.get("points", 0)
    next_t = int(100 * (1.5 ** level - 1))
    to_next= max(0, next_t - pts)

    return {
        "total_completed":    len(progress),
        "weekly_points":      weekly_points,
        "category_breakdown": cat_map,
        "points_to_next_level": to_next,
        "current_streak":     current_user.get("streak", 0),
        "best_streak":        current_user.get("best_streak", 0),
        "level":              level,
        "points":             pts,
    }


# ── GET /ai/achievements ──────────────────────────────────────────────────────
@router.get("/achievements")
async def achievements(
    current_user: dict = Depends(get_authenticated_user),
    db = Depends(get_db),
):
    unlocked = set(current_user.get("achievements", []))
    total    = current_user.get("total_tasks_completed", 0)
    pts      = current_user.get("points", 0)
    streak   = current_user.get("streak", 0)
    level    = current_user.get("level", 1)

    result = []
    for a in _ACHIEVEMENTS:
        aid = a["id"]
        is_done = aid in unlocked
        result.append({
            **a,
            "is_unlocked": is_done,
        })

    return {
        "achievements": result,
        "unlocked_count": len(unlocked),
        "total_count":    len(_ACHIEVEMENTS),
    }


# ── HELPERS ───────────────────────────────────────────────────────────────────
def _get_archetype(user: dict) -> str:
    streak = user.get("streak", 0)
    weekly = user.get("weekly_stats", {}).get("tasks_completed", 0)
    total  = user.get("total_tasks_completed", 0)
    if streak > 14 and weekly > 10: return "Champion"
    if weekly > 5:                   return "Achiever"
    if streak > 3:                   return "Consistent"
    if total > 0:                    return "Explorer"
    return "Beginner"


def _default_message(name: str, archetype: str, streak: int) -> str:
    msgs = {
        "Beginner":   f"Salom {name}! Har buyuk safar birinchi qadamdan boshlanadi. Bugun shu qadamni qo'ying! 🌱",
        "Explorer":   f"{name}, har kun yangi imkoniyat. Streak davom ettirishni unutmang! 🗺️",
        "Consistent": f"{name}, {streak} kunlik streak — bu sizning kuchingiz! Davom eting! 🔥",
        "Achiever":   f"Zo'r, {name}! Siz top foydalanuvchilar orasida. Global reytingga ko'z qoying! ⭐",
        "Champion":   f"{name}, siz platformaning elitasidasiz! Hamjamiyatga ilhom bo'ling! 🏆",
    }
    return msgs.get(archetype, f"Xayrli kun, {name}! 💪")


def _generate_schedule(level: int, archetype: str) -> list[dict]:
    days = ["Dushanba", "Seshanba", "Chorshanba", "Payshanba", "Juma", "Shanba", "Yakshanba"]
    schedule = []
    for i, day in enumerate(days):
        intensity = "Faol" if i < 5 else "Engil"
        tasks_count = 3 if i < 5 else 2
        schedule.append({
            "day":       day,
            "intensity": intensity,
            "tasks":     [f"{intensity} vazifa #{j+1}" for j in range(tasks_count)],
        })
    return schedule


def _fallback_response(message: str, user: dict, err: str = "") -> dict:
    name = user.get("full_name") or user.get("username", "talaba")
    streak = user.get("streak", 0)
    quotes = random.choice(_QUOTES["Explorer"])
    return {
        "response": (
            f"Salom {name}! 👋\n\n"
            f"'{quotes}'\n\n"
            f"Sizning streakingiz: 🔥 {streak} kun. "
            f"Bugun ham bir vazifa bajaring va uni saqlab qoling!"
        ),
        "suggested_tasks": None,
    }


# ── STATIC DATA ───────────────────────────────────────────────────────────────
_QUOTES: dict[str, list[str]] = {
    "Beginner": [
        "Har buyuk sayohat bitta qadam bilan boshlanadi. 🌱",
        "Boshlash — muvaffaqiyatning yarmosi. 💫",
        "Bugun ekilgan urug' ertaga o'rmon bo'ladi. 🌳",
    ],
    "Explorer": [
        "Izchillik — iste'doddan kuchliroq. 🔥",
        "Har kuni ozroq, lekin doim oldinga. ⚡",
        "Kichik g'alabalar katta muvaffaqiyatni quradi. 🏗️",
    ],
    "Consistent": [
        "Odatlar — taqdirni belgilovchi kuch. 💎",
        "Siz o'z yo'lingizda. To'xtamang! 🚀",
        f"Streak — disciplinaning ko'rinishi. 🔥",
    ],
    "Achiever": [
        "Endi yuqoriga! Global reytingda o'rnigizni mustahkamlang. 🏆",
        "Qiyinchilik — o'sishning boshqa nomi. ⭐",
        "Elite bo'lish — tanlov, holat emas. 💪",
    ],
    "Champion": [
        "Siz boshqalarga ilhom bo'layapsiz. Davom eting! 👑",
        "Grandmaster yo'lida — hech narsa to'xtata olmaydi. 💎",
        "Eng yaxshi rahbar — o'zi namuna ko'rsatuvchi. 🌟",
    ],
}

_ACHIEVEMENTS = [
    {"id": "first_step",       "name": "Birinchi qadam",     "emoji": "👣",
     "description": "Birinchi vazifangizni bajardingiz!", "rarity": "common",  "bonus_points": 10},
    {"id": "speed_runner",     "name": "Tez yuguruvchi",     "emoji": "⚡",
     "description": "Bir kunda 5 ta vazifa bajardingiz",  "rarity": "common",  "bonus_points": 30},
    {"id": "scholar",          "name": "Olim",               "emoji": "🎓",
     "description": "O'quv sohada 20 ta vazifa",          "rarity": "rare",    "bonus_points": 60},
    {"id": "week_warrior",     "name": "Hafta sarkardasi",   "emoji": "🗡️",
     "description": "7 kun ketma-ket streak",             "rarity": "rare",    "bonus_points": 50},
    {"id": "point_master",     "name": "Ball ustasi",        "emoji": "💰",
     "description": "1000 ball to'plash",                 "rarity": "rare",    "bonus_points": 100},
    {"id": "level_5",          "name": "Rivojlanuvchi",      "emoji": "🚀",
     "description": "5-darajaga erishish",                "rarity": "rare",    "bonus_points": 75},
    {"id": "centurion",        "name": "Yuzchi",             "emoji": "💯",
     "description": "100 ta vazifa bajarish",             "rarity": "epic",    "bonus_points": 200},
    {"id": "consistency_king", "name": "Izchillik qiroli",   "emoji": "👑",
     "description": "30 kun ketma-ket streak",            "rarity": "legendary","bonus_points": 500},
]
