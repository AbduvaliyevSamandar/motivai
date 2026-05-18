# -*- coding: utf-8 -*-
"""Comprehensive i18n migration: add translation keys and replace hardcoded strings.

Workflow:
  1. Adds new keys to strings.dart (preserves existing).
  2. Walks all .dart files in lib/ and replaces hardcoded Uzbek strings
     with S.get('key') calls.
  3. Ensures S import line exists in each modified file.

Only handles non-interpolated literals here — interpolated strings need
manual conversion to keep their template variables.
"""
import io
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent / "lib"
STRINGS_FILE = ROOT / "config" / "strings.dart"

# ---- Translation dictionary ----
# key -> (uz, ru, en)
NEW_KEYS = {
    # Misc
    "app_motto_short":    ("Maqsadga - har kuni bir qadam", "К цели - каждый день по шагу", "One step closer every day"),
    "app_about_full":     ("AI orqali talabalarga motivatsiya beruvchi ilova", "Приложение для мотивации студентов через AI", "AI-powered motivation app for students"),
    "version_label":      ("MotivAI v2.2.0", "MotivAI v2.2.0", "MotivAI v2.2.0"),
    "ai_mentor":          ("AI mentor", "AI ментор", "AI mentor"),
    "ai_help":            ("AI yordam", "AI помощь", "AI help"),
    "select_all":         ("Barchasini tanlash", "Выбрать всё", "Select all"),
    "clear_all":          ("Hammasini tozalash", "Очистить всё", "Clear all"),
    "mark_all_read":      ("Barchasini o'qilgan qilish", "Отметить всё прочитанным", "Mark all as read"),
    "skip":               ("O'tkazib yuborish", "Пропустить", "Skip"),
    "skipped":            ("O'tkazib yuborildi", "Пропущено", "Skipped"),
    "stop":               ("To'xtatish", "Остановить", "Stop"),
    "import_btn":         ("Import qilish", "Импортировать", "Import"),
    "create_new":         ("Yangisini yaratish", "Создать новое", "Create new"),
    "add_btn":            ("Qo'shish", "Добавить", "Add"),
    "remove_btn":         ("O'chirish", "Удалить", "Remove"),
    "copy":               ("Nusxa olish", "Копировать", "Copy"),
    "copied":             ("Nusxa olindi", "Скопировано", "Copied"),
    "nothing_found":      ("Hech narsa topilmadi", "Ничего не найдено", "Nothing found"),
    "could_not_open":     ("Sahifa ochib bo'lmadi", "Не удалось открыть страницу", "Could not open page"),
    "yes_let_us_start":   ("Yaxshi, boshlayman", "Хорошо, начнём", "OK, let's start"),
    "welcome":            ("Xush kelibsiz", "Добро пожаловать", "Welcome"),
    "welcome_to_motivai": ("MotivAI ga xush kelibsiz!", "Добро пожаловать в MotivAI!", "Welcome to MotivAI!"),

    # Sections / titles
    "color_theme_title":  ("Rang mavzusi", "Цветовая тема", "Color theme"),
    "color_theme_pick":   ("Ilovaning rang palitrasini tanlang", "Выберите цветовую палитру", "Pick the app's color palette"),
    "haptic_title":       ("Titrash kuchi", "Сила вибрации", "Haptic strength"),
    "sound_pack_title":   ("Tovush pachkasi", "Звуковой пакет", "Sound pack"),
    "auto_theme_hint":    ("Kechqurun dark, kunduzi light - avtomatik", "Вечером - тёмная, днём - светлая", "Dark at night, light by day - auto"),
    "delete_account_warn":("Bu amal qaytarib bo'lmaydi. Hamma vazifalar, XP, ", "Это действие нельзя отменить. Все задачи, XP, ", "This action cannot be undone. All tasks, XP, "),
    "with_all_data":      ("Hamma ma'lumotlar bilan birga", "Со всеми данными", "Along with all data"),
    "delete_account_btn": ("Akkauntni o'chirish", "Удалить аккаунт", "Delete account"),
    "test_notif_when":    ("5 soniyadan keyin keladi", "Придёт через 5 секунд", "Arrives in 5s"),
    "guide_help":         ("Qo'llanma", "Руководство", "Guide"),
    "guide_help_full":    ("Qo'llanma va savollar", "Руководство и вопросы", "Guide and FAQ"),

    # Habits
    "habits_title":           ("Kundalik odatlar", "Ежедневные привычки", "Daily habits"),
    "habits_empty_title":     ("Hali odat yo'q", "Привычек пока нет", "No habits yet"),
    "habits_empty_sub":       ("Kundalik odat qo'shing - streak orttiring", "Добавьте привычку - растите streak", "Add a daily habit - grow your streak"),
    "habit_new":              ("Yangi odat", "Новая привычка", "New habit"),
    "habit_name_label":       ("Odat nomi", "Название привычки", "Habit name"),
    "habit_name_validate":    ("Ism va kamida 1 kunni tanlang", "Имя и хотя бы 1 день", "Pick a name and at least 1 day"),
    "habit_delete_q":         ("Odatni o'chirish?", "Удалить привычку?", "Delete habit?"),
    "cancel_btn":             ("Bekor qilish", "Отмена", "Cancel"),

    # Friends
    "friends_title":          ("Do'stlar", "Друзья", "Friends"),
    "friends_empty":          ("Hali do'stlar yo'q", "Друзей пока нет", "No friends yet"),
    "friends_empty_sub":      ("Yuqoridagi \"+\" tugmasi orqali do'st qo'shing", "Добавьте друга через кнопку \"+\" сверху", "Add a friend via the \"+\" above"),
    "friend_add":             ("Do'st qo'shish", "Добавить друга", "Add friend"),
    "invite_code_label":      ("Taklif kodi (6 belgi)", "Код приглашения (6 знаков)", "Invite code (6 chars)"),
    "your_invite_code":       ("Sizning taklif kodingiz", "Ваш код приглашения", "Your invite code"),
    "share_invite_help":      ("Kodni do'stga yuboring - ular sizni do'st sifatida qo'sha oladi", "Отправьте код другу - он добавит вас", "Send the code to a friend - they can add you"),
    "wrong_amount":           ("Noto'g'ri miqdor", "Неверная сумма", "Wrong amount"),

    # Friend challenges
    "challenge_no_friend":    ("Avval \"Do'stlar\" bo'limida do'st qo'shing", "Сначала добавьте друга", "First add a friend in the Friends tab"),
    "challenge_new":          ("Yangi chellenj", "Новый челлендж", "New challenge"),
    "challenge_today_score":  ("Bugungi ball", "Очки за сегодня", "Today's score"),
    "challenge_empty":        ("Chellenj yo'q", "Челленджей нет", "No challenges"),
    "challenge_empty_sub":    ("Do'stingiz bilan 7 kunlik turnir yarating", "Создайте 7-дневный турнир с другом", "Create a 7-day tournament with a friend"),
    "challenge_friend_7day":  ("Do'st bilan 7 kunlik turnir", "7-дневный турнир с другом", "7-day tournament with a friend"),
    "challenge_start":        ("Chellenj boshlash", "Начать челлендж", "Start challenge"),
    "challenge_friend_score": ("Do'st ballini kiritish", "Ввести очки друга", "Enter friend's score"),

    # Flashcards
    "flashcards_empty":       ("Hali flashcards yo'q", "Карточек пока нет", "No flashcards yet"),
    "flashcards_empty_sub":   ("Yangi deck yarating - yodlash oson bo'ladi", "Создайте колоду - запоминайте легче", "Create a deck - memorise faster"),
    "flashcard_no_repeat":    ("Takrorlash uchun karta yo'q", "Нет карточек для повторения", "No cards to review"),
    "flashcard_no_card":      ("Karta yo'q", "Нет карточек", "No cards"),
    "flashcard_tap_for_back": ("Javobni ko'rish uchun kartaga bosing", "Нажмите чтобы увидеть ответ", "Tap to see the answer"),
    "deck_new":               ("Yangi deck", "Новая колода", "New deck"),
    "deck_name":              ("Deck nomi", "Название колоды", "Deck name"),
    "card_new":               ("Yangi karta", "Новая карточка", "New card"),
    "card_front_q":           ("Old tomon (savol)", "Лицевая (вопрос)", "Front (question)"),
    "card_back_a":            ("Orqa tomon (javob)", "Обратная (ответ)", "Back (answer)"),
    "card_add_help":          ("Old-orqa tomon bilan karta qo'shing", "Добавьте карточку с двумя сторонами", "Add a card with both sides"),
    "flashcard_label":        ("Flashcard deck", "Колода Flashcard", "Flashcard deck"),

    # Smart plan
    "smart_plan_title":       ("Aqlli reja", "Умный план", "Smart plan"),
    "smart_plan_intro":       ("Soat va yo'nalishni belgilab, reja yarating. AI shu vaqtni optimal bloklarga bo'ladi.", "Укажите время и направление - AI распределит на блоки.", "Set time and focus - AI splits it into optimal blocks."),
    "smart_plan_hours_q":     ("Qancha vaqtingiz bor?", "Сколько у вас времени?", "How much time do you have?"),
    "direction_label":        ("Yo'nalish:", "Направление:", "Direction:"),
    "split_to_blocks":        ("Vaqtni optimal bloklarga bo'lish", "Распределить на блоки", "Split into optimal blocks"),
    "no_plans_yet":           ("Hozircha rejalar yo'q", "Планов пока нет", "No plans yet"),
    "pick_we_plan":           ("Tanlang - biz sizga mos reja tuzamiz", "Выберите - подберём план", "Pick - we'll match a plan"),
    "subject_coding":         ("Kod / dasturlash", "Код / программирование", "Coding / programming"),
    "subject_language":       ("Til o'rganish", "Изучение языка", "Language learning"),
    "subject_meditation":     ("Meditatsiya / dam", "Медитация / отдых", "Meditation / rest"),
    "subject_sport":          ("Sport / mashq", "Спорт / тренировка", "Sport / workout"),
    "subject_reading":        ("O'qish / mashg'ulot", "Чтение / занятие", "Reading / study"),
    "subject_creative":       ("Ijodiy ish", "Творчество", "Creative work"),

    # Wrapped
    "wrapped_title":          ("Haftangiz xulosasi", "Итоги недели", "Your week wrapped"),
    "wrapped_subtitle":       ("Bu haftangiz qanday o'tgani", "Как прошла неделя", "How your week went"),
    "wrapped_tasks_done":     ("Bajarilgan vazifalar", "Выполненные задачи", "Tasks completed"),
    "wrapped_tasks_sub":      ("Bu hafta sizning natijangiz", "Ваш результат за неделю", "Your result this week"),
    "wrapped_xp":             ("XP to'pladingiz", "Вы набрали XP", "XP earned"),
    "wrapped_xp_sub":         ("Harakatingizning muqobil qiymati", "Эквивалент ваших усилий", "Equivalent of your effort"),
    "wrapped_top_cat":        ("Eng ko'p kategoriya", "Самая частая категория", "Top category"),
    "wrapped_keep_going":     ("Davom eting!", "Продолжайте!", "Keep going!"),
    "wrapped_next_higher":    ("Keyingi hafta yana balandroq", "На следующей неделе - выше", "Next week - higher still"),
    "wrapped_streak":         ("Streak saqlang", "Сохраняйте streak", "Keep the streak"),

    # Heatmap
    "activity_heatmap":       ("Faollik (35 kun)", "Активность (35 дней)", "Activity (35 days)"),
    "hour_x_day":             ("Soat - kun", "Час - день", "Hour - day"),
    "top_active_hour":        ("Eng faol soat", "Самый активный час", "Most active hour"),
    "top_active_day":         ("Eng mahsuldor kun", "Самый продуктивный день", "Most productive day"),
    "active_streak":          ("Ketma-ket faollik", "Серия активности", "Active streak"),

    # Rituals
    "rituals_empty":          ("Rituallar yo'q", "Ритуалов нет", "No rituals"),
    "ritual_new":             ("Yangi ritual", "Новый ритуал", "New ritual"),
    "ritual_name":            ("Ritual nomi", "Название ритуала", "Ritual name"),
    "ritual_saved":           ("Ritual saqlandi", "Ритуал сохранён", "Ritual saved"),
    "morning_ritual":         ("Kun boshi rituali", "Утренний ритуал", "Morning ritual"),
    "ritual_repeat_help":     ("Takroriy mashg'ulotlar uchun eslatma", "Напоминание для регулярных занятий", "Reminder for recurring activities"),
    "ritual_examples":        ("\"Har ertalab 20 min ingliz\" kabi takroriy ishlar", "Регулярные дела типа \"20 мин английского утром\"", "Recurring like \"20 min English every morning\""),

    # Notifications
    "notif_no":               ("Bildirishnomalar yo'q", "Уведомлений нет", "No notifications"),
    "notif_style_pick":       ("Bildirishnoma uslubini tanlang", "Выберите стиль уведомлений", "Pick notification style"),
    "notif_test":             ("MotivAI test", "MotivAI тест", "MotivAI test"),
    "notif_remind_min_before":("Vazifadan qancha vaqt oldin eslatish", "За сколько минут напомнить", "How long before to remind"),
    "notif_when":             ("Eslatma vaqti", "Время напоминания", "Reminder time"),

    # Search / dashboard
    "search_what":            ("Nimani qidiryapsiz?", "Что вы ищете?", "What are you searching for?"),
    "search_hint":            ("Vazifa, odat yoki flashcard nomini yozing", "Введите название задачи, привычки или карты", "Type a task, habit or card name"),
    "no_task_today":          ("Bu kunda vazifa yo'q", "На этот день задач нет", "No tasks for this day"),

    # Dashboard
    "dashboard_intro":        ("AI tavsiya etgan vazifalar", "Задачи от AI", "AI-suggested tasks"),
    "dashboard_pick_help":    ("Tanlang va ro'yxatingizga qo'shing", "Выберите и добавьте в список", "Pick and add to your list"),
    "add_to_tasks":           ("Vazifalarga qo'shish", "Добавить в задачи", "Add to tasks"),
    "tasks_add_first":        ("Vazifa qo'shing", "Добавьте задачу", "Add a task"),
    "task_completed":         ("Bu vazifa bajarilgan", "Эта задача выполнена", "This task is completed"),
    "task_skipped":           ("Vazifa o'tkazib yuborildi", "Задача пропущена", "Task skipped"),

    # Goals
    "primary_goal_q":         ("Asosiy maqsadingiz?", "Ваша главная цель?", "Your main goal?"),
    "preferred_field":        ("Ustuvorlik bergan soha", "Приоритетная сфера", "Preferred field"),
    "goal_streak":            ("Streak orqali o'z-o'zingizni rivojlantiring", "Развивайтесь через streak", "Grow yourself via streak"),
    "goal_rating":            ("Reytingda yuqorilang", "Поднимайтесь в рейтинге", "Climb the leaderboard"),
    "goal_daily_task":        ("Kuniga vazifa", "Задача в день", "A task a day"),
    "general_task":           ("Umumiy vazifa", "Общая задача", "General task"),

    # Onboarding / mentor
    "ai_minute_ground":       ("1 daqiqa - o'z kuningizni asoslang", "1 минута - заземлите свой день", "1 minute - ground your day"),
    "tree_30_grow":           ("30 kunlik daraxt o'sishi", "30-дневный рост дерева", "30-day tree growth"),
    "what_did_you_learn":     ("Nima o'rgandingiz? Qanday borish mumkin?", "Что выучили? Куда дальше?", "What did you learn? Where next?"),
    "add_reflection":         ("Izoh qo'shish (reflection)", "Добавить рефлексию", "Add reflection"),
    "session_stop_q":         ("Sessiyani to'xtatilsinmi?", "Остановить сессию?", "Stop session?"),
    "fewer_choices":          ("Choice overload kamaytiradi", "Снижает перегруз выбора", "Reduces choice overload"),
    "type_something":         ("Bir narsa yozing", "Напишите что-нибудь", "Type something"),

    # AI assistant
    "hi_im_motivai":          ("Salom! Men MotivAI", "Привет! Я MotivAI", "Hi! I'm MotivAI"),
    "how_can_i_help":         ("Sizga qanday yordam bera olaman?", "Чем могу помочь?", "How can I help you?"),
    "hours_ago":              ("Soat va kun statistikasi", "Часы и дни", "Hours and days"),

    # Auth / login
    "login_google_btn":       ("Google bilan kirish", "Войти через Google", "Sign in with Google"),
    "min6_char":              ("Kamida 6 belgi", "Минимум 6 символов", "At least 6 characters"),
    "verify_code":            ("Tasdiq kodi", "Код подтверждения", "Verification code"),
    "code_resend_help":       ("Kod kelmasa, oynani yopib qaytadan boshlang", "Если код не пришёл - закройте и начните снова", "If no code arrived - close and try again"),
    "reset_pass_btn":         ("Parolni tiklash", "Сброс пароля", "Reset password"),
    "new_pass_label":         ("Yangi parol", "Новый пароль", "New password"),

    # Voice
    "voice_unavailable":      ("Ovozli kirish mavjud emas", "Голосовой ввод недоступен", "Voice input unavailable"),

    # Sound
    "sound_soon":             ("Tez orada chalinadi (infratuzilma tayyor)", "Скоро (инфраструктура готова)", "Coming soon (infra ready)"),

    # Streak freeze
    "freeze_keeps_streak":    ("Freeze: streakni saqlaydi bitta-o'tkazib yuborilgan kunda", "Freeze: спасает streak за один пропущенный день", "Freeze: saves streak on a missed day"),

    # Stat / progress
    "last_30_days":           ("Oxirgi 30 kun", "Последние 30 дней", "Last 30 days"),
    "last_8_weeks":           ("Oxirgi 8 hafta", "Последние 8 недель", "Last 8 weeks"),

    # Misc small
    "ko_p":                   ("Ko'p", "Много", "Many"),
    "yo_q":                   ("Yo'q", "Нет", "No"),
    "json_paste_hint":        ("JSON yopishtiring - odat/kartalarga qo'shiladi", "Вставьте JSON - добавится к привычкам/картам", "Paste JSON - habits/cards will be added"),
    "json_paste_friend":      ("Do'stingizdan olgan JSON ni yopishtiring", "Вставьте JSON, полученный от друга", "Paste JSON received from a friend"),
    "share_habits_cards":     ("Odatlar + kartalar - do'stga yuboring", "Привычки + карты - другу", "Habits + cards - send to a friend"),
    "json_sample":            ("{\"app\":\"MotivAI\", ...}", "{\"app\":\"MotivAI\", ...}", "{\"app\":\"MotivAI\", ...}"),
    "tap_test_now":           ("Tanlang va darhol sinab ko'ring", "Выберите и тут же попробуйте", "Pick and try right away"),
    "task_remind_examples":   ("Masalan: 3 vazifani tugatish", "Например: завершить 3 задачи", "E.g. finish 3 tasks"),
    "tasks_reminders_wins":   ("Vazifalar, eslatmalar va yutuqlar", "Задачи, напоминания и достижения", "Tasks, reminders and wins"),
    "fokus_pomodoro":         ("Fokus (Pomodoro)", "Фокус (Pomodoro)", "Focus (Pomodoro)"),
    "pomodoro_breaks":        ("Pomodoro tanaffuslar", "Перерывы Pomodoro", "Pomodoro breaks"),
    "ambient_sound":          ("Fon ovozi", "Фоновая музыка", "Ambient sound"),
    "tasks_show_here":        ("Vazifalaringizga vaqt qo'shing -\neslatmalar shu yerda ko'rinadi", "Добавьте время к задачам -\nнапоминания будут здесь", "Add time to your tasks -\nreminders will appear here"),
}


