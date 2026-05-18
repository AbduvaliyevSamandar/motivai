"""Scan all .dart files for hardcoded Uzbek UI strings that should be in S.get().

Targets Text widgets, snackbar copies, dialog titles/content, hintText, label, tooltip.
Outputs a JSON report mapping file -> list of {line, snippet, suggested_key}.
"""
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent / "lib"

# Skip: pure-data services where strings are domain content, not UI chrome.
SKIP_PATHS = (
    "config/strings.dart",
    "config/constants.dart",
    "services/morning_ritual.dart",
    "services/journey_storage.dart",
    "services/sound_pack.dart",
    "services/user_goal.dart",
    "services/smart_plan.dart",
    "services/achievements.dart",
    "services/daily_challenge.dart",
    "services/task_templates.dart",
    "services/ambient_sounds.dart",
    "services/quotes.dart",
    "services/affirmations.dart",
    "config/theme_presets.dart",
)

# Uzbek/Russian unique characters (helps disambiguate from English/code)
UZ_HINT = re.compile(r"[\u00f3\u00fc\u011f\u0130\u015f\u0131]|[''`]|chiq|kirish|saqlash|qo'sh|tanla|bekor|tasdiq|ulashish|"
                     r"vazifa|reja|rejim|bildirish|rejim|sozla|profil|maxfi|akka|parol|hisob|"
                     r"y[oa]'?q|yo'q|chiq|tugat|yopish|yangi|eski|ish|haftal|kunlik|oylik|haqida")

# Strings that look like content but should NOT be translated (filenames, code labels, etc)
CODE_HINTS = re.compile(r"^[a-zA-Z_][\w./]*$|^\s*$|^\d+$|^[/.]|^http|^assets|^/")

# Match T('...'), Text('...'), title: '...', label: '...', hintText: '...', etc.
PATTERNS = [
    # Text('...'), Text("...")
    (re.compile(r"\bText\(\s*'((?:[^'\\]|\\.)+)'"), 'Text'),
    (re.compile(r"\bText\(\s*\"((?:[^\"\\]|\\.)+)\""), 'Text'),
    # Specific named arguments
    (re.compile(r"\b(title|hintText|labelText|tooltip|message|content|label|description|subtitle):\s*'((?:[^'\\]|\\.)+)'"), 'kw'),
    (re.compile(r"\b(title|hintText|labelText|tooltip|message|content|label|description|subtitle):\s*\"((?:[^\"\\]|\\.)+)\""), 'kw'),
    # SnackBar(content: Text('...')) bare strings
    (re.compile(r"SnackBar[^)]*Text\(\s*'((?:[^'\\]|\\.)+)'"), 'snack'),
]


def is_uz_string(s: str) -> bool:
    if len(s) < 3:
        return False
    if CODE_HINTS.match(s):
        return False
    # Must contain at least one space OR an apostrophe (real sentence indicator)
    if ' ' not in s and "'" not in s:
        # Could be a single Uzbek word
        if not UZ_HINT.search(s.lower()):
            return False
    # Avoid pure-English short strings
    if s.isascii() and ' ' not in s and "'" not in s:
        return False
    # Skip if all uppercase ASCII (likely a constant)
    if s.isascii() and s.isupper():
        return False
    return True


def scan_file(path: Path):
    rel = path.relative_to(ROOT).as_posix()
    if any(s in rel for s in SKIP_PATHS):
        return []
    text = path.read_text(encoding="utf-8")
    lines = text.split("\n")
    seen = set()
    matches = []
    for pat, kind in PATTERNS:
        for m in pat.finditer(text):
            content = m.group(2) if kind == 'kw' else m.group(1)
            # Skip already-translated S.get(...) wrapped contexts (heuristic)
            ctx_start = max(0, m.start() - 30)
            ctx = text[ctx_start:m.start()]
            if 'S.get(' in ctx:
                continue
            if not is_uz_string(content):
                continue
            line_no = text[: m.start()].count("\n") + 1
            key = (line_no, content)
            if key in seen:
                continue
            seen.add(key)
            matches.append({
                "line": line_no,
                "snippet": content,
                "kind": kind if kind != 'kw' else m.group(1),
            })
    return matches


def main():
    report = {}
    total = 0
    for path in sorted(ROOT.rglob("*.dart")):
        m = scan_file(path)
        if m:
            rel = path.relative_to(ROOT).as_posix()
            report[rel] = m
            total += len(m)
    print(json.dumps({"total": total, "files": {k: len(v) for k, v in report.items()}}, indent=2, ensure_ascii=False))
    out = Path(__file__).resolve().parent / "hardcoded_strings.json"
    out.write_text(json.dumps(report, indent=2, ensure_ascii=False), encoding="utf-8")
    print(f"\nFull report saved to: {out}")


if __name__ == "__main__":
    main()
