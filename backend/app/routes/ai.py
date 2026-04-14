"""
MotivAI — AI Router
Fayl joyi: backend/app/routes/ai.py

Endpointlar:
  POST /api/v1/ai/chat              — OpenAI chatbot
  POST /api/v1/ai/add-tasks         — Chat vazifalarini qo'shish
  GET  /api/v1/ai/motivation-plan   — Haftalik reja
  GET  /api/v1/ai/daily-insight     — Kunlik tahlil
  GET  /api/v1/ai/recommendations   — AI tavsiyalar
  GET  /api/v1/ai/achievements      — Yutuqlar
  GET  /api/v1/ai/motivation-quote  — Iqtibos
"""
from fastapi import APIRouter, HTTPException, status, Depends
from bson import ObjectId
from app.database import get_database
from app.utils.auth import decode_token
from datetime import datetime, timedelta
from pydantic import BaseModel
import random
import logging
import os
import json

logger = logging.getLogger(__name__)
router = APIRouter(prefix="/ai", tags=["AI & Motivation"])


# ── Auth helper ───────────────────────────────────────────────────────────────
async def get_current_user(authorization: str = None, db=None):
    if not authorization:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Authorization header missing")
    token = authorization.replace("Bearer ", "")
    payload = decode_token(token)
    if not payload:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or expired token")
    user_id = payload.get("sub")
    user = await db.users.find_one({"_id": ObjectId(user_id)})
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="User not found")
    return user


# ── Schemas ───────────────────────────────────────────────────────────────────
class ChatRequest(BaseModel):
    message: str
    history: list = []
    user_context: dict = {}

class AddTasksRequest(BaseModel):
    tasks: list


# ── Quotes ───────────────────────────────────────────────────────────────────
MOTIVATION_QUOTES = [
    "Muvaffaqiyat — 1% ilhom va 99% mehnat. Davom eting! 💪",
    "Buyuk ishlar faqat sevgi bilan amalga oshiriladi. ❤️",
    "Izchillik — iste'doddan kuchliroq qurol. 🔥",
    "Kelajak bugun qilingan ishga bog'liq. 🎯",
    "Imkonsiz ko'ringan narsa bajarilgunga qadar shunday ko'rinadi. 🚀",
    "Har katta safar bitta qadam bilan boshlanadi. 🌱",
    "O'z-o'zingga ishon — bu muvaffaqiyatning siriga! ⭐",
    "Har kun yangi imkoniyat — undan foydalaning! 🌅",
    "Qiyinchilik — o'sishning boshqa nomi. 📈",
    "Streak saqlash — bu o'z so'zingda turish. 🏆",
    "Kichik g'alabalar katta muvaffaqiyatni quradi. 🧱",
    "Bugun og'ir bo'lsa, ertaga oson bo'ladi. 💯",
]

ARCHETYPE_QUOTES = {
    "Beginner":   [
        "Salom! Har buyuk safar bitta qadam bilan boshlanadi. 🌱",
        "Boshlash — muvaffaqiyatning yarmosi! 💫",
    ],
    "Explorer":   [
        "Izchillik — iste'doddan kuchliroq. 🔥",
        "Har kuni ozroq, lekin doim oldinga! ⚡",
    ],
    "Consistent": [
        "Streak — disciplinangizning ko'zgusi. 🔥",
        "Odatlar taqdirni belgilaydi. Davom eting! 💎",
    ],
    "Achiever":   [
        "Top foydalanuvchilar orasida bo'lish — bu tanlov! ⭐",
        "Global reytingda o'rnigizni mustahkamlang! 🌍",
    ],
    "Champion":   [
        "Siz boshqalarga ilhom bo'layapsiz! 👑",
        "Grandmaster yo'lida — davom eting! 🌟",
    ],
}


def _archetype(user: dict) -> str:
    streak = user.get("streak", 0)
    weekly = 0
    ws = user.get("weekly_stats")
    if isinstance(ws, dict):
        weekly = ws.get("tasks_completed", 0)
    total = user.get("total_tasks_completed", 0)
    if streak > 14 and weekly > 10: return "Champion"
    if weekly > 5:                   return "Achiever"
    if streak > 3:                   return "Consistent"
    if total > 0:                    return "Explorer"
    return "Beginner"


