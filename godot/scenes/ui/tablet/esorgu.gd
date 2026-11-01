extends Control

## E-Sorgu: isim, plaka, şirket ve telefon alanları; sonuç kartları GameState geçmişinden.

const Kit := preload("res://scenes/ui/tablet/tablet_kit.gd")
const UiStyle := preload("res://scenes/ui_style.gd")

var fields := {}
var results: VBoxContainer
var built := false
var built_case := ""
var shown := -1


func render() -> void:
	if not built or built_case != Scenario.case_id:
		for child in get_children():
			child.queue_free()
		fields = {}
		_build()
		built = true
		built_case = Scenario.case_id
		shown = -1
	if shown == GameState.esorgu_history.size():
		return
	shown = GameState.esorgu_history.size()
	for child in results.get_children():
		child.queue_free()
	if GameState.esorgu_history.is_empty():
		results.add_child(UiStyle.label("Sorgu bekleniyor. İsim, plaka, şirket ya da telefon gir.", 14, UiStyle.MUTED))
		return
	for hit in GameState.esorgu_history:
		var found: bool = hit["found"]
		var card := Kit.panel(Kit.CARD, UiStyle.CRT if found else UiStyle.DANGER, 10)
		var column := VBoxContainer.new()
		column.add_theme_constant_override("separation", 4)
		card.add_child(column)
		var status := "KAYIT BULUNDU" if found else "KAYIT YOK"
		column.add_child(Kit.line("%s   ·   %s" % [status, hit.get("query", "")], 12, UiStyle.CRT if found else UiStyle.DANGER, true))
		column.add_child(UiStyle.label(str(hit["title"]), 18, UiStyle.INK))
		column.add_child(UiStyle.label(str(hit["body"]), 14, UiStyle.MUTED))
		results.add_child(card)


func _build() -> void:
	var column := VBoxContainer.new()
	Kit.cover(column)
	column.add_theme_constant_override("separation", 8)
	add_child(column)
	column.add_child(Kit.line("GBT   ·   PTS   ·   HTS", 12, UiStyle.CRT, true))
	var grid := GridContainer.new()
	grid.columns = 1 if get_viewport_rect().size.x < 760 else 2
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 6)
	column.add_child(grid)
	for key in ["İsim", "Plaka", "Şirket", "Telefon"]:
		var box := VBoxContainer.new()
		box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		box.add_child(Kit.line(key.to_upper(), 11, UiStyle.MUTED, true))
		var line := LineEdit.new()
		line.placeholder_text = key
		line.custom_minimum_size = Vector2(0, 38)
		box.add_child(line)
		fields[key] = line
		grid.add_child(box)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	column.add_child(row)
	var go := UiStyle.button("Sorgula")
	go.pressed.connect(_search)
	row.add_child(go)
	for hint in Scenario.data.get("esorguHints", []):
		var chip := UiStyle.button(str(hint["text"]))
		chip.add_theme_font_size_override("font_size", 13)
		chip.custom_minimum_size = Vector2(0, 34)
		chip.pressed.connect(_hint.bind(str(hint["text"]), str(hint.get("field", "İsim"))))
		row.add_child(chip)
	results = VBoxContainer.new()
	results.add_theme_constant_override("separation", 8)
	results.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_child(Kit.scroll(results))


func _hint(text: String, key: String) -> void:
	for name in fields.keys():
		fields[name].text = ""
	if fields.has(key):
		fields[key].text = text
	_search()


func _search() -> void:
	var query := ""
	for key in ["İsim", "Plaka", "Şirket", "Telefon"]:
		var text: String = fields[key].text.strip_edges()
		if text != "":
			query = text
			break
	GameState.search_esorgu(query)
