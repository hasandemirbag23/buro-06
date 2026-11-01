extends Node

## Üç dosyayı da baştan sona oynar: kanıt, PIN, telefon, E-Sorgu, bağlantı, gözaltı, sorgu, itiraf, kapanış.
## Çalıştır: godot --headless --path . res://tests/episodes_test.tscn

var fails := 0


func check(ok: bool, label: String) -> void:
	if not ok:
		fails += 1
		print("FAIL  ", label)


func _ready() -> void:
	for row in Scenario.catalog:
		if str(row.get("status", "")) != "open":
			continue
		_play(str(row["id"]))
	print("EPISODES_", "OK" if fails == 0 else "FAIL %d" % fails)
	get_tree().quit(0 if fails == 0 else 1)


func _play(id: String) -> void:
	check(GameState.open_case(id), "%s açıldı" % id)
	GameState.incoming_call = false
	var data := Scenario.data
	check(not GameState.travel("interrogation"), "%s: kanıtsız gözaltı kapalı" % id)
	GameState.brief()
	for spot in data["hotspots"]:
		GameState.inspect_hotspot(str(spot["id"]))
		GameState.dismiss_clue()
	check(GameState.phone_ready(), "%s: telefon delili" % id)
	check(not GameState.try_pin("0000"), "%s: yanlış PIN" % id)
	check(GameState.try_pin(str(data["pin"])), "%s: doğru PIN" % id)
	for item in data["phoneItems"]:
		GameState.open_phone_item(str(item["id"]))
	for hint in data["esorguHints"]:
		GameState.search_esorgu(str(hint["text"]))
	for query in ["otopsi", "dna", "villa", "kasa"]:
		GameState.search_esorgu(query)
	var missing: Array[String] = []
	for clue in data["clues"]:
		if not GameState.clues.has(str(clue["id"])):
			missing.append(str(clue["id"]))
	check(missing.is_empty(), "%s: ulaşılamayan kanıtlar %s" % [id, str(missing)])
	check(GameState.arrest_unlocked(), "%s: gözaltı açıldı" % id)
	check(GameState.travel("interrogation"), "%s: sorgu odasına geçildi" % id)
	for person in data["suspects"]:
		var sid := str(person["id"])
		GameState.select_suspect(sid)
		for clue_id in person["acceptedClueIds"]:
			if GameState.clues.has(clue_id):
				GameState.slam_evidence(clue_id)
		check(bool(GameState.confessed[sid]), "%s: %s itiraf etti" % [id, sid])
	check(GameState.case_is_closed(), "%s: dosya kapandı" % id)
