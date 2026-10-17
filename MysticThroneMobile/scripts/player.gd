extends CharacterBody3D

var movement_input := Vector2.ZERO
var health := 100
var move_speed := 6.2
var jump_velocity := 7.5
var gravity := 20.0
var attack_cooldown := 0.0
var attack_flash := 0.0
var weapon: MeshInstance3D
var main_node: Node

func build_visuals() -> void:
	main_node = get_parent()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.48
	capsule.height = 1.9
	var collision := CollisionShape3D.new()
	collision.shape = capsule
	collision.position.y = 0.95
	add_child(collision)

	var body_mesh := MeshInstance3D.new()
	var body := CapsuleMesh.new()
	body.radius = 0.46
	body.height = 1.85
	body_mesh.mesh = body
	body_mesh.position.y = 0.95
	var armor := StandardMaterial3D.new()
	armor.albedo_color = Color(0.18, 0.20, 0.29)
	armor.metallic = 0.65
	armor.roughness = 0.32
	body_mesh.material_override = armor
	add_child(body_mesh)

	var head := MeshInstance3D.new()
	var head_mesh := SphereMesh.new()
	head_mesh.radius = 0.31
	head_mesh.height = 0.62
	head.mesh = head_mesh
	head.position = Vector3(0.0, 2.05, 0.0)
	var head_mat := StandardMaterial3D.new()
	head_mat.albedo_color = Color(0.72, 0.54, 0.39)
	head.material_override = head_mat
	add_child(head)

	weapon = MeshInstance3D.new()
	var blade := BoxMesh.new()
	blade.size = Vector3(0.12, 1.25, 0.16)
	weapon.mesh = blade
	weapon.position = Vector3(0.58, 1.05, -0.12)
	weapon.rotation.z = -0.35
	var blade_mat := StandardMaterial3D.new()
	blade_mat.albedo_color = Color(0.62, 0.78, 1.0)
	blade_mat.metallic = 0.9
	blade_mat.emission_enabled = true
	blade_mat.emission = Color(0.08, 0.25, 0.9)
	blade_mat.emission_energy_multiplier = 0.8
	weapon.material_override = blade_mat
	add_child(weapon)

func set_movement_input(value: Vector2) -> void:
	movement_input = value.limit_length(1.0)

func _physics_process(delta: float) -> void:
	attack_cooldown = maxf(0.0, attack_cooldown - delta)
	attack_flash = maxf(0.0, attack_flash - delta)
	if attack_flash <= 0.0 and is_instance_valid(weapon):
		weapon.rotation.z = -0.35
	if not is_on_floor():
		velocity.y -= gravity * delta
	elif velocity.y < 0.0:
		velocity.y = 0.0
	var direction := Vector3(movement_input.x, 0.0, movement_input.y)
	if direction.length() > 1.0:
		direction = direction.normalized()
	velocity.x = direction.x * move_speed
	velocity.z = direction.z * move_speed
	if direction.length() > 0.08:
		look_at(global_position + direction, Vector3.UP)
	move_and_slide()

func request_jump() -> void:
	if is_on_floor():
		velocity.y = jump_velocity

func request_attack() -> void:
	if attack_cooldown > 0.0:
		return
	attack_cooldown = 0.48
	attack_flash = 0.18
	if is_instance_valid(weapon):
		weapon.rotation.z = -1.45
	for guard in get_tree().get_nodes_in_group("guards"):
		if not is_instance_valid(guard):
			continue
		var distance := global_position.distance_to(guard.global_position)
		var to_guard := (guard.global_position - global_position).normalized()
		var facing := -global_transform.basis.z
		if distance <= 2.65 and facing.dot(to_guard) > -0.1:
			guard.call("take_damage", 35)

func take_damage(amount: int) -> void:
	health = maxi(0, health - amount)
	if health == 0:
		var root := get_parent()
		if root and root.has_method("notify_player_dead"):
			root.call("notify_player_dead")
