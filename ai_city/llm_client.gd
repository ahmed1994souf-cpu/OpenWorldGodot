extends Node
class_name LLMClient

signal completed(success: bool, result: Dictionary, error_message: String)

var endpoint: String = ""
var api_key: String = ""
var model: String = ""
var timeout_seconds: float = 45.0
var _request: HTTPRequest
var _active: bool = false
var _horde_polling: bool = false
var _horde_request_id: String = ""
var _horde_deadline_ms: int = 0

const HORDE_ENDPOINT: String = "https://aihorde.net/api/v2/generate/text/async"
const HORDE_STATUS: String = "https://aihorde.net/api/v2/generate/text/status/{id}"
const HORDE_ANONYMOUS_KEY: String = "0000000000"
const GEMINI_ENDPOINT: String = "https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent"
const GEMINI_MODEL: String = "gemini-2.5-flash"
const OLD_GEMINI_ENDPOINT: String = "https://generativelanguage.googleapis.com/v1beta/openai/chat/completions"

func _ready() -> void:
    _load_config()
    _request = HTTPRequest.new()
    _request.timeout = timeout_seconds
    add_child(_request)
    _request.request_completed.connect(_on_request_completed)

func _load_config() -> void:
    endpoint = HORDE_ENDPOINT
    api_key = HORDE_ANONYMOUS_KEY
    model = ""
    var config := ConfigFile.new()
    if config.load("user://ai_city_config.cfg") == OK:
        endpoint = str(config.get_value("llm", "endpoint", HORDE_ENDPOINT)).strip_edges()
        api_key = str(config.get_value("llm", "api_key", HORDE_ANONYMOUS_KEY)).strip_edges()
        model = str(config.get_value("llm", "model", "")).strip_edges()
    if endpoint.is_empty() or endpoint == OLD_GEMINI_ENDPOINT:
        endpoint = HORDE_ENDPOINT
        api_key = HORDE_ANONYMOUS_KEY
        model = ""
    if endpoint == HORDE_ENDPOINT and api_key.is_empty():
        api_key = HORDE_ANONYMOUS_KEY
    if endpoint != HORDE_ENDPOINT and model.is_empty():
        model = GEMINI_MODEL

func save_config(new_endpoint: String, new_model: String, new_api_key: String) -> Error:
    endpoint = new_endpoint.strip_edges()
    model = new_model.strip_edges()
    api_key = new_api_key.strip_edges()
    if endpoint.is_empty() or endpoint == OLD_GEMINI_ENDPOINT:
        endpoint = HORDE_ENDPOINT
        model = ""
        api_key = HORDE_ANONYMOUS_KEY
    elif endpoint == HORDE_ENDPOINT and api_key.is_empty():
        api_key = HORDE_ANONYMOUS_KEY
    var config := ConfigFile.new()
    config.set_value("llm", "endpoint", endpoint)
    config.set_value("llm", "api_key", api_key)
    config.set_value("llm", "model", model)
    return config.save("user://ai_city_config.cfg")

func use_keyless_horde() -> Error:
    return save_config(HORDE_ENDPOINT, "", HORDE_ANONYMOUS_KEY)

func is_configured() -> bool:
    if endpoint == HORDE_ENDPOINT:
        return true
    return not endpoint.is_empty() and not model.is_empty() and not api_key.is_empty()

func _is_horde() -> bool:
    return endpoint == HORDE_ENDPOINT or endpoint.contains("aihorde.net/api/v2/generate/text/async")

func _is_native_gemini() -> bool:
    return endpoint.contains("generativelanguage.googleapis.com") and endpoint.contains("generateContent")

func _native_url() -> String:
    return endpoint.replace("{model}", model)

func _build_horde_prompt(messages: Array) -> String:
    var prompt := ""
    for item in messages:
        if not item is Dictionary:
            continue
        var role := str(item.get("role", "user"))
        var text := str(item.get("content", "")).strip_edges()
        if text.is_empty():
            continue
        if role == "system":
            prompt += "SYSTEM: " + text + "\n"
        elif role == "assistant":
            prompt += "ASSISTANT: " + text + "\n"
        else:
            prompt += "USER: " + text + "\n"
    prompt += "ASSISTANT:"
    return prompt

