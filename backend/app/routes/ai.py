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
import math

logger = logging.getLogger(__name__)
router = APIRouter(prefix="/ai", tags=["AI & Motivation"])


# ── AUTH HELPER ───────────────────────────────────────────────────────────────
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


# ── MOTIVATION QUOTES ─────────────────────────────────────────────────────────
MOTIVATION_QUOTES = [
    "Muvaffaqiyat — 1% ilhom va 99% mehnat. Davom eting! 💪",
    "Buyuk ishlar faqat sevgi bilan amalga oshiriladi. ❤️",
    "Soatga qarama — u kabi qil. Oldinga yur! ⏰",
    "Ishonch — muvaffaqiyatning yarmi. 🌟",
    "Kelajak bugun qilingan ishga bog'liq. 🎯",
    "Imkonsiz ko'ringan narsa bajarilgunga qadar shunday ko'rinadi. 🚀",
    "Siz o'ylayotgandan ko'ra dadilroq, kuchliroq va aqlliroqsiz! 💎",
    "Har katta safar bitta qadam bilan boshlanadi. 🌱",
    "Izchillik — iste'doddan kuchliroq qurol. 🔥",
    "Bugun og'ir bo'lsa, ertaga oson bo'ladi. 💯",
    "O'z-o'zingga ishon — bu muvaffaqiyatning siriga! ⭐",
    "Har kun yangi imkoniyat — undan foydalaning! 🌅",
    "Qiyinchilik — o'sishning boshqa nomi. 📈",
    "Streak saqlash — bu o'z so'zingda turish. 🏆",
    "Kichik g'alabalar katta muvaffaqiyatni quradi. 🧱",
]

UZ_QUOTES = {
    "Beginner": [
        "Salom! Har buyuk safar bitta qadam bilan boshlanadi. 🌱",
        "Boshlash — muvaffaqiyatning yarmosi! 💫",
        "Bugun ekilgan urug' ertaga o'rmon bo'ladi. 🌳",
    ],
    "Explorer": [
        "Izchillik — iste'doddan kuchliroq. 🔥",
        "Har kuni ozroq, lekin doim oldinga! ⚡",
        "Siz to'g'ri yo'ldasiz — to'xtamang! 🚀",
    ],
    "Consistent": [
        "Streak — disciplinangizning ko'zgusi. 🔥",
        "Odatlar taqdirni belgilaydi. Davom eting! 💎",
        "Siz o'z yo'lingizda — hech narsa to'xtata olmaydi! 🏆",
    ],
    "Achiever": [
        "Top foydalanuvchilar orasida bo'lish — bu tanlov! ⭐",
        "Qiyinchilik — o'sishning boshqa nomi. 📈",
        "Global reytingda o'rnigizni mustahkamlang! 🌍",
    ],
    "Champion": [
        "Siz boshqalarga ilhom bo'layapsiz! 👑",
        "Elita bo'lish — holat emas, tanlov! 💎",
        "Grandmaster yo'lida — davom eting! 🌟",
    ],
}


def get_archetype(user: dict) -> str:
    streak = user.get("streak", 0)
    weekly = user.get("weekly_stats", {}).get("tasks_completed", 0) if isinstance(user.get("weekly_stats"), dict) else 0
    total  = user.get("total_tasks_completed", 0)
    if streak > 14 and weekly > 10: return "Champion"
    if weekly > 5:                   return "Achiever"
    if streak > 3:                   return "Consistent"
    if total > 0:                    return "Explorer"
    return "Beginner"


def generate_recommendation_reason(context: dict) -> str:
    category = context.get("preferred_category", "general")
    level    = context.get("level", 1)
    reasons  = [
        f"Bu vazifa sizning {category} sohasidagi ko'nikmangizni oshiradi!",
        f"Daraja {level} uchun ideal qiyinchilik darajasi.",
        "AI tahlili asosida siz uchun maxsus tanlangan!",
        "Bu vazifa streakingizni davom ettirishga yordam beradi.",
        "Kunlik maqsadingizga erishish uchun mukammal tanlov!",
    ]
    return random.choice(reasons)


