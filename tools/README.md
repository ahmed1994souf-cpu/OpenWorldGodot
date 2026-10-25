# WWE RAW FMO research tools

This folder contains small exploratory tools for studying WWE RAW `.FMO` animation files.

## Current status

- `fmo_inspect.py`: read-only inspector for the file header, likely bone labels, and heuristic float candidates.
- It does **not** decode the complete animation format.
- It does **not** export GLB yet.
- The printed float values and byte spans are heuristics, not confirmed animation tracks.

## Run

```bash
python tools/fmo_inspect.py /path/to/Z_F_SUPLEX_H_N.FMO /path/to/Z_F_SUPLEX_H_Y.FMO
```

The tool only reads the input files. It does not modify them.

## Next research steps

1. Determine the exact meaning of header fields and record boundaries.
2. Identify transform/keyframe encodings by comparing multiple original FMO files.
3. Map decoded tracks to a compatible skeleton.
4. Only after the format is understood, implement and test GLB export.

This is a reverse-engineering research prototype. Do not treat its output as a validated animation conversion.

- `fmo_compare_fields.py`: read-only cross-file comparison of shared likely bone labels, nearby raw bytes, and raw little-endian 16-bit words. The printed words are not assigned meanings; repeated labels are listed individually.

## Compare multiple samples

```bash
python tools/fmo_compare_fields.py /path/to/Z_F_SUPLEX_H_N.FMO /path/to/Z_F_SUPLEX_H_Y.FMO /path/to/Z_BELLY2BELLY_N.FMO /path/to/Z_BELLY2BELLY_Y.FMO
```

This is an exploratory aid only. Similar bytes or plausible numeric values do not prove a keyframe layout.

## Compare a pair of related animation files

`fmo_pair_diff.py` prints contiguous byte-difference ranges and compares the first occurrence of each shared bone-like label. Use it on the N/Y variants of the same move:

```bash
python tools/fmo_pair_diff.py /path/to/Z_F_SUPLEX_H_N.FMO /path/to/Z_F_SUPLEX_H_Y.FMO
python tools/fmo_pair_diff.py /path/to/Z_BELLY2BELLY_N.FMO /path/to/Z_BELLY2BELLY_Y.FMO
```

The two files can have different lengths, so offsets are compared directly only over their shared byte range. Label offsets are reported independently and are not aligned animation tracks. Treat the report as a way to choose regions for closer inspection, not as a decoder.
