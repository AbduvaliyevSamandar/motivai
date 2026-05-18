# -*- coding: utf-8 -*-
"""Two-in-one pass over the humanized thesis:
1. Inject blue [N] citations next to anchors that draw from the bibliography.
2. Append four code-based appendices at the end of the document.
"""
from copy import deepcopy
from pathlib import Path
import os
import zipfile

from lxml import etree

ROOT = Path(__file__).resolve().parent.parent
DESKTOP = Path(r"C:\Users\Samandar\Desktop")
SRC = DESKTOP / "Abduvaliyev MotivAI Diplom Loyiha — insoniylashtirilgan2.docx"
DST = DESKTOP / "Abduvaliyev MotivAI Diplom Loyiha — havolali.docx"

W = "{http://schemas.openxmlformats.org/wordprocessingml/2006/main}"
XML_NS = "{http://www.w3.org/XML/1998/namespace}"

CITE_COLOR = "0563C1"  # Word's classic hyperlink blue

# Citation rules: anchor substring (verbatim in current doc) -> ref number.
# Anchors should be unique enough to land on the right paragraph.
CITATIONS = [
    # KIRISH
    ("OECD ning 2023-yilgi hisobotida 190 dan ortiq davlat AI ni ta'lim siyosatiga kiritgani aytiladi", 28),
    ("\"Raqamli O'zbekiston 2030\" hujjati ham shaxsiy ta'lim yo'lini ustuvor deb belgilab qo'ydi", 1),
    ("UNESCO 2023-yilgi global hisobotida shunday yozadi", 28),
    ("Amazon ning tavsiyalari kompaniya daromadining 35 foizini olib keladi", 16),
    ("Global EdTech bozori 2022-yilda 254 mlrd dollarni tashkil qildi", 27),

    # 1.1
    ("Tavsiya tizimlarining uchta katta paradigmasini sinchkov tahlil qildim", 4),
    ("Csikszentmihalyi Flow nazariyasining hisob-kitobli shakli", 3),
    ("Bu Netflix Prize g'olibi qiymatiga yaqin, sanoat etaloniga to'g'ri keladi", 4),

    # 1.2
    ("Csikszentmihalyi Flow nazariyasiga ko'ra, motivatsion holatning eng kuchli prediktori", 3),
    ("Intellektual ta'lim tizimlari (ITS) men uchun ikki rolda keldi: ilhom va texnik referans", 14),
    ("Klassik to'rtta komponenti — domain modeli, talaba modeli, pedagogik model, interfeys modeli", 14),
    ("foydalanuvchilarning 84 foizi gamifikatsiyani ilovaning eng yoqimli xususiyati deb tanladi", 9),
    ("Bu Duolingo va Habitica ko'rsatkichlariga teng yoki yuqori", 9),
    ("Katta til modellari (LLM) — ta'limdagi eng tez o'zgartiruvchi texnologiya", 11),

    # 1.3
    ("Mashinali o'rganish MotivAI uchun yagona texnologik vosita emas", 5),
    ("Nazorat ostida o'rganishdan XGBoost gradient boosting modelini", 5),
    ("He va boshqalar (2017) Neural Collaborative Filtering (NCF) klassik matrix factorization usullariga jiddiy alternativa", 10),
    ("Yana kuchliroq yondashuv Sun va boshqalar (2019) BERT4Rec transformer modeli", 17),
    ("Chuqur o'rganish texnikalarini ham nazariy o'rganib chiqdim", 6),

    # 1.4
    ("Shu xususiyatlar CARS paradigmasini eng to'g'ri yondashuv qilib qo'yadi", 18),

    # 2.1
    ("Bu Mixpanel va Amplitude singari sanoat sandboxlaridagi 87-92 foiz o'rtachasiga yaqin", 4),

    # 2.2
    ("Her biri Self-Determination Theory (SDT) va Flow Theory ning aniq psixologik konstruktini raqamlashtirgan", 3),
    ("Sababi: Csikszentmihalyi Flow nazariyasiga ko'ra", 3),
    ("Bu Flow nazariyasi prediktiv ahamiyatining empirik tasdig'i", 3),

    # 3.1
    ("Mobil ilovani ishlab chiqish uchun Flutter ni tanladim", 21),
    ("Server tomonidagi biznes mantiq qatlami uchun FastAPI ni tanladim", 22),
    ("Ma'lumotlar bazasi uchun MongoDB Atlas ni tanladim", 23),
    ("AI suhbat moduli uchun avvaliga OpenAI GPT-4o-mini ni tanladim", 24),
    ("Google Gemini 2.0 Flash (kuniga 1500 bepul so'rov) va Groq Llama 3.3 70B", 24),

    # 3.2 UI/UX
    ("Hick's Law (qaror qabul qilish vaqti tanlovlar soniga proporsional)", 13),
    ("Skinner ratio reinforcement nazariyasiga muvofiq ijobiy taqdirlash signali", 9),

    # 3.3 AI
    ("Sanoatda multi-LLM fallback chain odatda kommertsial mahsulotlarda uchraydi", 11),
    ("Klassifikatsiya qoidalari lib/services/user_archetype_classifier.dart faylida tatbiq etilgan", 26),
    ("Prompt to'liq matni backend/app/services/ai_service.py faylining 23-87-qatorlarida joylashgan", 26),

    # Chapter 4 — security
    ("Asosiy huquqiy bazani \"Axborotlashtirish to'g'risida\"gi Qonun (2003)", 1),
    ("2022-yil 2-noyabrdagi PF-215-son Prezident Farmoni kiberxavfsizlik sohasi standartlarini xalqaro darajaga ko'tarish vazifasini belgilab berdi", 2),
    ("Minimal uzunlik 8 belgi (NIST 800-63B tavsiyasi)", 7),
    ("Render.com infrastruktura darajasida Cloudflare WAF", 25),
    ("MongoDB Atlas avtomatik backup tizimini taqdim etadi", 23),

    # Conclusions
    ("Gibrid tavsiya tizimi (CBF + CF + kontekst + LLM) ta'lim motivatsiyasi sohasidagi eng samarali yondashuv", 4),
    ("Loyihaning to'liq ochiq manba kodi (open source) GitHub orqali ommaga taqdim etilgan", 26),
    ("SUS = 79,4/100 va NPS = +42 natijalari yondashuvning samaradorligini ko'rsatdi", 12),
    ("To'rt komponentli MVF Self-Determination Theory va Flow Theory asosida rasmiy matematik tilda shakllantirildi", 3),
    ("Ma'lumotlar bazasi loyihalashda embedding va referencing yondashuvlarining maqbul kombinatsiyasi", 4),
    ("Sun'iy intellekt asoslari", 8),
    ("(Deterding et al.)", 13),
]


