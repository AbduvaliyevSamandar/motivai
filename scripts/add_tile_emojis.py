# -*- coding: utf-8 -*-
"""Add emoji: '...' arg next to each profile tile so the chip renders a
picture-like emoji glyph (modern OS emoji = full-color illustration)."""
from pathlib import Path

PATH = Path(__file__).resolve().parent.parent / "lib" / "screens" / "main" / "profile_screen.dart"

# Map: a unique substring of the tile (e.g., its title S.get('...')) → emoji
EMOJI_BY_TITLE = {
    "S.get('auto_theme')":    "🌗",
    "S.get('theme_color')":   "🎨",
    "S.get('change_pass')":   "🔒",
    "S.get('flashcards')":    "📇",
    "S.get('habits')":        "🌱",
    "S.get('wrapped')":       "📊",
    "S.get('smart_plan')":    "🧠",
    "S.get('journey')":       "🌳",
    "S.get('heatmap')":       "📈",
    "S.get('rituals')":       "🌅",
    "S.get('friends_title')": "👥",
    "S.get('challenges')":    "🏆",
    "S.get('language')":      "🌍",
    "S.get('notifications')": "🔔",
    "S.get('test_notif')":    "🧪",
    "S.get('sound_pack')":    "🎵",
    "S.get('haptics')":       "📳",
    "S.get('export_data')":   "📤",
    "S.get('share_template')":"📨",
    "S.get('import_template')":"📥",
    "S.get('about_motivai')": "ℹ️",
    "S.get('help')":          "❓",
    "S.get('privacy_policy')":"🛡️",
    "S.get('terms_of_service')":"📜",
    "S.get('delete_account')":"🗑️",
    "S.get('smart_reminder')":"⏰",
}

text = PATH.read_text(encoding='utf-8')
total = 0

for marker, emoji in EMOJI_BY_TITLE.items():
    # Find each occurrence of `title: <marker>,` and add `emoji: '<emoji>',`
    # right BEFORE that line (insertion preserves indentation by reusing the
    # lookup substring's indentation).
    needle = f"title: {marker}"
    if needle not in text:
        # Many markers appear inside if-blocks with same title; allow soft fallback
        # by trying with a closing bracket in case of S.get('xxx') variants.
        continue
    # Insert emoji line before the title line. Find the start of the title line.
    idx = text.find(needle)
    while idx != -1:
        # Find start of line
        line_start = text.rfind('\n', 0, idx) + 1
        indent = text[line_start:idx]
        # Skip if emoji already added on previous line
        prev_line_start = text.rfind('\n', 0, line_start - 1) + 1
        prev_line = text[prev_line_start:line_start]
        if 'emoji:' in prev_line:
            idx = text.find(needle, idx + 1)
            continue
        new_line = f"{indent}emoji: '{emoji}',\n"
        text = text[:line_start] + new_line + text[line_start:]
        total += 1
        # Search continues after our insertion
        idx = text.find(needle, idx + len(new_line) + 1)

PATH.write_text(text, encoding='utf-8', newline='\n')
print(f"Added emoji to {total} tiles")
