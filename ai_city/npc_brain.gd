extends RefCounted
## Local fallback dialogue. For open-ended reasoning, configure a real chat model in AI SETUP.
const MAX_MEMORY: int = 16
var npc_name: String = "NPC"
var role: String = "citizen"
var personality: String = "friendly"
var knowledge: Array = []
var memory: Array[Dictionary] = []
var last_intent: String = "idle"
var last_action: String = "wander"
var last_response: String = ""

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
	var system_text := """You are an actual character in a living open-world city, not a help bot or a menu. Talk like a believable person with your own role, memories, mood, opinions and immediate surroundings. Answer the exact question; do not fall back to generic phrases, repeat a stock line, or ask the player to 'tell me more' unless genuinely needed. Remember earlier details and refer to them naturally. If the player speaks Arabic, answer naturally in Arabic; if Algerian Darija is used, you may answer in natural Darija. Keep ordinary replies concise but specific (usually 1-4 sentences). Never invent world facts not supplied in the world state or profile. You can request only these game actions: none, follow_player, stop, wander. Do not claim an action happened unless you set it. Return ONLY valid JSON with keys reply (string), action (one of none, follow_player, stop, wander), intent (short string), goal (short string)."""
	system_text += "\nCharacter profile: " + JSON.stringify({"name": npc_name, "role": role, "personality": personality, "knowledge": knowledge})
	system_text += "\nCurrent world state: " + JSON.stringify(world)
	var messages: Array = [{"role": "system", "content": system_text}]
	for item in memory:
		var role_name := "assistant" if str(item.get("speaker", "")) == npc_name else "user"
		messages.append({"role": role_name, "content": str(item.get("text", ""))})
	messages.append({"role": "user", "content": user_text})
	return messages

func plan(user_text: String, world: Dictionary) -> Dictionary:
	var q := user_text.to_lower().strip_edges()
	var intent := _detect_intent(q)
	var action := "none"
	var response := ""
	var previous_player := _last_player_message()
	var arabic := _is_arabic(q)
	match intent:
		"follow":
			action = "follow_player"
			response = _pick(["حاضر، نمشي معاك. قولّي وين رايحين.", "ماشي، نتبعك. إذا حبيت نوقف قولّي.", "أكيد، نجي معاك."] if arabic else ["Sure, I'll come with you. Where are we heading?", "Alright, I'll keep up. Tell me if you want me to stop.", "Okay, lead the way."])
		"stop":
			action = "stop"
			response = _pick(["حاضر، نبقى هنا.", "ماشي، نوقف هنا حتى تحتاجني.", "تمام، ما نزيدش نتبعك."] if arabic else ["Okay, I'll stay here.", "Got it. I'll wait here until you need me.", "Alright, I'll stop following you."])
		"wander":
			action = "wander"
			response = _pick(["نرجع لدورتي. نشوفك من بعد.", "حسنًا، نكمل طريقي.", "ماشي، نخليك تكمل وحدك."] if arabic else ["I'll get back to my route. See you around.", "Alright, I'll carry on with my day.", "No problem. I'll leave you to it."])
		"name":
			response = ("أنا %s، نخدم %s. واش حاب تعرف؟" % [npc_name, _arabic_role()]) if arabic else ("I'm %s. I work as a %s. What would you like to know?" % [npc_name, role])
		"where":
			response = _where_response(arabic)
		"help":
			response = "تقدر تسقسي على خدمتي ولا المدينة، أو تطلب مني نتبعك أو نبقى هنا." if arabic else "Ask me about my work or the city, or ask me to follow you, wait, or continue my route."
		"greeting":
			response = _pick(["أهلًا! واش راك؟ واش جابك لهنا؟", "سلام، فرحت كي شفتك. واش تحتاج؟", "أهلا بيك! كيفاش نقدر نعاونك؟"] if arabic else ["Hey! How's it going? What brings you here?", "Hi there. Good to see a familiar face. What do you need?", "Hello! How's your day going?"])
		"memory":
			response = _memory_response(arabic)
		"thanks":
			response = _pick(["بلا مزية، مرحبا في أي وقت.", "العفو، ما درت والو.", "لا شكر على واجب!"] if arabic else ["You're welcome. Happy to help.", "No problem at all.", "Anytime."])
		"how_are_you":
			response = _how_are_you(arabic)
		"job":
			response = _job_response(arabic)
		"city":
			response = _city_response(arabic)
		"personal":
			response = _personal_response(arabic)
		"farewell":
			response = _pick(["نشوفك من بعد، رد بالك على روحك.", "في أمان الله، إذا احتجتني تلقاني هنا."] if arabic else ["See you around. Take care.", "Alright, catch you later. I'll be around."])
		_:
			response = _contextual_response(q, previous_player, arabic, world)
	if response == last_response:
		response = _alternate_response(intent, arabic, response)
	last_intent = intent
	last_action = action
	remember("player", user_text)
	remember(npc_name, response)
	last_response = response
	return {"intent": intent, "action": action, "response": response, "memory_size": memory.size()}