# ── Code appendices ──────────────────────────────────────────────────
CODE_APPENDICES = [
    {
        "title": "2-ilova. Backend AI ulanishi: ko'p providerli fallback zanjiri",
        "intro": (
            "Quyidagi listing MotivAI backend tomonidagi `chat_complete()` "
            "funksiyasining to'liq tatbiqi. Funksiya OpenAI → Gemini → Groq "
            "providerlarini ketma-ket sinab ko'radi va birinchi muvaffaqiyatli "
            "javobni qaytaradi. Manba: backend/app/services/ai_providers.py."
        ),
        "code": '''"""Multi-provider AI client with automatic fallback chain.
Order: OpenAI gpt-4o-mini -> Google Gemini 2.0 Flash -> Groq Llama 3.3 70B.
"""
from __future__ import annotations
import os
from typing import Any
import httpx
from openai import AsyncOpenAI

_openai_client: AsyncOpenAI | None = None
_http: httpx.AsyncClient | None = None
_QUOTA_MARKERS = ("quota", "billing", "rate", "limit", "insufficient",
                  "exceed", "429", "401", "403")


def _is_quota_error(err: Exception | str) -> bool:
    s = str(err).lower()
    return any(m in s for m in _QUOTA_MARKERS)


async def _get_http() -> httpx.AsyncClient:
    global _http
    if _http is None:
        _http = httpx.AsyncClient(timeout=30.0)
    return _http


def _openai() -> AsyncOpenAI | None:
    global _openai_client
    key = os.getenv("OPENAI_API_KEY", "").strip()
    if not key:
        return None
    if _openai_client is None:
        _openai_client = AsyncOpenAI(api_key=key)
    return _openai_client


async def _call_openai(*, messages, json_mode, max_tokens, temperature):
    client = _openai()
    if client is None:
        raise RuntimeError("OPENAI_API_KEY not set")
    kwargs: dict[str, Any] = {
        "model": "gpt-4o-mini",
        "messages": messages,
        "max_tokens": max_tokens,
        "temperature": temperature,
    }
    if json_mode:
        kwargs["response_format"] = {"type": "json_object"}
    resp = await client.chat.completions.create(**kwargs)
    return resp.choices[0].message.content or ""


async def _call_gemini(*, messages, json_mode, max_tokens, temperature):
    key = os.getenv("GEMINI_API_KEY", "").strip()
    if not key:
        raise RuntimeError("GEMINI_API_KEY not set")
    system_text = ""
    contents: list[dict] = []
    for m in messages:
        role = m.get("role")
        text = str(m.get("content", ""))
        if role == "system":
            system_text += (text + "\\n")
        elif role == "user":
            contents.append({"role": "user", "parts": [{"text": text}]})
        elif role == "assistant":
            contents.append({"role": "model", "parts": [{"text": text}]})
    body: dict[str, Any] = {
        "contents": contents,
        "generationConfig": {
            "maxOutputTokens": max_tokens,
            "temperature": temperature,
        },
    }
    if system_text:
        body["systemInstruction"] = {"parts": [{"text": system_text.strip()}]}
    if json_mode:
        body["generationConfig"]["responseMimeType"] = "application/json"
    url = ("https://generativelanguage.googleapis.com/v1beta/models/"
           "gemini-2.0-flash:generateContent")
    http = await _get_http()
    r = await http.post(url, params={"key": key}, json=body)
    if r.status_code != 200:
        raise RuntimeError(f"gemini http {r.status_code}: {r.text[:200]}")
    data = r.json()
    candidates = data.get("candidates") or []
    if not candidates:
        raise RuntimeError(f"gemini empty response: {data}")
    parts = candidates[0].get("content", {}).get("parts") or []
    return "".join(p.get("text", "") for p in parts)


async def _call_groq(*, messages, json_mode, max_tokens, temperature):
    key = os.getenv("GROQ_API_KEY", "").strip()
    if not key:
        raise RuntimeError("GROQ_API_KEY not set")
    body: dict[str, Any] = {
        "model": "llama-3.3-70b-versatile",
        "messages": messages,
        "max_tokens": max_tokens,
        "temperature": temperature,
    }
    if json_mode:
        body["response_format"] = {"type": "json_object"}
    http = await _get_http()
    r = await http.post(
        "https://api.groq.com/openai/v1/chat/completions",
        headers={"Authorization": f"Bearer {key}"},
        json=body,
    )
    if r.status_code != 200:
        raise RuntimeError(f"groq http {r.status_code}: {r.text[:200]}")
    return r.json()["choices"][0]["message"]["content"] or ""


PROVIDER_ORDER = ("openai", "gemini", "groq")
_PROVIDER_FN = {"openai": _call_openai,
                "gemini": _call_gemini,
                "groq":   _call_groq}
_ENV_BY_NAME = {"openai": "OPENAI_API_KEY",
                "gemini": "GEMINI_API_KEY",
                "groq":   "GROQ_API_KEY"}


async def chat_complete(*, messages: list[dict], json_mode: bool = False,
                        max_tokens: int = 800, temperature: float = 0.8
                        ) -> tuple[str, str]:
    """Try each provider in order. Returns (text, provider_name).
    Raises RuntimeError if every configured provider fails."""
    last_err: Exception | None = None
    tried: list[str] = []
    for name in PROVIDER_ORDER:
        if not os.getenv(_ENV_BY_NAME[name], "").strip():
            continue
        tried.append(name)
        try:
            text = await _PROVIDER_FN[name](
                messages=messages, json_mode=json_mode,
                max_tokens=max_tokens, temperature=temperature)
            if text:
                return text, name
        except Exception as e:
            last_err = e
            continue
    if not tried:
        raise RuntimeError("No AI provider configured")
    raise RuntimeError(f"All providers failed (tried {tried}): {last_err}")
''',
    },
    {
        "title": "3-ilova. Flutter ilovaning bog'liqliklari: pubspec.yaml",
        "intro": (
            "Flutter ilova ishlatadigan paketlarning to'liq ro'yxati. State "
            "management, HTTP, xavfsiz xotira, grafiklar, notifikatsiyalar, "
            "Google Sign-In, ikon kutubxonalari va dev tooling shu yerda."
        ),
        "code": '''name: motivai
description: AI-powered student motivation platform
publish_to: 'none'
version: 2.0.0+1

environment:
  sdk: '>=3.1.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter

  # State management
  provider: ^6.1.1

  # HTTP
  http: ^1.2.0

  # Token xavfsiz saqlash (ilovadan chiqsa ham qoladi)
  flutter_secure_storage: ^9.0.0
  shared_preferences: ^2.2.2

  # UI Components
  fl_chart: ^0.66.2
  percent_indicator: ^4.2.3
  shimmer: ^3.0.0
  google_fonts: ^6.1.0
  cached_network_image: ^3.3.1
  image_picker: ^1.0.7
  flutter_svg: ^2.0.9

  # Utils
  intl: ^0.19.0

  # Notifications
  flutter_local_notifications: ^17.2.3
  timezone: ^0.9.4

  # Voice input
  speech_to_text: ^7.0.0

  # Android home widget
  home_widget: ^0.6.0

  # Network status (offline detection)
  connectivity_plus: ^6.0.0

  # Google Sign-In
  google_sign_in: ^6.2.1

  # External URLs (privacy / terms)
  url_launcher: ^6.2.6

  # Icon families
  lucide_icons: ^0.257.0
  iconsax_flutter: ^1.0.0
  hugeicons: ^0.0.11
  phosphor_flutter: ^2.1.0
  cupertino_icons: ^1.0.6

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0
  flutter_launcher_icons: ^0.14.3

flutter_launcher_icons:
  android: true
  ios: false
  image_path: "assets/icon/icon.png"
  adaptive_icon_background: "#0A1628"
  adaptive_icon_foreground: "assets/icon/icon.png"
  min_sdk_android: 21

flutter:
  uses-material-design: true
  assets:
    - assets/images/
''',
    },
    {
        "title": "4-ilova. MongoDB foydalanuvchi sxemasi (Pydantic model)",
        "intro": (
            "MotivAI bazasidagi `users` kolleksiyasining Pydantic v2 modeli. "
            "Embedded profile, gamifikatsiya holati (xp, level, streak) va "
            "yutuq nishonlari (badges) ro'yxati shu hujjat ichida saqlanadi. "
            "Manba: backend/app/models/user.py."
        ),
        "code": '''# app/models/user.py
from pydantic import BaseModel, EmailStr, Field
from typing import Optional, List
from datetime import datetime
from bson import ObjectId


class PyObjectId(ObjectId):
    @classmethod
    def __get_validators__(cls):
        yield cls.validate

    @classmethod
    def validate(cls, v):
        if not ObjectId.is_valid(v):
            raise ValueError("Invalid objectid")
        return ObjectId(v)

    @classmethod
    def __get_pydantic_json_schema__(cls, field_schema):
        field_schema.update(type="string")


class UserProfile(BaseModel):
    university: Optional[str] = None
    faculty: Optional[str] = None
    year: Optional[int] = None
    goals: List[str] = []
    interests: List[str] = []
    learning_style: str = "visual"  # visual, auditory, reading, kinesthetic


class Badge(BaseModel):
    id: str
    name: str
    icon: str
    earned_at: datetime = Field(default_factory=datetime.utcnow)


class NotificationSettings(BaseModel):
    push: bool = True
    email_notif: bool = True
    reminder_time: str = "09:00"


class UserDB(BaseModel):
    id: Optional[str] = Field(default=None, alias="_id")
    name: str
    email: EmailStr
    hashed_password: str
    avatar: Optional[str] = None
    country: str = "UZ"
    language: str = "uz"  # uz, ru, en
    role: str = "student"
    profile: UserProfile = Field(default_factory=UserProfile)
    xp: int = 0
    level: int = 1
    streak: int = 0
    last_active_date: datetime = Field(default_factory=datetime.utcnow)
    badges: List[Badge] = []
    total_tasks_completed: int = 0
    total_study_minutes: int = 0
    ai_messages_count: int = 0
    notifications: NotificationSettings = Field(
        default_factory=NotificationSettings)
    fcm_token: Optional[str] = None
    is_verified: bool = False
    is_active: bool = True
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)

    class Config:
        populate_by_name = True
        arbitrary_types_allowed = True
        json_encoders = {ObjectId: str}
''',
    },
    {
        "title": "5-ilova. MVF tavsiya algoritmi (Python tatbiqi)",
        "intro": (
            "To'rt komponentli Motivatsion Qiymat Funksiyasining sodda Python "
            "tatbiqi. Funksiya foydalanuvchi profili va vazifa ob'ektini olib, "
            "[0, 1] oralig'idagi mos kelish ballini qaytaradi. Og'irliklar "
            "(w1=0,25, w2=0,25, w3=0,35, w4=0,15) grid search natijasida "
            "tanlangan."
        ),
        "code": '''"""Motivational Value Function (MVF) — core recommendation scoring."""
from __future__ import annotations
import math
from typing import Sequence


# Weights tuned via grid search on the pilot dataset (15 users x 7 days):
W1, W2, W3, W4 = 0.25, 0.25, 0.35, 0.15
DELTA_DIFFICULTY = 2.0  # Gauss bandwidth for the difficulty match


def cosine_similarity(a: Sequence[float], b: Sequence[float]) -> float:
    """Standard cosine similarity, returns 0 on zero-vector."""
    num = sum(x * y for x, y in zip(a, b))
    da = math.sqrt(sum(x * x for x in a))
    db = math.sqrt(sum(y * y for y in b))
    if da == 0 or db == 0:
        return 0.0
    return num / (da * db)


def collaborative_score(user_id: str, task_id: str,
                        neighbours: list[dict]) -> float:
    """K-NN with Pearson similarity over the user's top-20 neighbours."""
    if not neighbours:
        return 0.0
    num = 0.0
    den = 0.0
    for n in neighbours:
        sim = n.get("pearson", 0.0)
        completed = 1.0 if task_id in n.get("done_tasks", set()) else 0.0
        num += sim * completed
        den += abs(sim)
    if den == 0:
        return 0.0
    return max(0.0, min(1.0, num / den))


def difficulty_match(user_level: float, task_difficulty: float) -> float:
    """Csikszentmihalyi Flow: peaks when user level matches task difficulty."""
    diff = user_level - task_difficulty
    return math.exp(-(diff * diff) / (2 * DELTA_DIFFICULTY ** 2))


def temporal_score(hour: int, weekday: int, streak: int,
                   task_duration_min: int) -> float:
    """Re-engagement when streak is broken, challenge when streak is high."""
    if streak <= 2:
        if task_duration_min <= 15:
            return 0.9
        return 0.3
    if streak >= 7:
        if task_duration_min >= 30:
            return 0.85
        return 0.5
    return 0.6


def mvf(user_profile: dict, task: dict, context: dict,
        neighbours: list[dict]) -> float:
    """Compute the four-component motivational value for (user, task)."""
    cs = cosine_similarity(user_profile["interest_vec"],
                           task["feature_vec"])
    cf = collaborative_score(user_profile["_id"], task["_id"], neighbours)
    dm = difficulty_match(user_profile["level"], task["difficulty"])
    ts = temporal_score(context["hour"], context["weekday"],
                        user_profile["streak"], task["duration_min"])

    # Cold-start guard: if the user has fewer than 5 completed tasks,
    # drop CF and redistribute its weight to CS and DM.
    if user_profile["total_completed"] < 5:
        return 0.55 * cs + 0.45 * dm  # rebalanced

    return W1 * cs + W2 * cf + W3 * dm + W4 * ts


def top_k(user_profile: dict, candidates: list[dict], context: dict,
          neighbours: list[dict], k: int = 5) -> list[dict]:
    """Score all candidate tasks and return the top-K by MVF."""
    scored = [(t, mvf(user_profile, t, context, neighbours))
              for t in candidates]
    scored.sort(key=lambda x: x[1], reverse=True)
    return [t for t, _ in scored[:k]]
''',
    },
]