def _build_system_prompt(user: dict) -> str:
    name    = user.get("full_name") or user.get("username", "talaba")
    level   = user.get("level", 1)
    streak  = user.get("streak", 0)
    points  = user.get("points", 0)
    prefs   = user.get("preferences") or {}
    if not isinstance(prefs, dict):
        prefs = {}
    subjects = prefs.get("subjects", [])

    return f"""Sen MotivAI — talabalar uchun AI motivatsion assistant.

FOYDALANUVCHI:
- Ism: {name}
- Daraja: {level}/20 | Ball: {points} | Streak: {streak} kun
- Qiziqishlar: {', '.join(subjects) if subjects else 'belgilanmagan'}

QOIDALAR:
1. DOIM o'zbek tilida javob ber.
2. Ismi bilan murojaat qil, iliq va rag'batlantiruvchi ohangda gapir.
3. Javob 150-250 so'z bo'lsin. Amaliy maslahatlar ber.
4. Agar foydalanuvchi reja, maqsad yoki vazifa so'rasa — "suggested_tasks" qaytarishi SHART.
5. Streak > 0 bo'lsa — uni yo'qotmaslik haqida eslatib tur.

VAZIFA TAVSIYA FORMATI (category: study/exercise/reading/meditation/social/creative/productivity/challenge):
{{
  "response": "...o'zbek tilidagi javob...",
  "suggested_tasks": [
    {{
      "title": "Vazifa nomi",
      "description": "Batafsil tavsif",
      "category": "study",
      "difficulty": "medium",
      "duration_minutes": 30,
      "estimated_points": 50
    }}
  ]
}}

Agar vazifa tavsiya kerak bo'lmasa: "suggested_tasks": null

MUHIM: FAQAT valid JSON qaytar. Markdown, kod bloki yo'q."""


# ── POST /ai/chat ─────────────────────────────────────────────────────────────
@router.post("/chat")
async def ai_chat(
    req: ChatRequest,
    authorization: str = None,
    db=Depends(get_database),
):
    """OpenAI GPT-4o-mini asosida motivatsion chatbot"""
    user    = await get_current_user(authorization, db)
    api_key = os.getenv("OPENAI_API_KEY", "")

    if not api_key:
        return _fallback_response(req.message, user)

    try:
        from openai import AsyncOpenAI
        client = AsyncOpenAI(api_key=api_key)

        # History (oxirgi 8 ta xabar)
        history = [
            {"role": m.get("role","user"), "content": str(m.get("content",""))}
            for m in (req.history or [])[-8:]
            if m.get("role") in ("user", "assistant")
        ]

        messages = [
            {"role": "system", "content": _build_system_prompt(user)},
            *history,
            {"role": "user",   "content": req.message},
        ]

        resp = await client.chat.completions.create(
            model="gpt-4o-mini",
            messages=messages,
            temperature=0.8,
            max_tokens=700,
            response_format={"type": "json_object"},
        )

        raw  = resp.choices[0].message.content or "{}"
        data = json.loads(raw)
        return {
            "response":        data.get("response", "Javob olishda xato."),
            "suggested_tasks": data.get("suggested_tasks") or None,
        }

    except json.JSONDecodeError:
        return {"response": raw if 'raw' in dir() else "Xato.",
                "suggested_tasks": None}
    except Exception as e:
        logger.error(f"OpenAI xato: {e}")
        return _fallback_response(req.message, user)