# ═══════════════════════════════════════════════════════════════════════════════
#  YANGI: AI CHAT ENDPOINT (OpenAI GPT-4o-mini)
# ═══════════════════════════════════════════════════════════════════════════════

class ChatRequest(BaseModel):
    message: str
    history: list = []
    user_context: dict = {}

class AddTasksRequest(BaseModel):
    tasks: list


def _build_system_prompt(user: dict) -> str:
    name    = user.get("full_name") or user.get("username", "talaba")
    level   = user.get("level", 1)
    streak  = user.get("streak", 0)
    points  = user.get("points", 0)
    prefs   = user.get("preferences", {}) if isinstance(user.get("preferences"), dict) else {}
    subjects= prefs.get("subjects", [])

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


@router.post("/chat")
async def ai_chat(
    req: ChatRequest,
    authorization: str = None,
    db=Depends(get_database),
):
    """OpenAI GPT-4o-mini asosida motivatsion chatbot"""
    user = await get_current_user(authorization, db)

    # OpenAI mavjudligini tekshirish
    api_key = os.getenv("OPENAI_API_KEY", "")
    if not api_key:
        # Fallback — OpenAI yo'q bo'lsa
        return _fallback_chat(req.message, user)

    try:
        from openai import AsyncOpenAI
        client = AsyncOpenAI(api_key=api_key)

        # History tayyorlash (oxirgi 8 ta xabar)
        history = [
            {"role": m.get("role", "user"), "content": str(m.get("content", ""))}
            for m in req.history[-8:]
            if m.get("role") in ("user", "assistant")
        ]

        messages = [
            {"role": "system", "content": _build_system_prompt(user)},
            *history,
            {"role": "user", "content": req.message},
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
            "response":        data.get("response", "Javob generatsiya qilishda xato."),
            "suggested_tasks": data.get("suggested_tasks") or None,
        }

    except json.JSONDecodeError:
        return {
            "response":        raw if 'raw' in dir() else "Xato yuz berdi.",
            "suggested_tasks": None,
        }
    except Exception as e:
        logger.error(f"OpenAI xato: {e}")
        return _fallback_chat(req.message, user, str(e))


def _fallback_chat(message: str, user: dict, err: str = "") -> dict:
    """OpenAI yo'q bo'lsa ishlaydi"""
    name    = user.get("full_name") or user.get("username", "talaba")
    streak  = user.get("streak", 0)
    archetype = get_archetype(user)
    quote   = random.choice(UZ_QUOTES.get(archetype, UZ_QUOTES["Explorer"]))

    msg = (
        f"Salom {name}! 👋\n\n"
        f"{quote}\n\n"
    )

    # Oddiy kalit so'z tekshirish
    text = message.lower()
    suggested = None

    if any(w in text for w in ["reja", "vazifa", "plan", "nima qilay", "yordam"]):
        msg += (
            f"Bugun uchun 3 ta vazifa tavsiya qilaman:\n"
            f"1. 📚 30 daqiqa o'qish\n"
            f"2. 💪 15 daqiqa jismoniy mashq\n"
            f"3. 🧘 10 daqiqa meditatsiya\n\n"
            f"Ularni qo'shib, bajarib streakingizni davom ettiring!"
        )
        suggested = [
            {"title": "30 daqiqa o'qish", "description": "Kitob yoki darslik o'qing",
             "category": "reading", "difficulty": "easy", "duration_minutes": 30, "estimated_points": 30},
            {"title": "Jismoniy mashq", "description": "15 daqiqa isitish va mashqlar",
             "category": "exercise", "difficulty": "easy", "duration_minutes": 15, "estimated_points": 20},
            {"title": "Meditatsiya", "description": "Nafas mashqlari va tinchlanish",
             "category": "meditation", "difficulty": "easy", "duration_minutes": 10, "estimated_points": 15},
        ]
    elif any(w in text for w in ["streak", "davom", "saqla"]):
        msg += (
            f"Streakingiz: 🔥 {streak} kun. "
            f"Uni saqlash uchun har kuni kamida bitta vazifa bajaring!\n\n"
            f"Eng oson yo'l — har kuni bir xil vaqtda kirish odatini shakllantiring. ⏰"
        )
    elif any(w in text for w in ["qiyin", "charchadim", "bo'lmayapti", "motivatsiya"]):
        msg += (
            f"Tushunaman, ba'zan qiyin bo'ladi. 💙\n\n"
            f"Lekin esda tuting: siz allaqachon {user.get('total_tasks_completed', 0)} ta "
            f"vazifa bajargansiz! Bu kichik narsa emas.\n\n"
            f"Bugun faqat BITTA kichik vazifani bajaring — shu kifoya. 🌱"
        )
    else:
        msg += (
            f"Streak: 🔥 {streak} kun | Daraja: {user.get('level', 1)} | "
            f"Ball: {user.get('points', 0)} ⭐\n\n"
            f"Bugun ham bir vazifa bajaring va natijangizni ko'ring!"
        )

    return {"response": msg, "suggested_tasks": suggested}