# Build a fast lookup from raw uz string (escaped, as appears in source) -> key.
# We need to handle single-quote escaping within Dart source carefully.
def uz_to_lookups():
    """Map both raw and Dart-escaped variants to the same key."""
    out = {}
    for key, (uz, _, _) in NEW_KEYS.items():
        out[uz] = key
        # Dart single-quoted with escaped apostrophes
        dart_form = uz.replace("'", "\\'")
        if dart_form != uz:
            out[dart_form] = key
    return out


def render_strings_block(existing_text: str) -> str:
    """Append new key entries to strings.dart's _all map (before the closing '};')."""
    # Find existing keys to skip duplicates
    existing_keys = set(re.findall(r"'([a-z_][a-z0-9_]*)':\s*\{", existing_text))
    new_lines = []
    for key, (uz, ru, en) in NEW_KEYS.items():
        if key in existing_keys:
            continue
        u = uz.replace("\\", "\\\\").replace("'", "\\'")
        r = ru.replace("\\", "\\\\").replace("'", "\\'")
        e = en.replace("\\", "\\\\").replace("'", "\\'")
        new_lines.append(f"    '{key}': {{'uz': '{u}', 'ru': '{r}', 'en': '{e}'}},")
    if not new_lines:
        return existing_text
    block = "\n    // ── Added by apply_i18n.py ──\n" + "\n".join(new_lines) + "\n  "
    # Insert before final '};' inside the _all map
    closing_pattern = r"(\n\s*)(\};)\s*\n\}\s*$"
    return re.sub(closing_pattern, lambda m: block + m.group(2) + "\n}\n", existing_text)


