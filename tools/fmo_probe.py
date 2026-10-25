#!/usr/bin/env python3
"""Read-only FMO byte probe. Prints raw bytes and aligned float32 candidates near bone labels.
Float values are clues only; this does NOT decode animation tracks or keyframes.
Usage: python fmo_probe.py FILE.FMO [LABEL ...]
"""
from pathlib import Path
import argparse
import math
import struct

KNOWN = (
    "o_body", "n_waist_b", "n_waist_a", "c_thigh_l", "e_leg_l",
    "L_FOOT", "c_thigh_r", "e_leg_r", "R_FOOT", "n_chest",
    "o_sako_r", "c_shoulder_r", "e_hand_r", "HAND_R",
    "SHAPE_HANDLE_R", "o_sako_l", "c_shoulder_l", "e_hand_l",
    "HAND_L", "SHAPE_HANDLE_L", "j_neck_a", "sub_body",
    "e_chest", "e_neck", "FACE",
)

def find_labels(data):
    found = []
    for label in KNOWN:
        needle = label.encode("ascii")
        start = 0
        while True:
            at = data.find(needle, start)
            if at < 0:
                break
            # Keep plausible null-terminated labels; avoid arbitrary substring hits.
            end = at + len(needle)
            if end < len(data) and data[end] == 0:
                found.append((at, label))
            start = at + 1
    return sorted(found)

def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("files", nargs="+", help="FMO files to inspect")
    ap.add_argument("--window", type=int, default=48, help="bytes shown before/after each label (default 48)")
    ap.add_argument("--floats", action="store_true", help="also show finite little-endian float32 candidates in the window")
    ap.add_argument("labels", nargs="*", help="optional label names to focus on")
    args = ap.parse_args()
    wanted = set(args.labels)
    for name in args.files:
        path = Path(name).expanduser()
        data = path.read_bytes()
        print(f"\n=== {path.name} | {len(data)} bytes ===")
        print("Header[0:16]:", data[:16].hex(" "))
        labels = find_labels(data)
        if wanted:
            labels = [(o, s) for o, s in labels if s in wanted]
        if not labels:
            print("No matching null-terminated known labels found.")
            continue
        for off, label in labels:
            lo = max(0, off - args.window)
            hi = min(len(data), off + len(label.encode("ascii")) + 1 + args.window)
            print(f"\n{label:16s} label@0x{off:04X}; bytes[0x{lo:04X}:0x{hi:04X}]")
            for row in range(lo, hi, 16):
                chunk = data[row:min(row + 16, hi)]
                print(f"  {row:04X}: {chunk.hex(' ')}")
            if args.floats:
                start = max(0, (lo + 3) & ~3)
                vals = []
                for p in range(start, hi - 3, 4):
                    v = struct.unpack_from("<f", data, p)[0]
                    if math.isfinite(v) and abs(v) < 1e6:
                        vals.append(f"0x{p:04X}={v:.5g}")
                if vals:
                    print("  aligned float32 candidates:", ", ".join(vals))
    print("\nReminder: offsets and float interpretations are exploratory, not a validated FMO specification.")

if __name__ == "__main__":
    main()
