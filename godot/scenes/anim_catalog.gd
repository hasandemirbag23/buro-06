extends RefCounted

## Ortak humanoid katalog. Her durum: grup, klip, süre, geçiş, yüz, tetik.
## Rig bunu okur; klipler kütüphaneden, duruş ofsetleri karakterde ortaktır.

const PATH := "res://data/animations.json"

static var _data: Dictionary = {}


static func data() -> Dictionary:
	if _data.is_empty():
		var parsed = JSON.parse_string(FileAccess.get_file_as_string(PATH))
		if parsed is Dictionary:
			_data = parsed
	return _data


static func resolve(action: String) -> String:
	var aliases: Dictionary = data().get("aliases", {})
	return str(aliases.get(action, action))


static func get_state(action: String) -> Dictionary:
	var states: Dictionary = data().get("states", {})
	var key := resolve(action)
	if states.has(key):
		return states[key]
	return {}


static func xfade_default() -> float:
	return float(data().get("xfade", 0.25))


static func names(group: String) -> Array[String]:
	var out: Array[String] = []
	var states: Dictionary = data().get("states", {})
	for key in states.keys():
		if str(states[key].get("group", "")) == group:
			out.append(str(key))
	return out
