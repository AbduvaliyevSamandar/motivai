# app/services/ai_service.py
import os
import json
import openai
from typing import List
from dotenv import load_dotenv

# Load API key from .env
load_dotenv()
client = openai.OpenAI(api_key=os.getenv("OPENAI_API_KEY"))


# ==============================
# Main AI chat function
# ==============================
async def chat_with_ai(
    message: str,
    user_context: dict,
    conversation_history: List[dict] = []
) -> dict:
    """
    Talabaga motivatsiya xabari yaratadi (GPT-3.5)
    """
    messages = [
        {"role": "system", "content": "Siz motivatsiya botisiz. Qisqa, ilhomlantiruvchi va aniq javoblar berasiz."}
    ]

    for ch in conversation_history[-5:]:
        messages.append({"role": ch.get("role", "user"), "content": ch["content"]})

    user_prompt = (
        f"Talabaga motivatsiya xabari: {message}\n"
        f"Foydalanuvchi: {user_context.get('name', 'Talaba')}, "
        f"streak: {user_context.get('streak', 0)}, "
        f"level: {user_context.get('level', 1)}"
    )
    messages.append({"role": "user", "content": user_prompt})

    try:
        response = client.chat.completions.create(
            model="gpt-3.5-turbo",
            messages=messages,
            max_tokens=300,
            temperature=0.7
        )
        text = response.choices[0].message.content
        tokens_used = response.usage.total_tokens
        return {"success": True, "message": text, "plan_data": None, "tokens_used": tokens_used}

    except openai.RateLimitError:
        return {"success": False, "message": "API quota tugadi, iltimos billingni tekshiring.", "plan_data": None, "tokens_used": 0}
    
    except openai.APIError as e:
        return {"success": False, "message": f"OpenAI API xatosi: {str(e)}", "plan_data": None, "tokens_used": 0}
    
    except Exception as e:
        return {"success": False, "message": f"Xatolik yuz berdi: {str(e)}", "plan_data": None, "tokens_used": 0}


# ==============================
# Quick motivation xabari
# ==============================
async def generate_quick_motivation(user_context: dict) -> dict:
    prompt = (
        f"Talabaga qisqa (2-3 gap) motivatsion xabar yoz. "
        f"Ism: {user_context.get('name', 'Talaba')}, "
        f"streak: {user_context.get('streak', 0)}, level: {user_context.get('level', 1)}"
    )

    try:
        response = client.chat.completions.create(
            model="gpt-3.5-turbo",
            messages=[{"role": "user", "content": prompt}],
            max_tokens=100,
            temperature=0.7
        )
        text = response.choices[0].message.content
        return {"success": True, "message": text}

    except openai.RateLimitError:
        return {"success": False, "message": "API quota tugadi, iltimos billingni tekshiring."}

    except openai.APIError as e:
        return {"success": False, "message": f"OpenAI API xatosi: {str(e)}"}


# ==============================
# Progress tahlili
# ==============================
async def analyze_progress(user_context: dict, progress_data: list, active_plans: list) -> dict:
    prompt = (
        f"Talaba progressini tahlil qil: "
        f"Ism: {user_context.get('name')}, XP: {user_context.get('xp')}, "
        f"level: {user_context.get('level')}, streak: {user_context.get('streak')}, "
        f"faol rejalar: {len(active_plans)}, so'nggi faoliyatlar: {json.dumps(progress_data[:5], default=str)}"
    )

    try:
        response = client.chat.completions.create(
            model="gpt-3.5-turbo",
            messages=[{"role": "user", "content": prompt}],
            max_tokens=300,
            temperature=0.7
        )
        text = response.choices[0].message.content
        return {"success": True, "message": text}

    except openai.RateLimitError:
        return {"success": False, "message": "API quota tugadi, iltimos billingni tekshiring."}

    except openai.APIError as e:
        return {"success": False, "message": f"OpenAI API xatosi: {str(e)}"}


# ==============================
# Daily tip yaratish
# ==============================
async def generate_daily_tip(category: str = "academic", language: str = "uz") -> dict:
    prompt = (
        f"'{category}' sohasida kunlik foydali maslahat yoz. Til: {language}. "
        f"Qisqa, aniq va amaliy bo'lsin (3-4 gap)."
    )

    try:
        response = client.chat.completions.create(
            model="gpt-3.5-turbo",
            messages=[{"role": "user", "content": prompt}],
            max_tokens=100,
            temperature=0.7
        )
        text = response.choices[0].message.content
        return {"success": True, "message": text}

    except openai.RateLimitError:
        return {"success": False, "message": "API quota tugadi, iltimos billingni tekshiring."}

    except openai.APIError as e:
        return {"success": False, "message": f"OpenAI API xatosi: {str(e)}"}