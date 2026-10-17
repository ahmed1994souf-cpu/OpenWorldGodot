extends Node3D

const PLAYER_SCRIPT = preload("res://scripts/player.gd")
const ENEMY_SCRIPT = preload("res://scripts/enemy.gd")
var player: CharacterBody3D
var camera: Camera3D
var joystick_vector := Vector2.ZERO
var joystick_base: Control
var joystick_knob: Control
var health_label: Label
var status_label: Label
var enemy_count_label: Label
var game_over := false

func _ready() -> void:
	_setup_world()
	_spawn_player()
	_spawn_enemies()
	_setup_ui()

func _process(_delta: float) -> void:
	if is_instance_valid(player):
		player.call("set_movement_input", joystick_vector)
		camera.global_position = player.global_position + Vector3(0.0, 7.0, 10.0)
		camera.look_at(player.global_position + Vector3(0.0, 1.2, 0.0), Vector3.UP)
		health_label.text = "HEALTH  %d" % int(player.get("health"))
		enemy_count_label.text = "GUARDS  %d" % get_tree().get_nodes_in_group("guards").size()
	if game_over:
		status_label.text = "YOU HAVE FALLEN  •  RESTART THE GAME"
	elif get_tree().get_nodes_in_group("guards").is_empty():
		status_label.text = "ARENA CLEARED  •  THE THRONE IS YOURS"
	else:
		status_label.text = "DEFEAT THE GUARDS  •  SURVIVE THE ARENA"

func _setup_world() -> void:
	var world_env := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = Sky.new()
	env.sky.sky_material = ProceduralSkyMaterial.new()
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.28, 0.31, 0.48)
	env.ambient_light_energy = 0.65
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	world_env.environment = env
	add_child(world_env)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48.0, -28.0, 0.0)
	sun.light_energy = 1.25
	sun.shadow_enabled = true
	add_child(sun)

	var floor_body := StaticBody3D.new()
	floor_body.name = "ArenaFloor"
	var floor_mesh := MeshInstance3D.new()
	var plane := BoxMesh.new()
	plane.size = Vector3(44.0, 1.0, 44.0)
	floor_mesh.mesh = plane
	var stone := StandardMaterial3D.new()
	stone.albedo_color = Color(0.12, 0.14, 0.19)
	stone.roughness = 0.92
	floor_mesh.material_override = stone
	floor_body.add_child(floor_mesh)
	var floor_collision := CollisionShape3D.new()
	var floor_shape := BoxShape3D.new()
	floor_shape.size = plane.size
	floor_collision.shape = floor_shape
	floor_body.add_child(floor_collision)
	floor_body.position.y = -0.5
	add_child(floor_body)

	for i in range(16):
		var angle := TAU * float(i) / 16.0
		var pillar := MeshInstance3D.new()
		var cylinder := CylinderMesh.new()
		cylinder.top_radius = 0.55
		cylinder.bottom_radius = 0.8
		cylinder.height = 5.0 + float(i % 3)
		pillar.mesh = cylinder
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.20, 0.18, 0.27) if i % 2 == 0 else Color(0.24, 0.17, 0.13)
		mat.metallic = 0.22
		pillar.material_override = mat
		pillar.position = Vector3(cos(angle) * 17.0, cylinder.height / 2.0 - 0.1, sin(angle) * 17.0)
		add_child(pillar)

	for i in range(8):
		var rune := MeshInstance3D.new()
		var rune_mesh := BoxMesh.new()
		rune_mesh.size = Vector3(1.0, 0.035, 4.0)
		rune.mesh = rune_mesh
		var rune_mat := StandardMaterial3D.new()
		rune_mat.albedo_color = Color(0.45, 0.16, 0.95)
		rune_mat.emission_enabled = true
		rune_mat.emission = Color(0.30, 0.04, 0.95)
		rune_mat.emission_energy_multiplier = 1.5
		rune.material_override = rune_mat
		rune.position = Vector3(0.0, 0.03, 0.0)
		rune.rotation.y = TAU * float(i) / 8.0
		add_child(rune)

	camera = Camera3D.new()
	camera.name = "FollowCamera"
	camera.fov = 72.0
	camera.current = true
	add_child(camera)

func _spawn_player() -> void:
	player = CharacterBody3D.new()
	player.name = "Player"
	player.set_script(PLAYER_SCRIPT)
	player.position = Vector3(0.0, 0.2, 5.0)
	player.add_to_group("player")
	add_child(player)
	player.call("build_visuals")

func _spawn_enemies() -> void:
	for i in range(5):
		var angle := TAU * float(i) / 5.0
		var enemy := CharacterBody3D.new()
		enemy.name = "ArenaGuard%d" % (i + 1)
		enemy.set_script(ENEMY_SCRIPT)
		enemy.position = Vector3(cos(angle) * 8.0, 0.15, sin(angle) * 8.0)
		add_child(enemy)
		enemy.call("build_visuals", i == 0)

