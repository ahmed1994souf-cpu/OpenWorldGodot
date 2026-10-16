extends Node
class_name LLMClient

signal completed(success: bool, result: Dictionary, error_message: String)

var endpoint: String = ""
var api_key: String = ""
var model: String = ""
var timeout_seconds: float = 25.0
var _request: HTTPRequest
var _active: bool = false

func _ready() -> void:
	_load_config()
	_request = HTTPRequest.new()
	_request.timeout = timeout_seconds
	add_child(_request)
	_request.request_completed.connect(_on_request_completed)

func _load_config() -> void:
	var config := ConfigFile.new()
	if config.load("user://ai_city_config.cfg") == OK:
		endpoint = str(config.get_value("llm", "endpoint", ""))
		api_key = str(config.get_value("llm", "api_key", ""))
		model = str(config.get_value("llm", "model", ""))

func save_config(new_endpoint: String, new_model: String, new_api_key: String) -> Error:
	endpoint = new_endpoint.strip_edges()
	model = new_model.strip_edges()
	api_key = new_api_key.strip_edges()
	var config := ConfigFile.new()
	config.set_value("llm", "endpoint", endpoint)
	config.set_value("llm", "model", model)
	config.set_value("llm", "api_key", api_key)
	return config.save("user://ai_city_config.cfg")

func is_configured() -> bool:
	return not endpoint.is_empty() and not model.is_empty()

func ask(messages: Array) -> bool:
	if _active:
		completed.emit(false, {}, "An AI request is already running.")
		return false
	if not is_configured():
		completed.emit(false, {}, "AI provider is not configured. Using local NPC brain.")
		return false
	var headers := PackedStringArray(["Content-Type: application/json"])
	if not api_key.is_empty():
		headers.append("Authorization: Bearer " + api_key)
	var payload := {"model": model, "messages": messages, "temperature": 0.8, "response_format": {"type": "json_object"}}
	_active = true
	var err := _request.request(endpoint, headers, HTTPClient.METHOD_POST, JSON.stringify(payload))
	if err != OK:
		_active = false
		completed.emit(false, {}, "Could not start HTTP request (error %s)." % err)
		return false
	return true

func _on_request_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	_active = false
	if result != HTTPRequest.RESULT_SUCCESS:
		completed.emit(false, {}, "Network request failed (result %s)." % result)
		return
	var parsed = JSON.parse_string(body.get_string_from_utf8())
	if response_code < 200 or response_code >= 300:
		completed.emit(false, {}, "AI server HTTP %s: %s" % [response_code, body.get_string_from_utf8().left(240)])
		return
	if not parsed is Dictionary:
		completed.emit(false, {}, "AI provider returned invalid JSON.")
		return
	var choices = parsed.get("choices", [])
	if choices.is_empty():
		completed.emit(false, {}, "AI response did not include choices.")
		return
	var message: Dictionary = choices[0].get("message", {})
	var content := str(message.get("content", ""))
	var plan = JSON.parse_string(content)
	if plan is Dictionary:
		completed.emit(true, plan, "")
	else:
		completed.emit(true, {"reply": content, "action": "none", "goal": ""}, "")
