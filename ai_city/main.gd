extends Node3D

var player: CharacterBody3D
var npcs: Array[CharacterBody3D] = []
var selected_npc: CharacterBody3D
var status_label: Label
var chat_input: LineEdit
var chat_panel: PanelContainer
var camera: Camera3D
var llm_client: Node
var pending_npc: CharacterBody3D
var pending_user_text: String = ""
var ai_setup_dialog: AcceptDialog
var ai_endpoint_input: LineEdit
var ai_model_input: LineEdit
var ai_key_input: LineEdit
var navigation_region: NavigationRegion3D

func _ready() -> void:
    _build_world()
    _build_navigation()
    _build_camera()
    _build_ui()
    var llm_script: Script = load("res://ai_city/llm_client.gd") as Script
    llm_client = llm_script.new()
    llm_client.name = "LLMClient"
    add_child(llm_client)
    llm_client.completed.connect(_on_llm_completed)
    _build_ai_setup()

func _build_world() -> void:
    var env := WorldEnvironment.new()
    var environment := Environment.new()
    environment.background_mode = Environment.BG_COLOR
    environment.background_color = Color(0.12, 0.16, 0.22)
    environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    environment.ambient_light_color = Color(0.65, 0.72, 0.85)
    environment.ambient_light_energy = 0.75
    env.environment = environment
    add_child(env)

    var sun := DirectionalLight3D.new()
    sun.rotation_degrees = Vector3(-55.0, -25.0, 0.0)
    sun.light_energy = 1.2
    add_child(sun)

    var ground := StaticBody3D.new()
    ground.name = "CityGround"
    var mesh := BoxMesh.new()
    mesh.size = Vector3(70.0, 0.4, 70.0)
    var visual := MeshInstance3D.new()
    visual.mesh = mesh
    var mat := StandardMaterial3D.new()
    mat.albedo_color = Color(0.16, 0.18, 0.20)
    visual.material_override = mat
    ground.add_child(visual)
    var shape := CollisionShape3D.new()
    var box := BoxShape3D.new()
    box.size = Vector3(70.0, 0.4, 70.0)
    shape.shape = box
    ground.add_child(shape)
    add_child(ground)

    for z in [-18.0, 18.0]:
        for x in [-24.0, -12.0, 12.0, 24.0]:
            _make_building(Vector3(x, 2.5, z), Vector3(8.0, 5.0, 7.0))
    for x in [-24.0, 24.0]:
        for z in [-6.0, 6.0]:
            _make_building(Vector3(x, 3.5, z), Vector3(7.0, 7.0, 7.0))

    player = _make_character("Player", Vector3(0.0, 1.0, 8.0), Color(0.25, 0.55, 1.0), true)
    player.set_meta("speed", 5.0)

    var npc_data := [
        ["Samir", Vector3(-7.0, 1.0, 2.0), Color(0.85, 0.35, 0.25), "friendly shopkeeper", "friendly"],
        ["Nadia", Vector3(7.0, 1.0, -2.0), Color(0.75, 0.25, 0.65), "street photographer", "curious"],
        ["Karim", Vector3(-3.0, 1.0, -9.0), Color(0.25, 0.70, 0.35), "taxi driver", "talkative"],
        ["Yacine", Vector3(4.0, 1.0, 10.0), Color(0.85, 0.70, 0.20), "security guard", "serious"]
    ]
    for data in npc_data:
        var npc := _make_character(str(data[0]), data[1], data[2], false)
        npc.set_meta("role", str(data[3]))
        npc.set_meta("personality", str(data[4]))
        npc.set_meta("knowledge", ["central square", "main road", "nearby shops", "city streets"])
        npcs.append(npc)

func _build_navigation() -> void:
    navigation_region = NavigationRegion3D.new()
    navigation_region.name = "CityNavigation"
    navigation_region.position.y = 0.2

    var nav_mesh := NavigationMesh.new()
    nav_mesh.agent_radius = 0.5
    nav_mesh.agent_height = 2.0
    nav_mesh.cell_size = 0.25
    nav_mesh.cell_height = 0.25
    nav_mesh.vertices = PackedVector3Array([
        Vector3(-20.0, 0.0, 14.0),
        Vector3(20.0, 0.0, 14.0),
        Vector3(20.0, 0.0, -14.0),
        Vector3(-20.0, 0.0, -14.0)
    ])
    nav_mesh.add_polygon(PackedInt32Array([0, 1, 2, 3]))
    navigation_region.navigation_mesh = nav_mesh
    add_child(navigation_region)