def _fallback_response(message: str, user: dict) -> dict:
    """OpenAI yo'q bo'lsa — rule-based javob"""
    name      = user.get("full_name") or user.get("username", "talaba")
    streak    = user.get("streak", 0)
    total     = user.get("total_tasks_completed", 0)
    archetype = _archetype(user)
    quote     = random.choice(ARCHETYPE_QUOTES.get(archetype, MOTIVATION_QUOTES))

    text = message.lower()
    suggested = None

    if any(w in text for w in ["reja","vazifa","plan","nima qilay","yordam","bugun"]):
        return {
            "response": (
                f"Salom {name}! 👋\n\n"
                f"Bugun uchun shaxsiy reja:\n\n"
                f"🌅 **Ertalab** (30 daqiqa): O'qish yoki yangi mavzu o'rganish\n"
                f"☀️ **Kun** (20 daqiqa): Jismoniy mashq\n"
                f"🌙 **Kechqurun** (15 daqiqa): Meditatsiya va rejalashtirish\n\n"
                f"{quote}\n\n"
                f"Ushbu vazifalarni kunlikka qo'shishni xohlaysizmi?"
            ),
            "suggested_tasks": [
                {"title": "Ertalabki o'qish sessiyasi",
                 "description": "Kitob yoki darslik bo'yicha 30 daqiqa o'qing",
                 "category": "reading", "difficulty": "easy",
                 "duration_minutes": 30, "estimated_points": 30},
                {"title": "Jismoniy mashq",
                 "description": "20 daqiqa isitish va mashqlar",
                 "category": "exercise", "difficulty": "easy",
                 "duration_minutes": 20, "estimated_points": 25},
                {"title": "Meditatsiya va rejalashtirish",
                 "description": "Nafas mashqlari va ertangi kun rejasi",
                 "category": "meditation", "difficulty": "easy",
                 "duration_minutes": 15, "estimated_points": 20},
            ],
        }

    if any(w in text for w in ["streak","davom","saqla","yo'qolmassin"]):
        return {
            "response": (
                f"{name}, streakingiz 🔥 {streak} kun!\n\n"
                f"Uni saqlash uchun oddiy qoida:\n"
                f"• Har kuni kamida BITTA vazifa bajaring\n"
                f"• Bir xil vaqtda (masalan, ertalab 8:00) kirish odatini shakllantiring\n"
                f"• Qiyin kunlarda eng oson vazifani tanlang\n\n"
                f"Bugun qaysi vazifani bajaring? Men yordam beraman!"
            ),
            "suggested_tasks": None,
        }

    if any(w in text for w in ["qiyin","charchadim","bo'lmayapti","motivatsiya","ilhom"]):
        return {
            "response": (
                f"Tushunaman, {name}. Hamma ham bunday kunlarni boshidan kechiradi. 💙\n\n"
                f"Lekin esda tuting: siz allaqachon **{total} ta vazifa** bajargansiz!\n"
                f"Bu kichik yutuq emas.\n\n"
                f"Bugun faqat BITTA kichik qadamni qo'ying — shu kifoya. 🌱\n\n"
                f"{quote}"
            ),
            "suggested_tasks": None,
        }

    return {
        "response": (
            f"Salom {name}! 👋\n\n"
            f"{quote}\n\n"
            f"📊 Sizning statistikangiz:\n"
            f"• Streak: 🔥 {streak} kun\n"
            f"• Daraja: {user.get('level', 1)}\n"
            f"• Ballar: ⭐ {user.get('points', 0)}\n\n"
            f"Bugun ham bir vazifa bajaring va natijangizni ko'ring!"
        ),
        "suggested_tasks": None,
    }


# ── POST /ai/add-tasks ────────────────────────────────────────────────────────
@router.post("/add-tasks")
async def add_tasks_from_chat(
    req: AddTasksRequest,
    authorization: str = None,
    db=Depends(get_database),
):
    """Chat tavsiya qilgan vazifalarni kunlik ro'yxatga qo'shish"""
    user = await get_current_user(authorization, db)
    uid  = str(user["_id"])
    now  = datetime.utcnow()
    inserted = []

    for t in (req.tasks or [])[:5]:
        if not isinstance(t, dict):
            continue
        doc = {
            "title":            str(t.get("title", "Vazifa"))[:200],
            "description":      str(t.get("description", ""))[:500],
            "category":         t.get("category", "study"),
            "difficulty":       t.get("difficulty", "medium"),
            "points_reward":    int(t.get("estimated_points", 50)),
            "duration_minutes": int(t.get("duration_minutes", 30)),
            "tags":             ["ai-generated"],
            "is_active":        True,
            "is_from_chat":     True,
            "is_daily":         True,
            "target_user_id":   uid,
            "created_by":       uid,
            "created_at":       now,
            "completion_count": 0,
        }
        res = await db.tasks.insert_one(doc)
        inserted.append(str(res.inserted_id))

    return {
        "success":       True,
        "inserted_count": len(inserted),
        "task_ids":      inserted,
        "message":       f"{len(inserted)} ta vazifa qo'shildi!",
    }


