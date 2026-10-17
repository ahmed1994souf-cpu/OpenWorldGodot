extends Node
class_name LLMClient

signal completed(success: bool, result: Dictionary, error_message: String)

const ENDPOINT := "https://api.llm7.io/v1/chat/completions"
const MODEL := "gpt-oss:20b"
const API_KEY := "unused"
var endpoint: String = ENDPOINT
var model: String = MODEL
var api_key: String = API_KEY
var timeout_seconds: float = 35.0
var _request: HTTPRequest
var _active := false

func _ready() -> void:
    endpoint = ENDPOINT
    model = MODEL
    api_key = API_KEY
    _request = HTTPRequest.new()
    _request.timeout = timeout_seconds
    add_child(_request)
    _request.request_completed.connect(_on_request_completed)

func is_configured() -> bool:
    return true

func save_config(_new_endpoint: String, _new_model: String, _new_api_key: String) -> Error:
    endpoint = ENDPOINT
    model = MODEL
    api_key = API_KEY
    var config := ConfigFile.new()
    config.set_value("llm", "endpoint", ENDPOINT)
    config.set_value("llm", "model", MODEL)
    config.set_value("llm", "api_key", API_KEY)
    return config.save("user://ai_city_config.cfg")

func use_keyless_horde() -> Error:
    return save_config("", "", "")

func ask(messages: Array) -> bool:
    if _active:
        completed.emit(false, {}, "AI request already in progress.")
        return false
    _active = true
    var headers := PackedStringArray(["Content-Type: application/json", "Accept: application/json", "Authorization: Bearer unused"])
    var payload := {"model": MODEL, "messages": messages, "temperature": 0.75, "max_tokens": 220}
    print("[LLM] POST ", ENDPOINT, " model=", MODEL)
    var err := _request.request(ENDPOINT, headers, HTTPClient.METHOD_POST, JSON.stringify(payload))
    if err != OK:
        _active = false
        completed.emit(false, {}, "Could not start AI request (error %s)." % err)
        return false
    return true

func _on_request_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
    var raw := body.get_string_from_utf8()
    print("[LLM] completed result=", result, " http=", response_code, " bytes=", body.size())
    _active = false
    if result != HTTPRequest.RESULT_SUCCESS:
        completed.emit(false, {}, "Network request failed (result %s). Check Internet/DNS/TLS." % result)
        return
    var parsed = JSON.parse_string(raw)
    if not parsed is Dictionary:
        completed.emit(false, {}, "AI returned invalid JSON: " + raw.left(500))
        return
    if response_code < 200 or response_code >= 300:
        completed.emit(false, {}, "AI server HTTP %s: %s" % [response_code, raw.left(700)])
        return
    var content := ""
    var choices = parsed.get("choices", [])
    if choices is Array and not choices.is_empty() and choices[0] is Dictionary:
        var message = choices[0].get("message", {})
        if message is Dictionary:
            content = str(message.get("content", ""))
    if content.is_empty():
        content = str(parsed.get("text", parsed.get("response", "")))
    content = content.strip_edges()
    if content.is_empty():
        completed.emit(false, {}, "AI returned no text.")
        return
    var parsed_plan := JSON.new()
    var parse_error := parsed_plan.parse(content)
    if parse_error == OK and parsed_plan.data is Dictionary:
        completed.emit(true, parsed_plan.data, "")
    else:
        completed.emit(true, {"reply": content, "action": "none", "intent": "conversation", "goal": ""}, "")