func _build_camera() -> void:
    var pivot := Node3D.new()
    pivot.name = "CameraPivot"
    add_child(pivot)
    var spring := SpringArm3D.new()
    spring.spring_length = 8.0
    spring.position = Vector3(0.0, 3.2, 0.0)
    spring.rotation_degrees.x = -12.0
    pivot.add_child(spring)
    camera = Camera3D.new()
    camera.fov = 65.0
    camera.current = true
    spring.add_child(camera)
    pivot.set_meta("target", player)
    camera.set_meta("pivot", pivot)

func _make_building(pos: Vector3, size: Vector3) -> void:
    var body := StaticBody3D.new()
    body.position = pos
    var mesh := BoxMesh.new()
    mesh.size = size
    var visual := MeshInstance3D.new()
    visual.mesh = mesh
    var mat := StandardMaterial3D.new()
    mat.albedo_color = Color(0.25 + randf() * 0.12, 0.27 + randf() * 0.10, 0.30 + randf() * 0.12)
    visual.material_override = mat
    body.add_child(visual)
    var collision := CollisionShape3D.new()
    var box := BoxShape3D.new()
    box.size = size
    collision.shape = box
    body.add_child(collision)
    add_child(body)

func _make_character(n: String, pos: Vector3, color: Color, is_player: bool) -> CharacterBody3D:
    var body := CharacterBody3D.new()
    body.name = n
    body.position = pos
    body.set_meta("display_name", n)
    body.set_meta("is_player", is_player)
    var capsule := CapsuleMesh.new()
    capsule.height = 2.0
    capsule.radius = 0.45
    var visual := MeshInstance3D.new()
    visual.mesh = capsule
    var mat := StandardMaterial3D.new()
    mat.albedo_color = color
    visual.material_override = mat
    body.add_child(visual)
    var collision := CollisionShape3D.new()
    var capsule_shape := CapsuleShape3D.new()
    capsule_shape.height = 2.0
    capsule_shape.radius = 0.45
    collision.shape = capsule_shape
    body.add_child(collision)
    if is_player:
        body.set_script(load("res://ai_city/player.gd"))
    else:
        body.set_script(load("res://ai_city/npc.gd"))
        body.set_meta("city", self)
    add_child(body)
    return body

func _build_ui() -> void:
    var layer := CanvasLayer.new()
    add_child(layer)
    status_label = Label.new()
    status_label.position = Vector2(24, 20)
    status_label.text = "AI CITY — Prototype 03\nReal NPC brain + memory + navigation"
    status_label.add_theme_font_size_override("font_size", 22)
    layer.add_child(status_label)
    var talk := Button.new()
    talk.text = "TALK"
    talk.position = Vector2(1040, 600)
    talk.size = Vector2(180, 70)
    talk.add_theme_font_size_override("font_size", 28)
    talk.pressed.connect(_talk_nearest)
    layer.add_child(talk)

    var controls := [
        ["◀", Vector2(35, 610), "ui_left"], ["▶", Vector2(155, 610), "ui_right"],
        ["▲", Vector2(95, 550), "ui_up"], ["▼", Vector2(95, 670), "ui_down"]
    ]
    for item in controls:
        var b := Button.new()
        b.text = item[0]
        b.position = item[1]
        b.size = Vector2(70, 55)
        b.add_theme_font_size_override("font_size", 26)
        b.button_down.connect(func(): Input.action_press(item[2]))
        b.button_up.connect(func(): Input.action_release(item[2]))
        layer.add_child(b)

    chat_panel = PanelContainer.new()
    chat_panel.position = Vector2(250, 500)
    chat_panel.size = Vector2(760, 150)
    chat_panel.visible = false
    layer.add_child(chat_panel)
    var box := VBoxContainer.new()
    chat_panel.add_child(box)
    var prompt := Label.new()
    prompt.name = "Prompt"
    prompt.text = ""
    prompt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    prompt.add_theme_font_size_override("font_size", 20)
    box.add_child(prompt)
    chat_input = LineEdit.new()
    chat_input.placeholder_text = "Talk naturally to the NPC..."
    chat_input.add_theme_font_size_override("font_size", 20)
    box.add_child(chat_input)
    var send := Button.new()
    send.text = "Send"
    send.pressed.connect(_send_message)
    box.add_child(send)
    chat_input.text_submitted.connect(func(_text: String): _send_message())


