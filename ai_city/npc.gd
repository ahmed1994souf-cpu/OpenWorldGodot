extends CharacterBody3D

var home_position: Vector3
var target_position: Vector3
var move_timer := 0.0
var conversation_count := 0
var speed := 1.2

func _ready() -> void:
    home_position = global_position
    target_position = home_position
    randomize()

func _physics_process(delta: float) -> void:
    move_timer -= delta
    if move_timer <= 0.0:
        move_timer = randf_range(3.0, 7.0)
        target_position = home_position + Vector3(randf_range(-3.0, 3.0), 0.0, randf_range(-3.0, 3.0))
    var offset := target_position - global_position
    offset.y = 0.0
    if offset.length() > 0.5:
        var dir := offset.normalized()
        velocity.x = dir.x * speed
        velocity.z = dir.z * speed
        rotation.y = lerp_angle(rotation.y, atan2(-dir.x, -dir.z), delta * 4.0)
    else:
        velocity.x = move_toward(velocity.x, 0.0, speed * 4.0 * delta)
        velocity.z = move_toward(velocity.z, 0.0, speed * 4.0 * delta)
    if not is_on_floor():
        velocity.y -= 18.0 * delta
    else:
        velocity.y = 0.0
    move_and_slide()

func get_response(text: String) -> String:
    conversation_count += 1
    var q := text.to_lower()
    var role := str(get_meta("role", "citizen"))
    if q.contains("where") or q.contains("where is") or q.contains("أين") or q.contains("وين"):
        return "I know this neighborhood. The main road is behind me, and the central square is ahead."
    if q.contains("name") or q.contains("اسم"):
        return "My name is %s. I am a %s." % [get_meta("display_name", "NPC"), role]
    if q.contains("help") or q.contains("ساعد") or q.contains("مساعدة"):
        return "Maybe. Tell me exactly what you need, and I will see what I can do."
    if q.contains("hello") or q.contains("hi") or q.contains("سلام") or q.contains("مرحبا"):
        return "Hello. Nice to meet you. What brings you to this part of the city?"
    return "I heard you say: '%s'. I am still learning about this city, but I can remember our conversation." % text
