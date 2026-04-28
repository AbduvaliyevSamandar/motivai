"""Bulk-swap Material `Icons.*` usage with Lucide equivalents.

Strategy: walk every .dart file under lib/, run a sed-style replace using
a curated map (top ~120 icons we actually use), then make sure each
touched file imports `lucide_icons`.

Icons not in the map stay on Material — better to leave a few stragglers
than break the build with a wrong reference.
"""
import re
from pathlib import Path

# Map: Material name -> Lucide name. Includes both `_rounded`, `_outlined`
# and bare suffix variants. Keys are matched as exact identifiers after
# `Icons.`.
MAP = {
    # Basic actions
    "add": "plus",
    "add_rounded": "plus",
    "add_circle_rounded": "plusCircle",
    "remove_rounded": "minus",
    "close_rounded": "x",
    "close": "x",
    "check": "check",
    "check_rounded": "check",
    "check_circle_rounded": "checkCircle2",
    "check_circle_outline": "checkCircle",
    "arrow_back_rounded": "arrowLeft",
    "arrow_back_ios_new_rounded": "chevronLeft",
    "arrow_forward_rounded": "arrowRight",
    "arrow_forward_ios_rounded": "chevronRight",
    "chevron_left_rounded": "chevronLeft",
    "chevron_right_rounded": "chevronRight",
    "keyboard_arrow_up_rounded": "chevronUp",
    "keyboard_arrow_down_rounded": "chevronDown",
    "expand_more_rounded": "chevronDown",
    "expand_less_rounded": "chevronUp",
    "refresh_rounded": "refreshCw",
    "sync_rounded": "refreshCw",
    "more_vert_rounded": "moreVertical",
    "more_horiz_rounded": "moreHorizontal",
    # File / data
    "delete_rounded": "trash2",
    "delete_outline_rounded": "trash2",
    "delete_forever_rounded": "trash2",
    "delete_sweep_outlined": "trash",
    "edit_rounded": "pencil",
    "edit_outlined": "pencil",
    "copy_rounded": "copy",
    "content_copy_rounded": "copy",
    "share_rounded": "share2",
    "save_rounded": "save",
    "download_rounded": "download",
    "upload_rounded": "upload",
    "file_upload_rounded": "upload",
    "file_download_rounded": "download",
    "paste_rounded": "clipboardPaste",
    "folder_outlined": "folder",
    "folder_rounded": "folder",
    "description_rounded": "fileText",
    "description_outlined": "fileText",
    # Communication
    "send_rounded": "send",
    "email_outlined": "mail",
    "email_rounded": "mail",
    "phone_rounded": "phone",
    "phone_outlined": "phone",
    "phone_android_rounded": "smartphone",
    "message_rounded": "messageSquare",
    "chat_rounded": "messageCircle",
    # Search / nav
    "search_rounded": "search",
    "filter_list_rounded": "filter",
    "filter_3_rounded": "filter",
    "tune_rounded": "sliders",
    "menu_rounded": "menu",
    "home_rounded": "home",
    "home_outlined": "home",
    "dashboard_rounded": "layoutDashboard",
    # Time / date
    "calendar_today_rounded": "calendar",
    "calendar_month_rounded": "calendarDays",
    "event_rounded": "calendar",
    "event_note_rounded": "calendarRange",
    "access_time_rounded": "clock",
    "access_time_filled_rounded": "clock",
    "alarm_rounded": "alarmClock",
    "timer_rounded": "timer",
    "timer_outlined": "timer",
    "history_rounded": "history",
    # Auth / security
    "lock_rounded": "lock",
    "lock_outline_rounded": "lock",
    "password_rounded": "key",
    "vpn_key_rounded": "key",
    "key_rounded": "key",
    "lock_reset_rounded": "keyRound",
    "visibility_rounded": "eye",
    "visibility_outlined": "eye",
    "visibility_off_rounded": "eyeOff",
    "visibility_off_outlined": "eyeOff",
    "logout_rounded": "logOut",
    "login_rounded": "logIn",
    "shield_outlined": "shield",
    "shield_rounded": "shield",
    # User
    "person_rounded": "user",
    "person_outline_rounded": "user",
    "person_outlined": "user",
    "person_add_rounded": "userPlus",
    "group_rounded": "users",
    "people_rounded": "users",
    "people_outlined": "users",
    "account_circle_rounded": "userCircle2",
    # Status / alert
    "error_outline_rounded": "alertCircle",
    "error_rounded": "alertCircle",
    "warning_rounded": "alertTriangle",
    "warning_amber_rounded": "alertTriangle",
    "info_outline_rounded": "info",
    "info_rounded": "info",
    "help_outline_rounded": "helpCircle",
    "help_rounded": "helpCircle",
    "report_rounded": "flag",
    # Theme
    "dark_mode_rounded": "moon",
    "light_mode_rounded": "sun",
    "brightness_auto_rounded": "sunMoon",
    "palette_rounded": "palette",
    "format_paint_rounded": "palette",
    # Notifications / sound
    "notifications_rounded": "bell",
    "notifications_outlined": "bell",
    "notifications_active_rounded": "bell",
    "notifications_off_rounded": "bellOff",
    "music_note_rounded": "music",
    "headphones_rounded": "headphones",
    "volume_up_rounded": "volume2",
    "volume_off_rounded": "volumeX",
    "vibration_rounded": "vibrate",
    "mic_rounded": "mic",
    "mic_off_rounded": "micOff",
    # Media
    "play_arrow_rounded": "play",
    "pause_rounded": "pause",
    "stop_rounded": "square",
    "skip_next_rounded": "skipForward",
    "skip_previous_rounded": "skipBack",
    "image_rounded": "image",
    "image_outlined": "image",
    "camera_alt_rounded": "camera",
    "camera_rounded": "camera",
    "photo_camera_rounded": "camera",
    # Network / cloud
    "cloud_rounded": "cloud",
    "cloud_off_rounded": "cloudOff",
    "cloud_upload_rounded": "uploadCloud",
    "cloud_sync_rounded": "refreshCw",
    "wifi_rounded": "wifi",
    "wifi_off_rounded": "wifiOff",
    # Editing
    "format_list_bulleted_rounded": "list",
    "format_quote_rounded": "quote",
    "format_bold_rounded": "bold",
    "format_italic_rounded": "italic",
    # Achievements / motivation
    "star_rounded": "star",
    "star_border_rounded": "star",
    "star_outline_rounded": "star",
    "favorite_rounded": "heart",
    "favorite_border_rounded": "heart",
    "bookmark_rounded": "bookmark",
    "bookmark_border_rounded": "bookmark",
    "flag_rounded": "flag",
    "trophy_rounded": "trophy",
    "emoji_events_rounded": "trophy",
    "leaderboard_rounded": "barChart3",
    "celebration_rounded": "partyPopper",
    "local_fire_department_rounded": "flame",
    "bolt_rounded": "zap",
    "rocket_launch_rounded": "rocket",
    "auto_awesome_rounded": "sparkles",
    "auto_awesome_outlined": "sparkles",
    "lightbulb_outline_rounded": "lightbulb",
    "lightbulb_rounded": "lightbulb",
    "psychology_rounded": "brain",
    "school_rounded": "graduationCap",
    "menu_book_rounded": "bookOpen",
    "book_rounded": "book",
    # Charts / data
    "bar_chart_rounded": "barChart3",
    "bar_chart_outlined": "barChart3",
    "show_chart_rounded": "lineChart",
    "donut_large_rounded": "pieChart",
    "pie_chart_rounded": "pieChart",
    "trending_up_rounded": "trendingUp",
    "trending_down_rounded": "trendingDown",
    "grid_view_rounded": "grid",
    # Categories
    "fitness_center_rounded": "dumbbell",
    "directions_run_rounded": "footprints",
    "spa_rounded": "flower",
    "self_improvement_rounded": "flower2",
    "restaurant_rounded": "utensils",
    "work_outline_rounded": "briefcase",
    "code_rounded": "code2",
    "translate_rounded": "languages",
    "calculate_rounded": "calculator",
    "science_rounded": "flaskConical",
    "biotech_rounded": "flaskConical",
    "history_edu_rounded": "scroll",
    "eco_rounded": "leaf",
    "park_rounded": "trees",
    "credit_card_rounded": "creditCard",
    "monetization_on_rounded": "circleDollarSign",
    "card_giftcard_rounded": "gift",
    "shopping_bag_rounded": "shoppingBag",
    # Misc
    "settings_rounded": "settings",
    "settings_outlined": "settings",
    "cleaning_services_outlined": "sparkles",
    "qr_code_rounded": "qrCode",
    "language_rounded": "globe",
    "translate_rounded": "languages",
    "play_circle_rounded": "playCircle",
    "swipe_left_rounded": "moveLeft",
    "touch_app_rounded": "pointer",
    "list_alt_rounded": "list",
    "checklist_rounded": "listChecks",
    "task_alt_rounded": "checkSquare",
    "add_task_rounded": "plus",
    "playlist_add_rounded": "listPlus",
    "toggle_on_rounded": "toggleRight",
    "toggle_off_rounded": "toggleLeft",
}

