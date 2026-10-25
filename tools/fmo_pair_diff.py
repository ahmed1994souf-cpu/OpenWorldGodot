#!/usr/bin/env python3
"""Read-only byte-difference report for paired WWE RAW FMO files.

This is a diagnostic only: changed byte ranges are not assumed to be keyframes.
Usage:
  python fmo_pair_diff.py first.FMO second.FMO
"""
from pathlib import Path
import re
import sys

LABEL_RE = re.compile(rb"[A-Za-z_][A-Za-z0-9_]{2,}")
PREFIXES = ("o_", "n_", "c_", "e_", "j_", "sub_", "shape_")
EXACT = {"L_FOOT", "R_FOOT", "HAND_L", "HAND_R", "FACE"}


def labels(data):
    out = {}
    for m in LABEL_RE.finditer(data):
        name = m.group().decode("ascii", "ignore")
        if name.lower().startswith(PREFIXES) or name in EXACT:
            out.setdefault(name, []).append(m.start())
    return out


def changed_runs(a, b):
    limit = min(len(a), len(b))
    runs = []
    start = None
    for i in range(limit):
        different = a[i] != b[i]
        if different and start is None:
            start = i
        elif not different and start is not None:
            runs.append((start, i - 1))
            start = None
    if start is not None:
        runs.append((start, limit - 1))
    if len(a) != len(b):
        runs.append((limit, max(len(a), len(b)) - 1))
    return runs, limit


def main(p1, p2):
    a_path, b_path = Path(p1).expanduser(), Path(p2).expanduser()
    a, b = a_path.read_bytes(), b_path.read_bytes()
    print(f"A: {a_path.name} ({len(a)} bytes)")
    print(f"B: {b_path.name} ({len(b)} bytes)")
    limit = min(len(a), len(b))
    prefix = 0
    while prefix < limit and a[prefix] == b[prefix]:
        prefix += 1
    suffix = 0
    while suffix < limit - prefix and a[-1 - suffix] == b[-1 - suffix]:
        suffix += 1
    print(f"Common prefix: {prefix} bytes; common suffix: {suffix} bytes")
    runs, _ = changed_runs(a, b)
    print(f"Changed runs in overlapping region (plus length difference): {len(runs)}")
    print("First 35 changed runs:")
    for start, end in runs[:35]:
        ahex = a[start:min(end + 1, len(a))][:12].hex(" ").upper()
        bhex = b[start:min(end + 1, len(b))][:12].hex(" ").upper()
        print(f"  0x{start:04X}-0x{end:04X} | A: {ahex} | B: {bhex}")
    la, lb = labels(a), labels(b)
    shared = sorted(set(la) & set(lb))
    print(f"Shared label names: {len(shared)}")
    print("Shared label offsets (first occurrence):")
    for name in shared:
        print(f"  {name:20s} A=0x{la[name][0]:04X} B=0x{lb[name][0]:04X}")
    print("\nReminder: byte changes are not decoded animation frames or transforms.")


if __name__ == "__main__":
    if len(sys.argv) != 3:
        raise SystemExit("Usage: python fmo_pair_diff.py first.FMO second.FMO")
    main(sys.argv[1], sys.argv[2])
