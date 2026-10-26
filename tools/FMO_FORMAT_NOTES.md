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

## Extended comparison from `fmo_compare_fields.py`

The supplied four-file output adds these cross-sample observations:

- The labels `HAND_L`, `HAND_R`, `L_FOOT`, `R_FOOT`, `SHAPE_HANDLE_L`, `SHAPE_HANDLE_R`, `c_shoulder_l`, `c_shoulder_r`, `c_thigh_l`, `c_thigh_r`, `e_chest`, `e_hand_l`, `e_hand_r`, `e_leg_l`, `e_leg_r`, `e_neck`, `j_neck_a`, `n_chest`, `n_waist_b`, `o_body`, `o_sako_l`, `o_sako_r`, and `sub_body` were detected as shared label names in the four samples.
- At several labels, three adjacent little-endian 16-bit values after the zero padding differ between samples. Examples: after `e_leg_l`, the triplets are `11,13,10`, `7,13,10`, `12,14,12`, and `8,13,7` in file order Suplex N, Suplex Y, Belly2Belly N, Belly2Belly Y. After `L_FOOT`, the triplets are `20,15,12`, `8,6,7`, `32,29,19`, and `16,14,11`.
- The repeated byte sequence `CD CC CC 3E` / `CD CC CC 3F` occurs near the `SHAPE_HANDLE_L/R` labels and is consistent with float32 values 0.4 / 1.6 in little-endian interpretation. This is only a numeric interpretation of those bytes; their semantic meaning is unknown.
- Some preceding four-byte values decode cleanly as float32 (for example, `CD CC CC 3F` = 1.6 and `CD CC CC 3E` = 0.4), while other four-byte patterns are non-floats or sentinel-like values. This mixed pattern warns against treating the whole area as a simple array of floats.

These observations improve the map of candidate fields but still do not establish which values are animation keys, indices, flags, or static bone metadata. No decoder or GLB exporter should be claimed from this evidence alone.


## Additional printable-string scan

A printable ASCII scan (runs of at least three bytes) was run on the four supplied FMO samples. In addition to the bone-like labels, it detected marker strings including:

- `L_FOOT` and `R_FOOT`
- `HAND_L` and `HAND_R`
- `SHAPE_HANDLE_L` and `SHAPE_HANDLE_R`
- `FACE` in `Z_BELLY2BELLY_N.FMO`

Observed positions vary by sample. For example, `L_FOOT` appears at 0x0340 (Suplex N), 0x02E0 (Suplex Y), 0x03BC (Belly2Belly N), and 0x03E0 (Belly2Belly Y). `HAND_R` appears at 0x0D14, 0x08C4, 0x1024, and 0x0BF8, respectively. These are literal string offsets from the supplied scan, not decoded semantic fields.

The scan also finds short printable runs such as `33s@`, `ff6A`, and `#<>`. Since these occur among binary data and vary across samples, they should be treated as incidental printable byte sequences unless further evidence identifies them as meaningful markers. The scan is useful for locating candidate labels, but it does not by itself identify animation frames or track encodings.

Current conclusion remains unchanged: no verified track/keyframe decoder or GLB exporter is implemented.
