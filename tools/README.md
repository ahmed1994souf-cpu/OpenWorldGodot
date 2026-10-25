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
