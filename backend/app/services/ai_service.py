# app/services/ai_service.py
"""AI service: motivation chat + tip + analysis.

Uses the multi-provider fallback chain in ai_providers (OpenAI →
Gemini → Groq). If every provider is exhausted we return a static
template message so the UI has something usable.
"""
from __future__ import annotations

import json
import logging
from typing import List

from dotenv import load_dotenv

from app.services.ai_providers import chat_complete, configured_providers

load_dotenv()
log = logging.getLogger(__name__)


def _lang_label(code: str) -> str:
    return {"uz": "o'zbek", "ru": "русский", "en": "English"}.get(code, "o'zbek")


def _system_prompt(user_context: dict) -> str:
    name = user_context.get("name") or "Talaba"
    lang_code = user_context.get("language") or "uz"
    streak = user_context.get("streak", 0)
    level = user_context.get("level", 1)
    xp = user_context.get("xp", 0)
    goals = user_context.get("goals") or []
    interests = user_context.get("interests") or []
    return (
        f"Sen MotivAI — talabalar uchun shaxsiy AI motivatsion assistant.\n\n"
        f"FOYDALANUVCHI: {name}\n"
        f"Daraja {level}, XP {xp}, streak {streak} kun\n"
        f"Maqsadlar: {', '.join(goals) if goals else 'belgilanmagan'}\n"
        f"Qiziqishlar: {', '.join(interests) if interests else 'belgilanmagan'}\n\n"
        f"QOIDALAR:\n"
        f"1. DOIMO {_lang_label(lang_code)} tilida javob ber.\n"
        f"2. Iliq, motivatsion ohang. Foydalanuvchini ismi bilan chaqir.\n"
        f"3. Javob 2-4 paragraf, har biri 1-3 jumla. Amaliy maslahat ber.\n"
        f"4. Streak > 0 bo'lsa — uni asrash muhimligini eslat.\n"
        f"5. Markdown qo'llasangiz **qalin** va emojilardan foyda — boshqa formatlash yo'q."
    )


def _fallback_message(user_context: dict, reason: str = "") -> dict:
    name = user_context.get("name") or "Talaba"
    streak = user_context.get("streak", 0)
    lang = user_context.get("language") or "uz"
    streak_line = ""
    if streak > 0:
        streak_line = {
            "uz": f"\n\n🔥 **{streak} kunlik streak'ingizni saqlang** — bugun ham 1 ta vazifa.",
            "ru": f"\n\n🔥 **Сохраните streak в {streak} дн.** — хотя бы 1 задача сегодня.",
            "en": f"\n\n🔥 **Keep your {streak}-day streak** — one task today.",
        }[lang]
    body = {
        "uz": f"Salom **{name}**! AI servisi vaqtincha band — bir oz keyinroq qayta urinib ko'ring.\n\nShu orada eng muhim ishingizdan boshlang: {streak_line}",
        "ru": f"Привет, **{name}**! AI временно недоступен — попробуйте чуть позже.\n\nПока начните с самой важной задачи: {streak_line}",
        "en": f"Hi **{name}**! AI is temporarily busy — try again in a moment.\n\nMeanwhile, start with your most important task: {streak_line}",
    }[lang]
    log.info("ai_service: returning fallback (%s)", reason or "no providers")
    return {"success": False, "message": body, "plan_data": None, "tokens_used": 0}


# ──────────────────────────────────────────────────────────────────────
# Main chat
# ──────────────────────────────────────────────────────────────────────
async def chat_with_ai(
    message: str,
    user_context: dict,
    conversation_history: List[dict] = [],
) -> dict:
    if not configured_providers():
        return _fallback_message(user_context, "no providers configured")

    messages: list[dict] = [{"role": "system", "content": _system_prompt(user_context)}]
    for ch in (conversation_history or [])[-5:]:
        role = ch.get("role")
        if role in ("user", "assistant"):
            messages.append({"role": role, "content": str(ch.get("content", ""))})
    messages.append({"role": "user", "content": message})

    try:
        text, provider = await chat_complete(
            messages=messages,
            json_mode=False,
            max_tokens=600,
            temperature=0.85,
        )
        return {
            "success": True,
            "message": text.strip() or _fallback_message(user_context)["message"],
            "plan_data": None,
            "tokens_used": 0,
            "provider": provider,
        }
    except Exception as e:
        return _fallback_message(user_context, str(e))


# ──────────────────────────────────────────────────────────────────────
# Quick motivation (2-3 sentences)
# ──────────────────────────────────────────────────────────────────────
async def generate_quick_motivation(user_context: dict) -> dict:
    if not configured_providers():
        return _fallback_message(user_context)

    name = user_context.get("name", "Talaba")
    streak = user_context.get("streak", 0)
    level = user_context.get("level", 1)
    lang = _lang_label(user_context.get("language", "uz"))
    prompt = (
        f"Talabaga juda qisqa (2-3 gap) motivatsion xabar yoz. "
        f"Ism: {name}, level: {level}, streak: {streak}. "
        f"Til: {lang}. Iliq, do'stona ohang. Faqat matn."
    )
    try:
        text, _ = await chat_complete(
            messages=[{"role": "user", "content": prompt}],
            max_tokens=120,
            temperature=0.9,
        )
        return {"success": True, "message": text.strip()}
    except Exception:
        return _fallback_message(user_context)


# ──────────────────────────────────────────────────────────────────────
# Progress analysis
# ──────────────────────────────────────────────────────────────────────
async def analyze_progress(user_context: dict, progress_data: list, active_plans: list) -> dict:
    if not configured_providers():
        return {"success": False, "message": _fallback_message(user_context)["message"]}

    lang = _lang_label(user_context.get("language", "uz"))
    prompt = (
        f"Talaba progressini qisqa (4-5 jumla) tahlil qil. "
        f"Ism: {user_context.get('name')}, XP: {user_context.get('xp')}, "
        f"daraja: {user_context.get('level')}, streak: {user_context.get('streak')}, "
        f"faol rejalar: {len(active_plans)}, "
        f"so'nggi faoliyatlar: {json.dumps(progress_data[:5], default=str)[:600]}\n"
        f"Til: {lang}. Konkret kuchli/zaif jihatlar va keyingi qadam ber."
    )
    try:
        text, _ = await chat_complete(
            messages=[{"role": "user", "content": prompt}],
            max_tokens=300,
            temperature=0.7,
        )
        return {"success": True, "message": text.strip()}
    except Exception as e:
        return {"success": False, "message": _fallback_message(user_context, str(e))["message"]}


# ──────────────────────────────────────────────────────────────────────
# Daily tip
# ──────────────────────────────────────────────────────────────────────
async def generate_daily_tip(category: str = "academic", language: str = "uz") -> dict:
    if not configured_providers():
        return {"success": False, "message": _fallback_message({"language": language})["message"]}

    lang = _lang_label(language)
    prompt = (
        f"'{category}' sohasida kunlik foydali maslahat yoz. "
        f"Til: {lang}. Qisqa, aniq, amaliy bo'lsin (3 jumla). "
        f"Faqat matn, JSON emas."
    )
    try:
        text, _ = await chat_complete(
            messages=[{"role": "user", "content": prompt}],
            max_tokens=120,
            temperature=0.7,
        )
        return {"success": True, "message": text.strip()}
    except Exception:
        return {"success": False, "message": _fallback_message({"language": language})["message"]}