# ── TASKS FROM CHAT ───────────────────────────────────────────────────────────
@router.post("/add-tasks")
async def add_tasks_from_chat(
    req: AddTasksRequest,
    authorization: str = None,
    db=Depends(get_database),
):
    """AI chat tavsiya qilgan vazifalarni kunlik ro'yxatga qo'shish"""
    user    = await get_current_user(authorization, db)
    uid     = str(user["_id"])
    now     = datetime.utcnow()
    inserted= []

    for t in req.tasks[:5]:  # Maksimum 5 ta
        if not isinstance(t, dict):
            continue
        doc = {
            "title":           str(t.get("title", "Vazifa"))[:200],
            "description":     str(t.get("description", ""))[:500],
            "category":        t.get("category", "study"),
            "difficulty":      t.get("difficulty", "medium"),
            "points_reward":   int(t.get("estimated_points", 50)),
            "duration_minutes":int(t.get("duration_minutes", 30)),
            "tags":            ["ai-generated"],
            "is_active":       True,
            "is_from_chat":    True,
            "is_daily":        True,
            "target_user_id":  uid,
            "created_by":      uid,
            "created_at":      now,
            "completion_count":0,
        }
        res = await db.tasks.insert_one(doc)
        inserted.append(str(res.inserted_id))

    return {
        "success":       True,
        "inserted_count":len(inserted),
        "task_ids":      inserted,
        "message":       f"{len(inserted)} ta vazifa qo'shildi!",
    }


# ── INSIGHTS ──────────────────────────────────────────────────────────────────
@router.get("/insights")
async def get_insights(authorization: str = None, db=Depends(get_database)):
    """Foydalanuvchi statistikasi va tahlili"""
    user   = await get_current_user(authorization, db)
    uid    = str(user["_id"])
    since  = datetime.utcnow() - timedelta(days=30)

    progress = await db.progress.find(
        {"user_id": uid, "created_at": {"$gte": since}}
    ).to_list(500)

    # Haftalik ballar (7 kun)
    weekly_points = [0] * 7
    today = datetime.utcnow().date()
    for p in progress:
        try:
            d    = p.get("created_at", datetime.utcnow()).date()
            diff = (today - d).days
            if 0 <= diff < 7:
                pts = p.get("points_earned", p.get("points_reward", 0))
                weekly_points[6 - diff] += int(pts or 0)
        except Exception:
            pass

    # Kategoriya taqsimoti
    cat_map: dict = {}
    for p in progress:
        if p.get("status") == "completed" or p.get("points_earned", 0) > 0:
            cat = p.get("category", "other")
            cat_map[cat] = cat_map.get(cat, 0) + 1

    level  = user.get("level", 1)
    pts    = user.get("points", 0)
    next_t = int(100 * (1.5 ** level - 1))
    to_next= max(0, next_t - pts)

    return {
        "total_completed":    len([p for p in progress if p.get("status") == "completed"]),
        "weekly_points":      weekly_points,
        "category_breakdown": cat_map,
        "points_to_next_level": to_next,
        "current_streak":    user.get("streak", 0),
        "best_streak":       user.get("best_streak", 0),
        "level":             level,
        "points":            pts,
    }


