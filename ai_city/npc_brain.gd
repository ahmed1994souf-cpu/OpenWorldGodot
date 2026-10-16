extends RefCounted
## AI-only NPC brain. There are deliberately no offline/canned NPC replies.
const MAX_MEMORY: int = 16
var npc_name: String = "NPC"
var role: String = "citizen"
var personality: String = "friendly"
var knowledge: Array = []
var memory: Array[Dictionary] = []
var last_intent: String = "idle"
var last_action: String = "none"

func setup(profile: Dictionary) -> void:
	npc_name = str(profile.get("name", "NPC"))
	role = str(profile.get("role", "citizen"))
	personality = str(profile.get("personality", "friendly"))
	knowledge = profile.get("knowledge", [])

func remember(speaker: String, text: String) -> void:
	if text.strip_edges().is_empty():
		return
	memory.append({"speaker": speaker, "text": text})
	while memory.size() > MAX_MEMORY:
		memory.pop_front()

func build_messages(user_text: String, world: Dictionary) -> Array:
	var system_text := """You are a believable character living in an open-world city, not a help bot. Respond to the exact player message with natural, context-aware conversation. Use conversation history and the character role/personality. Answer in the player's language; if they use Arabic, use natural Arabic or Algerian Darija. Do not use canned greetings or generic fallback phrases. Do not claim facts absent from the supplied character profile/world state. Keep replies natural, usually 1-4 sentences. You may request one action: none, follow_player, stop, wander. Do not claim an action happened unless you set it. Return ONLY valid JSON with keys reply (string), action (one of none, follow_player, stop, wander), intent (short string), goal (short string)."""
	system_text += "\nCharacter profile: " + JSON.stringify({"name": npc_name, "role": role, "personality": personality, "knowledge": knowledge})
	system_text += "\nCurrent world state: " + JSON.stringify(world)
	var messages: Array = [{"role": "system", "content": system_text}]
	for item in memory:
		var role_name := "assistant" if str(item.get("speaker", "")) == npc_name else "user"
		messages.append({"role": role_name, "content": str(item.get("text", ""))})
	messages.append({"role": "user", "content": user_text})
	return messages

func accept_remote_plan(user_text: String, plan: Dictionary) -> Dictionary:
	var response := str(plan.get("reply", plan.get("response", ""))).strip_edges()
	var action := str(plan.get("action", "none"))
	if not ["none", "follow_player", "stop", "wander"].has(action):
		action = "none"
	last_intent = str(plan.get("intent", "conversation"))
	last_action = action
	remember("player", user_text)
	if not response.is_empty():
		remember(npc_name, response)
	return {"intent": last_intent, "action": action, "response": response, "memory_size": memory.size()}
