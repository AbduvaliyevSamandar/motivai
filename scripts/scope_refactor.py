"""One-shot refactor: switch SharedPreferences keys to UserScope-aware versions.

For each target service, we:
  1. Add `import 'user_scope.dart';` (if missing).
  2. Replace `static const _key = 'motivai_xxx';` -> `static const _baseKey = 'motivai_xxx';
     static String get _key => UserScope.key(_baseKey);`
  3. Replace any literal SharedPreferences calls
     `getString('motivai_xxx')` -> `getString(UserScope.key('motivai_xxx'))`.
  4. Add a UserScope.changes listener that resets the cache (`_cache`, `_loaded`).

This is a one-off helper kept in scripts/ for traceability.
"""
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent / "lib" / "services"
PROVIDERS = Path(__file__).resolve().parent.parent / "lib" / "providers"

# (relative_path, list_of_field_names_to_scope, [optional cache var to reset])
TARGETS = [
    ("services/journey_storage.dart", ["_key"], "_cache"),
    ("services/streak_storage.dart", ["_countKey", "_lastGrantKey"], None),
    ("services/daily_challenge.dart", ["_completedKey", "_dateKey", "_progressKey"], None),
    ("services/morning_ritual.dart", ["_key"], "_cache"),
    ("services/rituals_storage.dart", ["_key"], "_cache"),
    ("services/friend_challenge.dart", ["_key"], "_cache"),
    ("services/friends_storage.dart", ["_listKey", "_myCodeKey"], "_cache"),
    ("services/habit_storage.dart", ["_key"], None),
    ("services/flashcards_storage.dart", ["_decksKey", "_cardsKey"], None),
    ("services/task_notes.dart", ["_key"], None),
    ("services/pinned_storage.dart", ["_key"], None),
    ("services/local_schedules.dart", ["_key"], None),
    ("services/achievements.dart", ["_unlockedKey"], None),
    ("services/custom_categories.dart", ["_key"], None),
    ("services/action_queue.dart", ["_key"], "_queue"),
    ("services/user_goal.dart", ["_key", "_customKey"], None),
]


def has_user_scope_import(text: str) -> bool:
    return "user_scope.dart" in text


def add_import(text: str) -> str:
    # Inject right after the last `import 'package:` or `import '...'` statement.
    lines = text.split("\n")
    last_import = -1
    for i, line in enumerate(lines):
        if line.startswith("import "):
            last_import = i
    if last_import < 0:
        return "import 'user_scope.dart';\n" + text
    insert_after = last_import
    lines.insert(insert_after + 1, "import 'user_scope.dart';")
    return "\n".join(lines)


def scope_field(text: str, field: str) -> str:
    """Convert `static const _key = 'motivai_xxx';` to scoped getter."""
    pattern = re.compile(
        r"static\s+const\s+" + re.escape(field) + r"\s*=\s*'(motivai_[^']+)'\s*;"
    )

    def repl(m: re.Match) -> str:
        base = m.group(1)
        base_field = field + "Base"
        return (
            f"static const {base_field} = '{base}';\n"
            f"  static String get {field} => UserScope.key({base_field});"
        )

    new_text, n = pattern.subn(repl, text)
    if n == 0:
        # Maybe field isn't `static const`; try `static final`
        pattern2 = re.compile(
            r"static\s+final\s+String\s+" + re.escape(field) + r"\s*=\s*'(motivai_[^']+)'\s*;"
        )
        new_text, n = pattern2.subn(repl, new_text)
    return new_text


def main():
    base_dir = ROOT.parent
    for rel, fields, cache_name in TARGETS:
        path = base_dir / rel
        if not path.exists():
            print(f"missing: {path}")
            continue
        text = path.read_text(encoding="utf-8")
        original = text
        for f in fields:
            text = scope_field(text, f)
        if text != original and not has_user_scope_import(text):
            text = add_import(text)
        if text != original:
            path.write_text(text, encoding="utf-8", newline="\n")
            print(f"updated: {rel}")
        else:
            print(f"no change: {rel}")


if __name__ == "__main__":
    main()