func accept_remote_plan(user_text: String, plan: Dictionary) -> Dictionary:
	var response := str(plan.get("reply", plan.get("response", "I'm listening."))).strip_edges()
	if response.is_empty():
		response = _contextual_response(user_text.to_lower(), _last_player_message(), _is_arabic(user_text), {})
	var action := str(plan.get("action", "none"))
	if not ["none", "follow_player", "stop", "wander"].has(action):
		action = "none"
	last_intent = str(plan.get("intent", "conversation"))
	last_action = action
	remember("player", user_text)
	remember(npc_name, response)
	last_response = response
	return {"intent": last_intent, "action": action, "response": response, "memory_size": memory.size()}

func _detect_intent(q: String) -> String:
	if _has_any(q, ["follow", "come with me", "تعال معي", "اتبعني", "اتبعني", "اتبع"]): return "follow"
	if _has_any(q, ["stop following", "stay here", "wait here", "stop", "توقف", "ابق هنا", "ابق", "قف"]): return "stop"
	if _has_any(q, ["go away", "continue your route", "wander", "اذهب", "تجول", "كمل طريقك"]): return "wander"
	if _has_any(q, ["what is your name", "your name", "who are you", "اسمك", "شكون انت", "من انت", "من أنت"]): return "name"
	if _has_any(q, ["where are we", "where is", "where can i", "where", "أين", "اين", "وين", "فين"]): return "where"
	if _has_any(q, ["help", "مساعدة", "مساعده", "عاونني", "ساعدني"]): return "help"
	if _has_any(q, ["remember", "do you remember", "تذكر", "هل تتذكر", "واش قلتلك"]): return "memory"
	if _has_any(q, ["thank", "thanks", "شكرا", "شكرًا", "يعطيك الصحة", "بارك الله"]): return "thanks"
	if _has_any(q, ["how are you", "how's it going", "كيف حالك", "واش راك", "راك لاباس", "لاباس عليك"]): return "how_are_you"
	if _has_any(q, ["what do you do", "your job", "work as", "خدمتك", "واش تخدم", "ماذا تعمل"]): return "job"
	if _has_any(q, ["city", "town", "neighborhood", "المدينة", "الحي", "البلاد", "المنطقة"]): return "city"
	if _has_any(q, ["your family", "your story", "your life", "tell me about yourself", "عائلتك", "قصتك", "احكيلي عليك"]): return "personal"
	if _has_any(q, ["bye", "goodbye", "see you", "مع السلامة", "باي", "نشوفك"]): return "farewell"
	if _has_any(q, ["hello", "hi", "hey", "سلام", "مرحبا", "اهلا", "أهلا", "صباح الخير", "مساء الخير"]): return "greeting"
	return "conversation"

func _has_any(q: String, terms: Array) -> bool:
	for term in terms:
		if q.contains(str(term)):
			return true
	return false

func _is_arabic(value: String) -> bool:
	for i in range(value.length()):
		var code := value.unicode_at(i)
		if code >= 0x0600 and code <= 0x06FF:
			return true
	return false

func _pick(options: Array) -> String:
	return str(options[randi_range(0, options.size() - 1)])

func _last_player_message() -> String:
	for i in range(memory.size() - 1, -1, -1):
		if str(memory[i].get("speaker", "")) == "player":
			return str(memory[i].get("text", ""))
	return ""

func _where_response(arabic: bool) -> String:
	if role.contains("taxi"):
		return "إذا راك تحوس على بلاصة، قولّي اسمها ونعاونك بالطريق. نعرف الطريق الرئيسي في هذي المنطقة." if arabic else "I drive these streets for a living. Tell me the place you're looking for and I'll help with directions."
	if role.contains("shopkeeper"):
		return "المحلات قريبة من الطريق الرئيسي. قولّي واش راك تحوس عليه ونحاول نوجّهك." if arabic else "The shops are close to the main road. Tell me what you're looking for and I'll point you the right way."
	return "راهي منطقة وسط المدينة، والطريق الرئيسي قريب. ما نقدرش نحدد عنوان دقيق من المعلومات اللي عندي." if arabic else "We're in the central part of the city, near the main road. I don't have an exact street address."