func _build_ai_setup() -> void:
    var layer: CanvasLayer = get_node_or_null("CanvasLayer")
    if layer == null:
        layer = get_child(0) as CanvasLayer
    var setup_button := Button.new()
    setup_button.text = "AI SETUP"
    setup_button.position = Vector2(1040, 520)
    setup_button.size = Vector2(180, 58)
    setup_button.pressed.connect(_open_ai_setup)
    layer.add_child(setup_button)

    ai_setup_dialog = AcceptDialog.new()
    ai_setup_dialog.title = "Connect NPC AI"
    ai_setup_dialog.dialog_text = "OpenAI-compatible chat endpoint. Saved privately on this device."
    ai_setup_dialog.size = Vector2i(650, 360)
    layer.add_child(ai_setup_dialog)
    var fields := VBoxContainer.new()
    ai_setup_dialog.add_child(fields)
    ai_endpoint_input = LineEdit.new()
    ai_endpoint_input.placeholder_text = "Endpoint URL (include /v1/chat/completions)"
    fields.add_child(ai_endpoint_input)
    ai_model_input = LineEdit.new()
    ai_model_input.placeholder_text = "Model name"
    fields.add_child(ai_model_input)
    ai_key_input = LineEdit.new()
    ai_key_input.placeholder_text = "API key (optional for local providers)"
    ai_key_input.secret = true
    fields.add_child(ai_key_input)
    var save_button := Button.new()
    save_button.text = "Save AI Settings"
    save_button.pressed.connect(_save_ai_setup)
    fields.add_child(save_button)
    var local_button := Button.new()
    local_button.text = "Use Offline NPC Brain"
    local_button.pressed.connect(_use_local_brain)
    fields.add_child(local_button)

func _open_ai_setup() -> void:
    if llm_client != null:
        ai_endpoint_input.text = str(llm_client.endpoint)
        ai_model_input.text = str(llm_client.model)
        ai_key_input.text = str(llm_client.api_key)
    ai_setup_dialog.popup_centered()

func _save_ai_setup() -> void:
    var save_error: int = llm_client.save_config(ai_endpoint_input.text, ai_model_input.text, ai_key_input.text)
    if save_error == OK:
        status_label.text = "AI settings saved on this device."
        ai_setup_dialog.hide()
    else:
        status_label.text = "Could not save AI settings (error %s)." % save_error

func _use_local_brain() -> void:
    llm_client.save_config("", "", "")
    status_label.text = "Offline NPC brain enabled."
    ai_setup_dialog.hide()

func _talk_nearest() -> void:
    var nearest: CharacterBody3D = null
    var best := 3.2
    for npc in npcs:
        var d := player.global_position.distance_to(npc.global_position)
        if d < best:
            best = d
            nearest = npc
    if nearest == null:
        status_label.text = "No NPC close enough. Walk closer to a capsule."
        return
    selected_npc = nearest
    chat_panel.visible = true
    var prompt: Label = chat_panel.get_node("VBoxContainer/Prompt")
    prompt.text = "%s (%s): I am listening. Ask naturally." % [nearest.get_meta("display_name"), nearest.get_meta("role")]
    chat_input.grab_focus()

func _send_message() -> void:
    if selected_npc == null or chat_input.text.strip_edges().is_empty():
        return
    var text := chat_input.text.strip_edges()
    chat_input.clear()
    pending_npc = selected_npc
    pending_user_text = text
    var prompt: Label = chat_panel.get_node("VBoxContainer/Prompt")
    if llm_client != null and llm_client.is_configured():
        prompt.text = "%s is thinking..." % selected_npc.get_meta("display_name")
        var accepted: bool = llm_client.ask(selected_npc.build_ai_messages(text))
        if accepted:
            return
        # If the request could not start, fall through to the local brain.
    var response: String = selected_npc.get_response(text)
    _show_npc_response(selected_npc, response)

func _on_llm_completed(success: bool, result: Dictionary, error_message: String) -> void:
    if pending_npc == null or not is_instance_valid(pending_npc):
        return
    var response: String
    if success:
        response = pending_npc.apply_remote_plan(pending_user_text, result)
    else:
        response = pending_npc.get_response(pending_user_text)
        if not error_message.is_empty():
            status_label.text = "AI fallback: " + error_message
    _show_npc_response(pending_npc, response)

func _show_npc_response(npc: CharacterBody3D, response: String) -> void:
    var prompt: Label = chat_panel.get_node("VBoxContainer/Prompt")
    prompt.text = "%s: %s" % [npc.get_meta("display_name"), response]
    status_label.text = "%s | intent: %s | action: %s | memory: %s" % [
        npc.get_meta("display_name"),
        npc.get_meta("last_intent", "conversation"),
        npc.get_meta("last_action", "talk"),
        str(npc.get_meta("memory_size", 0))
    ]

func _process(delta: float) -> void:
    if player == null:
        return
    var pivot: Node3D = camera.get_meta("pivot")
    pivot.global_position = pivot.global_position.lerp(player.global_position + Vector3(0.0, 1.0, 0.0), delta * 6.0)
    for npc in npcs:
        npc.set_meta("player_distance", player.global_position.distance_to(npc.global_position))
