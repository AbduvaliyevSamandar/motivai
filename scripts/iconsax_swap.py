"""Promote the most visible decorative icons from Lucide line-stroke to
Iconsax Bold — they read as more polished / Apple-grade in marketing
surfaces (streak flame, XP star, trophy on leaderboard, etc.).

We keep Lucide for everything functional (toolbars, profile rows,
secondary actions) so the bulk of the app stays consistent.
"""
import re
from pathlib import Path

# (lucide_name, iconsax_const)
SWAPS = {
    "LucideIcons.flame":      "Iconsax.flash_1",        # streak fire
    "LucideIcons.star":       "Iconsax.star_1",         # XP / favourite
    "LucideIcons.rocket":     "Iconsax.rocket",          # new release / boost
    "LucideIcons.book":       "Iconsax.book_1",
    "LucideIcons.bookOpen":   "Iconsax.book_saved",
    "LucideIcons.brain":      "Iconsax.brifecase_tick",  # mentor / smart plan
    "LucideIcons.target":     "Iconsax.flag_2",          # goal / target
    "LucideIcons.trophy":     "Iconsax.cup",
    "LucideIcons.zap":        "Iconsax.flash",
    "LucideIcons.partyPopper":"Iconsax.medal_star",
    "LucideIcons.heart":      "Iconsax.heart",
    "LucideIcons.sparkles":   "Iconsax.magicpen",        # AI surfaces
}

# Iconsax names use snake_case style with `1`/`2` suffix for variants.
ICONSAX_IMPORT = "import 'package:iconsax_flutter/iconsax_flutter.dart';"


def main():
    root = Path(__file__).resolve().parent.parent / "lib"
    total = 0
    files = 0
    for path in root.rglob("*.dart"):
        text = path.read_text(encoding="utf-8")
        original = text
        for old, new in SWAPS.items():
            text = text.replace(old, new)
        if text == original:
            continue
        if "iconsax_flutter" not in text:
            # Insert after lucide import (or last package import)
            lines = text.split("\n")
            last = -1
            for i, ln in enumerate(lines):
                if ln.startswith("import 'package:"):
                    last = i
            lines.insert(last + 1, ICONSAX_IMPORT)
            text = "\n".join(lines)
        path.write_text(text, encoding="utf-8", newline="\n")
        files += 1
        diff = sum(original.count(k) for k in SWAPS)
        total += diff
        print(f"{path.relative_to(root)}: {diff} swaps")
    print(f"\n{files} files updated, ~{total} icons promoted to Iconsax")


if __name__ == "__main__":
    main()
