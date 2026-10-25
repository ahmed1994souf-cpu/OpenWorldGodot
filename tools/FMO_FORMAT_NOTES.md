# WWE RAW FMO format notes (working research)

## Verified sample measurements

All values below were measured from the user's supplied original files; they are observations, not a complete format specification.

| File | Bytes | u16 at 0x08 | u16 at 0x0A |
|---|---:|---:|---:|
| `Z_F_SUPLEX_H_N.FMO` | 5576 | 136 (0x88) | 23 (0x17) |
| `Z_F_SUPLEX_H_Y.FMO` | 3692 | 119 (0x77) | 23 (0x17) |
| `Z_BELLY2BELLY_N.FMO` | 6784 | 209 (0xD1) | 25 (0x19) |
| `Z_BELLY2BELLY_Y.FMO` | 5076 | 209 (0xD1) | 24 (0x18) |

All four samples begin with bytes `FD FF 01 F0 21 03 01 20`. The strings include bone-like labels such as `o_body`, `n_waist_b`, `c_thigh_l`, and `e_chest`.

The field at 0x08 varies and may be a size/count/offset-related value, but its meaning is not established. The value at 0x0A looks like a small count in these samples, but it is not proven to be a bone count or frame count. Do not treat these hypotheses as facts.

## Public references checked

- ResHax thread about PC WWE RAW FML/FMO/FCL/FMH asks about formats and tools. It links an existing model tool, but does not provide a verified FMO-to-GLB converter: https://reshax.com/topic/19085-pc-wwe-raw-2002-fml-fmo-fcl-fmh-fcl/
- FML File Tool is described as an FML-to-OBJ converter, not an animation converter: https://gamebanana.com/tools/6637
- Briej's RAW modding guide says move editing involves FMH and FMO, but does not document a complete FMO animation decoder: https://legendsofmodding.org/threads/briejs-basic-raw-modding-guide.306/
- FML format research covers model files and skeleton-related data, not a ready-made FMO-to-GLB conversion: https://reshax.com/topic/12963-wwf-raw-model-format-researchfml/

## Current status

- `fmo_inspect.py` is a read-only heuristic inspector.
- No verified FMO track/keyframe decoder exists in this project yet.
- No GLB animation export has been implemented or validated.
- Next reverse-engineering step: compare the binary layout around each label across several samples, then identify consistent per-bone record boundaries and numeric encodings before writing an exporter.
