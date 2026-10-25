# WWE RAW FMO format notes (working research)

## Verified sample measurements

Measurements from the supplied original files; these are observations, not a complete format specification.

| File | Bytes | u16 at 0x08 | u16 at 0x0A |
|---|---:|---:|---:|
| `Z_F_SUPLEX_H_N.FMO` | 5576 | 136 (0x88) | 23 (0x17) |
| `Z_F_SUPLEX_H_Y.FMO` | 3692 | 119 (0x77) | 23 (0x17) |
| `Z_BELLY2BELLY_N.FMO` | 6784 | 209 (0xD1) | 25 (0x19) |
| `Z_BELLY2BELLY_Y.FMO` | 5076 | 209 (0xD1) | 24 (0x18) |

All four samples begin with bytes `FD FF 01 F0 21 03 01 20`. They contain bone-like labels such as `o_body`, `n_waist_b`, `c_thigh_l`, and `e_chest`.

## Cross-file label comparison

Running `fmo_compare.py` against all four samples shows:
- `o_body` begins at offset `0x000C` in all four files.
- `j_neck_a` appears at offsets `0x1204`, `0x0B44`, `0x15C8`, and `0x0FB0`, respectively.
- Distances from one detected label to the next vary substantially, so these distances are not fixed record sizes.
- These observations establish a shared labelled structure, but do not identify the animation track/keyframe encoding.

The field at 0x08 may be size/count/offset-related, but its meaning is unknown. The value at 0x0A looks like a small count in these samples, but it is not proven to be a bone count or frame count.

## Public references checked

- ResHax thread about PC WWE RAW FML/FMO/FCL/FMH: https://reshax.com/topic/19085-pc-wwe-raw-2002-fml-fmo-fcl-fmh-fcl/
- FML File Tool is an FML-to-OBJ converter, not a verified animation converter: https://gamebanana.com/tools/6637
- Briej's RAW modding guide discusses FMH/FMO but does not document a complete FMO decoder: https://legendsofmodding.org/threads/briejs-basic-raw-modding-guide.306/
- FML model format research: https://reshax.com/topic/12963-wwf-raw-model-format-researchfml/

## Current status

- `fmo_inspect.py`: read-only heuristic inspector.
- `fmo_compare.py`: read-only comparison of detected label offsets/spans.
- No verified FMO track/keyframe decoder exists in this project.
- No GLB animation export has been implemented or validated.
- Next step: inspect raw bytes between detected labels and compare candidate numeric blocks for the same bone across samples, without assuming label spans are records.
