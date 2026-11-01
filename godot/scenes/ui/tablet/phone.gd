extends Control

## Maktulün telefonu: PIN, galeri, mesajlar, banka, notlar, silinen dosyalar.

const Kit := preload("res://scenes/ui/tablet/tablet_kit.gd")
const UiStyle := preload("res://scenes/ui_style.gd")

const SECTIONS := [
	{"id": "gallery", "mark": "GL", "title": "Galeri"},
	{"id": "messages", "mark": "MS", "title": "Mesajlar"},
	{"id": "bank", "mark": "BN", "title": "Banka"},
	{"id": "notes", "mark": "NT", "title": "Notlar"},
	{"id": "deleted", "mark": "SL", "title": "Silinenler"},
	{"id": "mail", "mark": "YZ", "title": "Yazışma"},
]

var screen := "home"
var pin_buffer := ""
var stamp := ""
var stamp_case := ""


func render() -> void:
	if stamp_case != Scenario.case_id:
		stamp_case = Scenario.case_id
		screen = "home"
		pin_buffer = ""
		stamp = ""
	var next := "%s|%s|%s|%s|%s" % [screen, pin_buffer, GameState.phone_unlocked, GameState.pin_error, "|".join(GameState.clues)]
	if next == stamp and get_child_count() > 0:
		return
	stamp = next
	for child in get_children():
		child.queue_free()
	if not GameState.phone_ready():
		_gate("Telefon olay yerinde.", "Cesedin yanındaki cihaz delil poşetine girmeden açılmaz.")
		return
	if not GameState.phone_unlocked:
		_pin()
		return
	if screen == "home":
		if Scenario.case_id == "episode_01":
			_home()
		else:
			_item_home()
	else:
		_section()


func _gate(title: String, text: String) -> void:
	var column := VBoxContainer.new()
	Kit.cover(column)
	column.add_theme_constant_override("separation", 8)
	add_child(column)
	column.add_child(UiStyle.label(title, 24, UiStyle.DANGER))
	column.add_child(UiStyle.label(text, 15, UiStyle.MUTED))


func _pin() -> void:
	var column := VBoxContainer.new()
	Kit.cover(column)
	column.add_theme_constant_override("separation", 8)
	add_child(column)
	column.add_child(Kit.line("MAKTULÜN TELEFONU", 12, UiStyle.MUTED, true))
	column.add_child(UiStyle.label("Şifre", 26, UiStyle.INK))
	var hint_id := str(Scenario.data.get("pinHintClue", "clue_desk_photo"))
	var hint := str(Scenario.data.get("pinHint", "4 hane.")) if GameState.clues.has(hint_id) else str(Scenario.data.get("pinLocked", "4 hane."))
	column.add_child(UiStyle.label(hint, 14, UiStyle.MUTED))
	column.add_child(Kit.line(pin_buffer.lpad(4, "·"), 34, UiStyle.LAMP, true))
	if GameState.pin_error:
		column.add_child(Kit.line("Hatalı şifre", 14, UiStyle.DANGER, true))
	var keys := GridContainer.new()
	keys.columns = 3
	keys.add_theme_constant_override("h_separation", 6)
	keys.add_theme_constant_override("v_separation", 6)
	column.add_child(keys)
	for key in ["1", "2", "3", "4", "5", "6", "7", "8", "9", "C", "0"]:
		var button := UiStyle.button(key)
		button.custom_minimum_size = Vector2(72, 46)
		button.pressed.connect(_press.bind(key))
		keys.add_child(button)


func _press(key: String) -> void:
	if key == "C":
		pin_buffer = ""
	else:
		pin_buffer = (pin_buffer + key).substr(0, 4)
		if pin_buffer.length() == 4:
			var pin := pin_buffer
			pin_buffer = ""
			GameState.try_pin(pin)
			return
	stamp = ""
	render()


