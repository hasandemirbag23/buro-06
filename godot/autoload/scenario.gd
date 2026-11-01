extends Node

const CATALOG_PATH := "res://data/cases.json"

var data: Dictionary = {}
var case_id := ""
var catalog: Array = []


func _ready() -> void:
	var file := FileAccess.open(CATALOG_PATH, FileAccess.READ)
	if file == null:
		push_error("Dosya rafı açılmadı")
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		catalog = parsed.get("cases", [])
	if not load_case("episode_01"):
		push_error("Varsayılan dosya açılmadı")


func case_row(id: String) -> Dictionary:
	for row in catalog:
		if str(row.get("id", "")) == id:
			return row
	return {}


func load_case(id: String) -> bool:
	var row := case_row(id)
	var path := str(row.get("path", ""))
	if path == "" or str(row.get("status", "")) != "open":
		return false
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Vaka dosyası açılmadı: %s" % path)
		return false
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("Vaka JSON okunamadı")
		return false
	data = parsed
	case_id = id
	return true


func file_label() -> String:
	return "Dosya No %s  —  %s" % [str(data.get("fileNo", "?")), str(data.get("title", ""))]


func hotspot(id: String) -> Dictionary:
	for item in data.get("hotspots", []):
		if item["id"] == id:
			return item
	return {}


func clue(id: String) -> Dictionary:
	for item in data.get("clues", []):
		if item["id"] == id:
			return item
	return {}


func character(id: String) -> Dictionary:
	var roster: Dictionary = data.get("characters", {})
	if roster.has(id):
		return roster[id]
	for suspect in data.get("suspects", []):
		if suspect["id"] == id:
			return suspect["character"]
	return {}


func suspect(id: String) -> Dictionary:
	for item in data.get("suspects", []):
		if item["id"] == id:
			return item
	return {}


func phone_item(id: String) -> Dictionary:
	for item in data.get("phoneItems", []):
		if item["id"] == id:
			return item
	return {}


## Gözaltı için en az iki kilit delil gerekir (listede tek delil varsa o yeterli).
func arrest_unlocked(ids: Array) -> bool:
	var needed: Array = data.get("arrestClueIds", [])
	var have := 0
	for clue_id in needed:
		if ids.has(clue_id):
			have += 1
	return have >= mini(2, needed.size()) and not needed.is_empty()


## Bu kanıtı kabul eden şüphelilerin adları.
func clue_owners(clue_id: String) -> Array[String]:
	var out: Array[String] = []
	for person in data.get("suspects", []):
		if person["acceptedClueIds"].has(clue_id):
			out.append(str(person["character"]["name"]))
	return out


func phone_ready(ids: Array) -> bool:
	return ids.has(str(data.get("phoneClueId", "clue_victim_phone")))


func all_clues_found(ids: Array) -> bool:
	var rows: Array = data.get("clues", [])
	if rows.is_empty():
		return false
	for item in rows:
		if not ids.has(item["id"]):
			return false
	return true


func normalize_query(raw: String) -> String:
	var text := raw.strip_edges()
	text = text.replace("İ", "i").replace("I", "i").replace("ı", "i")
	text = text.to_lower()
	text = text.replace("ş", "s").replace("ğ", "g").replace("ü", "u")
	text = text.replace("ö", "o").replace("ç", "c").replace("ı", "i")
	var out := ""
	for i in text.length():
		var c := text[i]
		var code := c.unicode_at(0)
		var digit := code >= 48 and code <= 57
		var latin := code >= 97 and code <= 122
		if digit or latin:
			out += c
	return out


func find_esorgu(raw: String) -> Dictionary:
	var key := normalize_query(raw)
	if key == "":
		return {}
	for record in data.get("esorgu", []):
		for candidate in record["keys"]:
			if candidate == key:
				return record
	return {}


func dialogue_node(suspect_id: String, node_id: String) -> Dictionary:
	var tree: Dictionary = suspect(suspect_id).get("dialogue", {})
	return tree.get(node_id, tree.get("start", {}))


func anim_for_stress(id: String, stress: int, confessed: bool) -> String:
	if confessed or stress >= 100:
		return "BROKEN_CONFESS"
	if stress >= 70:
		return "ANGRY"
	if stress >= 50:
		return "NERVOUS_SWEAT"
	if stress >= 35:
		return "NERVOUS"
	if stress >= 15:
		return "LOOK_AWAY"
	var calm := str(suspect(id).get("calm", ""))
	return calm if calm != "" else "IDLE"


func bpm_for_stress(stress: int) -> int:
	var clamped := clampi(stress, 0, 100)
	return int(round(75.0 + (float(clamped) / 100.0) * 85.0))


func resolve_slam(suspect_id: String, clue_id: String, stress: int, already: bool) -> Dictionary:
	var person := suspect(suspect_id)
	var accepted: bool = (not already) and person["acceptedClueIds"].has(clue_id)
	var delta := 0
	if accepted:
		delta = int(person.get("stressHit", 35))
	elif not already:
		delta = 10
	var next_stress := mini(100, stress + delta)
	var confessed := next_stress >= 100
	var anim := "BROKEN_CONFESS" if confessed else ("ANGRY_SLAM" if accepted else "DEFENSIVE")
	var lines: Dictionary = person["lines"]
	var line := ""
	if already:
		line = lines["repeat"]
	elif confessed:
		line = lines["confess"]
	elif accepted:
		line = lines["hit"]
	else:
		line = lines["miss"]
	var behzat := ""
	if already:
		behzat = "Aynı kanıt ikinci kez işlemez."
	elif confessed:
		behzat = "İşte bu. Tutanağa geç."
	elif accepted:
		behzat = "Sıkıştır. Elini masadan çekmesin."
	else:
		behzat = "La bebe, yanlış dosya!"
	var kind := "hit"
	if not accepted and not already:
		kind = "other" if not clue_owners(clue_id).is_empty() else "unrelated"
	return {
		"kind": kind,
		"accepted": accepted,
		"stress": next_stress,
		"bpm": bpm_for_stress(next_stress),
		"anim": anim,
		"confessed": confessed,
		"line": line,
		"behzatLine": behzat,
	}
