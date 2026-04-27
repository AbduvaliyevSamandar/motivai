# app/services/email_service.py
"""Email delivery via SMTP (Gmail-compatible).

Configure via env: SMTP_HOST, SMTP_PORT, SMTP_USER, SMTP_PASSWORD,
SMTP_FROM_NAME, SMTP_FROM_EMAIL. If SMTP_USER is empty, this falls back to
logging the OTP to stdout (handy for local dev — never use in prod).
"""
from __future__ import annotations

import logging
import smtplib
from email.message import EmailMessage
from typing import Optional

from app.core.config import settings

logger = logging.getLogger(__name__)


def _build_message(*, to: str, subject: str, html: str, text: str) -> EmailMessage:
    msg = EmailMessage()
    msg["Subject"] = subject
    msg["To"] = to
    from_email = settings.SMTP_FROM_EMAIL or settings.SMTP_USER
    if settings.SMTP_FROM_NAME:
        msg["From"] = f"{settings.SMTP_FROM_NAME} <{from_email}>"
    else:
        msg["From"] = from_email
    msg.set_content(text)
    msg.add_alternative(html, subtype="html")
    return msg


def send_email(to: str, subject: str, html: str, text: str) -> bool:
    """Returns True if delivered. Falls back to console logging in dev."""
    if not settings.SMTP_USER or not settings.SMTP_PASSWORD:
        logger.warning(
            "SMTP not configured — printing email to log. "
            "Set SMTP_USER + SMTP_PASSWORD env vars in production."
        )
        logger.info("EMAIL TO %s | %s\n%s", to, subject, text)
        return False

    msg = _build_message(to=to, subject=subject, html=html, text=text)
    try:
        with smtplib.SMTP(settings.SMTP_HOST, settings.SMTP_PORT, timeout=15) as s:
            s.ehlo()
            s.starttls()
            s.login(settings.SMTP_USER, settings.SMTP_PASSWORD)
            s.send_message(msg)
        logger.info("Email sent to %s | subject=%s", to, subject)
        return True
    except Exception as exc:  # noqa: BLE001
        logger.error("Email send failed: %s", exc)
        return False


def send_otp_email(*, to: str, code: str, purpose: str = "register") -> bool:
    """Sends a 6-digit OTP. ``purpose`` controls subject/body wording."""
    titles = {
        "register": ("Ro'yxatdan o'tish kodi", "Ro'yxatdan o'tish"),
        "reset": ("Parolni tiklash kodi", "Parolni tiklash"),
        "login": ("Kirish tasdiq kodi", "Kirish tasdiqi"),
    }
    subject, heading = titles.get(purpose, titles["register"])

    text = (
        f"MotivAI {heading}\n\n"
        f"Tasdiq kodingiz: {code}\n\n"
        "Bu kod 10 daqiqa davomida amal qiladi. "
        "Agar siz bu so'rovni yubormagan bo'lsangiz, e'tibor bermang.\n"
        "— MotivAI"
    )
    html = (
        "<div style=\"font-family: -apple-system, sans-serif; max-width: 480px;"
        " margin: 0 auto; padding: 24px; background: #f7f6fb; border-radius: 16px;\">"
        f"  <h2 style=\"color: #7C3AED; margin-bottom: 4px;\">MotivAI</h2>"
        f"  <p style=\"color: #555; margin-top: 0;\">{heading}</p>"
        "  <div style=\"font-size: 36px; letter-spacing: 8px; font-weight: 800;"
        f"    color: #111; background: white; padding: 18px; text-align: center;"
        f"    border-radius: 12px; margin: 16px 0;\">"
        f"    {code}"
        "  </div>"
        "  <p style=\"color: #777; font-size: 13px; line-height: 1.6;\">"
        "    Bu kod 10 daqiqa davomida amal qiladi.<br/>"
        "    Agar siz bu so'rovni yubormagan bo'lsangiz, e'tibor bermang."
        "  </p>"
        "  <p style=\"color: #aaa; font-size: 11px; margin-top: 24px;\">— MotivAI</p>"
        "</div>"
    )
    return send_email(to=to, subject=subject, html=html, text=text)
