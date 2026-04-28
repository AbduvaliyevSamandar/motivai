"""Surgical overflow fix: for every `Text(...)` block that contains a
`$variable` interpolation but lacks maxLines/overflow, inject those props
so it can't blow past its parent.

Strategy:
  1. Match Text(...) spanning multiple lines via greedy balanced parens
  2. If the body already has 'maxLines' or 'overflow', skip
  3. Otherwise, insert ', maxLines: 1, overflow: TextOverflow.ellipsis'
     just before the final closing ')' of the Text() call

We only touch Text widgets that contain `$` (i.e. dynamic content) — pure
literal labels like `Text('Hello')` are left alone since the developer
sized them deliberately.
"""
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent / "lib"


def find_text_calls(text: str):
    """Yield (start, end) tuples for each `Text(...)` call.

    Handles nested parens via a tiny depth counter — assumes string
    literals don't contain unescaped parens (true for this repo).
    """
    i = 0
    while True:
        m = re.search(r"\bText\(", text[i:])
        if not m:
            break
        start = i + m.start()
        depth = 0
        j = i + m.end()  # right after '('
        depth = 1
        in_string = None  # ' or "
        escape = False
        while j < len(text) and depth > 0:
            ch = text[j]
            if in_string:
                if escape:
                    escape = False
                elif ch == "\\":
                    escape = True
                elif ch == in_string:
                    in_string = None
            else:
                if ch == "'" or ch == '"':
                    in_string = ch
                elif ch == "(":
                    depth += 1
                elif ch == ")":
                    depth -= 1
                    if depth == 0:
                        yield start, j
                        i = j + 1
                        break
            j += 1
        else:
            i = j
            break


def fix_file(path: Path) -> int:
    text = path.read_text(encoding="utf-8")
    out = []
    last = 0
    fixed = 0
    for start, end in list(find_text_calls(text)):
        body = text[start:end + 1]
        # Skip if no interpolation
        if "$" not in body:
            continue
        if "maxLines" in body or "overflow:" in body:
            continue
        # Inject before final ')'
        # Find the position of the closing ')' relative to text
        # body[-1] is ')'. Insert ' maxLines: 1, overflow: TextOverflow.ellipsis,'
        # before it.
        new_body = body[:-1].rstrip()
        # Make sure we have a trailing comma so injection lines up
        if not new_body.endswith(","):
            new_body += ","
        new_body += "\n              maxLines: 1, overflow: TextOverflow.ellipsis,\n            )"
        out.append(text[last:start])
        out.append(new_body)
        last = end + 1
        fixed += 1
    out.append(text[last:])
    if fixed == 0:
        return 0
    path.write_text("".join(out), encoding="utf-8", newline="\n")
    return fixed


def main():
    total = 0
    for path in sorted(ROOT.rglob("*.dart")):
        n = fix_file(path)
        if n:
            print(f"{path.relative_to(ROOT)}: +{n}")
            total += n
    print(f"\nTotal Text widgets hardened: {total}")


if __name__ == "__main__":
    main()
