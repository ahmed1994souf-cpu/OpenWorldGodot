extends RefCounted
## Local-first NPC brain with short-term memory and structured action plans.
const MAX_MEMORY: int = 8
var npc_name: String = "NPC"
var role: String = "citizen"
var personality: String = "friendly"
var knowledge: Array = []
var memory: Array[Dictionary] = []
var last_intent: String = "idle"
var last_action: String = "wander"

func setup(profile: Dictionary) -> void:
	npc_name = str(profile.get("name", "NPC"))
	role = str(profile.get("role", "citizen"))
	personality = str(profile.get("personality", "friendly"))
	knowledge = profile.get("knowledge", [])

func remember(speaker: String, text: String) -> void:
	memory.append({"speaker": speaker, "text": text})
	while memory.size() > MAX_MEMORY:
		memory.pop_front()

func build_messages(user_text: String, world: Dictionary) -> Array:
	var system_text := """You control one NPC in a 3D city game. Be natural, consistent with your profile, and respond in the language used by the player. Use recent conversation and world facts. Never claim an action happened unless your JSON requests it. Return ONLY JSON with keys reply (string), action (one of none, follow_player, stop, wander), intent (short string), goal (short string)."""
	system_text += "\nProfile: " + JSON.stringify({"name": npc_name, "role": role, "personality": personality, "knowledge": knowledge})
	system_text += "\nWorld state: " + JSON.stringify(world)
	var messages: Array = [{"role": "system", "content": system_text}]
	for item in memory:
		var role_name := "assistant" if str(item.get("speaker", "")) == npc_name else "user"
		messages.append({"role": role_name, "content": str(item.get("text", ""))})
	messages.append({"role": "user", "content": user_text})
	return messages

func plan(user_text: String, world: Dictionary) -> Dictionary:
	var q := user_text.to_lower().strip_edges()
	var intent := _detect_intent(q)
	var action := "talk"
	var response := ""
	match intent:
		"follow":
			action = "follow_player"
			response = "حاضر، سأتبعك." if _is_arabic(q) else _follow_response()
		"stop":
			action = "stop"
			response = "حسنًا، سأبقى هنا." if _is_arabic(q) else "Okay. I will stay here."
		"wander":
			action = "wander"
			response = "سأعود إلى جولتي." if _is_arabic(q) else "Alright. I will continue my routine."
		"name":
			response = "اسمي %s وأعمل %s." % [npc_name, role] if _is_arabic(q) else "My name is %s. I work as a %s." % [npc_name, role]
		"where":
			response = "نحن في منطقة وسط المدينة، والطريق الرئيسي قريب." if _is_arabic(q) else "We're in the central part of the city. The main road is nearby."
		"help":
			response = "أستطيع التحدث معك أو اتباعك أو العودة إلى جولتي." if _is_arabic(q) else "I can chat, follow you, stop, or continue my routine."
		"greeting":
			response = "أهلًا! ماذا تريد أن تعرف؟" if _is_arabic(q) else _greeting_response()
		"memory":
			response = _memory_response()
		_:
			response = "فهمت ما تقوله. أخبرني المزيد." if _is_arabic(q) else _generic_response(q)
	last_intent = intent
	last_action = action
	remember("player", user_text)
	remember(npc_name, response)
	return {"intent": intent, "action": action, "response": response, "memory_size": memory.size()}

func accept_remote_plan(user_text: String, plan: Dictionary) -> Dictionary:
	var response := str(plan.get("reply", plan.get("response", "I am listening.")))
	var action := str(plan.get("action", "none"))
	if not ["none", "follow_player", "stop", "wander"].has(action):
		action = "none"
	last_intent = str(plan.get("intent", "conversation"))
	last_action = action
	remember("player", user_text)
	remember(npc_name, response)
	return {"intent": last_intent, "action": action, "response": response, "memory_size": memory.size()}

func _detect_intent(q: String) -> String:
	if _has_any(q, ["follow", "come with me", "تعال معي", "اتبعني", "اتبع"]): return "follow"
	if _has_any(q, ["stop", "stay", "wait here", "توقف", "ابق", "قف"]): return "stop"
	if _has_any(q, ["walk", "go", "wander", "اذهب", "تجول"]): return "wander"
	if _has_any(q, ["name", "who are you", "اسمك", "من انت", "من أنت"]): return "name"
	if _has_any(q, ["where", "where are we", "أين", "اين", "وين"]): return "where"
	if _has_any(q, ["help", "ساعد", "مساعدة", "مساعده"]): return "help"
	if _has_any(q, ["remember", "do you remember", "تذكر", "هل تتذكر"]): return "memory"
	if _has_any(q, ["hello", "hi", "hey", "سلام", "مرحبا", "اهلا", "أهلا"]): return "greeting"
	return "conversation"

func _has_any(q: String, terms: Array) -> bool:
	for term in terms:
		if q.contains(str(term)): return true
	return false

func _is_arabic(value: String) -> bool:
	for i in range(value.length()):
		var code := value.unicode_at(i)
		if code >= 0x0600 and code <= 0x06FF: return true
	return false

func _greeting_response() -> String:
	return "Hello. Nice to meet you. What brings you to this part of the city?" if personality != "serious" else "Hello. What do you need?"

func _follow_response() -> String:
	return "I can walk with you. Keep moving and I will stay nearby." if role.contains("guard") else "Sure. I will come with you."

func _memory_response() -> String:
	for i in range(memory.size() - 1, -1, -1):
		if str(memory[i].get("speaker", "")) == "player":
			return "أتذكر رسالتك الأخيرة: %s" % memory[i].text if _is_arabic(str(memory[i].text)) else "I remember your recent message: %s" % memory[i].text
	return "بدأنا للتو الحديث." if _is_arabic(npc_name) else "We have only just started talking."

func _generic_response(q: String) -> String:
	if q.is_empty(): return "I am listening."
	if role.contains("shopkeeper"): return "I run a small shop nearby. What are you looking for?"
	if role.contains("photographer"): return "I take photos around the city. Have you found an interesting place?"
	if role.contains("taxi"): return "I drive a taxi here. Where would you like to go?"
	if role.contains("guard"): return "I watch this area. Tell me what happened."
	return "I understand. Tell me a little more so I can help."