func ask(messages: Array) -> bool:
    if _active or not is_configured():
        completed.emit(false, {}, "AI client is not configured.")
        return false

    _active = true
    _horde_polling = false
    var headers := PackedStringArray(["Content-Type: application/json", "Accept: application/json"])
    var payload: Dictionary
    var request_url := endpoint

    if _is_horde():
        headers.append("apikey: " + (api_key if not api_key.is_empty() else HORDE_ANONYMOUS_KEY))
        headers.append("Client-Agent: AI-City-Godot/1.0")
        payload = {
            "prompt": _build_horde_prompt(messages),
            "params": {
                "n": 1,
                "max_length": 160,
                "max_context_length": 2048,
                "temperature": 0.75,
                "top_p": 0.9
            },
            "trusted_workers": false
        }
        request_url = HORDE_ENDPOINT
    elif _is_native_gemini():
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
        payload = {"contents": contents, "generationConfig": {"temperature": 0.8}}
        if not system_text.is_empty():
            payload["systemInstruction"] = {"parts": [{"text": system_text}]}
        request_url = _native_url()
    else:
        headers.append("Authorization: Bearer " + api_key)
        payload = {"model": model, "messages": messages, "temperature": 0.8, "max_tokens": 300}

    print("[LLM] POST ", request_url, " model=", model)
    var err := _request.request(request_url, headers, HTTPClient.METHOD_POST, JSON.stringify(payload))
    if err != OK:
        _active = false
        completed.emit(false, {}, "Could not start AI request (error %s)." % err)
        return false
    return true

func _schedule_horde_poll() -> void:
    await get_tree().create_timer(2.0).timeout
    if not _active or not _horde_polling:
        return
    if Time.get_ticks_msec() >= _horde_deadline_ms:
        _active = false
        _horde_polling = false
        completed.emit(false, {}, "AI Horde request timed out while waiting for a volunteer worker.")
        return
    var headers := PackedStringArray(["Accept: application/json", "apikey: " + (api_key if not api_key.is_empty() else HORDE_ANONYMOUS_KEY), "Client-Agent: AI-City-Godot/1.0"])
    var url := HORDE_STATUS.replace("{id}", _horde_request_id)
    var err := _request.request(url, headers, HTTPClient.METHOD_GET)
    if err != OK:
        _active = false
        _horde_polling = false
        completed.emit(false, {}, "Could not poll AI Horde request (error %s)." % err)

func _on_request_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
    var raw := body.get_string_from_utf8()
    print("[LLM] completed result=", result, " http=", response_code, " bytes=", body.size())

    if result != HTTPRequest.RESULT_SUCCESS:
        _active = false
        _horde_polling = false
        completed.emit(false, {}, "Network request failed (result %s). Check Internet access/DNS/TLS and Android INTERNET permission." % result)
        return

    var parsed = JSON.parse_string(raw)
    if not parsed is Dictionary:
        _active = false
        _horde_polling = false
        completed.emit(false, {}, "AI provider returned invalid JSON: %s" % raw.left(700))
        return

    if _is_horde():
        if not _horde_polling:
            if response_code < 200 or response_code >= 300:
                _active = false
                completed.emit(false, {}, "AI Horde submit HTTP %s: %s" % [response_code, raw.left(700)])
                return
            _horde_request_id = str(parsed.get("id", ""))
            if _horde_request_id.is_empty():
                _active = false
                completed.emit(false, {}, "AI Horde did not return a request id: %s" % raw.left(700))
                return
            _horde_polling = true
            _horde_deadline_ms = Time.get_ticks_msec() + 120000
            print("[LLM] Horde request id=", _horde_request_id)
            _schedule_horde_poll()
            return

        if response_code < 200 or response_code >= 300:
            _active = false
            _horde_polling = false
            completed.emit(false, {}, "AI Horde status HTTP %s: %s" % [response_code, raw.left(700)])
            return
        var done := bool(parsed.get("done", false))
        if not done:
            _schedule_horde_poll()
            return
        var generations = parsed.get("generations", [])
        var content := ""
        if generations is Array and not generations.is_empty() and generations[0] is Dictionary:
            content = str(generations[0].get("text", "")).strip_edges()
        _active = false
        _horde_polling = false
        if content.is_empty():
            completed.emit(false, {}, "AI Horde finished without text: %s" % raw.left(700))
            return
        var plan = JSON.parse_string(content)
        if plan is Dictionary:
            completed.emit(true, plan, "")
        else:
            completed.emit(true, {"reply": content, "action": "none", "intent": "conversation", "goal": ""}, "")
        return

    if response_code < 200 or response_code >= 300:
        _active = false
        completed.emit(false, {}, "AI server HTTP %s: %s" % [response_code, raw.left(700)])
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
        if content.is_empty():
            content = str(parsed.get("text", parsed.get("response", "")))

    _active = false
    content = content.strip_edges()
    if content.is_empty():
        completed.emit(false, {}, "AI returned no text. Raw response: %s" % raw.left(700))
        return
    var plan = JSON.parse_string(content)
    if plan is Dictionary:
        completed.emit(true, plan, "")
    else:
        completed.emit(true, {"reply": content, "action": "none", "intent": "conversation", "goal": ""}, "")