# ── ACHIEVEMENTS ──────────────────────────────────────────────────────────────
ACHIEVEMENTS_LIST = [
    {"id": "first_step",       "name": "Birinchi qadam",   "emoji": "👣",
     "description": "Birinchi vazifani bajaring",          "rarity": "common",   "bonus_points": 10},
    {"id": "speed_runner",     "name": "Tez yuguruvchi",   "emoji": "⚡",
     "description": "Bir kunda 5 ta vazifa bajaring",      "rarity": "common",   "bonus_points": 30},
    {"id": "scholar",          "name": "Olim",             "emoji": "🎓",
     "description": "O'quv sohada 20 ta vazifa bajaring",  "rarity": "rare",     "bonus_points": 60},
    {"id": "week_warrior",     "name": "Hafta sarkardasi", "emoji": "🗡️",
     "description": "7 kun ketma-ket streak",              "rarity": "rare",     "bonus_points": 50},
    {"id": "point_master",     "name": "Ball ustasi",      "emoji": "💰",
     "description": "1000 ball to'plang",                  "rarity": "rare",     "bonus_points": 100},
    {"id": "level_5",          "name": "Rivojlanuvchi",    "emoji": "🚀",
     "description": "5-darajaga ering",                    "rarity": "rare",     "bonus_points": 75},
    {"id": "centurion",        "name": "Yuzchi",           "emoji": "💯",
     "description": "100 ta vazifa bajaring",              "rarity": "epic",     "bonus_points": 200},
    {"id": "consistency_king", "name": "Izchillik qiroli", "emoji": "👑",
     "description": "30 kun ketma-ket streak",             "rarity": "legendary","bonus_points": 500},
]


@router.get("/achievements")
async def get_achievements(authorization: str = None, db=Depends(get_database)):
    user     = await get_current_user(authorization, db)
    unlocked = set(user.get("achievements", []))
    result   = [
        {**a, "is_unlocked": a["id"] in unlocked}
        for a in ACHIEVEMENTS_LIST
    ]
    return {
        "achievements":   result,
        "unlocked_count": len(unlocked),
        "total_count":    len(ACHIEVEMENTS_LIST),
    }


# ── MOTIVATION PLAN ───────────────────────────────────────────────────────────
@router.get("/motivation-plan")
async def get_motivation_plan(authorization: str = None, db=Depends(get_database)):
    """Haftalik motivatsion reja"""
    try:
        user   = await get_current_user(authorization, db)
        uid    = str(user["_id"])
        level  = user.get("level", 1)
        streak = user.get("streak", 0)
        points = user.get("points", 0)
        name   = user.get("full_name") or user.get("username", "")
        archetype = get_archetype(user)

        # LLM bilan boyitish (ixtiyoriy)
        personal_msg = random.choice(UZ_QUOTES.get(archetype, UZ_QUOTES["Explorer"]))
        api_key = os.getenv("OPENAI_API_KEY", "")
        if api_key:
            try:
                from openai import AsyncOpenAI
                client = AsyncOpenAI(api_key=api_key)
                prompt = (
                    f"'{name}' ismli talaba uchun 2 jumlali shaxsiy motivatsion xabar yoz. "
                    f"Daraja: {level}, Streak: {streak} kun. O'zbek tilida, iliq ohangda. "
                    f"FAQAT matn qaytar."
                )
                r = await client.chat.completions.create(
                    model="gpt-4o-mini",
                    messages=[{"role": "user", "content": prompt}],
                    max_tokens=120, temperature=0.9,
                )
                personal_msg = r.choices[0].message.content.strip()
            except Exception:
                pass

        # Preferred tasks
        prefs    = user.get("preferences", {}) if isinstance(user.get("preferences"), dict) else {}
        subjects = prefs.get("subjects", [])

        # Available tasks
        tasks = await db.tasks.find({"is_active": True}).limit(3).to_list(3)
        recommendation = None
        if tasks:
            t = random.choice(tasks)
            recommendation = {
                "id":          str(t["_id"]),
                "title":       t.get("title", ""),
                "category":    t.get("category", "study"),
                "difficulty":  t.get("difficulty", "medium"),
                "points_reward": t.get("points_reward", 50),
            }

        return {
            "archetype":        archetype,
            "personal_message": personal_msg,
            "motivation_quote": random.choice(MOTIVATION_QUOTES),
            "focus_areas":      subjects[:3] or ["Umumiy o'quv"],
            "streak":           streak,
            "level":            level,
            "points":           points,
            "recommendation":   recommendation,
        }

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Motivation plan xato: {e}")
        raise HTTPException(status_code=500, detail="Motivatsion reja generatsiya xatosi")


