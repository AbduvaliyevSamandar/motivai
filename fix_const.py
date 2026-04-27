"""One-shot helper: removes `const` prefixes on Widget constructors reported
as 'Invalid constant value' errors by flutter analyze. Idempotent; runs
until error count stops decreasing or reaches zero."""
import re
import subprocess
import sys

MAX_PASSES = 8

def run_analyze():
    out = subprocess.run(
        'flutter analyze lib',
        shell=True,
        capture_output=True,
        text=True,
    ).stdout
    errors = []
    pattern = re.compile(r'error - Invalid constant value - (\S+):(\d+):(\d+)')
    for line in out.splitlines():
        m = pattern.search(line)
        if m:
            path = m.group(1).replace('\\', '/')
            errors.append((path, int(m.group(2)), int(m.group(3))))
    return errors

def fix_once(errors):
    files = {}
    for path, _, _ in errors:
        if path not in files:
            with open(path, 'r', encoding='utf-8') as f:
                files[path] = f.readlines()
    touched = set()
    for path, row, col in errors:
        lines = files[path]
        # Walk up to 10 lines back to find a `const ` followed by uppercase
        for r in range(row - 1, max(-1, row - 12), -1):
            if r < 0:
                break
            line = lines[r]
            idx = 0
            while True:
                idx = line.find('const ', idx)
                if idx == -1:
                    break
                nxt = line[idx + 6 : idx + 7]
                if nxt and nxt.isupper():
                    line = line[:idx] + line[idx + 6:]
                    lines[r] = line
                    touched.add(path)
                    break
                idx += 6
            if path in touched and lines[r] != line:
                break  # moved on
            if path in touched:
                break
    for path in touched:
        with open(path, 'w', encoding='utf-8') as f:
            f.writelines(files[path])
    return len(touched)

prev_count = -1
for i in range(MAX_PASSES):
    errors = run_analyze()
    count = len(errors)
    print(f'Pass {i}: {count} invalid_constant errors')
    if count == 0 or count == prev_count:
        break
    prev_count = count
    fixed = fix_once(errors)
    if fixed == 0:
        break

print('Done.')
