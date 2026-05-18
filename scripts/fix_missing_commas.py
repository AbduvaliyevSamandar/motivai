"""Restore trailing commas the recolor script accidentally stripped.

Pattern: a line ending in `)` followed by a line starting with `_tile(` or `_section(` etc.,
without a comma. This is unambiguous in widget-list contexts.
"""
from pathlib import Path
import re

TARGETS = [
    Path(__file__).resolve().parent.parent / "lib" / "screens" / "main" / "profile_screen.dart",
]

# A right paren on its own line, no trailing comma, followed by another widget call.
# Restrict to safe contexts: next non-blank line begins with _tile, _section, _label,
# _switch, _PrimaryButton, etc. — i.e., widget list children.
NEXT_HEADS = (
    "_tile(", "_section(", "_label(", "_switch(",
    "_buildAchievement", "_HeaderActionBtn", "_PrimaryButton",
    "Padding(", "SizedBox(", "Divider(",
)


def fix(text: str) -> tuple[str, int]:
    lines = text.split("\n")
    n = 0
    for i in range(len(lines) - 1):
        cur = lines[i]
        nxt = lines[i + 1].lstrip()
        if cur.rstrip().endswith(")") and not cur.rstrip().endswith("),"):
            if any(nxt.startswith(h) for h in NEXT_HEADS):
                lines[i] = cur.rstrip() + ","
                n += 1
    return "\n".join(lines), n


for path in TARGETS:
    text = path.read_text(encoding="utf-8")
    new_text, n = fix(text)
    if n:
        path.write_text(new_text, encoding="utf-8", newline="\n")
        print(f"{path.name}: added {n} commas")
    else:
        print(f"{path.name}: no fixes needed")