ICON_RE = re.compile(r"\bIcons\.([a-zA-Z_][a-zA-Z0-9_]*)")
LUCIDE_IMPORT = "import 'package:lucide_icons/lucide_icons.dart';"


def lucide_replace(text: str) -> tuple[str, int]:
    count = 0

    def repl(m: re.Match) -> str:
        nonlocal count
        name = m.group(1)
        if name in MAP:
            count += 1
            return f"LucideIcons.{MAP[name]}"
        return m.group(0)

    return ICON_RE.sub(repl, text), count


def ensure_import(text: str) -> str:
    if "package:lucide_icons" in text:
        return text
    # insert after the last `import 'package:` line
    lines = text.split("\n")
    last_pkg = -1
    for i, ln in enumerate(lines):
        if ln.startswith("import 'package:"):
            last_pkg = i
    if last_pkg < 0:
        return LUCIDE_IMPORT + "\n" + text
    lines.insert(last_pkg + 1, LUCIDE_IMPORT)
    return "\n".join(lines)


def main():
    root = Path(__file__).resolve().parent.parent / "lib"
    total = 0
    files = 0
    for path in root.rglob("*.dart"):
        text = path.read_text(encoding="utf-8")
        new_text, n = lucide_replace(text)
        if n == 0:
            continue
        if "LucideIcons" in new_text:
            new_text = ensure_import(new_text)
        path.write_text(new_text, encoding="utf-8", newline="\n")
        total += n
        files += 1
        print(f"{path.relative_to(root)}: {n} icons")
    print(f"\n{files} files updated, {total} icons swapped")


if __name__ == "__main__":
    main()
