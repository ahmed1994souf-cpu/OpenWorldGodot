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

func _ready() -> void:
    home_position = global_position
    target_position = home_position
    city = get_meta("city", null) as Node3D
    if city != null:
        player = city.get("player") as CharacterBody3D
    move_timer = randf_range(1.0, 3.0)

func _physics_process(delta: float) -> void:
    if city != null:
        player = city.get("player") as CharacterBody3D
    if player == null:
        _wander(delta)
        return

    var player_distance: float = global_position.distance_to(player.global_position)
    if behavior == "follow":
        _follow_player(delta, player_distance)
    elif behavior == "talk":
        _face_player(delta)
        velocity.x = move_toward(velocity.x, 0.0, speed * 6.0 * delta)
        velocity.z = move_toward(velocity.z, 0.0, speed * 6.0 * delta)
    else:
        _wander(delta)

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
    _move_toward(target_position, delta)

func _follow_player(delta: float, player_distance: float) -> void:
    if player_distance > follow_distance:
        _move_toward(player.global_position, delta)
    else:
        velocity.x = move_toward(velocity.x, 0.0, speed * 6.0 * delta)
        velocity.z = move_toward(velocity.z, 0.0, speed * 6.0 * delta)
        _face_player(delta)

func _move_toward(target: Vector3, delta: float) -> void:
    var offset: Vector3 = target - global_position
    offset.y = 0.0
    if offset.length() > 0.6:
        var dir: Vector3 = offset.normalized()
        velocity.x = dir.x * speed
        velocity.z = dir.z * speed
        rotation.y = lerp_angle(rotation.y, atan2(-dir.x, -dir.z), delta * 5.0)
    else:
        velocity.x = move_toward(velocity.x, 0.0, speed * 5.0 * delta)
        velocity.z = move_toward(velocity.z, 0.0, speed * 5.0 * delta)

func _face_player(delta: float) -> void:
    if player == null:
        return
    var flat: Vector3 = player.global_position - global_position
    flat.y = 0.0
    if flat.length_squared() > 0.01:
        rotation.y = lerp_angle(rotation.y, atan2(-flat.x, -flat.z), delta * 6.0)

func get_response(text: String) -> String:
    conversation_count += 1
    var q: String = text.to_lower().strip_edges()
    var role: String = str(get_meta("role", "citizen"))
    if q.contains("follow") or q.contains("come with me") or q.contains("تعال معي") or q.contains("اتبعني"):
        behavior = "follow"
        return "Sure. I will stay with you."
    if q.contains("stop") or q.contains("stay") or q.contains("توقف") or q.contains("ابق"):
        behavior = "talk"
        return "Okay. I will stay here."
    if q.contains("walk") or q.contains("go") or q.contains("اذهب"):
        behavior = "wander"
        return "Alright. I will head out and continue my routine."
    if q.contains("where") or q.contains("where is") or q.contains("أين") or q.contains("وين"):
        return "I know this neighborhood. The main road is behind me, and the central square is ahead."
    if q.contains("name") or q.contains("اسم"):
        return "My name is %s. I am a %s." % [get_meta("display_name", "NPC"), role]
    if q.contains("help") or q.contains("ساعد") or q.contains("مساعدة"):
        return "Maybe. Tell me exactly what you need, and I will see what I can do."
    if q.contains("hello") or q.contains("hi") or q.contains("سلام") or q.contains("مرحبا"):
        behavior = "talk"
        return "Hello. Nice to meet you. What brings you to this part of the city?"
    return "I heard you. I am a %s, and I am still learning about this city." % role
