extends Node

signal updated
signal focused(hotspot_id: String)
signal slammed(clue_id: String)
signal aimed(action: String)

var scene_id := "office"
var clues: Array[String] = []
var inspected: Array[String] = []
var phone_unlocked := false
var pin_error := false
var active_suspect := ""
var stress := {}
var anims := {}
var bpm := {}
var confessed := {}
var used := {}
var table_clues: Array[String] = []
var impact_nonce := 0
var speaker := ""
var line := ""
var behzat_line := ""
var pending_clue_id := ""
var queued_speaker := ""
var queued_line := ""
var savci_due := false
var notice := ""
var incoming_call := true
var esorgu_history: Array = []
var briefing_done := false
var show_case := false
var tablet_open := false
var tablet_app := "home"
var shot := "wide"
var slam_clue_id := ""
var dialogue_node := {}
var site_greeted := false
var board_links: Array[String] = []
var focus_active := false
var savci_called := false
var wrong_slams := 0
var sealed := false


func _ready() -> void:
	reset_case()


func set_focus(on: bool) -> void:
	if focus_active == on:
		return
	focus_active = on
	updated.emit()


func reset_case() -> void:
	focus_active = false
	scene_id = "office"
	clues = []
	inspected = []
	phone_unlocked = false
	pin_error = false
	active_suspect = ""
	_blank_suspects()
	table_clues = []
	impact_nonce = 0
	speaker = ""
	line = ""
	behzat_line = ""
	pending_clue_id = ""
	queued_speaker = ""
	queued_line = ""
	savci_due = false
	notice = ""
	incoming_call = true
	esorgu_history = []
	site_greeted = false
	board_links = []
	briefing_done = false
	show_case = false
	tablet_open = false
	tablet_app = "home"
	shot = "wide"
	slam_clue_id = ""
	savci_called = false
	wrong_slams = 0
	sealed = false
	Cinematic.reset()
	updated.emit()


func snapshot() -> Dictionary:
	return {
		"case_id": Scenario.case_id,
		"started": true,
		"sealed": sealed,
		"show_case": show_case,
		"scene_id": scene_id,
		"clues": clues.duplicate(),
		"inspected": inspected.duplicate(),
		"phone_unlocked": phone_unlocked,
		"active_suspect": active_suspect,
		"stress": stress.duplicate(),
		"anims": anims.duplicate(),
		"bpm": bpm.duplicate(),
		"confessed": confessed.duplicate(),
		"used": used.duplicate(true),
		"table_clues": table_clues.duplicate(),
		"speaker": speaker,
		"line": line,
		"behzat_line": behzat_line,
		"incoming_call": incoming_call,
		"esorgu_history": esorgu_history.duplicate(true),
		"briefing_done": briefing_done,
		"tablet_open": false,
		"tablet_app": tablet_app,
		"shot": shot,
		"dialogue_node": dialogue_node.duplicate(),
		"site_greeted": site_greeted,
		"board_links": board_links.duplicate(),
		"savci_called": savci_called,
		"wrong_slams": wrong_slams,
	}


func apply_snapshot(snap: Dictionary) -> void:
	scene_id = str(snap.get("scene_id", "office"))
	clues = _as_strings(snap.get("clues", []))
	inspected = _as_strings(snap.get("inspected", []))
	phone_unlocked = bool(snap.get("phone_unlocked", false))
	pin_error = false
	active_suspect = str(snap.get("active_suspect", ""))
	stress = _as_dict(snap.get("stress", {}))
	anims = _as_dict(snap.get("anims", {}))
	bpm = _as_dict(snap.get("bpm", {}))
	confessed = _as_dict(snap.get("confessed", {}))
	used = _as_dict(snap.get("used", {}))
	table_clues = _as_strings(snap.get("table_clues", []))
	speaker = str(snap.get("speaker", ""))
	line = str(snap.get("line", ""))
	behzat_line = str(snap.get("behzat_line", ""))
	pending_clue_id = ""
	queued_speaker = ""
	queued_line = ""
	savci_due = false
	notice = ""
	incoming_call = bool(snap.get("incoming_call", false))
	esorgu_history = snap.get("esorgu_history", []) if snap.get("esorgu_history", []) is Array else []
	briefing_done = bool(snap.get("briefing_done", false))
	show_case = bool(snap.get("show_case", false))
	tablet_open = false
	tablet_app = str(snap.get("tablet_app", "home"))
	shot = str(snap.get("shot", "wide"))
	slam_clue_id = ""
	dialogue_node = _as_dict(snap.get("dialogue_node", {}))
	site_greeted = bool(snap.get("site_greeted", false))
	board_links = _as_strings(snap.get("board_links", []))
	savci_called = bool(snap.get("savci_called", false))
	wrong_slams = int(snap.get("wrong_slams", 0))
	sealed = bool(snap.get("sealed", false))
	updated.emit()