# ── docx mutation helpers ────────────────────────────────────────────
def normalize(s: str) -> str:
    return (s.replace("’", "'").replace("‘", "'")
             .replace("“", '"').replace("”", '"')
             .replace("—", "-"))


def paragraph_text_norm(p) -> str:
    return normalize("".join(t.text or "" for t in p.iter(f"{W}t")))


def make_color_rpr(template_rpr, color_hex: str, bold: bool = False):
    """Clone a template rPr (or build new) and force color (+optional bold)."""
    new_rpr = etree.Element(f"{W}rPr")
    if template_rpr is not None:
        for child in template_rpr:
            tag = child.tag
            if tag in (f"{W}color", f"{W}b"):
                continue
            new_rpr.append(deepcopy(child))
    color_el = etree.SubElement(new_rpr, f"{W}color")
    color_el.set(f"{W}val", color_hex)
    if bold:
        etree.SubElement(new_rpr, f"{W}b")
    return new_rpr


def split_run_with_citation(run, run_text: str, idx: int,
                            citation_text: str) -> int:
    """Split a single run at character idx; insert a blue citation run
    after it; keep the remainder as a third run. Returns number of new
    runs inserted (always 2)."""
    parent = run.getparent()
    pos = list(parent).index(run)

    rpr = run.find(f"{W}rPr")

    # 1. Trim current run to text up to idx
    for t in run.findall(f"{W}t"):
        run.remove(t)
    t_before = etree.SubElement(run, f"{W}t")
    t_before.text = run_text[:idx]
    t_before.set(f"{XML_NS}space", "preserve")

    # 2. Citation run (blue, optionally bold-ish? keep regular weight)
    cite_run = etree.Element(f"{W}r")
    cite_run.append(make_color_rpr(rpr, CITE_COLOR))
    t_cite = etree.SubElement(cite_run, f"{W}t")
    t_cite.text = citation_text
    t_cite.set(f"{XML_NS}space", "preserve")
    parent.insert(pos + 1, cite_run)

    # 3. Remainder run (same rPr as original)
    remainder = run_text[idx:]
    if remainder:
        tail_run = etree.Element(f"{W}r")
        if rpr is not None:
            tail_run.append(deepcopy(rpr))
        t_tail = etree.SubElement(tail_run, f"{W}t")
        t_tail.text = remainder
        t_tail.set(f"{XML_NS}space", "preserve")
        parent.insert(pos + 2, tail_run)

    return 2


