# -*- coding: utf-8 -*-
"""Second pass: handle curly apostrophes/em-dashes that pass-1 missed.

Uses normalisation: both source string and dictionary key are stripped of
fancy punctuation before matching, so 'Qo'shish' (curly) maps to the same
key as 'Qo\\'shish' (straight).
"""
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent / "lib"
STRINGS_FILE = ROOT / "config" / "strings.dart"

# Additional keys for strings we missed.
NEW_KEYS = {
    "delete_btn":        ("O'chirish", "Удалить", "Delete"),
    "skip_btn":          ("O'tkazib yuborish", "Пропустить", "Skip"),
    "stop_btn":          ("To'xtatish", "Остановить", "Stop"),
    "continue_action":   ("Davom etish", "Продолжить", "Continue"),
    "type_something_x":  ("Bir narsa yozing", "Напишите что-нибудь", "Type something"),
    "many":              ("Ko'p", "Много", "Many"),
    "guide":             ("Qo'llanma", "Руководство", "Guide"),
    "add_action":        ("Qo'shish", "Добавить", "Add"),
    "import_temp":       ("Template import", "Импорт шаблона", "Import template"),
    "task_skipped_msg":  ("Vazifa o'tkazib yuborildi", "Задача пропущена", "Task skipped"),
    "no_card_yet":       ("Hali karta yo'q", "Карточек пока нет", "No cards yet"),
    "tasks_reminders_wins_msg": ("Vazifalar, eslatmalar va yutuqlar", "Задачи, напоминания и достижения", "Tasks, reminders and wins"),
    "send_friend_json":  ("Odatlar + kartalar - do'stga yuboring", "Привычки + карты - другу", "Habits + cards - send to a friend"),
    "deck_yarating":     ("Yangi deck yarating - yodlash oson bo'ladi", "Создайте колоду - запоминайте легче", "Create a deck - memorise faster"),
    "habits_grow_streak":("Kundalik odat qo'shing - streak orttiring", "Добавьте привычку - растите streak", "Add a daily habit - grow your streak"),
    "auto_dark_light":   ("Kechqurun dark, kunduzi light - avtomatik", "Вечером - тёмная, днём - светлая", "Dark at night, light by day - auto"),
    "json_paste_help":   ("JSON yopishtiring - odat/kartalarga qo'shiladi", "Вставьте JSON - добавится к привычкам/картам", "Paste JSON - habits/cards will be added"),
    "send_invite":       ("Kodni do'stga yuboring - ular sizni do'st sifatida qo'sha oladi", "Отправьте код другу - он добавит вас", "Send the code to a friend - they can add you"),
    "ai_one_minute":     ("1 daqiqa - o'z kuningizni asoslang", "1 минута - заземлите свой день", "1 minute - ground your day"),
    "ground_motto":      ("Maqsadga - har kuni bir qadam", "К цели - каждый день по шагу", "One step closer every day"),
    "hour_day":          ("Soat - kun", "Час - день", "Hour - day"),
    "tap_we_plan":       ("Tanlang - biz sizga mos reja tuzamiz", "Выберите - подберём план", "Pick - we'll match a plan"),
    "export_data_btn":   ("Ma'lumotlarni eksport", "Экспорт данных", "Export data"),
    "mark_all_read_btn": ("Barchasini o'qilgan qilish", "Отметить всё прочитанным", "Mark all as read"),
    "tasks_show_here_x": ("Vazifalaringizga vaqt qo'shing -\neslatmalar shu yerda ko'rinadi", "Добавьте время к задачам -\nнапоминания будут здесь", "Add time to your tasks -\nreminders will appear here"),
}


def normalise(s: str) -> str:
    """Map fancy punctuation to ASCII for matching only."""
    return (
        s.replace("\u2019", "'")
         .replace("\u2018", "'")
         .replace("\u2014", "-")
         .replace("\u2013", "-")
         .replace("\u2026", "...")
    )


def append_keys_to_strings(text: str) -> tuple[str, int]:
    existing = set(re.findall(r"'([a-z_][a-z0-9_]*)':\s*\{", text))
    new_lines = []
    added = 0
    for key, (uz, ru, en) in NEW_KEYS.items():
        if key in existing:
            continue
        u = uz.replace("\\", "\\\\").replace("'", "\\'").replace("\n", "\\n")
        r = ru.replace("\\", "\\\\").replace("'", "\\'").replace("\n", "\\n")
        e = en.replace("\\", "\\\\").replace("'", "\\'").replace("\n", "\\n")
        new_lines.append(f"    '{key}': {{'uz': '{u}', 'ru': '{r}', 'en': '{e}'}},")
        added += 1
    if not new_lines:
        return text, 0
    block = "\n    // ── Added by apply_i18n_pass2.py ──\n" + "\n".join(new_lines) + "\n  "
    closing_pattern = r"(\n\s*)(\};)\s*\n\}\s*$"
    return re.sub(closing_pattern, lambda m: block + m.group(2) + "\n}\n", text), added


def ensure_s_import(text: str, file_path: Path) -> str:
    if "S.get(" not in text:
        return text
    if "config/strings.dart" in text:
        return text
    rel_depth = len(file_path.relative_to(ROOT).parts) - 1
    rel_prefix = "../" * rel_depth
    m = re.search(r"^import\s+'[^']+';", text, re.M)
    if not m:
        return text
    insert_pos = m.end()
    return text[:insert_pos] + f"\nimport '{rel_prefix}config/strings.dart';" + text[insert_pos:]


def replace_in_file(text: str, lookup_norm: dict) -> tuple[str, int]:
    count = 0

    def replace(match: re.Match) -> str:
        nonlocal count
        body = match.group(1)
        key = lookup_norm.get(normalise(body))
        if not key:
            return match.group(0)
        count += 1
        return f"S.get('{key}')"

    return re.sub(r"'((?:[^'\\\n]|\\.)*)'", replace, text), count


def main():
    # 1) Add new keys
    strings_text = STRINGS_FILE.read_text(encoding="utf-8")
    new_strings, n_keys = append_keys_to_strings(strings_text)
    if n_keys:
        STRINGS_FILE.write_text(new_strings, encoding="utf-8", newline="\n")
        print(f"Added {n_keys} new keys to strings.dart")

    # 2) Build normalised lookup (raw uz strings + escaped Dart variants -> key)
    lookup_norm = {}
    for key, (uz, _, _) in NEW_KEYS.items():
        for variant in {uz, uz.replace("'", "\\'"), uz.replace("'", "\u2019"),
                        uz.replace("-", "\u2014"), uz.replace("\n", "\\n")}:
            lookup_norm[normalise(variant)] = key

    # 3) Replace in source files
    total = 0
    for path in sorted(ROOT.rglob("*.dart")):
        if path == STRINGS_FILE:
            continue
        text = path.read_text(encoding="utf-8")
        new_text, n = replace_in_file(text, lookup_norm)
        if n == 0:
            continue
        new_text = ensure_s_import(new_text, path)
        path.write_text(new_text, encoding="utf-8", newline="\n")
        total += n
        print(f"  {path.relative_to(ROOT).as_posix()}: {n}")
    print(f"\nTotal pass-2 replacements: {total}")


if __name__ == "__main__":
    main()
