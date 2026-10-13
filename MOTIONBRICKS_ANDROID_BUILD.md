# MotionBricks Android ARM64 build

This repository is prepared for the open-world 3D Godot project.

## GitHub Actions

Run:

**Actions → Build MotionBricks Android ARM64 → Run workflow**

The workflow builds the native GDExtension for `arm64-v8a`, downloads the official MotionBricks G1 F32 runtime bundle, and publishes an artifact named:

`MotionBricks-Android-ARM64-runtime`

The upstream project currently publishes a G1 F32 bundle of about 0.73 GB and the generated animation uses a 34-joint G1 skeleton. The game therefore keeps a fallback to the existing player animations until the on-device retargeting is validated.

Do not commit the generated model bundle or `.so` files to GitHub; they are produced by the workflow artifact.
