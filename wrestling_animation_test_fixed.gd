extends Node3D

# Isolated diagnostic only: does not change the game's main scene.
const CHARACTER_CANDIDATE_PATHS := [
	"res://assets/characters/jammo/Jammo-Character/Assets/Jammo-Character/Models/Jammo_LowPoly.fbx",
	"res://Jammo_LowPoly.fbx",
]
const BODY_SLAM_PATH := "res://assets/animations/motifect/wrestling_body_slam.fbx"

func _ready() -> void:
	print("\n=== Jammo + Motifect Body Slam inspection ===")
	var character_skeleton: Skeleton3D = null
	var character_scene := _load_first_scene(CHARACTER_CANDIDATE_PATHS)
	if character_scene == null:
		push_error("Jammo FBX scene could not be loaded.")
	else:
		var character := character_scene.instantiate()
		add_child(character)
		var skeleton := _find_skeleton(character)
		character_skeleton = skeleton
		if skeleton == null:
			push_error("Jammo scene has no Skeleton3D.")
		else:
			print("JAMMO_SKELETON_OK bones=", skeleton.get_bone_count())
			print("JAMMO_BONE_NAMES=", _bone_names(skeleton))
		var character_player := _find_animation_player(character)
		print("JAMMO_ANIMATION_PLAYER=", character_player != null)
		if character_player != null:
			print("JAMMO_ANIMATIONS=", character_player.get_animation_list())

	if not ResourceLoader.exists(BODY_SLAM_PATH):
		push_error("Body Slam FBX is missing or has not been imported: " + BODY_SLAM_PATH)
		return
	var slam_scene := load(BODY_SLAM_PATH) as PackedScene
	if slam_scene == null:
		push_error("Godot could not load Body Slam FBX as PackedScene.")
		return
	var slam := slam_scene.instantiate()
	add_child(slam)
	var slam_skeleton := _find_skeleton(slam)
	var slam_player := _find_animation_player(slam)
	print("BODY_SLAM_SCENE_LOADED=true")
	print("BODY_SLAM_SKELETON_BONES=", slam_skeleton.get_bone_count() if slam_skeleton != null else -1)
	if slam_skeleton != null:
		print("BODY_SLAM_BONE_NAMES=", _bone_names(slam_skeleton))
	if character_skeleton != null and slam_skeleton != null:
		_report_bone_name_overlap(character_skeleton, slam_skeleton)
	if slam_player == null:
		push_error("Body Slam FBX loaded but no AnimationPlayer was found; clip cannot be retargeted yet.")
	else:
		var animation_names := slam_player.get_animation_list()
		print("BODY_SLAM_ANIMATIONS=", animation_names)
		if animation_names.is_empty():
			push_error("AnimationPlayer exists but contains no animations.")
		else:
			print("BODY_SLAM_CLIP_FOUND=true")
			for animation_name in animation_names:
				var animation := slam_player.get_animation(animation_name)
				if animation == null:
					continue
				print("CLIP_INFO name=", animation_name, " length=", animation.length, " tracks=", animation.get_track_count())
				for track_index in range(animation.get_track_count()):
					print("CLIP_TRACK path=", animation.track_get_path(track_index), " type=", animation.track_get_type(track_index))
	print("NOTE: This diagnostic inspects rigs and track paths; it does not claim the clip is retargeted onto Jammo.")
	print("=== END ===")

func _load_first_scene(paths: Array) -> PackedScene:
	for path in paths:
		if ResourceLoader.exists(path):
			print("Loading Jammo from ", path)
			return load(path) as PackedScene
	return null

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

func _normalized_bone_name(name: String) -> String:
	var normalized := name
	if normalized.begins_with("mixamorig_"):
		normalized = normalized.trim_prefix("mixamorig_")
	return normalized.to_lower().replace("_", "").replace(" ", "")

func _report_bone_name_overlap(target: Skeleton3D, source: Skeleton3D) -> void:
	var target_names := {}
	for i in range(target.get_bone_count()):
		target_names[_normalized_bone_name(target.get_bone_name(i))] = target.get_bone_name(i)
	var matched := PackedStringArray()
	var unmatched := PackedStringArray()
	for i in range(source.get_bone_count()):
		var source_name := source.get_bone_name(i)
		var key := _normalized_bone_name(source_name)
		if target_names.has(key):
			matched.append(source_name + " -> " + str(target_names[key]))
		else:
			unmatched.append(source_name)
	print("BONE_NAME_MATCH_COUNT=", matched.size(), "/", source.get_bone_count())
	print("BONE_NAME_MATCHES=", matched)
	print("BONE_NAME_UNMATCHED_SOURCE=", unmatched)
	print("NOTE: Name overlap is diagnostic only; it does not validate rest-pose compatibility or retarget the animation.")

func _bone_names(skeleton: Skeleton3D) -> PackedStringArray:
	var names := PackedStringArray()
	for i in range(skeleton.get_bone_count()):
		names.append(skeleton.get_bone_name(i))
	return names
