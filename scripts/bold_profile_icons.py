# -*- coding: utf-8 -*-
"""Swap Iconsax line icons to bold (_copy) variants in profile tiles for
picture-like appearance against the colored gradient chips."""
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent / "lib"

# Iconsax names that have _copy bold variants we want to use in tiles
SWAP = {
    "Iconsax.brush_1": "Iconsax.brush_1_copy",
    "Iconsax.lock_1": "Iconsax.lock_1_copy",
    "Iconsax.card": "Iconsax.card_copy",
    "Iconsax.activity": "Iconsax.activity_copy",
    "Iconsax.magicpen": "Iconsax.magicpen_copy",
    "Iconsax.tree": "Iconsax.tree_copy",
    "Iconsax.grid_8": "Iconsax.grid_8_copy",
    "Iconsax.profile_2user": "Iconsax.profile_2user_copy",
    "Iconsax.cup": "Iconsax.cup_copy",
    "Iconsax.translate": "Iconsax.translate_copy",
    "Iconsax.notification_1": "Iconsax.notification_1_copy",
    "Iconsax.music_circle": "Iconsax.music_circle_copy",
    "Iconsax.mobile": "Iconsax.mobile_copy",
    "Iconsax.import_1": "Iconsax.import_1_copy",
    "Iconsax.send_1": "Iconsax.send_1_copy",
    "Iconsax.export_1": "Iconsax.export_1_copy",
    "Iconsax.send_2": "Iconsax.send_2_copy",
    "Iconsax.flash_1": "Iconsax.flash_1_copy",
    "Iconsax.brifecase_tick": "Iconsax.brifecase_tick_copy",
    "Iconsax.heart": "Iconsax.heart_copy",
    "Iconsax.star": "Iconsax.star_copy",
    "Iconsax.book": "Iconsax.book_copy",
    "Iconsax.box": "Iconsax.box_copy",
    "Iconsax.user": "Iconsax.user_copy",
    "Iconsax.user_octagon": "Iconsax.user_octagon_copy",
    "Iconsax.book_1": "Iconsax.book_1_copy",
    "Iconsax.timer_1": "Iconsax.timer_1_copy",
    "Iconsax.calendar": "Iconsax.calendar_copy",
    "Iconsax.calendar_1": "Iconsax.calendar_1_copy",
    "Iconsax.clock": "Iconsax.clock_copy",
    "Iconsax.archive": "Iconsax.archive_copy",
    "Iconsax.add_circle": "Iconsax.add_circle_copy",
    "Iconsax.tick_circle": "Iconsax.tick_circle_copy",
}

# Files where the swap should happen
TARGETS = [
    "screens/main/profile_screen.dart",
]


def main():
    total = 0
    for rel in TARGETS:
        p = ROOT / rel
        text = p.read_text(encoding="utf-8")
        n = 0
        for old, new in SWAP.items():
            # Avoid double-swap and only target `icon: X` and `icon: X,` contexts
            for ctx_pat in (
                f"icon: {old},",
                f"icon: {old}\n",
            ):
                count = text.count(ctx_pat)
                if count:
                    text = text.replace(ctx_pat, ctx_pat.replace(old, new))
                    n += count
        if n:
            p.write_text(text, encoding="utf-8", newline="\n")
            print(f"  {rel}: {n} swaps")
            total += n
    print(f"\nTotal: {total}")


if __name__ == "__main__":
    main()
