"""
Multi-provider AI client with automatic fallback chain.

Order: OpenAI gpt-4o-mini → Google Gemini 2.0 Flash → Groq Llama 3.3 70B.
Each provider can be skipped (no API key) — the chain just moves to the
next one. If all providers fail (quota / network / 5xx), the caller should
fall back to a rule-based template.

Env vars (any subset, in priority order):
  OPENAI_API_KEY    — gpt-4o-mini
  GEMINI_API_KEY    — Google AI Studio key (free 1500 req/day)
  GROQ_API_KEY      — Groq Cloud key (free, very fast Llama)

All providers are called via httpx so we have a single transport layer.
We don't pull in google-generativeai or groq SDKs — REST is cheaper and
keeps requirements.txt small.
"""
from __future__ import annotations

import json
import logging
import os
from typing import Any

import httpx
from openai import AsyncOpenAI

log = logging.getLogger("ai_providers")

# ── Module-level clients (lazy init) ───────────────────────────────────
_openai_client: AsyncOpenAI | None = None
_http: httpx.AsyncClient | None = None

# These error markers tell us "this provider is exhausted, try next".
_QUOTA_ERROR_MARKERS = (
    "quota", "billing", "rate", "limit", "insufficient",
    "exceed", "429", "401", "403",
)


def _is_quota_error(err: Exception | str) -> bool:
    s = str(err).lower()
    return any(m in s for m in _QUOTA_ERROR_MARKERS)


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


# ── Provider 1: OpenAI ────────────────────────────────────────────────
async def _call_openai(
    *, messages: list[dict], json_mode: bool, max_tokens: int, temperature: float
) -> str:
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


# ── Provider 2: Google Gemini 2.0 Flash ───────────────────────────────
# Docs: https://ai.google.dev/gemini-api/docs/text-generation
# Free tier: 1500 req/day, 60 req/min on gemini-2.0-flash-exp.
async def _call_gemini(
    *, messages: list[dict], json_mode: bool, max_tokens: int, temperature: float
) -> str:
    key = os.getenv("GEMINI_API_KEY", "").strip()
    if not key:
        raise RuntimeError("GEMINI_API_KEY not set")

    # Gemini wants a single 'system_instruction' + 'contents' (alternating
    # user/model). Squash our OpenAI-shape messages into that format.
    system_text = ""
    contents: list[dict] = []
    for m in messages:
        role = m.get("role")
        text = str(m.get("content", ""))
        if role == "system":
            system_text += (text + "\n")
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

    url = (
        "https://generativelanguage.googleapis.com/v1beta/models/"
        "gemini-2.0-flash:generateContent"
    )
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


# ── Provider 3: Groq Cloud (Llama 3.3 70B) ────────────────────────────
# Docs: https://console.groq.com/docs/api-reference
# Free tier: ~30 req/min on llama-3.3-70b-versatile, very fast inference.
async def _call_groq(
    *, messages: list[dict], json_mode: bool, max_tokens: int, temperature: float
) -> str:
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
    data = r.json()
    return data["choices"][0]["message"]["content"] or ""


# ── Public: unified chat completion with fallback ─────────────────────
PROVIDER_ORDER = ("openai", "gemini", "groq")
_PROVIDER_FN = {
    "openai": _call_openai,
    "gemini": _call_gemini,
    "groq":   _call_groq,
}


async def chat_complete(
    *,
    messages: list[dict],
    json_mode: bool = False,
    max_tokens: int = 800,
    temperature: float = 0.8,
) -> tuple[str, str]:
    """Try each provider in order. Returns (text, provider_name).

    Raises RuntimeError only if every provider that's configured fails.
    Providers without an API key are silently skipped.
    """
    last_err: Exception | None = None
    tried: list[str] = []
    for name in PROVIDER_ORDER:
        # Skip providers without keys — they can't fail, they just don't exist.
        env_key = {"openai": "OPENAI_API_KEY", "gemini": "GEMINI_API_KEY",
                   "groq": "GROQ_API_KEY"}[name]
        if not os.getenv(env_key, "").strip():
            continue
        tried.append(name)
        try:
            text = await _PROVIDER_FN[name](
                messages=messages,
                json_mode=json_mode,
                max_tokens=max_tokens,
                temperature=temperature,
            )
            if text:
                log.info("ai_providers: served by %s", name)
                return text, name
            log.warning("ai_providers: %s returned empty, falling through", name)
        except Exception as e:
            last_err = e
            level = logging.INFO if _is_quota_error(e) else logging.WARNING
            log.log(level, "ai_providers: %s failed (%s); trying next", name, e)
            continue
    if not tried:
        raise RuntimeError("No AI provider configured (set OPENAI_API_KEY, GEMINI_API_KEY, or GROQ_API_KEY)")
    raise RuntimeError(f"All providers failed (tried {tried}): {last_err}")


def configured_providers() -> list[str]:
    """Reporting helper — which providers have keys set."""
    return [
        name for name in PROVIDER_ORDER
        if os.getenv({"openai": "OPENAI_API_KEY", "gemini": "GEMINI_API_KEY",
                      "groq": "GROQ_API_KEY"}[name], "").strip()
    ]


async def chat_json(
    *,
    messages: list[dict],
    max_tokens: int = 800,
    temperature: float = 0.8,
) -> tuple[dict, str]:
    """Call chat_complete with json_mode and parse. Falls back to dict
    with raw text under 'response' if JSON parsing fails."""
    text, provider = await chat_complete(
        messages=messages,
        json_mode=True,
        max_tokens=max_tokens,
        temperature=temperature,
    )
    try:
        return json.loads(text), provider
    except json.JSONDecodeError:
        return {"response": text, "suggested_tasks": None}, provider