func _item_home() -> void:
	var column := VBoxContainer.new()
	Kit.cover(column)
	column.add_theme_constant_override("separation", 8)
	add_child(column)
	column.add_child(Kit.line("MAKTULÜN TELEFONU  ·  kilit açık", 12, UiStyle.CRT, true))
	for item in Scenario.data.get("phoneItems", []):
		var button := UiStyle.button(str(item.get("title", "")))
		button.pressed.connect(_open.bind(str(item["id"])))
		column.add_child(button)


func _home() -> void:
	var column := VBoxContainer.new()
	Kit.cover(column)
	column.add_theme_constant_override("separation", 10)
	add_child(column)
	column.add_child(Kit.line("MAKTULÜN TELEFONU  ·  kilit açık", 12, UiStyle.CRT, true))
	var grid := GridContainer.new()
	grid.columns = 3 if get_viewport_rect().size.x < 860 else 5
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	column.add_child(grid)
	for section in SECTIONS:
		var button := UiStyle.button(section["mark"] + "\n" + section["title"])
		button.custom_minimum_size = Vector2(96, 72)
		button.add_theme_font_size_override("font_size", 14)
		button.pressed.connect(_open.bind(section["id"]))
		grid.add_child(button)


func _open(next: String) -> void:
	screen = next
	stamp = ""
	render()


func _section() -> void:
	var column := VBoxContainer.new()
	Kit.cover(column)
	column.add_theme_constant_override("separation", 8)
	add_child(column)
	var back := UiStyle.button("‹ Telefon")
	back.custom_minimum_size = Vector2(0, 34)
	back.pressed.connect(_open.bind("home"))
	column.add_child(back)
	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 8)
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_child(Kit.scroll(body))
	match screen:
		"gallery":
			_gallery(body)
		"messages":
			_record(body, "sms_zafer", "MESAJLAR")
		"bank":
			_record(body, "bank", "BANKA")
		"notes":
			_record(body, "notes", "NOTLAR")
		"deleted":
			body.add_child(Kit.line("SİLİNMİŞ DOSYALAR  ·  kurtarıldı", 12, UiStyle.DANGER, true))
			_record(body, "sms_concert", "SİLİNEN")
		"mail":
			_record(body, "mail", "YAZIŞMA")
		_:
			_record(body, screen, "KAYIT")


func _gallery(body: VBoxContainer) -> void:
	body.add_child(Kit.line("GALERİ", 12, UiStyle.MUTED, true))
	var shots := [
		{"id": "clue_desk_photo", "title": "Şantiye masası", "color": Color("8a6a3a")},
		{"id": "clue_cracked_column", "title": "Çatlak kolon", "color": Color("6a675f")},
		{"id": "clue_suv_photo", "title": "SUV izi", "color": Color("3a4450")},
		{"id": "clue_victim_phone", "title": "Kırık ekran", "color": Color("2a2e33")},
	]
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	body.add_child(grid)
	for shot in shots:
		var known: bool = GameState.clues.has(shot["id"])
		var card := Kit.panel(shot["color"] if known else Kit.CARD, Kit.LINE, 8)
		card.custom_minimum_size = Vector2(160, 110)
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var label := Kit.line(shot["title"] if known else "boş kare", 14, UiStyle.INK if known else UiStyle.MUTED, true)
		card.add_child(label)
		grid.add_child(card)


func _record(body: VBoxContainer, item_id: String, heading: String) -> void:
	var item := Scenario.phone_item(item_id)
	if item.is_empty():
		return
	body.add_child(Kit.line(heading, 12, UiStyle.MUTED, true))
	var known: bool = GameState.clues.has(item["unlocksClueId"])
	var card := Kit.panel(Kit.CARD, UiStyle.CRT if known else UiStyle.LAMP, 10)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 6)
	card.add_child(column)
	column.add_child(UiStyle.label(str(item["title"]), 18, UiStyle.INK))
	if known:
		column.add_child(UiStyle.label(str(item["body"]), 14, UiStyle.MUTED))
		column.add_child(Kit.line("Dosyada", 12, UiStyle.CRT, true))
	else:
		var button := UiStyle.button("Aç ve dosyaya işle")
		button.pressed.connect(GameState.open_phone_item.bind(item_id))
		column.add_child(button)
	body.add_child(card)
