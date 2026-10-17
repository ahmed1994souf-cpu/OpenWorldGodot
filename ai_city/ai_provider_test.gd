extends SceneTree

func _init() -> void:
    var client_script: Script = load("res://ai_city/llm_client.gd") as Script
    if client_script == null:
        print("[AI TEST] Could not load LLMClient script")
        quit(2)
        return

    var client: Node = client_script.new()
    root.add_child(client)
    await process_frame
    await create_timer(0.5).timeout

    print("[AI TEST] endpoint=", client.endpoint, " model=", client.model, " configured=", client.is_configured())
    if not client.is_configured():
        print("[AI TEST] FAIL: client is not configured")
        quit(3)
        return

    var done := false
    var success := false
    var result_data: Dictionary = {}
    var error_message := ""
    client.completed.connect(func(ok: bool, result: Dictionary, err: String):
        success = ok
        result_data = result
        error_message = err
        done = true
    )

    var accepted: bool = client.ask([
        {"role": "system", "content": "Reply briefly in JSON with keys reply, action, intent, goal. The reply must be a natural NPC answer."},
        {"role": "user", "content": "Hello. Say one short sentence to prove you are responding."}
    ])
    if not accepted:
        print("[AI TEST] FAIL: request did not start")
        quit(4)
        return

    var deadline := Time.get_ticks_msec() + 50000
    while not done and Time.get_ticks_msec() < deadline:
        await process_frame

    if not done:
        print("[AI TEST] FAIL: timed out waiting for provider response")
        quit(5)
        return

    if not success:
        print("[AI TEST] FAIL: ", error_message)
        quit(6)
        return

    print("[AI TEST] PASS: provider returned result=", result_data)
    quit(0)
