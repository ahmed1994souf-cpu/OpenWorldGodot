extends RefCounted
## Provider-agnostic NPC brain.
## The game can use the local planner now and a remote LLM later without changing NPC movement code.

const MAX_MEMORY: int = 8

var npc_name: String = "NPC"
var role: String = "citizen"
var personality: String = "friendly"
var knowledge: Array[String] = []
var memory: Array[Dictionary] = []
var last_intent: String = "idle"
var last_action: String = "wander"

func setup(profile: Dictionary) -> void:
    npc_name = str(profile.get("name", "NPC"))
    role = str(profile.get("role", "citizen"))
    personality = str(profile.get("personality", "friendly"))
    knowledge = profile.get("knowledge", []) as Array

func remember(speaker: String, text: String) -> void:
    memory.append({"speaker": speaker, "text": text})
    while memory.size() > MAX_MEMORY:
        memory.pop_front()

func plan(user_text: String, world: Dictionary) -> Dictionary:
    var q: String = user_text.to_lower().strip_edges()
    var intent: String = _detect_intent(q)
    last_intent = intent

    var action: String = "talk"
    var response: String = ""
    match intent:
        "follow":
            action = "follow_player"
            last_action = action
            response = _follow_response()
        "stop":
            action = "stop"
            last_action = action
            response = "Okay. I will stay here."
        "wander":
            action = "wander"
            last_action = action
            response = "Alright. I will continue my routine."
        "name":
            response = "My name is %s. I work as a %s." % [npc_name, role]
        "where":
            response = "You are in the central part of the city. The main road is nearby."
        "help":
            response = _help_response(world)
        "greeting":
            action = "talk"
            last_action = action
            response = _greeting_response()
        "memory":
            response = _memory_response()
        _:
            response = _generic_response(q, world)

    remember("player", user_text)
    remember(npc_name, response)
    return {
        "intent": intent,
        "action": action,
        "response": response,
        "memory_size": memory.size()
    }

func _detect_intent(q: String) -> String:
    if _has_any(q, ["follow", "come with me", "تعال معي", "اتبعني", "اتبعني"]):
        return "follow"
    if _has_any(q, ["stop", "stay", "wait here", "توقف", "ابق", "ابق هنا"]):
        return "stop"
    if _has_any(q, ["walk", "go", "wander", "اذهب", "تحرك", "امش"]):
        return "wander"
    if _has_any(q, ["name", "who are you", "اسمك", "من انت", "من أنت"]):
        return "name"
    if _has_any(q, ["where", "where are we", "أين", "اين", "وين"]):
        return "where"
    if _has_any(q, ["help", "ساعد", "مساعدة", "مساعده"]):
        return "help"
    if _has_any(q, ["remember", "do you remember", "تذكر", "هل تتذكر"]):
        return "memory"
    if _has_any(q, ["hello", "hi", "hey", "سلام", "مرحبا", "اهلا", "أهلا"]):
        return "greeting"
    return "conversation"

func _has_any(q: String, terms: Array[String]) -> bool:
    for term in terms:
        if q.contains(term):
            return true
    return false

func _greeting_response() -> String:
    if personality == "serious":
        return "Hello. What do you need?"
    return "Hello. Nice to meet you. What brings you to this part of the city?"

func _follow_response() -> String:
    if role.contains("guard"):
        return "I can walk with you. Keep moving and I will stay nearby."
    return "Sure. I will come with you."

func _help_response(world: Dictionary) -> String:
    var distance: float = float(world.get("player_distance", 0.0))
    if distance > 8.0:
        return "I can help, but come a little closer first."
    return "Tell me what you need. I can talk, follow you, stop, or continue my routine."

func _memory_response() -> String:
    if memory.size() < 3:
        return "We have only just started talking. I do not know much about you yet."
    var last_player: String = ""
    for i in range(memory.size() - 1, -1, -1):
        if str(memory[i].get("speaker", "")) == "player":
            last_player = str(memory[i].get("text", ""))
            break
    if last_player.is_empty():
        return "I remember that we have been talking."
    return "I remember your recent message: %s" % last_player

func _generic_response(q: String, world: Dictionary) -> String:
    if q.is_empty():
        return "I am listening."
    if role.contains("shopkeeper"):
        return "I run a small shop nearby. If you need something, ask me specifically."
    if role.contains("photographer"):
        return "I am taking photos around the city. There are interesting places beyond the main road."
    if role.contains("taxi"):
        return "I drive a taxi here. If you need a ride, tell me where you want to go."
    if role.contains("guard"):
        return "I watch this area. Tell me what happened."
    return "I understand you are asking about: %s. Tell me a little more so I can help." % q