func _how_are_you(arabic: bool) -> String:
	if role.contains("guard"):
		return "لاباس، الخدمة هادئة حتى الآن، بصح نبقى نراقب المنطقة." if arabic else "Doing alright. It's been quiet on duty, but I still have to watch the area."
	if role.contains("taxi"):
		return "لاباس، نهاري كان طويل شوية مع السياقة. وانت واش حوالك؟" if arabic else "Pretty good, though I've been driving around all day. How about you?"
	if role.contains("photographer"):
		return "راني مليح! نحاول نلقى منظر يستاهل تصويرة اليوم." if arabic else "I'm good! I'm hoping to find something worth photographing today."
	return "الحمد لله، نهاري ماشي مليح. وانت؟" if arabic else "I'm doing well, thanks for asking. How's your day going?"

func _job_response(arabic: bool) -> String:
	if role.contains("shopkeeper"):
		return "نخدم في التجارة، ونعاون الناس يلقاو واش يحتاجو. لوكان راك تحوس على حاجة قولّي." if arabic else "I run a little shop and help people find what they need. Are you looking for anything?"
	if role.contains("photographer"):
		return "نصوّر شوارع المدينة والناس والأماكن اللي عندها حكاية. الضوء هنا يعطيني صور مليحة." if arabic else "I'm a street photographer. I look for small moments and places with a story to tell."
	if role.contains("taxi"):
		return "أنا سائق طاكسي؛ نخدم في شوارع المدينة ونعرف الطريق الرئيسي مليح." if arabic else "I'm a taxi driver. I spend my days on these streets and know the main roads pretty well."
	if role.contains("guard"):
		return "أنا حارس هنا. خدمتي نراقب المنطقة ونحافظ على الهدوء." if arabic else "I'm the security guard here. I keep an eye on the area and try to keep things calm."
	return "نعيش ونخدم هنا كيما بزاف ناس. كل نهار نتعلم حاجة جديدة على المدينة." if arabic else "I live and work around here, like plenty of people. You learn something new about this city every day."

func _city_response(arabic: bool) -> String:
	return "المدينة فيها طريق رئيسي ومحلات وشوارع جانبية. مازال ما عنديش تفاصيل على كل بلاصة، بصح نقدر نعاونك بالمعلومات اللي نعرفها." if arabic else "This part of the city has a main road, shops and side streets. I don't know every detail yet, but I can help with what I do know."

func _personal_response(arabic: bool) -> String:
	if role.contains("photographer"):
		return "ولّيت نحب التصوير لأنه يخليني نلاحظ تفاصيل الناس يفوتوها. كل شارع عنده قصة، حتى لو ما تبانش من أول نظرة." if arabic else "I got into photography because it makes me notice things other people walk past. Every street has a story if you look closely."
	if role.contains("taxi"):
		return "السياقة علمتني نصبر ونسمع للناس. كل راكب عنده حكاية مختلفة، وبعض الحكايات تبقى في بالك." if arabic else "Driving has taught me patience and how to listen. Every passenger has a different story, and some stay with you."
	if role.contains("guard"):
		return "أنا شخص نحب النظام ونرتاح كي نعرف الناس اللي حولي في أمان. ما نهدرش بزاف وقت الخدمة." if arabic else "I like order and knowing the people around me are safe. I can be quiet while I'm on duty."
	if role.contains("shopkeeper"):
		return "نحب نعرف الناس اللي يجو للمحل، مش غير نبيع ونشري. الحومة تولي دارك كي تعرف وجوهها." if arabic else "I like getting to know the people who come by, not just selling things. A neighborhood feels like home when you know its faces."
	return "مازال ما حكيتلكش بزاف على روحي. اسقسي على حاجة محددة ونحكيلك اللي نقدر عليه." if arabic else "I haven't told you much about myself yet. Ask me something specific and I'll share what I can."

func _contextual_response(q: String, previous_player: String, arabic: bool, world: Dictionary) -> String:
	if _has_any(q, ["why", "علاش", "لماذا"]):
		return ("على حساب واش تقصد بالضبط. راك تسقسي على كلامي اللي فات ولا على حاجة أخرى؟") if arabic else ("What part do you mean? Are you asking why I said that earlier, or about something else?")
	if _has_any(q, ["yes", "yeah", "okay", "ok", "نعم", "ايه", "إيه", "صح"]):
		return ("تمام. تحب نزيد نفسرلك ولا عندك سؤال آخر؟") if arabic else ("Alright. Want me to explain a bit more, or did you have something else in mind?")
	if _has_any(q, ["no", "لا", "مش هكذا", "not that"]):
		return ("فهمت، يمكن فهمتك غلط. وضّحلي شوية واش تقصد.") if arabic else ("I may have misunderstood. Give me a little more detail about what you mean.")
	if _has_any(q, ["shop", "buy", "price", "محل", "نشري", "السعر", "نبيع"]):
		return ("إذا راك تحوس على سلعة، قولّي اسمها. نقدر نعاونك غير بالمعلومات المتوفرة عندي.") if arabic else ("What are you looking to buy? I can help with the information I have, but I don't know every shop's inventory.")
	if _has_any(q, ["photo", "picture", "تصويرة", "صورة"]):
		return ("كاين مناظر في الشوارع تستاهل تتصوّر. نحب نلقط اللحظات العفوية أكثر من الصور المرتبة.") if arabic and role.contains("photographer") else ("I like candid street moments best. They tell you more about a place than a posed picture." if role.contains("photographer") else ("التصوير يخلّد لحظات مليحة. واش حاب تصوّر؟" if arabic else "Photos can capture a good moment. What are you hoping to photograph?"))
	if _has_any(q, ["danger", "problem", "trouble", "خطر", "مشكل", "مشكلة"]):
		return ("واش صرا بالضبط؟ احكيلي وشفت ولا واش سمعت، ونشوفو كيفاش نتصرفو.") if arabic else ("What happened exactly? Tell me what you saw or heard and we can work out what to do.")
	if previous_player != "":
		return ("سمعتك. كي قلتلي «%s»، واش أكثر حاجة حاب تعرف عليها؟" % previous_player.left(70)) if arabic else ("I hear you. About what you said earlier — what part matters most to you?")
	return _role_specific_opening(arabic)

