# Jammo character — wrestling animation target

This folder records the selected replacement character for the wrestling-animation work.

## Official source

- Repository: https://github.com/mixandjam/Jammo-Character
- License shown by the upstream repository: MIT
- Upstream model is rigged for Mixamo. See the upstream README for model details and usage notes.

## Integration plan

1. Obtain the official repository's model files from the upstream link above.
2. Locate the FBX model and inspect its skeleton/bone names.
3. Compare the skeleton against the Motifect animation FBX files (starting with `wrestling_body_slam.fbx`, then `judo_hip_throw.fbx` and `wrestling_double_leg_takedown.fbx`).
4. Retarget/import the selected animations in Godot and verify the attacker and receiver motions together.
5. Replace the old combat animation assignments only after the new animation resources are verified.

## Current status

Jammo has been selected as the candidate character, but the binary model asset is **not copied into this repository yet**. This file is a source/integration note, not a claim that the model or animations are already imported or tested.

The upstream repository is a Unity-oriented project, so its original project files should not be treated as a ready-made Godot scene. Import only the needed model/texture assets into this Godot project after downloading them.
