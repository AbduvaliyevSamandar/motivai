# -*- coding: utf-8 -*-
"""Pass 3: catch-all for remaining UI strings. Adds missing keys, replaces in
specific files at known line numbers (more surgical than pass 1/2)."""
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent / "lib"
STRINGS = ROOT / "config" / "strings.dart"

NEW_KEYS = {
    "did_it":          ("Bajardim", "Сделал", "Did it"),
    "edit_btn":        ("Tahrirlash", "Редактировать", "Edit"),
    "pin_btn":         ("Pin qilish", "Закрепить", "Pin"),
    "unpin_btn":       ("Pinni yechish", "Открепить", "Unpin"),
    "upcoming_label":  ("Yaqinlashmoqda", "Скоро", "Upcoming"),
    "cancel":          ("Bekor", "Отмена", "Cancel"),
    "hour_short":      ("Soat", "Часы", "Hour"),
    "minute_short":    ("Daqiqa", "Минуты", "Minute"),
    "days_label":      ("Kunlar", "Дни", "Days"),
    "reminder_prefix": ("Eslatma", "Напоминание", "Reminder"),
    "title_pin":       ("Pin", "Закр.", "Pin"),
    "edit_task":       ("Vazifani tahrirlash", "Редактировать задачу", "Edit task"),
    "enter_task_name": ("Vazifa nomini kiriting", "Введите название задачи", "Enter task name"),
    "select_task":     ("Vazifa tanlang", "Выберите задачу", "Select a task"),
    "level_with":      ("Daraja", "Уровень", "Level"),
}


# (file, old_string, new_string)
EDITS = [
    # task_card.dart
    ("screens/widgets/task_card.dart", "text: 'Pin',", "text: S.get('title_pin'),"),
    ("screens/widgets/task_card.dart", "label: 'Bajardim',", "label: S.get('did_it'),"),
    ("screens/widgets/task_card.dart",
     "pinned ? 'Pinni yechish' : 'Pin qilish',",
     "pinned ? S.get('unpin_btn') : S.get('pin_btn'),"),
    ("screens/widgets/task_card.dart", "'Tahrirlash',", "S.get('edit_btn'),"),
    ("screens/widgets/task_card.dart", "'Yaqinlashmoqda',", "S.get('upcoming_label'),"),
    # task_detail_sheet.dart
    ("screens/widgets/task_detail_sheet.dart", "_miniBadge('Yaqinlashmoqda',", "_miniBadge(S.get('upcoming_label'),"),
    ("screens/widgets/task_detail_sheet.dart", "label: 'Bajardim',", "label: S.get('did_it'),"),
    ("screens/widgets/task_detail_sheet.dart", "label: 'Tahrirlash',", "label: S.get('edit_btn'),"),
    ("screens/widgets/task_detail_sheet.dart", "'Bekor'", "S.get('cancel')"),
    ("screens/widgets/task_detail_sheet.dart", "'Saqlash'", "S.get('save')"),
    # add_task_dialog.dart
    ("screens/widgets/add_task_dialog.dart",
     "_isEdit ? 'Vazifani tahrirlash' : S.get('add_task'),",
     "_isEdit ? S.get('edit_task') : S.get('add_task'),"),
    ("screens/widgets/add_task_dialog.dart",
     "_toast('Vazifa nomini kiriting', err: true);",
     "_toast(S.get('enter_task_name'), err: true);"),
    # dashboard_screen.dart
    ("screens/main/dashboard_screen.dart", "title: 'Vazifalar',", "title: S.get('tasks_label'),"),
    # search_screen.dart
    ("screens/main/search_screen.dart", "_section('Vazifalar',", "_section(S.get('tasks_label'),"),
    # achievements_screen.dart
    ("screens/main/achievements_screen.dart", "'Yutuqlar'", "S.get('achievements')"),
    # notifications_screen.dart
    ("screens/main/notifications_screen.dart", "'Bildirishnomalar'", "S.get('notifications')"),
    # rituals_screen.dart
    ("screens/main/rituals_screen.dart", "label: 'Soat',", "label: S.get('hour_short'),"),
    ("screens/main/rituals_screen.dart", "label: 'Daqiqa',", "label: S.get('minute_short'),"),
    ("screens/main/rituals_screen.dart", "'Kunlar'", "S.get('days_label')"),
    # wrapped_screen.dart
    ("screens/main/wrapped_screen.dart", "title: 'Streak'", "title: S.get('streak')"),
    # friend_challenges_screen.dart
    ("screens/main/friend_challenges_screen.dart", "'Bekor'", "S.get('cancel')"),
    ("screens/main/friend_challenges_screen.dart", "'Saqlash'", "S.get('save')"),
    # friends_screen.dart
    ("screens/main/friends_screen.dart", "'Bekor'", "S.get('cancel')"),
    # profile_screen.dart
    ("screens/main/profile_screen.dart", "'Bekor'", "S.get('cancel')"),
    # chat_screen.dart
    ("screens/chat/chat_screen.dart", ": 'Vazifa tanlang',", ": S.get('select_task'),"),
    # morning_ritual_card.dart
    ("widgets/morning_ritual_card.dart", "label: 'Saqlash',", "label: S.get('save'),"),
    # notification_provider.dart
    ("providers/notification_provider.dart",
     "title: 'Eslatma: $taskTitle',",
     "title: '${S.get(\"reminder_prefix\")}: $taskTitle',"),
    ("providers/notification_provider.dart",
     "title: 'Yaqinlashmoqda: $taskTitle',",
     "title: '${S.get(\"upcoming_label\")}: $taskTitle',"),
    # level_badge.dart, completion_dialog.dart
    ("widgets/level_badge.dart", "'Daraja $level'", "'${S.get(\"level\")} $level'"),
    ("screens/widgets/completion_dialog.dart", "'Daraja $newLevel'", "'${S.get(\"level\")} $newLevel'"),
    # task_mentor.dart
    ("services/task_mentor.dart",
     "'Vazifa aynan nimadan iborat? 1 jumlada yozing.'",
     "'Vazifa aynan nimadan iborat? 1 jumlada yozing.'"),  # leave (could also translate)
    # journey_screen.dart "Vazifa"
    ("screens/main/journey_screen.dart", "'Vazifa', LucideIcons.checkCircle2,", "S.get('tasks_label') + ', LucideIcons.checkCircle2,'"),  # placeholder won't apply
    # profile help item
    ("screens/main/profile_screen.dart",
     "_helpItem(LucideIcons.plus, 'Vazifa qo\\'shish',",
     "_helpItem(LucideIcons.plus, S.get('add_task'),"),
]