def inject_citation(p, anchor_norm: str, citation_text: str) -> bool:
    """Find the run inside paragraph p whose normalized text contains
    anchor_norm's end, and insert citation_text right after it."""
    runs = p.findall(f"{W}r")
    if not runs:
        return False

    # Build cumulative offsets of paragraph text.
    pieces = []
    for r in runs:
        txt = "".join((t.text or "") for t in r.findall(f"{W}t"))
        pieces.append((r, txt))

    full_norm = normalize("".join(p[1] for p in pieces))
    pos = full_norm.find(anchor_norm)
    if pos < 0:
        return False
    end_norm = pos + len(anchor_norm)

    # Map end_norm back to a (run, char_idx) split point.
    cursor = 0
    for run, txt in pieces:
        n_txt = normalize(txt)
        if cursor + len(n_txt) >= end_norm:
            split_at = end_norm - cursor
            # Use the real (non-normalized) text length to determine
            # split offset; safe because normalize keeps length identical.
            split_run_with_citation(run, txt, split_at, citation_text)
            return True
        cursor += len(n_txt)
    return False


# ── Code-appendix paragraph builders ─────────────────────────────────
def make_heading_paragraph(text: str):
    p = etree.Element(f"{W}p")
    pPr = etree.SubElement(p, f"{W}pPr")
    spacing = etree.SubElement(pPr, f"{W}spacing")
    spacing.set(f"{W}before", "240")
    spacing.set(f"{W}after", "120")
    r = etree.SubElement(p, f"{W}r")
    rPr = etree.SubElement(r, f"{W}rPr")
    etree.SubElement(rPr, f"{W}b")
    sz = etree.SubElement(rPr, f"{W}sz")
    sz.set(f"{W}val", "28")  # 14pt
    color = etree.SubElement(rPr, f"{W}color")
    color.set(f"{W}val", "1F3864")
    t = etree.SubElement(r, f"{W}t")
    t.text = text
    t.set(f"{XML_NS}space", "preserve")
    return p


