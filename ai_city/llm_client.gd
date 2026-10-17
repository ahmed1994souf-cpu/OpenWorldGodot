extends Node
class_name LLMClient

signal completed(success: bool, result: Dictionary, error_message: String)

var endpoint: String = ""
var api_key: String = ""
var model: String = ""
var timeout_seconds: float = 90.0
var _request: HTTPRequest
var _active: bool = false

const DEFAULT_ENDPOINT: String = "https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent"
const DEFAULT_MODEL: String = "gemini-2.5-flash"
const OLD_GEMINI_ENDPOINT: String = "https://generativelanguage.googleapis.com/v1beta/openai/chat/completions"

func _ready() -> void:
    _load_config()
    _request = HTTPRequest.new()
    _request.timeout = timeout_seconds
    add_child(_request)
    _request.request_completed.connect(_on_request_completed)

func _load_config() -> void:
    endpoint = DEFAULT_ENDPOINT
    model = DEFAULT_MODEL
    api_key = ""
    var config := ConfigFile.new()
    if config.load("user://ai_city_config.cfg") == OK:
        endpoint = str(config.get_value("llm", "endpoint", DEFAULT_ENDPOINT)).strip_edges()
        api_key = str(config.get_value("llm", "api_key", "")).strip_edges()
        model = str(config.get_value("llm", "model", DEFAULT_MODEL)).strip_edges()
    if endpoint.is_empty() or endpoint == OLD_GEMINI_ENDPOINT:
        endpoint = DEFAULT_ENDPOINT
    if model.is_empty():
        model = DEFAULT_MODEL

func save_config(new_endpoint: String, new_model: String, new_api_key: String) -> Error:
    endpoint = new_endpoint.strip_edges()
    model = new_model.strip_edges()
    api_key = new_api_key.strip_edges()
    if endpoint.is_empty() or endpoint == OLD_GEMINI_ENDPOINT:
        endpoint = DEFAULT_ENDPOINT
    var config := ConfigFile.new()
    config.set_value("llm", "endpoint", endpoint)
    config.set_value("llm", "model", model)
    config.set_value("llm", "api_key", api_key)
    return config.save("user://ai_city_config.cfg")

func is_configured() -> bool:
    return not endpoint.is_empty() and not model.is_empty() and not api_key.is_empty()

func _is_native_gemini() -> bool:
    return endpoint.contains("generativelanguage.googleapis.com") and endpoint.contains("generateContent")

func _native_url() -> String:
    return endpoint.replace("{model}", model)

func ask(messages: Array) -> bool:
    if _active or not is_configured():
        return false

    var headers := PackedStringArray(["Content-Type: application/json"])
    var payload: Dictionary

    if _is_native_gemini():
        headers.append("x-goog-api-key: " + api_key)
        var contents: Array = []
        var system_text := ""
        for item in messages:
            if not item is Dictionary:
                continue
            var role := str(item.get("role", "user"))
            var text := str(item.get("content", ""))
            if text.is_empty():
                continue
            if role == "system":
                system_text = text
                continue
            var native_role := "model" if role == "assistant" else "user"
            contents.append({"role": native_role, "parts": [{"text": text}]})

        payload = {
            "contents": contents,
            "generationConfig": {
                "temperature": 0.8,
                "responseMimeType": "application/json",
                "responseSchema": {
                    "type": "OBJECT",
                    "properties": {
                        "reply": {"type": "STRING"},
                        "action": {"type": "STRING", "enum": ["none", "follow_player", "stop", "wander"]},
                        "intent": {"type": "STRING"},
                        "goal": {"type": "STRING"}
                    },
                    "required": ["reply", "action", "intent", "goal"]
                }
            }
        }
        if not system_text.is_empty():
            payload["systemInstruction"] = {"parts": [{"text": system_text}]}
    else:
        # Keep custom OpenAI-compatible endpoints supported.
        headers.append("Authorization: Bearer " + api_key)
        payload = {"model": model, "messages": messages, "temperature": 0.8}

    _active = true
    var request_url := _native_url() if _is_native_gemini() else endpoint
    var err := _request.request(request_url, headers, HTTPClient.METHOD_POST, JSON.stringify(payload))
    if err != OK:
        _active = false
        completed.emit(false, {}, "Could not start AI request (error %s)." % err)
        return false
    return true

func _on_request_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
    _active = false
    var raw := body.get_string_from_utf8()
    if result != HTTPRequest.RESULT_SUCCESS:
        completed.emit(false, {}, "Network request failed (result %s). Check Android INTERNET permission and connection." % result)
        return
    if response_code < 200 or response_code >= 300:
        completed.emit(false, {}, "AI server HTTP %s: %s" % [response_code, raw.left(500)])
        return

    var parsed = JSON.parse_string(raw)
    if not parsed is Dictionary:
        completed.emit(false, {}, "AI provider returned invalid JSON.")
        return

    var content := ""
    if _is_native_gemini():
        var candidates = parsed.get("candidates", [])
        if candidates is Array and not candidates.is_empty() and candidates[0] is Dictionary:
            var candidate: Dictionary = candidates[0]
            var candidate_content = candidate.get("content", {})
            if candidate_content is Dictionary:
                var parts = candidate_content.get("parts", [])
                if parts is Array:
                    for part in parts:
                        if part is Dictionary and not str(part.get("text", "")).is_empty():
                            content = str(part.get("text", ""))
                            break
    else:
        var choices = parsed.get("choices", [])
        if choices is Array and not choices.is_empty() and choices[0] is Dictionary:
            var message = choices[0].get("message", {})
            if message is Dictionary:
                content = str(message.get("content", ""))

    content = content.strip_edges()
    if content.is_empty():
        completed.emit(false, {}, "AI returned no text. Raw response: %s" % raw.left(500))
        return

    var plan = JSON.parse_string(content)
    if plan is Dictionary:
        completed.emit(true, plan, "")
    else:
        completed.emit(true, {"reply": content, "action": "none", "intent": "conversation", "goal": ""}, "")
