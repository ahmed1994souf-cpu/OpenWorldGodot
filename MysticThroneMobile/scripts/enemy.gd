extends CharacterBody3D

var health := 70
var move_speed := 2.5
var gravity := 20.0
var attack_timer := 0.0
var player: Node3D
var boss_guard := false

func build_visuals(is_boss: bool = false) -> void:
	boss_guard = is_boss
	health = 130 if boss_guard else 70
	move_speed = 2.0 if boss_guard else 2.7
	add_to_group("guards")
	var collision := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.48 if not boss_guard else 0.62
	capsule.height = 1.9 if not boss_guard else 2.4
	collision.shape = capsule
	collision.position.y = capsule.height * 0.5
	add_child(collision)

	var body_mesh := MeshInstance3D.new()
	var mesh := CapsuleMesh.new()
	mesh.radius = 0.46 if not boss_guard else 0.60
	mesh.height = 1.85 if not boss_guard else 2.35
	body_mesh.mesh = mesh
	body_mesh.position.y = mesh.height * 0.5
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.52, 0.13, 0.17) if not boss_guard else Color(0.35, 0.08, 0.62)
	material.metallic = 0.42
	material.roughness = 0.48
	body_mesh.material_override = material
	add_child(body_mesh)

	var head := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.28 if not boss_guard else 0.36
	sphere.height = sphere.radius * 2.0
	head.mesh = sphere
	head.position.y = 2.05 if not boss_guard else 2.55
	var head_material := StandardMaterial3D.new()
	head_material.albedo_color = Color(0.17, 0.12, 0.13) if not boss_guard else Color(0.85, 0.57, 0.12)
	head.material_override = head_material
	add_child(head)

func _physics_process(delta: float) -> void:
	attack_timer = maxf(0.0, attack_timer - delta)
	if not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player") as Node3D
	if not is_instance_valid(player):
		return
	if not is_on_floor():
		velocity.y -= gravity * delta
	elif velocity.y < 0.0:
		velocity.y = 0.0
	var distance := global_position.distance_to(player.global_position)
	if distance > 1.75 and distance < 18.0:
		var direction := player.global_position - global_position
		direction.y = 0.0
		direction = direction.normalized()
		velocity.x = direction.x * move_speed
		velocity.z = direction.z * move_speed
		if direction.length() > 0.01:
			look_at(global_position + direction, Vector3.UP)
	elif distance <= 1.75:
		velocity.x = move_toward(velocity.x, 0.0, move_speed * 4.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, move_speed * 4.0 * delta)
		if attack_timer <= 0.0:
			attack_timer = 1.25 if boss_guard else 1.6
			player.call("take_damage", 14 if boss_guard else 8)
	else:
		velocity.x = move_toward(velocity.x, 0.0, move_speed * delta)
		velocity.z = move_toward(velocity.z, 0.0, move_speed * delta)
	move_and_slide()

func take_damage(amount: int) -> void:
	health -= amount
	if health <= 0:
		remove_from_group("guards")
		queue_free()