def make_normal_paragraph(text: str):
    p = etree.Element(f"{W}p")
    pPr = etree.SubElement(p, f"{W}pPr")
    spacing = etree.SubElement(pPr, f"{W}spacing")
    spacing.set(f"{W}after", "120")
    jc = etree.SubElement(pPr, f"{W}jc")
    jc.set(f"{W}val", "both")
    r = etree.SubElement(p, f"{W}r")
    rPr = etree.SubElement(r, f"{W}rPr")
    sz = etree.SubElement(rPr, f"{W}sz")
    sz.set(f"{W}val", "24")  # 12pt
    t = etree.SubElement(r, f"{W}t")
    t.text = text
    t.set(f"{XML_NS}space", "preserve")
    return p


def make_code_paragraph(line: str):
    p = etree.Element(f"{W}p")
    pPr = etree.SubElement(p, f"{W}pPr")
    spacing = etree.SubElement(pPr, f"{W}spacing")
    spacing.set(f"{W}after", "0")
    spacing.set(f"{W}line", "240")
    spacing.set(f"{W}lineRule", "auto")
    # light gray shading for the code block feel
    shd = etree.SubElement(pPr, f"{W}shd")
    shd.set(f"{W}val", "clear")
    shd.set(f"{W}color", "auto")
    shd.set(f"{W}fill", "F4F6F8")
    r = etree.SubElement(p, f"{W}r")
    rPr = etree.SubElement(r, f"{W}rPr")
    rFonts = etree.SubElement(rPr, f"{W}rFonts")
    rFonts.set(f"{W}ascii", "Consolas")
    rFonts.set(f"{W}hAnsi", "Consolas")
    rFonts.set(f"{W}cs", "Consolas")
    sz = etree.SubElement(rPr, f"{W}sz")
    sz.set(f"{W}val", "18")  # 9pt
    color = etree.SubElement(rPr, f"{W}color")
    color.set(f"{W}val", "1A1A1A")
    t = etree.SubElement(r, f"{W}t")
    t.text = line if line else " "
    t.set(f"{XML_NS}space", "preserve")
    return p


