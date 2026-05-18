# -*- coding: utf-8 -*-
"""Final pass: replace remaining strings (covers both single and double quoted)."""
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent / "lib"

# Source string forms (both ' and " variants will be tried)
TARGETS = [
    ('screens/main/notifications_screen.dart', "Barchasini o\u2019qilgan qilish", 'mark_all_read'),
    ('screens/widgets/completion_dialog.dart', 'Davom etish', 'continue_btn'),
    ('screens/main/progress_screen.dart', "Ko\u2019p", 'many'),
    ('screens/focus_screen.dart', "To\u2019xtatish", 'stop_btn'),
    ('screens/focus_screen.dart', "O\u2019tkazib yuborish", 'skip_btn'),
    ('screens/onboarding_screen.dart', "O\u2019tkazib yuborish", 'skip_btn'),
    ('screens/main/habits_screen.dart', "O\u2019chirish", 'delete'),
    ('screens/main/profile_screen.dart', "O\u2019chirish", 'delete'),
    ('screens/widgets/task_card.dart', "O\u2019chirish", 'delete'),
    ('screens/main/profile_screen.dart', "Qo\u2019llanma", 'guide'),
    ('screens/main/flashcards_screen.dart', "Qo\u2019shish", 'add_action'),
    ('screens/main/habits_screen.dart', "Qo\u2019shish", 'add_action'),
    ('providers/notification_provider.dart', "Vazifa o\u2019tkazib yuborildi", 'task_skipped_msg'),
]


def ensure_s_import(text: str, file_path: Path) -> str:
    if 'S.get(' not in text:
        return text
    if 'config/strings.dart' in text:
        return text
    rel_depth = len(file_path.parts) - 1
    rel_prefix = '../' * rel_depth
    m = re.search(r"^import\s+'[^']+';", text, re.M)
    if not m:
        return text
    return text[: m.end()] + f"\nimport '{rel_prefix}config/strings.dart';" + text[m.end():]


total = 0
for rel, raw, key in TARGETS:
    p = ROOT / rel
    text = p.read_text(encoding='utf-8')
    repl = f"S.get('{key}')"
    found_any = False
    # Try all four forms: 'X', "X", straight apostrophe variant, double-quoted variants.
    forms = [
        f"'{raw}'",
        f'"{raw}"',
        f"'{raw.replace(chr(0x2019), chr(0x27))}'",
        f'"{raw.replace(chr(0x2019), chr(0x27))}"',
        # Dart-escaped single-quoted with backslash apostrophe
        "'" + raw.replace(chr(0x2019), "\\'") + "'",
    ]
    for form in forms:
        if form in text:
            text = text.replace(form, repl)
            found_any = True
    if found_any:
        text = ensure_s_import(text, Path(rel))
        p.write_text(text, encoding='utf-8', newline='\n')
        total += 1
        print(f'  {rel}: OK ({raw[:30]})')
    else:
        print(f'  {rel}: NOT FOUND ({raw[:30]})')
print(f'\nTotal: {total}')
