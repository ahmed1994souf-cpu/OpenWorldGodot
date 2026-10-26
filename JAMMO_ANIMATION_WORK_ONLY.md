# Current animation task: Jammo only

This is the active work target. Do not use AJ or Orton for this phase; they are being removed from the game.

## Known state
- The isolated test scene is `wrestling_animation_test.tscn`.
- The inspection script is `wrestling_animation_test.gd`.
- The Jammo model is referenced through the Git submodule at `assets/characters/jammo/Jammo-Character`.
- The approximately 8 MB animation pack mentioned by the user is not currently confirmed as present in this repository. Do not claim its contents have been imported until the actual archive is available in the workspace/repository.

## Work order
1. Import the Jammo model and run the rig inspection scene.
2. Record the real Skeleton3D bone count and names from Godot output.
3. Locate the user's actual 8 MB animation archive and list the real animation filenames.
4. Pick one suitable wrestling clip and retarget it to Jammo.
5. Verify playback before adding more clips or changing the main scene.
6. Only after the attacker clip works, add a compatible receiver reaction and synchronize both.

## Important
Do not substitute AJ/Orton. Do not edit the main scene while rig/animation compatibility is unverified. Do not report bone counts, successful playback, or imported clips without a real test result.
