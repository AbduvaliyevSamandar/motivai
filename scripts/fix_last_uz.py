# -*- coding: utf-8 -*-
"""Final cleanup of last remaining Uzbek strings in UI."""
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent / "lib"

EDITS = [
    # login_screen
    ('screens/auth/login_screen.dart',
     "'Tarmoq xatosi'",
     "S.tr('Tarmoq xatosi', 'Ошибка сети', 'Network error')"),
    ('screens/auth/login_screen.dart',
     "'Email tasdiqlanmagan'",
     "S.tr('Email tasdiqlanmagan', 'Email не подтверждён', 'Email not verified')"),
    ('screens/auth/login_screen.dart',
     "'Parol yangilandi! Endi kiring.'",
     "S.tr('Parol yangilandi! Endi kiring.', 'Пароль обновлён! Войдите.', 'Password updated! Please sign in.')"),

    # wrapped_screen
    ('screens/main/wrapped_screen.dart',
     "'hozirgi daraja'",
     "S.tr('hozirgi daraja', 'текущий уровень', 'current level')"),

    # add_task_dialog
    ('screens/widgets/add_task_dialog.dart',
     "'Vaqt tanlash'",
     "S.tr('Vaqt tanlash', 'Выбрать время', 'Pick time')"),

    # api error
    ('services/api.dart',
     "'Tarmoq xatosi: $e'",
     "'${S.tr(\"Tarmoq xatosi\", \"Ошибка сети\", \"Network error\")}: $e'"),

    # rituals_storage notification
    ('services/rituals_storage.dart',
     "'Vaqt keldi — ${r.durationMin} daqiqa fokus'",
     "'${S.tr(\"Vaqt keldi\", \"Время пришло\", \"Time to focus\")} — ${r.durationMin} ${S.tr(\"daqiqa fokus\", \"мин. фокуса\", \"min focus\")}'"),

    # sound_pack
    ('services/sound_pack.dart',
     "'Standart tovush, oddiy eslatma'",
     "S.tr('Standart tovush, oddiy eslatma', 'Стандартный звук, обычное напоминание', 'Standard sound, regular reminder')"),

    # otp_sheet
    ('widgets/otp_sheet.dart',
     "'${widget.email} ga 6 xonali kod yuborildi'",
     "'${widget.email} ${S.tr(\"ga 6 xonali kod yuborildi\", \"— отправлен 6-значный код\", \"— 6-digit code sent\")}'"),
]


def ensure_s_import(text: str, file_path: Path) -> str:
    if 'S.get(' not in text and 'S.tr(' not in text:
        return text
    if 'config/strings.dart' in text:
        return text
    rel_depth = len(file_path.parts) - 1
    rel_prefix = '../' * rel_depth
    import re
    m = re.search(r"^import\s+'[^']+';", text, multi := __import__('re').MULTILINE)
    if not m:
        return text
    return text[: m.end()] + f"\nimport '{rel_prefix}config/strings.dart';" + text[m.end():]


total = 0
for rel, old, new in EDITS:
    p = ROOT / rel
    text = p.read_text(encoding='utf-8')
    if old in text:
        text = text.replace(old, new, 1)
        text = ensure_s_import(text, Path(rel))
        p.write_text(text, encoding='utf-8', newline='\n')
        total += 1
        print(f"  {rel}: OK")
    else:
        print(f"  {rel}: MISS [{old[:50]}]")
print(f"\nTotal: {total}")