func _as_strings(raw: Variant) -> Array[String]:
	var out: Array[String] = []
	if raw is Array:
		for item in raw:
			out.append(str(item))
	return out


func _as_dict(raw: Variant) -> Dictionary:
	return raw if raw is Dictionary else {}


func phone_ready() -> bool:
	return Scenario.phone_ready(clues)


func arrest_unlocked() -> bool:
	return Scenario.arrest_unlocked(clues)


func case_is_closed() -> bool:
	var people: Array = Scenario.data.get("suspects", [])
	for person in people:
		var id: String = str(person["id"])
		if not bool(confessed.get(id, false)):
			return false
	return not people.is_empty()


func open_case(id: String) -> bool:
	var row := Scenario.case_row(id)
	if str(row.get("status", "")) != "open":
		notice = "Dosya %s boş. Senaryo yazılınca rafa düşer." % str(row.get("fileNo", ""))
		updated.emit()
		return false
	if not Scenario.load_case(id):
		notice = "Dosya açılmadı."
		updated.emit()
		return false
	reset_case()
	return true


func greet_site() -> void:
	if site_greeted:
		return
	var arrival: Dictionary = Scenario.data.get("arrival", {})
	if arrival.is_empty():
		return
	site_greeted = true
	speaker = str(arrival.get("speaker", ""))
	line = str(arrival.get("line", ""))
	updated.emit()


func _blank_suspects() -> void:
	stress = {}
	anims = {}
	bpm = {}
	confessed = {}
	used = {}
	dialogue_node = {}
	for person in Scenario.data.get("suspects", []):
		var id: String = str(person["id"])
		var calm := str(person.get("calm", "IDLE"))
		stress[id] = 0
		anims[id] = calm if calm != "" else "IDLE"
		bpm[id] = 75
		confessed[id] = false
		used[id] = []
		dialogue_node[id] = "start"


func open_tablet(app: String = "home") -> void:
	tablet_open = true
	tablet_app = app
	updated.emit()


func close_tablet() -> void:
	tablet_open = false
	updated.emit()


func answer_call() -> void:
	incoming_call = false
	notice = "Brifing Behzat'in masasında."
	scene_id = "office"
	updated.emit()


func decline_call() -> void:
	incoming_call = false
	notice = "Behzat ofiste. Masasına uğra."
	updated.emit()


func dismiss_notice() -> void:
	notice = ""
	updated.emit()


func dismiss_clue() -> void:
	pending_clue_id = ""
	if queued_line != "":
		speaker = queued_speaker
		line = queued_line
		queued_speaker = ""
		queued_line = ""
	updated.emit()
	if savci_due:
		savci_due = false
		Cinematic.play("call_savci")


## Diyalog plakasını kapat (olay yerinde yürümeye başlarken).
func clear_dialogue() -> void:
	if speaker == "" and line == "" and behzat_line == "":
		return
	speaker = ""
	line = ""
	behzat_line = ""
	updated.emit()


func close_case_report() -> void:
	show_case = false
	updated.emit()


func open_case_report() -> void:
	if case_is_closed():
		show_case = true
		updated.emit()


func travel(next_scene: String) -> bool:
	if next_scene == "interrogation" and not arrest_unlocked():
		notice = "Gözaltı için kilit delil henüz yok."
		updated.emit()
		return false
	get_tree().paused = false
	scene_id = next_scene
	tablet_open = false
	speaker = ""
	line = ""
	behzat_line = ""
	shot = "wide"
	Cinematic.play("travel_" + next_scene)
	updated.emit()
	return true


func read_files() -> void:
	speaker = "Komiser"
	if briefing_done:
		line = "%s klasörü. %s. Kapakta çay lekesi var." % [str(Scenario.data.get("place", "Dosya")), str(Scenario.data.get("title", ""))]
	else:
		line = "Klasör kapalı. Önce başkomiserin masasına uğra."
	updated.emit()


func open_records() -> void:
	speaker = "Hayalet"
	line = "Eski terminal. GBT, PTS ve HTS bu makinede."
	open_tablet("esorgu")