# ── DAILY INSIGHT ─────────────────────────────────────────────────────────────
@router.get("/daily-insight")
async def get_daily_insight(authorization: str = None, db=Depends(get_database)):
    """Kunlik tahlil va tavsiyalar"""
    try:
        user   = await get_current_user(authorization, db)
        uid    = str(user["_id"])

        today_start = datetime.utcnow().replace(hour=0, minute=0, second=0, microsecond=0)
        today_end   = datetime.utcnow().replace(hour=23, minute=59, second=59, microsecond=999999)

        today_progress = await db.progress.find({
            "user_id": uid,
            "created_at": {"$gte": today_start, "$lte": today_end}
        }).to_list(None)

        completed_today   = len([p for p in today_progress if p.get("status") == "completed"])
        total_today       = len(today_progress)
        completion_rate   = (completed_today / total_today * 100) if total_today > 0 else 0
        points_today      = sum(p.get("points_earned", p.get("points_reward", 0))
                                for p in today_progress if p.get("status") == "completed")

        msgs = {
            0: "Boshlang! Birinchi vazifani bajarib momentum qiling. 🚀",
            1: f"Ajoyib! {completed_today} ta vazifa bajarildi. Davom eting! 💪",
            3: "Siz bugun yonib turibsiz! 🔥",
            5: "Ishtiyoqingiz a'lo! Maqsadlaringizni ezib o'tayapsiz! 🏆",
        }
        motivation_msg = msgs.get(completed_today,
            f"Fantastik! {completed_today} ta vazifa bajarildi!")

        next_recommendation = None
        if total_today < 3:
            available = await db.tasks.find({"is_active": True}).limit(1).to_list(None)
            if available:
                t = available[0]
                next_recommendation = {
                    "task_id":     str(t["_id"]),
                    "title":       t.get("title", ""),
                    "points_reward": t.get("points_reward", 50),
                }

        return {
            "date":               today_start.isoformat(),
            "total_tasks":        total_today,
            "completed_tasks":    completed_today,
            "completion_rate":    round(completion_rate, 2),
            "points_earned":      points_today,
            "motivation_message": motivation_msg,
            "next_recommendation":next_recommendation,
            "streak":             user.get("streak", 0),
        }
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Daily insight xato: {e}")
        raise HTTPException(status_code=500, detail="Kunlik tahlil xatosi")


# ── RECOMMENDATIONS ───────────────────────────────────────────────────────────
@router.get("/recommendations")
async def get_recommendations(
    count: int = 5,
    authorization: str = None,
    db=Depends(get_database),
):
    """AI tavsiyalari"""
    try:
        user  = await get_current_user(authorization, db)
        tasks = await db.tasks.find({"is_active": True}).limit(count).to_list(None)
        recommendations = []
        for task in tasks:
            reason = generate_recommendation_reason({
                "preferred_category": task.get("category", "general"),
                "level": user.get("level", 1),
            })
            recommendations.append({
                "task": {
                    "id":           str(task["_id"]),
                    "title":        task.get("title", ""),
                    "category":     task.get("category", "study"),
                    "difficulty":   task.get("difficulty", "medium"),
                    "points_reward":task.get("points_reward", 50),
                },
                "reason": reason,
            })
        return {"recommendations": recommendations, "count": len(recommendations)}
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Recommendations xato: {e}")
        raise HTTPException(status_code=500, detail="Tavsiyalar xatosi")


# ── MOTIVATION QUOTE ──────────────────────────────────────────────────────────
@router.get("/motivation-quote")
async def get_motivation_quote():
    return {"quote": random.choice(MOTIVATION_QUOTES)}
