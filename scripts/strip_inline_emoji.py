"""Remove inline emoji from UI strings (snackbars, banners, headlines).

Targets only single-quoted strings that contain BOTH normal text words
and a `\\u{...}` emoji escape — those are decorative emoji-in-copy that
read as 'AI wrote this'. Pure emoji-only strings (used as iconography
in `Text(emoji)`) are left alone.

Spec:
  - Match a single-quoted Dart string that has at least one ASCII letter
    AND at least one `\\u{...}` escape
  - Strip the `\\u{...}` escapes (and any single space immediately around
    them) inside that string
  - Skip if the file is in lib/services/ (those tend to be emoji
    constants for theme presets / mood lists / friend avatars / etc.)
"""
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent / "lib"

# Skip files where emoji is data, not UI copy.
SKIP_PATHS = (
    "services/morning_ritual.dart",
    "services/journey_storage.dart",
    "services/sound_pack.dart",
    "services/haptic_service.dart",
    "services/user_goal.dart",
    "services/smart_plan.dart",
    "services/achievements.dart",
    "services/daily_challenge.dart",
    "services/task_templates.dart",
    "services/ambient_sounds.dart",
    "config/theme_presets.dart",
)

EMOJI_ESCAPE = re.compile(r"\\u\{[0-9a-fA-F]+\}")


def strip_in_string(literal: str) -> str:
    """Remove emoji escapes from a single-quoted string literal value."""
    # Drop emoji escape + the optional space adjacent to it
    cleaned = re.sub(r"\s*\\u\{[0-9a-fA-F]+\}\s*", " ", literal)
    return re.sub(r"\s+", " ", cleaned).strip()


def transform(text: str) -> tuple[str, int]:
    out = []
    i = 0
    count = 0
    rx = re.compile(r"'((?:[^'\\]|\\.)*)'")
    for m in rx.finditer(text):
        body = m.group(1)
        if not EMOJI_ESCAPE.search(body):
            continue
        # Require at least one ASCII letter in the literal (proves it's
        # a sentence, not a pure emoji icon).
        if not re.search(r"[A-Za-z]{2,}", body):
            continue
        new_body = strip_in_string(body)
        if new_body == body:
            continue
        out.append(text[i:m.start() + 1])
        out.append(new_body)
        out.append("'")
        i = m.end()
        count += 1
    out.append(text[i:])
    return "".join(out), count


def main():
    total = 0
    for path in sorted(ROOT.rglob("*.dart")):
        rel = path.relative_to(ROOT).as_posix()
        if any(s in rel for s in SKIP_PATHS):
            continue
        text = path.read_text(encoding="utf-8")
        new_text, n = transform(text)
        if n == 0:
            continue
        path.write_text(new_text, encoding="utf-8", newline="\n")
        total += n
        print(f"{rel}: {n} stripped")
    print(f"\nTotal inline emojis removed: {total}")


if __name__ == "__main__":
    main()
