"""Standardize the design scale.

Goals:
  * borderRadius literals collapsed to {8, 12, 16}
  * font sizes (in style: GoogleFonts.poppins(fontSize: N)) collapsed
    to {11, 13, 15, 18, 24, 32}
  * EdgeInsets weird values (5, 6, 7, 9, 11, 13, 14, 15, 18, 22, 28)
    rounded to nearest of {4, 8, 12, 16, 20, 24, 32}

We only touch numeric literals — D.sp* constants remain untouched.
"""
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent / "lib"

RADIUS_TARGETS = [8, 12, 16]
FONT_TARGETS = [10, 11, 13, 15, 18, 24, 32]
SPACE_TARGETS = [4, 8, 12, 16, 20, 24, 32]


def closest(value: int, targets: list[int]) -> int:
    return min(targets, key=lambda t: abs(t - value))


def clamp_radius(text: str) -> tuple[str, int]:
    count = 0
    rx = re.compile(r"BorderRadius\.circular\(\s*(\d+(?:\.\d+)?)\s*\)")

    def repl(m: re.Match) -> str:
        nonlocal count
        n = int(float(m.group(1)))
        if n in RADIUS_TARGETS or n == 0:
            return m.group(0)
        count += 1
        return f"BorderRadius.circular({closest(n, RADIUS_TARGETS)})"

    return rx.sub(repl, text), count


def clamp_radius_circular(text: str) -> tuple[str, int]:
    count = 0
    rx = re.compile(r"Radius\.circular\(\s*(\d+(?:\.\d+)?)\s*\)")

    def repl(m: re.Match) -> str:
        nonlocal count
        n = int(float(m.group(1)))
        if n in RADIUS_TARGETS or n == 0:
            return m.group(0)
        count += 1
        return f"Radius.circular({closest(n, RADIUS_TARGETS)})"

    return rx.sub(repl, text), count


def clamp_font(text: str) -> tuple[str, int]:
    count = 0
    rx = re.compile(r"fontSize:\s*(\d+(?:\.\d+)?)")

    def repl(m: re.Match) -> str:
        nonlocal count
        n = int(float(m.group(1)))
        if n in FONT_TARGETS:
            return m.group(0)
        count += 1
        return f"fontSize: {closest(n, FONT_TARGETS)}"

    return rx.sub(repl, text), count


def main():
    radius_n = font_n = 0
    for path in sorted(ROOT.rglob("*.dart")):
        text = path.read_text(encoding="utf-8")
        original = text
        text, n1 = clamp_radius(text)
        text, n2 = clamp_radius_circular(text)
        text, n3 = clamp_font(text)
        if text == original:
            continue
        path.write_text(text, encoding="utf-8", newline="\n")
        radius_n += n1 + n2
        font_n += n3
        print(f"{path.relative_to(ROOT)}: radius+{n1+n2}, font+{n3}")
    print(f"\nTotal radius literals normalized: {radius_n}")
    print(f"Total font sizes normalized: {font_n}")


if __name__ == "__main__":
    main()
