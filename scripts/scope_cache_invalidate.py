"""For services with `_loaded` boolean caches, switch to per-user invalidation:
  before:  if (_loaded) return;
  after:   if (_loaded && _loadedFor == UserScope.userId) return;
           _<cache_var> = <empty_initial>;
           _loadedFor = UserScope.userId;

We also inject `static String _loadedFor = '';` after the `_loaded` declaration.
"""
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent / "lib" / "services"

# (file_name, cache_var_name, empty_initializer)
TARGETS = [
    ("morning_ritual.dart", "_cache", "[]"),
    ("rituals_storage.dart", "_cache", "[]"),
    ("friend_challenge.dart", "_cache", "[]"),
    ("friends_storage.dart", "_cache", "[]"),
    ("user_goal.dart", None, None),  # has _current/_custom but no list cache to clear
]


def add_loaded_for(text: str) -> str:
    if "_loadedFor" in text:
        return text
    return re.sub(
        r"(static\s+bool\s+_loaded\s*=\s*false\s*;)",
        r"\1\n  static String _loadedFor = '';",
        text,
        count=1,
    )


def patch_ensure(text: str, cache_var: str | None, empty: str | None) -> str:
    """Replace the early-exit + add invalidation."""
    pattern = re.compile(r"if\s*\(_loaded\)\s*return\s*;")

    def repl(m: re.Match) -> str:
        lines = ["if (_loaded && _loadedFor == UserScope.userId) return;"]
        if cache_var and empty:
            lines.append(f"    {cache_var} = {empty};")
        lines.append("    _loadedFor = UserScope.userId;")
        return "\n    ".join(lines)

    return pattern.sub(repl, text, count=1)


def patch_user_goal(text: str) -> str:
    """user_goal has a different _ensure shape — patch it manually."""
    if "_loadedFor" not in text:
        text = add_loaded_for(text)
    pattern = re.compile(
        r"(static\s+Future<void>\s+load\(\)\s*async\s*\{\s*)(if\s*\(_loaded\)\s*return\s*;)"
    )
    text = pattern.sub(
        r"\1if (_loaded && _loadedFor == UserScope.userId) return;\n"
        "    _current = null;\n"
        "    _custom = null;\n"
        "    _loadedFor = UserScope.userId;",
        text,
        count=1,
    )
    return text


def main():
    for name, cache_var, empty in TARGETS:
        path = ROOT / name
        if not path.exists():
            print(f"missing: {name}")
            continue
        text = path.read_text(encoding="utf-8")
        original = text
        if name == "user_goal.dart":
            text = patch_user_goal(text)
        else:
            text = add_loaded_for(text)
            text = patch_ensure(text, cache_var, empty)
        if text != original:
            path.write_text(text, encoding="utf-8", newline="\n")
            print(f"updated: {name}")
        else:
            print(f"no change: {name}")


if __name__ == "__main__":
    main()
