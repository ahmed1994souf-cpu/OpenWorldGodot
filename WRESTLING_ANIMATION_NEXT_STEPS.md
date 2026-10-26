# Wrestling animation test — current status

This is an isolated experiment. The game's main scene has not been changed.

## What is present
- `wrestling_animation_test.tscn`: isolated test scene.
- `wrestling_animation_test.gd`: attempts to load the Jammo FBX and print the Skeleton3D bone names.
- `assets/characters/jammo/Jammo-Character`: Git submodule reference to the upstream Jammo model project.

## Important limitations
- The Motifect animation pack is not stored in this repository yet.
- The Jammo FBX has not been imported or run in a Godot editor in this environment.
- No real Body Slam, Suplex, Power Bomb, or receiver reaction has been played on Jammo yet.
- The test scene is only a rig inspection step, not a completed animation test.

## Next steps in Godot 4
1. Clone/download this repository with submodules initialized. If using Git, use `git clone --recurse-submodules <repo-url>`. If already cloned, run `git submodule update --init --recursive`.
2. Open `project.godot` in Godot and wait for asset import.
3. Open `wrestling_animation_test.tscn` and run it. Check Output for the skeleton and bone list. If the FBX cannot load, inspect the import error and correct the path/import settings first.
4. Add the Motifect animation FBX files to a separate folder, e.g. `res://assets/animations/motifect/`. Do not commit the entire pack until its license and file size are checked.
5. Import the target character as a scene and the source animation FBX as an AnimationLibrary (where supported by the Godot version). In Advanced Import, select Skeleton3D, assign a BoneMap with SkeletonProfileHumanoid, inspect auto-mapping, then reimport. Godot's official guide notes that matching bone names alone is insufficient; bone hierarchy and rest pose must also be compatible.
6. Create an AnimationPlayer/AnimationLibrary on the test character and play one animation first. Verify the hips, spine, arms, legs, and root motion before trying it in the game.
7. A wrestling throw generally needs coordinated attacker and receiver animations plus gameplay timing/positioning. Do not label a single-character Body Slam clip as a complete two-character move unless the receiver reaction is also present.

## Official Godot references
- https://docs.godotengine.org/en/stable/tutorials/assets_pipeline/retargeting_3d_skeletons.html
- https://godotengine.org/article/animation-retargeting-in-godot-4-0/
