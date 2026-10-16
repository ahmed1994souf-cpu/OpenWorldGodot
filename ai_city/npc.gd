extends CharacterBody3D

var home_position: Vector3
var target_position: Vector3
var move_timer: float = 0.0
var conversation_count: int = 0
var speed: float = 1.2
var city: Node3D
var player: CharacterBody3D
var behavior: String = "wander"
var follow_distance: float = 2.4
var wait_timer: float = 0.0
var last_player_distance: float = 999.0
var navigation_agent: NavigationAgent3D
var brain: RefCounted
var brain_ready: bool = false

func _ready() -> void:
    home_position = global_position
    target_position = home_position
    city = get_meta("city", null) as Node3D
    if city != null:
        player = city.get("player") as CharacterBody3D

    navigation_agent = NavigationAgent3D.new()
    navigation_agent.name = "NavigationAgent3D"
    navigation_agent.path_desired_distance = 0.45
    navigation_agent.target_desired_distance = 0.8
    navigation_agent.radius = 0.5
    navigation_agent.height = 2.0
    navigation_agent.avoidance_enabled = true
    add_child(navigation_agent)

    var brain_script: Script = load("res://ai_city/npc_brain.gd") as Script
    brain = brain_script.new()
    brain.setup({
        "name": str(get_meta("display_name", "NPC")),
        "role": str(get_meta("role", "citizen")),
        "personality": str(get_meta("personality", "friendly")),
        "knowledge": get_meta("knowledge", [])
    })
    brain_ready = true
    move_timer = randf_range(1.0, 3.0)
    call_deferred("_finish_navigation_setup")

func _finish_navigation_setup() -> void:
    if navigation_agent != null and is_instance_valid(navigation_agent):
        navigation_agent.target_position = target_position

func _physics_process(delta: float) -> void:
    if city != null:
        player = city.get("player") as CharacterBody3D
    if player == null:
        _wander(delta)
        _apply_motion(delta)
        return

    last_player_distance = global_position.distance_to(player.global_position)
    if behavior == "follow":
        _follow_player(delta, last_player_distance)
    elif behavior == "talk":
        _face_player(delta)
        _brake(delta)
    else:
        _wander(delta)

    _apply_motion(delta)

func _apply_motion(delta: float) -> void:
    if not is_on_floor():
        velocity.y -= 18.0 * delta
    else:
        velocity.y = 0.0
    move_and_slide()

func _wander(delta: float) -> void:
    move_timer -= delta
    if move_timer <= 0.0:
        move_timer = randf_range(2.5, 6.0)
        target_position = home_position + Vector3(randf_range(-5.0, 5.0), 0.0, randf_range(-5.0, 5.0))
        _set_navigation_target(target_position)
    _navigate(delta)

func _follow_player(delta: float, player_distance: float) -> void:
    if player_distance > follow_distance:
        target_position = player.global_position
        _set_navigation_target(target_position)
        _navigate(delta)
    else:
        _brake(delta)
        _face_player(delta)

func _set_navigation_target(target: Vector3) -> void:
    if navigation_agent == null:
        return
    var nav_target: Vector3 = target
    nav_target.y = global_position.y
    if navigation_agent.target_position.distance_to(nav_target) > 0.8:
        navigation_agent.target_position = nav_target

func _navigate(delta: float) -> void:
    if navigation_agent == null or not navigation_agent.is_inside_tree():
        _move_direct(target_position, delta)
        return
    if navigation_agent.is_navigation_finished():
        _brake(delta)
        return
    var next_path_position: Vector3 = navigation_agent.get_next_path_position()
    var offset: Vector3 = next_path_position - global_position
    offset.y = 0.0
    if offset.length_squared() < 0.04:
        _brake(delta)
        return
    var dir: Vector3 = offset.normalized()
    velocity.x = dir.x * speed
    velocity.z = dir.z * speed
    rotation.y = lerp_angle(rotation.y, atan2(-dir.x, -dir.z), delta * 5.0)

func _move_direct(target: Vector3, delta: float) -> void:
    var offset: Vector3 = target - global_position
    offset.y = 0.0
    if offset.length() > 0.6:
        var dir: Vector3 = offset.normalized()
        velocity.x = dir.x * speed
        velocity.z = dir.z * speed
        rotation.y = lerp_angle(rotation.y, atan2(-dir.x, -dir.z), delta * 5.0)
    else:
        _brake(delta)

func _brake(delta: float) -> void:
    velocity.x = move_toward(velocity.x, 0.0, speed * 6.0 * delta)
    velocity.z = move_toward(velocity.z, 0.0, speed * 6.0 * delta)

func _face_player(delta: float) -> void:
    if player == null:
        return
    var flat: Vector3 = player.global_position - global_position
    flat.y = 0.0
    if flat.length_squared() > 0.01:
        rotation.y = lerp_angle(rotation.y, atan2(-flat.x, -flat.z), delta * 6.0)

func get_response(_text: String) -> String:
    # Deliberately disabled: NPCs must never answer from scripted local dialogue.
    return ""

func _apply_brain_action(action: String) -> void:
    match action:
        "follow_player":
            behavior = "follow"
        "stop":
            behavior = "talk"
        "wander":
            behavior = "wander"
            move_timer = 0.1
        _:
            behavior = "talk"

func build_ai_messages(user_text: String) -> Array:
	var world: Dictionary = {
		"player_distance": last_player_distance,
		"npc_position": str(global_position),
		"player_position": str(player.global_position) if player != null else str(global_position),
		"behavior": behavior,
		"city_time": Time.get_time_string_from_system()
	}
	return brain.build_messages(user_text, world)

func apply_remote_plan(user_text: String, plan: Dictionary) -> String:
	if not brain_ready:
		return ""
	var result: Dictionary = brain.accept_remote_plan(user_text, plan)
	_apply_brain_action(str(result.get("action", "none")))
	set_meta("last_intent", str(result.get("intent", "conversation")))
	set_meta("last_action", str(result.get("action", "none")))
	set_meta("memory_size", int(result.get("memory_size", 0)))
	return str(result.get("response", ""))
