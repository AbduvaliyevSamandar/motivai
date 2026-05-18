# -*- coding: utf-8 -*-
"""Pass 4: Final cleanup of all visible Uzbek-only UI strings."""
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent / "lib"
STRINGS = ROOT / "config" / "strings.dart"

NEW_KEYS = {
    "min_ago":          ("min oldin", "мин. назад", "min ago"),
    "hour_ago":         ("soat oldin", "ч. назад", "hr ago"),
    "day_ago":          ("kun oldin", "дн. назад", "d ago"),
    "min_before":       ("daqiqa oldin", "мин. до", "min before"),
    "min_before_remind":("min oldin eslatma", "мин. напомнить", "min before reminder"),
    "min_starts_in":    ("daqiqadan keyin boshlanadi", "минут до начала", "minutes till start"),
    "min_arrives":      ("5 soniyadan keyin yetib keladi", "Придёт через 5 секунд", "Arrives in 5s"),
    "after_days":       ("Keyin {n} kunda", "Через {n} дн.", "In {n} days"),
    "after_hours":      ("Keyin {n} soat", "Через {n} ч.", "In {n} hours"),
    "after_minutes":    ("Keyin {n} daqiqa", "Через {n} мин.", "In {n} minutes"),
    "select_at_least":  ("Kamida bitta vazifa tanlang", "Выберите хотя бы одну задачу", "Select at least one task"),
    "plan_created":     ("Reja yaratildi - Bosh sahifadan ko'ring", "План создан - смотрите на главной", "Plan created - see on Home"),
    "task_done_caps":   ("VAZIFA BAJARILDI!", "ЗАДАЧА ВЫПОЛНЕНА!", "TASK COMPLETED!"),
    "no_done_yet":      ("Hali bajarilgan vazifa yo'q", "Выполненных задач пока нет", "No completed tasks yet"),
    "mit_3":            ("MIT rejim: eng muhim 3 vazifa", "MIT режим: 3 важнейшие задачи", "MIT mode: 3 most important"),
    "no_plan_for_task": ("Ushbu vazifa uchun plan topilmadi", "План для задачи не найден", "No plan found for this task"),
    "fake_email":       ("Bu email vaqtinchalik/soxta. Real email kiriting.", "Этот email временный. Введите настоящий.", "This is a temporary email. Enter a real one."),
    "account_locked":   ("Hisob bloklangan", "Аккаунт заблокирован", "Account locked"),
    "cancel_caps":      ("BEKOR QILISH", "ОТМЕНА", "CANCEL"),
    "every_leaf":       ("Har bargda - siz qilgan bir vazifa.", "Каждый лист - выполненная задача.", "Each leaf is a completed task."),
    "tree_flower":      ("Yana {n} kun ish qilib daraxtni gullattring.", "Ещё {n} дней - и дерево зацветёт.", "{n} more days to make the tree bloom."),
    "ai_step_motto":    ("Maqsadga har kuni bir qadam - AI bilan motivatsion reja.", "К цели по шагу - план с AI-мотивацией.", "One step a day - AI-driven motivation plan."),
    "smart_plan_subj":  ("Aqlli reja", "Умный план", "Smart plan"),
    "tasks_added_n":    ("{n} ta vazifa qo'shildi!", "Добавлено {n} задач!", "{n} tasks added!"),
    "imported_x":       ("Import qo'shildi: {a} odat, {b} kolod, {c} karta", "Импорт: {a} привычек, {b} колод, {c} карт", "Imported: {a} habits, {b} decks, {c} cards"),
    "today_goal_short": ("Bugungi maqsad", "Цель дня", "Today's goal"),
    "morning_minute":   ("1 daqiqa - kayfiyat, maqsad, minnatdorlik", "1 минута - настроение, цель, благодарность", "1 minute - mood, goal, gratitude"),
    "enter_otp":        ("Tasdiq kodini kiriting", "Введите код подтверждения", "Enter verification code"),
    "new_achievements": ("Yangi yutuqlar: {n}", "Новые достижения: {n}", "New achievements: {n}"),
    "friend_score_q":   ("{name} ning bugun bajargan vazifalari sonini kiriting", "Введите количество задач друга {name}", "Enter task count for {name}"),
    "challenge_recap":  ("{a} vazifa/kun × {b} kun", "{a} задач/день × {b} дн.", "{a} tasks/day × {b} days"),
}


