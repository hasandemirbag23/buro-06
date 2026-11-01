extends RefCounted

## data/character_profiles.json okuyucusu. Kişilik değerleri 0..1; eksik değer 0.5.

const PATH := "res://data/character_profiles.json"
const TRAITS := ["confidence", "patience", "aggression", "curiosity", "sociability", "stress_resistance"]

static var _data: Dictionary = {}


static func all() -> Dictionary:
	if _data.is_empty():
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH))
		if parsed is Dictionary:
			_data = parsed
	return _data


static func has_profile(id: String) -> bool:
	return all().has(id) and id != "_doc"


static func profile(id: String) -> Dictionary:
	var raw: Dictionary = all().get(id, {})
	var out := {
		"first_name": str(raw.get("first_name", id)),
		"last_name": str(raw.get("last_name", "")),
		"role": str(raw.get("role", "npc")),
		"traits": raw.get("traits", []),
		"voice": raw.get("voice", {"pitch": 1.0}),
		"personality": personality(id),
	}
	return out


static func personality(id: String) -> Dictionary:
	var raw: Dictionary = all().get(id, {}).get("personality", {})
	var out := {}
	for key in TRAITS:
		out[key] = clampf(float(raw.get(key, 0.5)), 0.0, 1.0)
	return out
