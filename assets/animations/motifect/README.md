# Motifect animation import checklist

This folder is intentionally a placeholder: the animation binaries have not been downloaded or committed.

## First clip to test
Look for the pack's wrestling body-slam clip. Import it alone first, rather than all 40 clips.

## Godot workflow
1. Keep the source FBX untouched in this folder.
2. Open the FBX Import dock / Advanced Import Settings.
3. For the Jammo target model, import it as a Scene and select its Skeleton3D.
4. Create a BoneMap using SkeletonProfileHumanoid and inspect all auto-mapped bones.
5. Import the source animation FBX as an AnimationLibrary where supported by the installed Godot version. Select its Skeleton3D and configure the matching humanoid profile/BoneMap too.
6. Reimport and check the animation tracks point to the intended target skeleton. Play the clip in an isolated test scene before touching the main game.
7. If the clip does not retarget cleanly, do not force it into the game: inspect bone hierarchy, rest pose, facing axis, and root motion first.

## Wrestling-specific warning
A throw animation for the attacker is not a complete wrestling move by itself. A convincing move usually requires a synchronized receiver fall/impact reaction, correct relative positions, and gameplay timing. Confirm that the pack actually contains a compatible receiver clip before calling this a complete move.

## Source
Motifect Martial Arts Motion Pack: https://www.fab.com/listings/95f5f297-aee7-4496-8c7d-e4e7ed53b45d
Official Godot retargeting guide: https://docs.godotengine.org/en/stable/tutorials/assets_pipeline/retargeting_3d_skeletons.html