# (file, old, new)
EDITS = [
    # notification_provider
    ("providers/notification_provider.dart",
     "body: '$reminderMinutes daqiqadan keyin boshlanadi',",
     "body: '$reminderMinutes ${S.get(\"min_starts_in\")}',"),
    ("providers/notification_provider.dart",
     "body: '$minutesUntil daqiqadan keyin boshlanadi',",
     "body: '$minutesUntil ${S.get(\"min_starts_in\")}',"),

    # task_provider
    ("providers/task_provider.dart",
     "'Ushbu vazifa uchun plan topilmadi'",
     "S.get('no_plan_for_task')"),

    # auth
    ("screens/auth/login_screen.dart",
     "'Hisob bloklangan'",
     "S.get('account_locked')"),
    ("screens/auth/register_screen.dart",
     "'Bu email vaqtinchalik/soxta. Real email kiriting.'",
     "S.get('fake_email')"),

    # chat
    ("screens/chat/chat_screen.dart",
     "_snack(\"Reja yaratildi — Bosh sahifadan ko'ring\");",
     "_snack(S.get('plan_created'));"),
    ("screens/chat/chat_screen.dart",
     "_snack(\"Kamida bitta vazifa tanlang\", err: true);",
     "_snack(S.get('select_at_least'), err: true);"),

    # dashboard
    ("screens/main/dashboard_screen.dart",
     "'BEKOR QILISH'",
     "S.get('cancel_caps')"),
    ("screens/main/dashboard_screen.dart",
     "'Hali bajarilgan vazifa yo\\'q'",
     "S.get('no_done_yet')"),
    ("screens/main/dashboard_screen.dart",
     "'MIT rejim: eng muhim 3 vazifa'",
     "S.get('mit_3')"),

    # journey
    ("screens/main/journey_screen.dart",
     "'Har bargda — siz qilgan bir vazifa.'",
     "S.get('every_leaf')"),
    ("screens/main/journey_screen.dart",
     "'Yana ${30 - _productive} kun ish qilib daraxtni gullattring.'",
     "S.get('tree_flower').replaceAll('{n}', '${30 - _productive}')"),

    # notifications time labels
    ("screens/main/notifications_screen.dart",
     "if (diff.inMinutes < 60) return '${diff.inMinutes} min oldin';",
     "if (diff.inMinutes < 60) return '${diff.inMinutes} ${S.get(\"min_ago\")}';"),
    ("screens/main/notifications_screen.dart",
     "if (diff.inHours < 24) return '${diff.inHours} soat oldin';",
     "if (diff.inHours < 24) return '${diff.inHours} ${S.get(\"hour_ago\")}';"),
    ("screens/main/notifications_screen.dart",
     "if (diff.inDays < 7) return '${diff.inDays} kun oldin';",
     "if (diff.inDays < 7) return '${diff.inDays} ${S.get(\"day_ago\")}';"),

    # profile
    ("screens/main/profile_screen.dart",
     "'${np.defaultReminderMinutes} min oldin eslatma'",
     "'${np.defaultReminderMinutes} ${S.get(\"min_before_remind\")}'"),
    ("screens/main/profile_screen.dart",
     "'5 soniyadan keyin yetib keladi'",
     "S.get('min_arrives')"),

    # rituals time labels
    ("screens/main/rituals_screen.dart",
     "return 'Keyin ${diff.inDays} kunda';",
     "return S.get('after_days').replaceAll('{n}', '${diff.inDays}');"),
    ("screens/main/rituals_screen.dart",
     "return 'Keyin ${diff.inHours} soat';",
     "return S.get('after_hours').replaceAll('{n}', '${diff.inHours}');"),
    ("screens/main/rituals_screen.dart",
     "return 'Keyin ${diff.inMinutes} daqiqa';",
     "return S.get('after_minutes').replaceAll('{n}', '${diff.inMinutes}');"),

    # smart_plan
    ("screens/main/smart_plan_screen.dart",
     "'Aqlli reja — ${_hours.round()} soat',",
     "'${S.get(\"smart_plan_subj\")} - ${_hours.round()} ${S.get(\"unit_hour\")}',"),

    # onboarding
    ("screens/onboarding_screen.dart",
     "'Maqsadga har kuni bir qadam — AI bilan motivatsion reja.'",
     "S.get('ai_step_motto')"),

    # completion dialog
    ("screens/widgets/completion_dialog.dart",
     "'VAZIFA BAJARILDI!'",
     "S.get('task_done_caps')"),
    ("screens/widgets/completion_dialog.dart",
     "'Yangi yutuqlar: ${newBadges.length}'",
     "S.get('new_achievements').replaceAll('{n}', '${newBadges.length}')"),

    # task_detail_sheet time labels
    ("screens/widgets/task_detail_sheet.dart",
     "'${task.reminderMinutes} daqiqa oldin'",
     "'${task.reminderMinutes} ${S.get(\"min_before\")}'"),
    ("screens/widgets/task_detail_sheet.dart",
     "if (diff.inMinutes < 60) return '${diff.inMinutes} min oldin';",
     "if (diff.inMinutes < 60) return '${diff.inMinutes} ${S.get(\"min_ago\")}';"),
    ("screens/widgets/task_detail_sheet.dart",
     "if (diff.inHours < 24) return '${diff.inHours} soat oldin';",
     "if (diff.inHours < 24) return '${diff.inHours} ${S.get(\"hour_ago\")}';"),
    ("screens/widgets/task_detail_sheet.dart",
     "return '${diff.inDays} kun oldin';",
     "return '${diff.inDays} ${S.get(\"day_ago\")}';"),

    # morning_ritual_card
    ("widgets/morning_ritual_card.dart",
     "'Bugungi maqsad'",
     "S.get('today_goal_short')"),
    ("widgets/morning_ritual_card.dart",
     "'1 daqiqa — kayfiyat, maqsad, minnatdorlik'",
     "S.get('morning_minute')"),

    # otp_sheet
    ("widgets/otp_sheet.dart",
     "'Tasdiq kodini kiriting'",
     "S.get('enter_otp')"),

    # friend_challenges_screen
    ("screens/main/friend_challenges_screen.dart",
     "'${c.friendName} ning bugun bajargan vazifalari sonini kiriting'",
     "S.get('friend_score_q').replaceAll('{name}', c.friendName)"),
    ("screens/main/friend_challenges_screen.dart",
     "'${c.goalTasksPerDay} vazifa/kun × ${c.days} kun'",
     "S.get('challenge_recap').replaceAll('{a}', '${c.goalTasksPerDay}').replaceAll('{b}', '${c.days}')"),
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
        block = "\n    // ── Added by apply_i18n_pass4.py ──\n" + "\n".join(new_lines) + "\n  "
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
    total = 0
    for rel, old, new in EDITS:
        p = ROOT / rel
        text = p.read_text(encoding="utf-8")
        if old in text:
            text = text.replace(old, new, 1)
            text = ensure_s_import(text, Path(rel))
            p.write_text(text, encoding="utf-8", newline="\n")
            total += 1
            print(f"  {rel}: OK")
        else:
            print(f"  {rel}: MISS [{old[:50]}]")
    print(f"\nReplaced: {total}")


if __name__ == "__main__":
    main()