def ensure_s_import(text: str) -> str:
    """Make sure each .dart file imports the strings file when it uses S.get(...)."""
    if "S.get(" not in text:
        return text
    if "config/strings.dart" in text or "../config/strings.dart" in text:
        return text
    # Find first import line
    m = re.search(r"^import\s+'[^']+';", text, re.M)
    if not m:
        return text
    insert_pos = m.end()
    return text[:insert_pos] + "\nimport '../../config/strings.dart';" + text[insert_pos:]


def replace_in_file(text: str, lookups: dict) -> tuple[str, int]:
    """Replace 'Uzbek' single-quoted literals with S.get('key')."""
    count = 0

    def replace(match: re.Match) -> str:
        nonlocal count
        body = match.group(1)
        # Check both raw and dart-escaped
        key = lookups.get(body)
        if not key:
            return match.group(0)
        count += 1
        return f"S.get('{key}')"

    # Match single-quoted literals (escape-aware, no leading $ for interpolation).
    # We don't touch already-translated S.get() because the body wouldn't match a key.
    new_text = re.sub(
        r"'((?:[^'\\\n]|\\.)*)'",
        replace,
        text,
    )
    return new_text, count


def main():
    sys.stdout.reconfigure(encoding="utf-8")
    # Step 1: update strings.dart
    strings_text = STRINGS_FILE.read_text(encoding="utf-8")
    new_strings = render_strings_block(strings_text)
    if new_strings != strings_text:
        STRINGS_FILE.write_text(new_strings, encoding="utf-8", newline="\n")
        added = len(re.findall(r"'[a-z_][a-z0-9_]*':\s*\{", new_strings)) - len(
            re.findall(r"'[a-z_][a-z0-9_]*':\s*\{", strings_text)
        )
        print(f"Added {added} new keys to strings.dart")

    # Step 2: replace strings in lib/**/*.dart
    lookups = uz_to_lookups()
    total = 0
    for path in sorted(ROOT.rglob("*.dart")):
        if path == STRINGS_FILE:
            continue
        rel = path.relative_to(ROOT).as_posix()
        if "config/strings.dart" in rel:
            continue
        text = path.read_text(encoding="utf-8")
        new_text, n = replace_in_file(text, lookups)
        if n == 0:
            continue
        new_text = ensure_s_import(new_text)
        path.write_text(new_text, encoding="utf-8", newline="\n")
        total += n
        print(f"  {rel}: {n} replacement(s)")
    print(f"\nTotal replacements: {total}")


if __name__ == "__main__":
    main()
