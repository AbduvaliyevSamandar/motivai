"""Find Text widgets inside Row that lack overflow handling.

A Text inside a Row without Flexible/Expanded wrap (or maxLines/overflow
on the Text itself) is a likely overflow source. We just print warnings —
the user fixes manually based on context.
"""
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent / "lib"

# Match Text(...)  not preceded by Flexible(...) or wrapped in Expanded
# This is heuristic — we just look for Text( with a string starting `'$`
# (interpolation) and no maxLines/overflow nearby.
RX = re.compile(
    r"Text\(\s*'(?:[^']|\\')*\$\{?[a-zA-Z_]",
    re.MULTILINE,
)


def main():
    for path in sorted(ROOT.rglob("*.dart")):
        text = path.read_text(encoding="utf-8")
        for m in RX.finditer(text):
            start = m.start()
            # Look at next 200 chars for maxLines/overflow markers
            window = text[start:start + 250]
            if "maxLines" in window or "overflow" in window:
                continue
            line_no = text[:start].count("\n") + 1
            preview = text[start:start + 60].replace("\n", " ")
            print(f"{path.relative_to(ROOT)}:{line_no}  {preview}")


if __name__ == "__main__":
    main()
