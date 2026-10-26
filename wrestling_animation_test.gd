extends Node3D

# Isolated rig inspection scene. This does not change the game's main scene.
# Open wrestling_animation_test.tscn in Godot and run it to inspect the imported rig.
const CHARACTER_SCENE_PATH := "res://assets/characters/jammo/Jammo-Character/Assets/Jammo-Character/Models/Jammo_LowPoly.fbx"

func _ready() -> void:
	print("\n=== Wrestling animation rig test ===")
	if not ResourceLoader.exists(CHARACTER_SCENE_PATH):
		push_warning("Jammo FBX was not found/imported. Ensure the Git submodule is initialized and Godot has imported the FBX: " + CHARACTER_SCENE_PATH)
		return

	var packed := load(CHARACTER_SCENE_PATH) as PackedScene
	if packed == null:
		push_warning("Godot could not load the FBX as a PackedScene. Check the import error in the FileSystem dock.")
		return

	var character := packed.instantiate()
	add_child(character)
	var skeleton := _find_node_of_type(character, "Skeleton3D") as Skeleton3D
	if skeleton == null:
		push_warning("No Skeleton3D found in this FBX. The model may need conversion or a different importer.")
		return

	print("Skeleton found: ", skeleton.get_path())
	print("Bone count: ", skeleton.get_bone_count())
	for i in range(skeleton.get_bone_count()):
		print("Bone ", i, ": ", skeleton.get_bone_name(i))

	var animation_player := _find_node_of_type(character, "AnimationPlayer") as AnimationPlayer
	if animation_player == null:
		print("No AnimationPlayer found in the character file; expected for a model-only FBX.")
	else:
		print("Animations embedded in model: ", animation_player.get_animation_list())
		print("Next step: import a Motifect FBX animation and retarget it to this skeleton before playback.")
	print("=== Rig inspection complete; no wrestling move has been applied yet ===")

func _find_node_of_type(root: Node, type_name: String) -> Node:
	if root.get_class() == type_name:
		return root
	for child in root.get_children():
		var found := _find_node_of_type(child, type_name)
		if found != null:
			return found
	return null