def add_keys():
    s = STRINGS.read_text(encoding="utf-8")
    existing = set(re.findall(r"'([a-z_][a-z0-9_]*)':\s*\{", s))
    new_lines = []
    for k, (uz, ru, en) in NEW_KEYS.items():
        if k in existing:
            continue
        u = uz.replace("\\", "\\\\").replace("'", "\\'")
        r = ru.replace("\\", "\\\\").replace("'", "\\'")
        e = en.replace("\\", "\\\\").replace("'", "\\'")
        new_lines.append(f"    '{k}': {{'uz': '{u}', 'ru': '{r}', 'en': '{e}'}},")
    if new_lines:
        block = "\n    // ── Added by apply_i18n_pass3.py ──\n" + "\n".join(new_lines) + "\n  "
        s = re.sub(r"(\n\s*)(\};)\s*\n\}\s*$", lambda m: block + m.group(2) + "\n}\n", s)
        STRINGS.write_text(s, encoding="utf-8", newline="\n")
        print(f"Added {len(new_lines)} keys")


def ensure_s_import(text: str, file_path: Path) -> str:
    if "S.get(" not in text:
        return text
    if "config/strings.dart" in text:
        return text
    rel_depth = len(file_path.parts) - 1
    rel_prefix = "../" * rel_depth
    m = re.search(r"^import\s+'[^']+';", text, re.M)
    if not m:
        return text
    return text[: m.end()] + f"\nimport '{rel_prefix}config/strings.dart';" + text[m.end():]


def main():
    add_keys()
    total_replaced = 0
    files_touched = set()
    for rel, old, new in EDITS:
        p = ROOT / rel
        text = p.read_text(encoding="utf-8")
        if old in text:
            text = text.replace(old, new, 1)
            text = ensure_s_import(text, Path(rel))
            p.write_text(text, encoding="utf-8", newline="\n")
            total_replaced += 1
            files_touched.add(rel)
            print(f"  {rel}: OK ({old[:40]})")
        else:
            print(f"  {rel}: NOT FOUND ({old[:40]})")
    print(f"\nReplaced: {total_replaced}; touched {len(files_touched)} files")


if __name__ == "__main__":
    main()