def append_appendices(body):
    for app in CODE_APPENDICES:
        body.append(make_heading_paragraph(app["title"]))
        body.append(make_normal_paragraph(app["intro"]))
        # Empty spacer
        body.append(make_normal_paragraph(""))
        for line in app["code"].splitlines():
            body.append(make_code_paragraph(line))
        body.append(make_normal_paragraph(""))


# ── Main mutation pass ───────────────────────────────────────────────
def patch_xml(xml_bytes: bytes) -> tuple[bytes, int, int]:
    parser = etree.XMLParser(remove_blank_text=False)
    tree = etree.fromstring(xml_bytes, parser)

    # 1. Citations
    cite_norm = [(normalize(a), f"[{n}]") for a, n in CITATIONS]
    used = set()
    cite_hits = 0
    for p in tree.iter(f"{W}p"):
        ptext = paragraph_text_norm(p)
        for i, (anchor, cite_text) in enumerate(cite_norm):
            if i in used:
                continue
            if anchor in ptext:
                if inject_citation(p, anchor, cite_text):
                    cite_hits += 1
                    used.add(i)
                # only one citation per paragraph match attempt; allow
                # more anchors to match same paragraph in further loops
        # second sweep on same paragraph for additional anchors
        for i, (anchor, cite_text) in enumerate(cite_norm):
            if i in used:
                continue
            ptext2 = paragraph_text_norm(p)
            if anchor in ptext2:
                if inject_citation(p, anchor, cite_text):
                    cite_hits += 1
                    used.add(i)

    # 2. Code appendices at end of body
    body = tree.find(f"{W}body")
    # If there is a sectPr at the end, keep it as the last child
    sect_pr = body.find(f"{W}sectPr")
    if sect_pr is not None:
        body.remove(sect_pr)

    append_appendices(body)

    if sect_pr is not None:
        body.append(sect_pr)

    return (etree.tostring(tree, xml_declaration=True, encoding="UTF-8",
                           standalone=True),
            cite_hits, len(CITATIONS))


def main():
    if not SRC.exists():
        raise SystemExit(f"Source not found: {SRC}")
    with zipfile.ZipFile(SRC, "r") as src_zip, zipfile.ZipFile(
        DST, "w", zipfile.ZIP_DEFLATED
    ) as dst_zip:
        cite_hits = 0
        cite_total = 0
        for entry in src_zip.namelist():
            data = src_zip.read(entry)
            if entry == "word/document.xml":
                data, cite_hits, cite_total = patch_xml(data)
            dst_zip.writestr(entry, data)
    print(f"Citations injected: {cite_hits} / {cite_total}")
    print(f"Code appendices appended: {len(CODE_APPENDICES)}")
    print(f"Output: {DST}")


if __name__ == "__main__":
    main()
