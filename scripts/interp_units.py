# -*- coding: utf-8 -*-
"""Translate the unit-word suffixes inside interpolated strings.

Patterns: '$X kun', '$X soat', '$X daqiqa', '$X tanga', '$X kunlik streak'.
"""
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent / "lib"

NEW_KEYS = {
    "unit_day":     ("kun", "дн.", "days"),
    "unit_hour":    ("soat", "ч.", "hours"),
    "unit_minute":  ("daqiqa", "мин.", "minutes"),
    "unit_coin":    ("tanga", "монет", "coins"),
    "day_streak":   ("kunlik streak", "дней streak", "day streak"),
    "review_count": ("ta takror", "повтор.", "to review"),
    "results_count":("ta natija", "результ.", "results"),
    "remaining":    ("ta", "", ""),  # Uzbek particle, empty in ru/en
    "focused_min":  ("daqiqa fokuslangansiz. ", "минут сосредоточения. ", "minutes focused. "),
}


def add_keys(strings_text: str) -> tuple[str, int]:
    existing = set(re.findall(r"'([a-z_][a-z0-9_]*)':\s*\{", strings_text))
    new_lines = []
    for key, (uz, ru, en) in NEW_KEYS.items():
        if key in existing:
            continue
        u = uz.replace("\\", "\\\\").replace("'", "\\'")
        r = ru.replace("\\", "\\\\").replace("'", "\\'")
        e = en.replace("\\", "\\\\").replace("'", "\\'")
        new_lines.append(f"    '{key}': {{'uz': '{u}', 'ru': '{r}', 'en': '{e}'}},")
    if not new_lines:
        return strings_text, 0
    block = "\n    // ── Added by interp_units.py ──\n" + "\n".join(new_lines) + "\n  "
    closing_pattern = r"(\n\s*)(\};)\s*\n\}\s*$"
    return re.sub(closing_pattern, lambda m: block + m.group(2) + "\n}\n", strings_text), len(new_lines)


PATTERNS = [
    (re.compile(r"'\$(\w+) kunlik streak'"), "day_streak", "var"),
    (re.compile(r"'\$(\w+) ta takror'"), "review_count", "var"),
    (re.compile(r"'\$(\w+) ta natija'"), "results_count", "var"),
    (re.compile(r"'\$(\w+) tanga'"), "unit_coin", "var"),
    (re.compile(r"'\$(\w+) kun'"), "unit_day", "var"),
    (re.compile(r"'\$\{([^{}]+)\} soat'"), "unit_hour", "expr"),
    (re.compile(r"'\$\{([^{}]+)\} daqiqa fokuslangansiz\. '"), "focused_min", "expr"),
]


def transform(text: str) -> tuple[str, int]:
    n = 0
    for pat, key, kind in PATTERNS:
        def repl(m, key=key, kind=kind):
            captured = m.group(1)
            prefix = f"${captured}" if kind == "var" else f"${{{captured}}}"
            return f"'{prefix} ${{S.get('{key}')}}'"
        text, c = pat.subn(repl, text)
        n += c
    return text, n


def ensure_s_import(text: str, file_path: Path) -> str:
    if "S.get(" not in text:
        return text
    if "config/strings.dart" in text:
        return text
    rel_depth = len(file_path.parts) - 1
    rel_prefix = "../" * rel_depth
    m = re.search(r"^import\s+'[^']+';", text, re.M)
    if not m:
        return text
    return text[: m.end()] + f"\nimport '{rel_prefix}config/strings.dart';" + text[m.end():]


def main():
    strings_file = ROOT / "config" / "strings.dart"
    s = strings_file.read_text(encoding="utf-8")
    new_s, n_keys = add_keys(s)
    if n_keys:
        strings_file.write_text(new_s, encoding="utf-8", newline="\n")
        print(f"Added {n_keys} unit keys")

    total = 0
    for path in sorted(ROOT.rglob("*.dart")):
        if path == strings_file:
            continue
        text = path.read_text(encoding="utf-8")
        new_text, n = transform(text)
        if n == 0:
            continue
        new_text = ensure_s_import(new_text, path.relative_to(ROOT))
        path.write_text(new_text, encoding="utf-8", newline="\n")
        total += n
        print(f"  {path.relative_to(ROOT).as_posix()}: {n}")
    print(f"\nTotal interpolation replacements: {total}")


if __name__ == "__main__":
    main()
