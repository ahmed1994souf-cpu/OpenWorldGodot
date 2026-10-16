extends CharacterBody3D

@export var speed: float = 5.0
var gravity := 18.0

func _physics_process(delta: float) -> void:
    var input_vec := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
    var dir := Vector3(input_vec.x, 0.0, input_vec.y)
    if dir.length() > 0.01:
        dir = dir.normalized()
        velocity.x = dir.x * speed
        velocity.z = dir.z * speed
        rotation.y = lerp_angle(rotation.y, atan2(-dir.x, -dir.z), delta * 8.0)
    else:
        velocity.x = move_toward(velocity.x, 0.0, speed * 8.0 * delta)
        velocity.z = move_toward(velocity.z, 0.0, speed * 8.0 * delta)
    if not is_on_floor():
        velocity.y -= gravity * delta
    else:
        velocity.y = 0.0
    move_and_slide()