func _role_specific_opening(arabic: bool) -> String:
	if role.contains("shopkeeper"):
		return _pick(["واش راك تحتاج اليوم؟ نقدر نهدر معاك على المحلات والسلع اللي نعرفها.", "نهاري كامل هنا مع الزبائن؛ مرات نسمع قصص أغرب من الخيال. واش حاب تعرف؟"] if arabic else ["What are you looking for today? I can talk about the shops and things I know.", "I spend all day here with customers. You hear some surprising stories. What do you want to know?"])
	if role.contains("photographer"):
		return _pick(["كنت نشوف الضوء كيفاش طايح على البنايات. مرات أبسط لقطة تحكي قصة كاملة.", "كل مرة ندور نلقى تفصيل جديد في هذي الشوارع. واش لاحظت انت؟"] if arabic else ["I was watching the light fall across the buildings. Sometimes a small detail tells a whole story.", "Every time I walk around, I notice something new on these streets. What have you noticed?"])
	if role.contains("taxi"):
		return _pick(["الطريق اليوم هادئ نسبيا. راك رايح لجهة معينة؟", "نقضي وقت طويل في الطريق، ونسمع حكايات من كل نوع. واش حاب تهدر عليه؟"] if arabic else ["The roads are fairly quiet right now. Are you headed somewhere?", "I spend a lot of time on the road and hear all kinds of stories. What's on your mind?"])
	if role.contains("guard"):
		return _pick(["كل شيء هادئ في المنطقة حتى الآن. كاين حاجة حبيت تبلغني عليها؟", "راني نراقب المكان. إذا لاحظت حاجة غريبة قولّي."] if arabic else ["Everything looks quiet around here so far. Is there something you need to report?", "I'm keeping watch. Let me know if you've noticed anything unusual."])
	return _pick(["احكيلي، واش راه شاغل بالك؟", "أنا هنا، نسمعلك. واش صرا معاك اليوم؟"] if arabic else ["What's on your mind?", "I'm listening. How has your day been?"])

func _alternate_response(intent: String, arabic: bool, current: String) -> String:
	match intent:
		"greeting":
			return "أهلا بيك! واش حاب نحكيو عليه؟" if arabic else "Hey again. What would you like to talk about?"
		"how_are_you":
			return "مازال لاباس، شكرا على سؤالك. وانت؟" if arabic else "Still doing alright, thanks for asking. And you?"
		"job":
			return "هذي خدمتي كل يوم، بصح كل نهار فيه حاجة جديدة." if arabic else "That's my day-to-day work, though no two days are quite the same."
		_:
			return "نحب نجاوبك مليح، بصح ما فهمتش قصدك كامل. تقدر تعاودها بطريقة أخرى؟" if arabic else "I want to give you a proper answer, but I didn't quite catch your meaning. Could you phrase it another way?"

func _memory_response(arabic: bool) -> String:
	for i in range(memory.size() - 1, -1, -1):
		if str(memory[i].get("speaker", "")) == "player":
			var remembered := str(memory[i].get("text", ""))
			return ("إيه، آخر حاجة قلتها لي كانت: «%s»." % remembered) if arabic else ("Yes, the last thing you told me was: “%s”." % remembered)
	return "مازال ما هدرتناش بزاف." if arabic else "We haven't talked much yet."

func _arabic_role() -> String:
	if role.contains("shopkeeper"): return "تاجر"
	if role.contains("photographer"): return "مصور شوارع"
	if role.contains("taxi"): return "سائق طاكسي"
	if role.contains("guard"): return "حارس أمن"
	return "مواطن"