func brief() -> void:
	briefing_done = true
	speaker = "Başkomiser Behzat"
	line = Scenario.data.get("briefing", "")
	updated.emit()


func inspect_hotspot(id: String) -> void:
	var spot := Scenario.hotspot(id)
	if spot.is_empty():
		return
	var clue_id: String = spot["unlocksClueId"]
	var known := clues.has(clue_id)
	if not inspected.has(id):
		inspected.append(id)
	if not known:
		clues.append(clue_id)
		pending_clue_id = clue_id
		queued_speaker = str(spot["speaker"])
		queued_line = str(spot["text"])
		speaker = ""
		line = ""
		behzat_line = ""
		_reveal(clue_id)
	else:
		speaker = spot["speaker"]
		line = spot["text"]
	focused.emit(id)
	updated.emit()


func try_pin(pin: String) -> bool:
	if not phone_ready():
		notice = "Telefon hâlâ olay yerinde."
		updated.emit()
		return false
	if pin == str(Scenario.data.get("pin", "")):
		phone_unlocked = true
		pin_error = false
		notice = "Telefon kilidi açıldı."
		updated.emit()
		return true
	pin_error = true
	notice = "Hatalı şifre."
	updated.emit()
	return false


func open_phone_item(item_id: String) -> void:
	if not phone_unlocked:
		return
	var item := Scenario.phone_item(item_id)
	if item.is_empty():
		return
	var clue_id: String = item["unlocksClueId"]
	if not clues.has(clue_id):
		clues.append(clue_id)
		pending_clue_id = clue_id
		notice = "%s envantere girdi." % Scenario.clue(clue_id).get("title", "Kanıt")
		_reveal(clue_id)
	updated.emit()


func search_esorgu(raw: String) -> void:
	var key := Scenario.normalize_query(raw)
	if key == "":
		notice = "Sorgu metni boş."
		updated.emit()
		return
	var record := Scenario.find_esorgu(raw)
	if record.is_empty():
		esorgu_history.push_front({
			"query": raw.strip_edges(),
			"found": false,
			"title": "Kayıt yok",
			"body": "GBT, PTS ve HTS kayıtlarında eşleşme yok.",
		})
		updated.emit()
		return
	var clue_id: String = record["unlocksClueId"]
	var known := clues.has(clue_id)
	if not known:
		clues.append(clue_id)
		pending_clue_id = clue_id
		notice = "%s envantere girdi." % Scenario.clue(clue_id).get("title", "Kanıt")
		_reveal(clue_id)
	esorgu_history.push_front({
		"query": raw.strip_edges(),
		"found": true,
		"title": record["title"],
		"body": record["body"],
	})
	if esorgu_history.size() > 8:
		esorgu_history.resize(8)
	updated.emit()


## Kanıt panosunda iki kanıt arasına bağ kurar. Yeni bağsa true döner.
func link_clues(a: String, b: String) -> bool:
	if a == "" or b == "" or a == b:
		return false
	var key := a + "|" + b if a < b else b + "|" + a
	if board_links.has(key):
		return false
	board_links.append(key)
	updated.emit()
	return true


func select_suspect(id: String) -> void:
	var person := Scenario.suspect(id)
	if person.is_empty():
		return
	active_suspect = id
	shot = "wide"
	slam_clue_id = ""
	speaker = person["character"]["name"]
	line = Scenario.dialogue_node(id, dialogue_node[id]).get("text", person["lines"]["idle"])
	behzat_line = ""
	Cinematic.clear_lie()
	updated.emit()


func _reveal(clue_id: String) -> void:
	Cinematic.on_clue(clue_id)
	if not savci_called and arrest_unlocked():
		savci_called = true
		if pending_clue_id != "":
			savci_due = true
		else:
			Cinematic.play("call_savci")


## Alt paneldeki diyalog seçenekleri (kullanılmış kanıtlara göre dallanır).
func dialogue_options() -> Array:
	if active_suspect == "":
		return []
	var node := Scenario.dialogue_node(active_suspect, dialogue_node[active_suspect])
	var out: Array = []
	var accepted: Array = Scenario.suspect(active_suspect).get("acceptedClueIds", [])
	for option in node.get("options", []):
		var needs: String = option.get("requires", "")
		if needs != "":
			# Şüphelinin kabul ettiği kanıt masaya vurulmalı; kabul etmediği kanıt ise elde olması yeter.
			var open: bool = used[active_suspect].has(needs) or (not accepted.has(needs) and clues.has(needs))
			if not open:
				continue
		out.append(option)
	return out


