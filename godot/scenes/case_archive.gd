extends RefCounted

## Dosya raflarının kaydı. Oynanış ilerlemesi user:// altında durur.

const SAVE_PATH := "user://buro_save.json"
const SETTINGS_PATH := "user://buro_settings.json"

static var store: Dictionary = {"active": "", "slots": {}}
static var settings: Dictionary = {"master": 90.0, "music": 60.0, "ambient": 60.0, "sfx": 80.0, "voice": 90.0, "fullscreen": false}
static var ready := false
static var packs: Dictionary = {}


static func boot() -> void:
	if ready:
		return
	ready = true
	_read(SAVE_PATH, store)
	_read(SETTINGS_PATH, settings)


static func remember(snap: Dictionary) -> void:
	boot()
	var id := str(snap.get("case_id", ""))
	if id == "":
		return
	store["active"] = id
	var slots: Dictionary = store.get("slots", {})
	slots[id] = snap
	store["slots"] = slots
	_write(SAVE_PATH, store)


static func slot(id: String) -> Dictionary:
	boot()
	var slots: Dictionary = store.get("slots", {})
	var found: Variant = slots.get(id, {})
	return found if found is Dictionary else {}


static func continue_id() -> String:
	boot()
	var active := str(store.get("active", ""))
	if active != "" and status(Scenario.case_row(active)) in ["Devam ediyor", "Eksik delil"]:
		return active
	for row in Scenario.catalog:
		var id := str(row.get("id", ""))
		if status(row) in ["Devam ediyor", "Eksik delil"]:
			return id
	return ""


static func status(row: Dictionary) -> String:
	boot()
	if str(row.get("status", "")) != "open":
		return "Açılmamış"
	var snap := slot(str(row.get("id", "")))
	if snap.is_empty() or not bool(snap.get("started", false)):
		return "Açılmamış"
	if bool(snap.get("sealed", false)):
		return "Kapatıldı"
	var pack := _pack(row)
	var owned: Array = snap.get("clues", [])
	var told: Dictionary = snap.get("confessed", {})
	var people: Array = pack.get("suspects", [])
	var all_told := not people.is_empty()
	for id in people:
		if not bool(told.get(id, false)):
			all_told = false
	var pages: Array = pack.get("clues", [])
	var all_pages := not pages.is_empty()
	for id in pages:
		if not owned.has(id):
			all_pages = false
	if all_told and all_pages:
		return "Çözüldü"
	if all_told:
		return "Eksik delil"
	return "Devam ediyor"


static func next_case(after_id: String) -> Dictionary:
	var rows: Array = Scenario.catalog.duplicate()
	rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(str(a.get("fileNo", "0"))) < int(str(b.get("fileNo", "0")))
	)
	var passed := false
	for row in rows:
		if str(row.get("id", "")) == after_id:
			passed = true
			continue
		if passed and str(row.get("status", "")) == "open":
			return row
	return {}


static func save_settings() -> void:
	boot()
	_write(SETTINGS_PATH, settings)


static func _pack(row: Dictionary) -> Dictionary:
	var path := str(row.get("path", ""))
	if path == "" :
		return {}
	if packs.has(path):
		return packs[path]
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	var pack := {"clues": [], "suspects": []}
	if parsed is Dictionary:
		for item in parsed.get("clues", []):
			pack["clues"].append(str(item.get("id", "")))
		for person in parsed.get("suspects", []):
			pack["suspects"].append(str(person.get("id", "")))
	packs[path] = pack
	return pack


static func _read(path: String, into: Dictionary) -> void:
	if not FileAccess.file_exists(path):
		return
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		for key in parsed.keys():
			into[key] = parsed[key]


static func _write(path: String, data: Dictionary) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify(data))
