#!/usr/bin/env python3
"""Read-only inspector for WWE RAW FMO files.

Usage:
  python fmo_inspect.py /path/to/file.FMO
  python fmo_inspect.py file1.FMO file2.FMO

This is an exploratory inspector, not a full FMO decoder or GLB converter.
It never modifies input files.
"""
from pathlib import Path
import math
import re
import struct
import sys


def inspect(filename):
    path = Path(filename).expanduser()
    data = path.read_bytes()
    print(f"FILE: {path}")
    print(f"SIZE: {len(data)} bytes")
    print("HEADER:")
    for off in range(0, min(0x30, len(data)), 16):
        chunk = data[off:off + 16]
        hx = " ".join(f"{b:02X}" for b in chunk)
        txt = "".join(chr(b) if 32 <= b < 127 else "." for b in chunk)
        print(f"  {off:04X}: {hx:<47} {txt}")

    labels = []
    for m in re.finditer(rb"[A-Za-z_][A-Za-z0-9_]{2,}", data):
        label = m.group().decode("ascii", "ignore")
        if (label.lower().startswith(("o_", "n_", "c_", "e_", "j_", "sub_", "shape_"))
                or label in ("L_FOOT", "R_FOOT", "HAND_L", "HAND_R", "FACE")):
            labels.append((m.start(), label))

    print(f"\nBONE-LIKE LABELS: {len(labels)}")
    for i, (off, label) in enumerate(labels):
        end = labels[i + 1][0] if i + 1 < len(labels) else len(data)
        nul = data.find(b"\0", off, min(off + len(label) + 2, len(data)))
        start = nul + 1 if nul >= 0 else off + len(label)
        stop = min(start + 64, end, len(data))
        candidates = []
        for pos in range((start + 3) & ~3, stop - 3, 4):
            value = struct.unpack_from("<f", data, pos)[0]
            if math.isfinite(value) and 0.01 <= abs(value) <= 10000:
                candidates.append(f"+{pos-off:02X}:{value:.4g}")
        extra = "  float candidates: " + ", ".join(candidates[:8]) if candidates else ""
        print(f"  0x{off:04X} {label:<18} span={end-off:4} bytes{extra}")

    print("\nWARNING: labels, spans, and float candidates are heuristics only.")
    print("This tool does not decode FMO animation tracks or export GLB.")


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python fmo_inspect.py file.FMO [other.FMO ...]")
        raise SystemExit(2)
    for arg in sys.argv[1:]:
        try:
            inspect(arg)
        except Exception as exc:
            print(f"ERROR: {arg}: {exc}")
