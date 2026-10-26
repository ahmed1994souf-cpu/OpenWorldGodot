extends Node3D

# Separate test scene. This script does not modify the game's main scene.
# It tries the submodule model path first, then the root-level FBX.
const CHARACTER_CANDIDATE_PATHS := [
	"res://assets/characters/jammo/Jammo-Character/Assets/Jammo-Character/Models/Jammo_LowPoly.fbx",
	"res://Jammo_LowPoly.fbx",
]

func _ready() -> void:
	print("\n=== Jammo wrestling rig test ===")
	var model_path := ""
	for candidate in CHARACTER_CANDIDATE_PATHS:
		if ResourceLoader.exists(candidate):
			model_path = candidate
			break

	if model_path.is_empty():
		push_warning("Jammo FBX not found. Initialize the Jammo submodule or ensure Jammo_LowPoly.fbx is at the project root, then let Godot import it.")
		return

	print("Model path: ", model_path)
	var packed_scene := load(model_path) as PackedScene
	if packed_scene == null:
		push_warning("Could not load Jammo FBX as PackedScene. Check Godot's import errors.")
		return

	var character := packed_scene.instantiate()
	add_child(character)
	var skeleton := _find_skeleton(character)
	if skeleton == null:
		push_warning("No Skeleton3D found. Stop here; do not retarget animations yet.")
		return

	print("Skeleton path: ", skeleton.get_path())
	print("Bone count: ", skeleton.get_bone_count())
	for i in range(skeleton.get_bone_count()):
		print("Bone ", i, ": ", skeleton.get_bone_name(i))

	var animation_player := _find_animation_player(character)
	if animation_player == null:
		print("No AnimationPlayer found in the model; this can be normal for a model-only FBX.")
	else:
		print("Animation list: ", animation_player.get_animation_list())
	print("Rig inspection finished. No Motifect animation has been applied.")
	print("=== END ===")

func _find_skeleton(root: Node) -> Skeleton3D:
	if root is Skeleton3D:
		return root as Skeleton3D
	for child in root.get_children():
		var found := _find_skeleton(child)
		if found != null:
			return found
	return null

func _find_animation_player(root: Node) -> AnimationPlayer:
	if root is AnimationPlayer:
		return root as AnimationPlayer
	for child in root.get_children():
		var found := _find_animation_player(child)
		if found != null:
			return found
	return null