# ── GET /ai/motivation-plan ───────────────────────────────────────────────────
@router.get("/motivation-plan")
async def motivation_plan(
    authorization: str = None,
    db=Depends(get_database),
):
    user      = await get_current_user(authorization, db)
    name      = user.get("full_name") or user.get("username", "")
    level     = user.get("level", 1)
    streak    = user.get("streak", 0)
    archetype = _archetype(user)

    # LLM boyitish (ixtiyoriy)
    personal_msg = random.choice(
        ARCHETYPE_QUOTES.get(archetype, MOTIVATION_QUOTES))
    api_key = os.getenv("OPENAI_API_KEY", "")
    if api_key:
        try:
            from openai import AsyncOpenAI
            client = AsyncOpenAI(api_key=api_key)
            r = await client.chat.completions.create(
                model="gpt-4o-mini",
                messages=[{"role": "user", "content":
                    f"'{name}' ismli talaba uchun 2 jumlali shaxsiy motivatsion xabar yoz. "
                    f"Daraja: {level}, Streak: {streak} kun. O'zbek tilida, iliq ohangda. "
                    f"FAQAT matn, JSON emas."}],
                max_tokens=120, temperature=0.9)
            personal_msg = r.choices[0].message.content.strip()
        except Exception:
            pass

    prefs = user.get("preferences") or {}
    if not isinstance(prefs, dict):
        prefs = {}
    subjects = prefs.get("subjects", [])

    # Sample recommendation
    task = await db.tasks.find_one({"is_active": True})
    rec = None
    if task:
        rec = {
            "id":           str(task["_id"]),
            "title":        task.get("title", ""),
            "category":     task.get("category", "study"),
            "difficulty":   task.get("difficulty", "medium"),
            "points_reward": task.get("points_reward", 50),
        }

    return {
        "archetype":        archetype,
        "personal_message": personal_msg,
        "motivation_quote": random.choice(MOTIVATION_QUOTES),
        "focus_areas":      subjects[:3] or ["Umumiy o'quv"],
        "streak":           streak,
        "level":            level,
        "points":           user.get("points", 0),
        "recommendation":   rec,
    }


# ── GET /ai/daily-insight ─────────────────────────────────────────────────────
@router.get("/daily-insight")
async def daily_insight(
    authorization: str = None,
    db=Depends(get_database),
):
    try:
        user = await get_current_user(authorization, db)
        uid  = str(user["_id"])

        today_start = datetime.utcnow().replace(
            hour=0, minute=0, second=0, microsecond=0)
        today_end = datetime.utcnow().replace(
            hour=23, minute=59, second=59, microsecond=999999)

        today_progress = await db.progress.find({
            "user_id": uid,
            "created_at": {"$gte": today_start, "$lte": today_end}
        }).to_list(None)

        completed_today = len([p for p in today_progress
                               if p.get("status") == "completed"])
        total_today     = len(today_progress)
        cr = (completed_today / total_today * 100) if total_today > 0 else 0
        pts_today = sum(
            p.get("points_earned", p.get("points_reward", 0))
            for p in today_progress
            if p.get("status") == "completed"
        )

        msgs = {
            0: "Boshlang! Birinchi vazifani bajarib momentum qiling. 🚀",
            1: f"{completed_today} ta vazifa bajarildi. Davom eting! 💪",
            3: "Bugun yonib turibsiz! 🔥",
            5: "Ishtiyoqingiz a'lo! Maqsadlaringizni ezib o'tayapsiz! 🏆",
        }
        msg = msgs.get(completed_today,
            f"{completed_today} ta vazifa bajarildi!")

        next_rec = None
        if total_today < 3:
            avail = await db.tasks.find(
                {"is_active": True}).limit(1).to_list(None)
            if avail:
                t = avail[0]
                next_rec = {
                    "task_id":      str(t["_id"]),
                    "title":        t.get("title", ""),
                    "points_reward": t.get("points_reward", 50),
                }

        return {
            "date":               today_start.isoformat(),
            "total_tasks":        total_today,
            "completed_tasks":    completed_today,
            "completion_rate":    round(cr, 2),
            "points_earned":      pts_today,
            "motivation_message": msg,
            "next_recommendation": next_rec,
            "streak":             user.get("streak", 0),
        }
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"daily_insight xato: {e}")
        raise HTTPException(status_code=500, detail=str(e))


