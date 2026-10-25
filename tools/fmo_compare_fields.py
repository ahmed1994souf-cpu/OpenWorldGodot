#!/usr/bin/env python3
"""Compare raw bytes around shared labels in WWE RAW FMO files.

Read-only research helper. It does not decode animation tracks or modify files.
Usage:
  python fmo_compare_fields.py file1.FMO file2.FMO [more.FMO ...]
"""
from pathlib import Path
import re
import struct
import sys

LABEL_RE = re.compile(rb"[A-Za-z_][A-Za-z0-9_]{2,}")
WANTED_PREFIXES = ("o_", "n_", "c_", "e_", "j_", "sub_", "shape_")
WANTED_EXACT = {"L_FOOT", "R_FOOT", "HAND_L", "HAND_R", "FACE"}


def labels_in(data):
    found = {}
    for match in LABEL_RE.finditer(data):
        name = match.group().decode("ascii", "ignore")
        if name.lower().startswith(WANTED_PREFIXES) or name in WANTED_EXACT:
            found.setdefault(name, []).append(match.start())
    return found


def dump_window(data, offset, before=8, after=40):
    start = max(0, offset - before)
    end = min(len(data), offset + after)
    return " ".join(f"{byte:02X}" for byte in data[start:end])


def main(paths):
    files = []
    for arg in paths:
        path = Path(arg).expanduser()
        try:
            data = path.read_bytes()
        except OSError as exc:
            print(f"ERROR {path}: {exc}")
            continue
        files.append((path, data, labels_in(data)))
        print(f"\nFILE {path} | {len(data)} bytes")
        if len(data) >= 12:
            print("header[0:12]:", data[:12].hex(" ").upper())
            print("u16le@08:", struct.unpack_from("<H", data, 8)[0],
                  "| u16le@0A:", struct.unpack_from("<H", data, 10)[0])

    if len(files) < 2:
        print("\nProvide at least two readable FMO files to compare.")
        return

    shared = set.intersection(*(set(labels) for _, _, labels in files))
    print(f"\nSHARED LABEL NAMES: {len(shared)}")
    for name in sorted(shared):
        # Repeated labels can exist; list every occurrence, don't silently assume uniqueness.
        print(f"\nLABEL {name}")
        for path, data, labels in files:
            positions = labels[name]
            for index, pos in enumerate(positions, 1):
                print(f"  {path.name} occurrence {index}: offset=0x{pos:04X}")
                print("   ", dump_window(data, pos))
                # Show small little-endian words after the end of the text label.
                field_start = pos + len(name)
                available = data[field_start:min(field_start + 24, len(data))]
                words = [struct.unpack_from("<H", available, i)[0]
                         for i in range(0, len(available) - 1, 2)]
                print("    u16le after label (raw, not interpreted):", words)


if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("Usage: python fmo_compare_fields.py file1.FMO file2.FMO [more.FMO ...]")
        raise SystemExit(2)
    main(sys.argv[1:])
