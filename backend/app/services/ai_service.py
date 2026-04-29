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
        f"5. Markdown qo'llasangiz **qalin** va emojilardan foyda — boshqa formatlash yo'q.\n\n"
        f"OUTPUT FORMAT (JSON, nothing else, no markdown fences):\n"
        f'{{"response": "...sizning matnli javobingiz...", '
        f'"suggested_tasks": [{{"title": "...", "description": "...", '
        f'"category": "study|exercise|reading|meditation|social|creative|productivity|challenge", '
        f'"difficulty": "easy|medium|hard|expert", "duration_minutes": 30, '
        f'"estimated_points": 50}}]}}\n\n'
        f"VAZIFA TAVSIYA QILISH — DEFAULT YOQILGAN:\n"
        f"- DOIMO 2..4 ta vazifa qaytar. Sukut yo'q — har xabarga vazifa kerak.\n"
        f"- Foydalanuvchi xabari qisqa bo'lsa ham (masalan 'salom', 'charchadim', "
        f"'nima qilay') — uning holati va profilidan kelib chiqib mos vazifa yarat.\n"
        f"  Charchagan bo'lsa: kichik/oson vazifalar (10-20 daqiqa). "
        f"Maqsadi haqida gapirsa: shu sohada vazifalar. "
        f"Salom desa: bugungi maqsadiga qadam — qiziqishlariga mos.\n"
        f"- FAQAT mavhum bilim savoli bo'lsa (masalan 'Eyfel minorasi qachon qurilgan?') "
        f"vazifa qo'shma — suggested_tasks: [].\n"
        f"- duration_minutes 15..120, estimated_points 10..200 oralig'ida.\n"
        f"- title qisqa va harakat-fe'li bilan (5-10 so'z, masalan 'Algebra: 20 ta misol yech'), "
        f"description 1-2 jumla — nima va qanday qilishni aniq aytsin.\n"
        f"- Vazifalar bir-biriga aralashmasin, har biri alohida amaliy qadam bo'lsin.\n"
        f"- Til: barcha matn (response, title, description) {_lang_label(lang_code)} tilida."
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
            json_mode=True,
            max_tokens=900,
            temperature=0.85,
        )
    except Exception as e:
        return _fallback_message(user_context, str(e))

    # Parse JSON. If the model misformatted, treat full text as the message
    # and skip suggestions rather than failing the whole chat.
    parsed: dict = {}
    try:
        parsed = json.loads(text)
    except json.JSONDecodeError:
        # Some providers wrap in ```json ... ``` even when asked not to.
        cleaned = text.strip().lstrip("`")
        if cleaned.startswith("json\n"):
            cleaned = cleaned[5:]
        cleaned = cleaned.rstrip("`").strip()
        try:
            parsed = json.loads(cleaned)
        except Exception:
            log.warning("ai_service: %s returned non-JSON; using raw text", provider)
            parsed = {"response": text.strip(), "suggested_tasks": []}

    response_text = (parsed.get("response") or "").strip()
    if not response_text:
        response_text = _fallback_message(user_context)["message"]

    raw_tasks = parsed.get("suggested_tasks") or []
    if not isinstance(raw_tasks, list):
        raw_tasks = []

    # Normalise / sanity-check each task so the client gets clean shape.
    valid_categories = {"study", "exercise", "reading", "meditation", "social",
                        "creative", "productivity", "challenge"}
    valid_difficulty = {"easy", "medium", "hard", "expert"}
    suggested: list[dict] = []
    for t in raw_tasks[:5]:  # cap at 5
        if not isinstance(t, dict):
            continue
        title = (t.get("title") or "").strip()
        if not title:
            continue
        cat = (t.get("category") or "study").lower()
        diff = (t.get("difficulty") or "medium").lower()
        try:
            dur = int(t.get("duration_minutes") or 30)
        except (TypeError, ValueError):
            dur = 30
        try:
            pts = int(t.get("estimated_points") or 50)
        except (TypeError, ValueError):
            pts = 50
        suggested.append({
            "title": title,
            "description": (t.get("description") or "").strip(),
            "category": cat if cat in valid_categories else "study",
            "difficulty": diff if diff in valid_difficulty else "medium",
            "duration_minutes": max(15, min(120, dur)),
            "estimated_points": max(10, min(200, pts)),
        })

    return {
        "success": True,
        "message": response_text,
        "suggested_tasks": suggested if suggested else None,
        "plan_data": None,
        "tokens_used": 0,
        "provider": provider,
    }


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