# ── GET /ai/recommendations ───────────────────────────────────────────────────
@router.get("/recommendations")
async def recommendations(
    count: int = 5,
    authorization: str = None,
    db=Depends(get_database),
):
    user  = await get_current_user(authorization, db)
    tasks = await db.tasks.find(
        {"is_active": True}).limit(count).to_list(None)
    result = []
    for t in tasks:
        result.append({
            "task": {
                "id":           str(t["_id"]),
                "title":        t.get("title", ""),
                "category":     t.get("category", "study"),
                "difficulty":   t.get("difficulty", "medium"),
                "points_reward": t.get("points_reward", 50),
            },
            "reason": random.choice([
                "AI tahlili asosida siz uchun tanlangan!",
                "Bu vazifa streakingizni davom ettirishga yordam beradi.",
                "Kunlik maqsadingizga erishish uchun mukammal tanlov!",
                f"Daraja {user.get('level',1)} uchun ideal qiyinchilik.",
            ]),
        })
    return {"recommendations": result, "count": len(result)}


# ── GET /ai/achievements ──────────────────────────────────────────────────────
ACHIEVEMENTS = [
    {"id": "first_step",       "name": "Birinchi qadam",   "emoji": "👣",
     "description": "Birinchi vazifani bajaring",          "rarity": "common",   "bonus_points": 10},
    {"id": "speed_runner",     "name": "Tez yuguruvchi",   "emoji": "⚡",
     "description": "Bir kunda 5 ta vazifa bajaring",      "rarity": "common",   "bonus_points": 30},
    {"id": "scholar",          "name": "Olim",             "emoji": "🎓",
     "description": "O'quv sohada 20 ta vazifa bajaring",  "rarity": "rare",     "bonus_points": 60},
    {"id": "week_warrior",     "name": "Hafta sarkardasi", "emoji": "🗡️",
     "description": "7 kun ketma-ket streak",              "rarity": "rare",     "bonus_points": 50},
    {"id": "point_master",     "name": "Ball ustasi",      "emoji": "💰",
     "description": "1000 ball to\'plang",                 "rarity": "rare",     "bonus_points": 100},
    {"id": "level_5",          "name": "Rivojlanuvchi",    "emoji": "🚀",
     "description": "5-darajaga ering",                    "rarity": "rare",     "bonus_points": 75},
    {"id": "centurion",        "name": "Yuzchi",           "emoji": "💯",
     "description": "100 ta vazifa bajaring",              "rarity": "epic",     "bonus_points": 200},
    {"id": "consistency_king", "name": "Izchillik qiroli", "emoji": "👑",
     "description": "30 kun ketma-ket streak",             "rarity": "legendary","bonus_points": 500},
]


@router.get("/achievements")
async def achievements(
    authorization: str = None,
    db=Depends(get_database),
):
    user     = await get_current_user(authorization, db)
    unlocked = set(user.get("achievements", []))
    result   = [{**a, "is_unlocked": a["id"] in unlocked}
                for a in ACHIEVEMENTS]
    return {
        "achievements":   result,
        "unlocked_count": len(unlocked),
        "total_count":    len(ACHIEVEMENTS),
    }


# ── GET /ai/motivation-quote ──────────────────────────────────────────────────
@router.get("/motivation-quote")
async def motivation_quote():
    return {"quote": random.choice(MOTIVATION_QUOTES)}
