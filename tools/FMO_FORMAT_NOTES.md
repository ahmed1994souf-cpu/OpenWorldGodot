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

## Focused inspection: `e_leg_l` in the two Suplex samples

A later read-only byte dump around the literal label `e_leg_l` produced these observations:

| File | Label offset | First 16 bytes after label |
|---|---:|---|
| `Z_F_SUPLEX_H_N.FMO` | `0x018C` | `00 00 00 00 00 00 0B 00 0D 00 0A 00 00 00 00 00` |
| `Z_F_SUPLEX_H_Y.FMO` | `0x015C` | `00 00 00 00 00 00 07 00 0D 00 0A 00 00 00 00 00` |

The displayed 16-byte label itself is followed by zero padding before the first nonzero small integers. The small-integer sequence differs at its first value (`0B 00` versus `07 00`), while `0D 00` and `0A 00` match. Farther after the label, the two files also show different binary values. Some 4-byte sequences can be interpreted as IEEE-754 floats, but this alone does not prove that they are transforms or animation values.

These are byte-level observations only. The label boundary is not yet proven to be a record boundary, and the meaning of the integers, float candidates, and intervening zero bytes remains unknown. Do not use them as decoded keyframes or export them to a rig until cross-sample validation establishes their structure.

## Four-file comparison around shared bone labels

A read-only dump of 40 bytes beginning 8 bytes before each detected label was supplied for all four samples. The following are direct observations:

| File | Size | `o_body` | `n_waist_b` | `c_thigh_l` | `e_leg_l` |
|---|---:|---:|---:|---:|---:|
| `Z_F_SUPLEX_H_N.FMO` | 5576 | `0x0C` | `0xF4` | `0x140` | `0x18C` |
| `Z_F_SUPLEX_H_Y.FMO` | 3692 | `0x0C` | `0xD0` | `0x110` | `0x15C` |
| `Z_BELLY2BELLY_N.FMO` | 6784 | `0x0C` | `0x104` | `0x15C` | `0x1D8` |
| `Z_BELLY2BELLY_Y.FMO` | 5076 | `0x0C` | `0x1C4` | `0x204` | `0x274` |

The eight bytes immediately before `n_waist_b` and `c_thigh_l` are not consistent across all samples. The bytes after the labels also differ. At `o_body`, the 16-bit field at offset `0x08` is `0x0088`, `0x0077`, or `0x00D1`; the next 16-bit field at `0x0A` is `0x17`, `0x19`, or `0x18` in the supplied samples.

These offsets and byte patterns are measured facts, not a decoded schema. In particular, neither header field is yet proven to be a frame count, bone count, or data length. This comparison still does not establish a safe animation/keyframe decoder or GLB exporter.