func choose_option(index: int) -> void:
	var options := dialogue_options()
	if index < 0 or index >= options.size():
		return
	var option: Dictionary = options[index]
	var suspect_id := active_suspect
	var next_id: String = option.get("next", "start")
	dialogue_node[suspect_id] = next_id
	var node := Scenario.dialogue_node(suspect_id, next_id)
	var delta := int(option.get("stress", 0))
	if delta > 0 and not confessed[suspect_id]:
		stress[suspect_id] = mini(95, int(stress[suspect_id]) + delta)
		bpm[suspect_id] = Scenario.bpm_for_stress(int(stress[suspect_id]))
	var forced: String = option.get("anim", "")
	anims[suspect_id] = forced if forced != "" else Scenario.anim_for_stress(suspect_id, int(stress[suspect_id]), confessed[suspect_id])
	speaker = Scenario.suspect(suspect_id)["character"]["name"]
	line = node.get("text", "")
	behzat_line = option.get("behzat", "")
	var lying := bool(node.get("lie", false))
	if lying:
		Cinematic.mark_lie(suspect_id)
	else:
		Cinematic.clear_lie()
	shot = "closeup" if delta >= 10 or lying else "wide"
	updated.emit()
	if forced == "DEFENSIVE":
		_settle_anim(suspect_id, 1.6)


func _settle_anim(suspect_id: String, delay: float) -> void:
	impact_nonce += 1
	var nonce := impact_nonce
	get_tree().create_timer(delay).timeout.connect(func() -> void:
		if impact_nonce != nonce:
			return
		anims[suspect_id] = Scenario.anim_for_stress(suspect_id, int(stress[suspect_id]), confessed[suspect_id])
		updated.emit()
	)


func set_shot(next_shot: String) -> void:
	shot = next_shot
	updated.emit()


func slam_evidence(clue_id: String) -> void:
	if active_suspect == "":
		notice = "Önce şüpheliyi sandalyeye oturt."
		updated.emit()
		return
	if not clues.has(clue_id):
		return
	var suspect_id := active_suspect
	var already: bool = used[suspect_id].has(clue_id)
	var result := Scenario.resolve_slam(suspect_id, clue_id, int(stress[suspect_id]), already)
	stress[suspect_id] = result["stress"]
	bpm[suspect_id] = result["bpm"]
	anims[suspect_id] = result["anim"]
	confessed[suspect_id] = result["confessed"]
	if result["accepted"] and not already:
		used[suspect_id].append(clue_id)
	if not table_clues.has(clue_id):
		table_clues.append(clue_id)
	impact_nonce += 1
	var nonce := impact_nonce
	slam_clue_id = clue_id
	speaker = Scenario.suspect(suspect_id)["character"]["name"]
	line = result["line"]
	behzat_line = result["behzatLine"]
	shot = "closeup"
	if result["confessed"]:
		dialogue_node[suspect_id] = "confessed"
	if result["accepted"]:
		notice = "Kanıt masaya indi."
	elif already:
		notice = "Bu kanıt zaten masaya indi."
	elif result["kind"] == "other":
		notice = "Bu delil başka bir şüpheliyi bağlıyor: %s." % ", ".join(Scenario.clue_owners(clue_id))
	else:
		notice = "Bu delil bu şüpheliyle bağlantılı değil."
	if case_is_closed():
		show_case = true
	if result["confessed"]:
		Cinematic.clear_lie()
		Cinematic.play("confession")
	elif not result["accepted"]:
		if not already and result["kind"] == "unrelated":
			wrong_slams += 1
		Cinematic.mark_lie(suspect_id)
	else:
		Cinematic.clear_lie()
		Cinematic.punch(0.035)
	slammed.emit(clue_id)
	updated.emit()
	if result["anim"] in ["ANGRY_SLAM", "DEFENSIVE"]:
		var hold := 0.9 if result["anim"] == "ANGRY_SLAM" else 1.8
		get_tree().create_timer(hold).timeout.connect(func() -> void:
			if impact_nonce != nonce:
				return
			if anims[suspect_id] != result["anim"]:
				return
			anims[suspect_id] = Scenario.anim_for_stress(suspect_id, int(stress[suspect_id]), confessed[suspect_id])
			updated.emit()
		)
