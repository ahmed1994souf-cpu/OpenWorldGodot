#!/usr/bin/env python3
"""Compare bone-like label offsets in WWE RAW FMO files.

Read-only research helper. Offsets/spans are string-boundary observations,
not proven animation-record boundaries.
"""
from pathlib import Path
import re
import sys

PATTERN = re.compile(rb"[A-Za-z_][A-Za-z0-9_]{2,}")
PREFIXES = ("o_", "n_", "c_", "e_", "j_", "sub_", "shape_")
SPECIAL = {"L_FOOT", "R_FOOT", "HAND_L", "HAND_R", "FACE"}


def labels(path):
    data = Path(path).expanduser().read_bytes()
    found = []
    for match in PATTERN.finditer(data):
        name = match.group().decode("ascii", "ignore")
        if name.lower().startswith(PREFIXES) or name in SPECIAL:
            found.append((match.start(), name))
    rows = {}
    for i, (offset, name) in enumerate(found):
        end = found[i + 1][0] if i + 1 < len(found) else len(data)
        rows[name] = (offset, end - offset)
    return len(data), rows


def main(paths):
    all_rows = []
    for path in paths:
        size, row = labels(path)
        all_rows.append((path, size, row))
    names = []
    for _, _, row in all_rows:
        for name in row:
            if name not in names:
                names.append(name)
    print("Label".ljust(20) + "".join(f"{Path(p).name[:18]:>20}" for p, _, _ in all_rows))
    print("-" * (20 + 20 * len(all_rows)))
    for name in names:
        cells = []
        for _, _, row in all_rows:
            if name in row:
                off, span = row[name]
                cells.append(f"0x{off:04X}/{span}")
            else:
                cells.append("-")
        print(name.ljust(20) + "".join(f"{cell:>20}" for cell in cells))
    print("\nNote: spans are distances to the next detected label, not verified record sizes.")


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python fmo_compare.py file1.FMO file2.FMO [more.FMO ...]")
        raise SystemExit(2)
    main(sys.argv[1:])
