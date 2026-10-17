extends SceneTree

var _done := false
var _success := false
var _result_data: Dictionary = {}
var _error_message := ""

func _on_completed(ok: bool, result: Dictionary, err: String) -> void:
    print("[AI TEST] completed signal received ok=", ok)
    _success = ok
    _result_data = result
    _error_message = err
    _done = true

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

    client.completed.connect(_on_completed)

    var accepted: bool = client.ask([
        {"role": "system", "content": "Reply briefly in JSON with keys reply, action, intent, goal. The reply must be a natural NPC answer."},
        {"role": "user", "content": "Hello. Say one short sentence to prove you are responding."}
    ])
    if not accepted:
        print("[AI TEST] FAIL: request did not start")
        quit(4)
        return

    # AI Horde is volunteer-powered and can queue before a worker accepts the job.
    var deadline := Time.get_ticks_msec() + 145000
    while not _done and Time.get_ticks_msec() < deadline:
        await process_frame

    if not _done:
        print("[AI TEST] FAIL: timed out waiting for provider response")
        quit(5)
        return

    if not _success:
        print("[AI TEST] FAIL: ", _error_message)
        quit(6)
        return

    print("[AI TEST] PASS: provider returned result=", _result_data)
    print("AI_PROVIDER_TEST_SUCCESS")
    quit(0)