func _setup_ui() -> void:
	var canvas := CanvasLayer.new()
	canvas.name = "MobileHUD"
	add_child(canvas)
	var ui := Control.new()
	ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui.mouse_filter = Control.MOUSE_FILTER_PASS
	canvas.add_child(ui)

	var title := Label.new()
	title.text = "MYSTIC THRONE"
	title.position = Vector2(28, 18)
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color(0.88, 0.75, 1.0))
	ui.add_child(title)

	health_label = Label.new()
	health_label.position = Vector2(30, 60)
	health_label.add_theme_font_size_override("font_size", 21)
	health_label.add_theme_color_override("font_color", Color(1.0, 0.35, 0.38))
	ui.add_child(health_label)

	enemy_count_label = Label.new()
	enemy_count_label.position = Vector2(30, 90)
	enemy_count_label.add_theme_font_size_override("font_size", 18)
	enemy_count_label.add_theme_color_override("font_color", Color(0.78, 0.82, 1.0))
	ui.add_child(enemy_count_label)

	status_label = Label.new()
	status_label.anchor_left = 0.5
	status_label.anchor_right = 0.5
	status_label.offset_left = -330
	status_label.offset_right = 330
	status_label.offset_top = 24
	status_label.offset_bottom = 58
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.add_theme_font_size_override("font_size", 17)
	status_label.add_theme_color_override("font_color", Color(0.86, 0.79, 1.0))
	ui.add_child(status_label)

	joystick_base = Control.new()
	joystick_base.position = Vector2(34, 520)
	joystick_base.size = Vector2(160, 160)
	joystick_base.gui_input.connect(_on_joystick_input)
	ui.add_child(joystick_base)
	var base_panel := Panel.new()
	base_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var base_style := StyleBoxFlat.new()
	base_style.bg_color = Color(0.12, 0.13, 0.20, 0.62)
	base_style.border_color = Color(0.60, 0.53, 0.85, 0.9)
	base_style.set_border_width_all(3)
	base_style.set_corner_radius_all(80)
	base_panel.add_theme_stylebox_override("panel", base_style)
	base_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	joystick_base.add_child(base_panel)
	joystick_knob = Panel.new()
	joystick_knob.position = Vector2(48, 48)
	joystick_knob.size = Vector2(64, 64)
	var knob_style := StyleBoxFlat.new()
	knob_style.bg_color = Color(0.63, 0.52, 0.95, 0.85)
	knob_style.set_corner_radius_all(32)
	joystick_knob.add_theme_stylebox_override("panel", knob_style)
	joystick_knob.mouse_filter = Control.MOUSE_FILTER_IGNORE
	joystick_base.add_child(joystick_knob)

	var jump_button := _make_button(ui, "JUMP", Vector2(1080, 545), Vector2(145, 78), Color(0.18, 0.36, 0.68))
	jump_button.pressed.connect(_on_jump_pressed)
	var attack_button := _make_button(ui, "ATTACK", Vector2(1080, 630), Vector2(165, 76), Color(0.52, 0.13, 0.25))
	attack_button.pressed.connect(_on_attack_pressed)

func _make_button(parent: Control, label_text: String, pos: Vector2, button_size: Vector2, color: Color) -> Button:
	var button := Button.new()
	button.text = label_text
	button.position = pos
	button.size = button_size
	button.add_theme_font_size_override("font_size", 21)
	var normal := StyleBoxFlat.new()
	normal.bg_color = color
	normal.border_color = Color(0.85, 0.78, 1.0, 0.95)
	normal.set_border_width_all(2)
	normal.set_corner_radius_all(18)
	var pressed_style := normal.duplicate() as StyleBoxFlat
	pressed_style.bg_color = color.lightened(0.28)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", pressed_style)
	button.add_theme_stylebox_override("pressed", pressed_style)
	parent.add_child(button)
	return button

func _on_joystick_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if not event.pressed:
			joystick_vector = Vector2.ZERO
			joystick_knob.position = Vector2(48, 48)
	elif event is InputEventScreenDrag:
		_update_joystick(event.position)
	elif event is InputEventMouseButton:
		if event.pressed:
			_update_joystick(event.position)
		else:
			joystick_vector = Vector2.ZERO
			joystick_knob.position = Vector2(48, 48)
	elif event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		_update_joystick(event.position)

func _update_joystick(local_pos: Vector2) -> void:
	var center := joystick_base.size * 0.5
	var offset := local_pos - center
	if offset.length() > 48.0:
		offset = offset.normalized() * 48.0
	joystick_vector = Vector2(offset.x / 48.0, offset.y / 48.0)
	joystick_knob.position = center + offset - joystick_knob.size * 0.5

func _on_jump_pressed() -> void:
	if is_instance_valid(player):
		player.call("request_jump")

func _on_attack_pressed() -> void:
	if is_instance_valid(player):
		player.call("request_attack")

func notify_player_dead() -> void:
	game_over = true
