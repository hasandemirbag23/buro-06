extends Control

## Dosyalar: soruşturma, otopsi, olay yeri ve resmi belgeler. Kilitli olanlar kırmızı.

const Kit := preload("res://scenes/ui/tablet/tablet_kit.gd")
const UiStyle := preload("res://scenes/ui_style.gd")

var stamp := ""


func render() -> void:
	var next := Scenario.case_id + "|" + "|".join(GameState.clues) + "|" + "|".join(GameState.inspected)
	if next == stamp and get_child_count() > 0:
		return
	stamp = next
	for child in get_children():
		child.queue_free()
	var column := VBoxContainer.new()
	Kit.cover(column)
	column.add_theme_constant_override("separation", 8)
	add_child(column)
	column.add_child(Kit.line(Scenario.file_label().to_upper() + "  ·  ARŞİV", 12, UiStyle.MUTED, true))
	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 8)
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_child(Kit.scroll(list))
	var current := ""
	for doc in _docs():
		if doc["cat"] != current:
			current = doc["cat"]
			list.add_child(Kit.line(current.to_upper(), 13, UiStyle.LAMP, true))
		var open: bool = doc["open"]
		var card := Kit.panel(Kit.CARD, UiStyle.DANGER if not open else Kit.LINE, 10)
		var body := VBoxContainer.new()
		body.add_theme_constant_override("separation", 3)
		card.add_child(body)
		body.add_child(Kit.line(doc["title"], 16, UiStyle.INK if open else UiStyle.DANGER))
		if open:
			body.add_child(UiStyle.label(doc["body"], 14, UiStyle.MUTED))
		else:
			body.add_child(Kit.line("GİZLİ  ·  kanıt gerekli", 12, UiStyle.DANGER, true))
		list.add_child(card)


func _docs() -> Array:
	var out: Array = []
	out.append({"cat": "Soruşturma", "title": "Dosya No %s — ön rapor" % str(Scenario.data.get("fileNo", "")), "body": str(Scenario.data.get("briefing", "")), "open": true})
	var autopsy: Dictionary = Scenario.data.get("autopsy", {})
	if not autopsy.is_empty():
		out.append({
			"cat": "Otopsi",
			"title": str(autopsy.get("title", "Ön otopsi notu")),
			"body": str(autopsy.get("body", "")),
			"open": GameState.clues.has(str(autopsy.get("clue", ""))),
		})
	for spot in Scenario.data.get("hotspots", []):
		out.append({"cat": "Olay Yeri", "title": str(spot["title"]), "body": str(spot["text"]), "open": GameState.inspected.has(spot["id"])})
	for id in GameState.clues:
		var found := Scenario.clue(id)
		if found.get("source", "") in ["esorgu", "phone"]:
			out.append({"cat": "Resmi Belgeler", "title": str(found.get("title", "")), "body": str(found.get("summary", "")), "open": true})
	if GameState.case_is_closed():
		out.append({"cat": "Soruşturma", "title": "Kapanış tutanağı", "body": str(Scenario.data.get("report", "")), "open": true})
	return out
