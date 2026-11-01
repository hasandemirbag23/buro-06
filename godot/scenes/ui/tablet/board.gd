extends Control

## Mantar kanıt panosu: sürükleme, yakınlaştırma, kırmızı ip, ayrıntı, çelişki.

const Kit := preload("res://scenes/ui/tablet/tablet_kit.gd")
const UiStyle := preload("res://scenes/ui_style.gd")

const CORK := Vector2(1500, 980)
const PAIRS := [
	["clue_suv_photo", "clue_pts_06kzy44"],
	["clue_bank_500k", "clue_company_record"],
	["clue_zafer_sms", "clue_concrete_report"],
	["clue_hts_tarik", "clue_pts_06kzy44"],
	["clue_victim_phone", "clue_no_suicide"],
	["who_emre", "clue_victim_phone"],
	["who_emre", "clue_bank_500k"],
	["who_emre", "clue_zafer_sms"],
	["who_tarik", "who_kuzey"],
	["who_tarik", "who_plate"],
	["who_tarik", "clue_hts_tarik"],
	["who_kuzey", "clue_bank_500k"],
	["who_kuzey", "clue_company_record"],
	["who_zafer", "clue_zafer_sms"],
	["who_zafer", "clue_concrete_report"],
	["who_plate", "clue_suv_photo"],
	["who_plate", "clue_pts_06kzy44"],
	["doc_suicide", "clue_no_suicide"],
]

## kind: name, photo, slip, map, doc. rule: always | any | clue.
const SPEC := {
	"who_emre": {"title": "Emre Karaca", "kind": "name", "rule": "clue", "needs": ["clue_victim_phone"], "at": Vector2(36, 28), "size": Vector2(168, 78), "text": "Maktul. Vadi Kule mühendisi. 14. kattan düşmüş."},
	"who_zafer": {"title": "Zafer Yılmaz", "kind": "name", "rule": "clue", "needs": ["clue_zafer_sms"], "at": Vector2(230, 36), "size": Vector2(150, 78), "text": "Şantiye şefi. Emre'yi 01:00'de konteynere çağırmış. Sicilinde mühür bozma var."},
	"who_tarik": {"title": "Tarık Soylu", "kind": "name", "rule": "clue", "needs": ["clue_company_record", "clue_hts_tarik", "clue_pts_06kzy44"], "at": Vector2(430, 24), "size": Vector2(168, 78), "text": "Kuzey Hafriyat yetkilisi. Hattı ve aracı cinayet saatinde şantiyede."},
	"who_kuzey": {"title": "Kuzey Hafriyat A.Ş.", "kind": "name", "rule": "clue", "needs": ["clue_company_record", "clue_bank_500k"], "at": Vector2(660, 40), "size": Vector2(200, 78), "text": "Alt yüklenici. Emre'ye cinayetten bir gün önce 500.000 TL göndermiş."},
	"who_plate": {"title": "06 KZY 44", "kind": "name", "rule": "clue", "needs": ["clue_suv_photo", "clue_pts_06kzy44"], "at": Vector2(920, 28), "size": Vector2(168, 78), "text": "Siyah SUV. Tescil Tarık Soylu. 01:12 giriş, 01:47 çıkış."},
	"map_vadi": {"title": "Vadi Kule", "kind": "map", "rule": "any", "needs": [], "at": Vector2(36, 150), "size": Vector2(200, 130), "text": "Ankara, şantiye. 14. kat boş. Kamera 03 kapıda."},
	"doc_suicide": {"title": "İntihar tutanağı", "kind": "doc", "rule": "always", "needs": [], "at": Vector2(270, 160), "size": Vector2(170, 110), "text": "Resmi satır: Emre Karaca 14. kattan atlamış. Tanık yok."},
	"clue_victim_phone": {"title": "", "kind": "photo", "rule": "clue", "needs": ["clue_victim_phone"], "at": Vector2(36, 340), "size": Vector2(146, 168)},
	"clue_desk_photo": {"title": "", "kind": "photo", "rule": "clue", "needs": ["clue_desk_photo"], "at": Vector2(220, 360), "size": Vector2(146, 168)},
	"clue_cracked_column": {"title": "", "kind": "photo", "rule": "clue", "needs": ["clue_cracked_column"], "at": Vector2(480, 200), "size": Vector2(146, 168)},
	"clue_suv_photo": {"title": "", "kind": "photo", "rule": "clue", "needs": ["clue_suv_photo"], "at": Vector2(700, 200), "size": Vector2(146, 168)},
	"clue_bank_500k": {"title": "", "kind": "slip", "rule": "clue", "needs": ["clue_bank_500k"], "at": Vector2(900, 150), "size": Vector2(170, 120)},
	"clue_company_record": {"title": "", "kind": "doc", "rule": "clue", "needs": ["clue_company_record"], "at": Vector2(1120, 150), "size": Vector2(160, 110)},
	"clue_pts_06kzy44": {"title": "", "kind": "doc", "rule": "clue", "needs": ["clue_pts_06kzy44"], "at": Vector2(980, 340), "size": Vector2(160, 110)},
	"clue_hts_tarik": {"title": "", "kind": "doc", "rule": "clue", "needs": ["clue_hts_tarik"], "at": Vector2(1180, 340), "size": Vector2(160, 110)},
	"clue_zafer_sms": {"title": "", "kind": "doc", "rule": "clue", "needs": ["clue_zafer_sms"], "at": Vector2(250, 620), "size": Vector2(160, 110)},
	"clue_concrete_report": {"title": "", "kind": "doc", "rule": "clue", "needs": ["clue_concrete_report"], "at": Vector2(480, 560), "size": Vector2(160, 110)},
	"clue_no_suicide": {"title": "", "kind": "doc", "rule": "clue", "needs": ["clue_no_suicide"], "at": Vector2(36, 620), "size": Vector2(170, 110)},
}
const PHOTO := {
	"clue_victim_phone": Color("2c3138"),
	"clue_desk_photo": Color("8a6a3a"),
	"clue_cracked_column": Color("6a675f"),
	"clue_suv_photo": Color("3a4450"),
}

var cards := {}
var stamp := ""
var link_from := ""
var primed := false
var shown := {}
var animating := 0
var zoom := 1.0
var pan := Vector2.ZERO
var fitted := false
var touch := {}
var pinch := 0.0
var viewport: Control
var cork: Control
var threads: Threads
var status: Label
var banner: Label
var detail: PanelContainer
var detail_title: Label
var detail_body: Label
var detail_flag: Label
var detail_id := ""

class Threads extends Control:
	func _draw() -> void:
		var board := get_parent().get_parent().get_parent() as Control
		var cards: Dictionary = board.get("cards")
		for key in GameState.board_links:
			board.call("_string", self, cards, key, false)
		var clash := str(Scenario.data.get("contradiction", ""))
		var parts := clash.split("|")
		if parts.size() == 2 and GameState.clues.has(parts[0]):
			board.call("_string", self, cards, clash, true)


var built_case := ""
var _sheet_case := ""
var _sheet: Dictionary = {}


func sheet() -> Dictionary:
	if _sheet_case == Scenario.case_id and not _sheet.is_empty():
		return _sheet
	_sheet_case = Scenario.case_id
	if Scenario.case_id == "episode_01":
		_sheet = SPEC
	else:
		_sheet = _grid_sheet()
	return _sheet


func links() -> Array:
	if Scenario.case_id == "episode_01":
		return PAIRS
	var rows: Array = Scenario.data.get("pairs", [])
	return rows


func _grid_sheet() -> Dictionary:
	var out: Dictionary = {}
	var index := 0
	for item in Scenario.data.get("clues", []):
		_pin_card(out, str(item["id"]), "", "doc", "clue", [str(item["id"])], "", index)
		index += 1
	for person in Scenario.data.get("suspects", []):
		var who := "who_" + str(person["id"])
		_pin_card(out, who, str(person["character"]["name"]), "name", "any", [], str(person["lines"]["idle"]), index)
		index += 1
	return out


func _pin_card(out: Dictionary, id: String, title: String, kind: String, rule: String, needs: Array, text: String, index: int) -> void:
	var col := index % 4
	var row := int(index / 4.0)
	var card := {
		"title": title,
		"kind": kind,
		"rule": rule,
		"needs": needs,
		"at": Vector2(40 + col * 280, 40 + row * 200),
		"size": Vector2(220, 120 if kind != "name" else 88),
	}
	if text != "":
		card["text"] = text
	out[id] = card


func render() -> void:
	if viewport == null or built_case != Scenario.case_id:
		_rebuild()
	var next := "%s|%s|%s|%s" % [Scenario.case_id, link_from, "|".join(GameState.clues), "|".join(GameState.board_links)]
	if next == stamp:
		return
	stamp = next
	_sync()
	if threads:
		threads.queue_redraw()


func _rebuild() -> void:
	for child in get_children():
		remove_child(child)
		child.free()
	viewport = null
	cork = null
	threads = null
	status = null
	banner = null
	detail = null
	cards = {}
	shown = {}
	primed = false
	stamp = ""
	_sheet_case = ""
	built_case = Scenario.case_id
	_build()


func _build() -> void:
	var bar := HBoxContainer.new()
	bar.set_anchors_preset(Control.PRESET_TOP_WIDE)
	bar.offset_bottom = 44
	bar.add_theme_constant_override("separation", 6)
	bar.add_child(_zoom_button("−", 0.86))
	bar.add_child(_zoom_button("+", 1.16))
	var fit := UiStyle.button("Sığdır")
	fit.custom_minimum_size = Vector2(64, 40)
	fit.pressed.connect(_fit_view)
	bar.add_child(fit)
	status = Kit.line("0 delil", 13, UiStyle.DANGER, true)
	status.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.add_child(status)
	add_child(bar)
	banner = Kit.line("", 13, UiStyle.LAMP, true)
	banner.position = Vector2(8, 46)
	add_child(banner)
	viewport = Control.new()
	viewport.clip_contents = true
	viewport.mouse_filter = Control.MOUSE_FILTER_STOP
	viewport.anchor_left = 0
	viewport.anchor_top = 0
	viewport.anchor_right = 1
	viewport.anchor_bottom = 1
	viewport.offset_top = 68
	viewport.offset_bottom = 0
	viewport.gui_input.connect(_view_input)
	viewport.resized.connect(_on_view_resized)
	add_child(viewport)
	cork = Control.new()
	cork.custom_minimum_size = CORK
	cork.size = CORK
	cork.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var wood := ColorRect.new()
	wood.color = Color("7a4e2d")
	wood.size = CORK
	wood.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cork.add_child(wood)
	var grain := ColorRect.new()
	grain.color = Color(0.35, 0.2, 0.1, 0.25)
	grain.position = Vector2(0, 180)
	grain.size = Vector2(CORK.x, 8)
	grain.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cork.add_child(grain)
	threads = Threads.new()
	threads.size = CORK
	threads.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cork.add_child(threads)
	viewport.add_child(cork)
	for id in sheet().keys():
		cards[id] = _card(id)
		cork.add_child(cards[id])
	_build_detail()
	move_child(banner, get_child_count() - 1)


func _zoom_button(text: String, factor: float) -> Button:
	var button := UiStyle.button(text)
	button.custom_minimum_size = Vector2(44, 40)
	button.pressed.connect(func() -> void:
		_zoom_at(viewport.size * 0.5, factor)
	)
	return button


func _card(id: String) -> PanelContainer:
	var spec: Dictionary = sheet()[id]
	var found := Scenario.clue(id)
	var title := str(spec["title"]) if str(spec["title"]) != "" else str(found.get("title", id))
	var size: Vector2 = spec["size"]
	var kind := str(spec["kind"])
	var card := PanelContainer.new()
	card.custom_minimum_size = size
	card.size = size
	card.pivot_offset = size * 0.5
	card.mouse_filter = Control.MOUSE_FILTER_STOP
	card.visible = false
	var paper := Color("e7d7b1")
	var ink := Color("2a2118")
	if kind == "slip":
		paper = Color("d7ead0")
	elif kind == "map":
		paper = Color("d8c7a1")
	elif kind == "name":
		paper = Color("f4efe6")
	card.add_theme_stylebox_override("panel", Kit.box(paper, Color("cbb892"), 3, 1, 6))
	var column := VBoxContainer.new()
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_theme_constant_override("separation", 3)
	card.add_child(column)
	if kind == "photo":
		var shot := ColorRect.new()
		shot.custom_minimum_size = Vector2(size.x - 16, 78)
		shot.color = PHOTO.get(id, Color("333333"))
		shot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		column.add_child(shot)
	elif kind == "map":
		var plate := ColorRect.new()
		plate.custom_minimum_size = Vector2(size.x - 16, 52)
		plate.color = Color("c4b48a")
		plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
		column.add_child(plate)
		var road := ColorRect.new()
		road.color = Color("8a3a32")
		road.position = Vector2(8, 24)
		road.size = Vector2(size.x - 36, 3)
		road.mouse_filter = Control.MOUSE_FILTER_IGNORE
		plate.add_child(road)
	elif kind == "slip":
		var amount := Kit.line("500.000 TL", 16, Color("1e3a32"), true)
		amount.mouse_filter = Control.MOUSE_FILTER_IGNORE
		column.add_child(amount)
	var caption := Kit.line(title, 12, ink)
	caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	caption.custom_minimum_size = Vector2(size.x - 16, 28)
	caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(caption)
	var pin_row := CenterContainer.new()
	pin_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pin_row.custom_minimum_size = Vector2(0, 12)
	var pin := ColorRect.new()
	pin.custom_minimum_size = Vector2(10, 10)
	pin.color = UiStyle.DANGER
	pin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pin_row.add_child(pin)
	column.add_child(pin_row)
	column.move_child(pin_row, 0)
	var flag := Kit.line("ÇELİŞKİ", 11, UiStyle.DANGER, true)
	flag.name = "Flag"
	flag.visible = false
	flag.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(flag)
	card.gui_input.connect(_touch.bind(id, card))
	return card


func _build_detail() -> void:
	detail = PanelContainer.new()
	detail.visible = false
	detail.mouse_filter = Control.MOUSE_FILTER_STOP
	detail.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	detail.offset_top = -210
	detail.offset_bottom = -8
	detail.offset_left = 8
	detail.offset_right = -8
	detail.add_theme_stylebox_override("panel", Kit.box(Color("14171d"), UiStyle.LAMP, 10, 1, 12))
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 6)
	detail.add_child(column)
	detail_title = Kit.line("", 16, UiStyle.LAMP, true)
	column.add_child(detail_title)
	detail_flag = Kit.line("ÇELİŞKİ  ·  bu delil resmî tutanakla çelişiyor.", 13, UiStyle.DANGER, true)
	detail_flag.visible = false
	column.add_child(detail_flag)
	detail_body = UiStyle.label("", 14, UiStyle.INK)
	detail_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail_body.custom_minimum_size = Vector2(0, 48)
	column.add_child(detail_body)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	var link := UiStyle.button("İp ger")
	link.custom_minimum_size = Vector2(96, 44)
	link.pressed.connect(_arm_link)
	row.add_child(link)
	var close := UiStyle.button("Kapat")
	close.custom_minimum_size = Vector2(84, 44)
	close.pressed.connect(_close_detail)
	row.add_child(close)
	column.add_child(row)
	add_child(detail)


func _sync() -> void:
	var count := 0
	for id in cards.keys():
		var card: Control = cards[id]
		var on := _owned(id)
		card.visible = on
		if on:
			count += 1
		var flag := card.find_child("Flag", true, false)
		if flag is CanvasItem:
			(flag as CanvasItem).visible = _conflict(id)
		var border := UiStyle.DANGER if id == link_from or _conflict(id) else Color("cbb892")
		var paper := Color("f4efe6")
		var kind := str(sheet()[id]["kind"])
		if kind == "slip":
			paper = Color("d7ead0")
		elif kind == "map":
			paper = Color("d8c7a1")
		elif kind == "photo" or kind == "doc":
			paper = Color("e7d7b1")
		card.add_theme_stylebox_override("panel", Kit.box(paper, border, 3, 2 if id == link_from or _conflict(id) else 1, 6))
		if on and not shown.has(id):
			shown[id] = true
			if primed:
				_fly(card)
			else:
				card.position = sheet()[id]["at"]
	var rows: Array = Scenario.data.get("clues", [])
	var total := rows.size()
	var got := GameState.clues.size()
	if got >= total and total > 0:
		status.text = "Bütün deliller panoda."
		status.add_theme_color_override("font_color", UiStyle.CRT)
	else:
		status.text = "%d / %d delil  ·  eksikken dosya kapanmaz" % [got, total]
		status.add_theme_color_override("font_color", UiStyle.DANGER)
	banner.text = "İkinci karta bas." if link_from != "" else ""
	primed = true
	_layout()


func _layout() -> void:
	for id in cards.keys():
		var card: Control = cards[id]
		if card.get_meta("moved", false) or card.get_meta("anim", false):
			continue
		card.position = sheet()[id]["at"]


func _owned(id: String) -> bool:
	var spec: Dictionary = sheet()[id]
	var rule := str(spec["rule"])
	if rule == "always":
		return true
	if rule == "any":
		return GameState.clues.size() > 0
	for need in spec["needs"]:
		if GameState.clues.has(str(need)):
			return true
	return false


func _conflict(id: String) -> bool:
	var parts := str(Scenario.data.get("contradiction", "")).split("|")
	if parts.size() != 2:
		return false
	return GameState.clues.has(parts[0]) and (id == parts[0] or id == parts[1])


func _fly(card: Control) -> void:
	var dest := _dest(card)
	card.set_meta("anim", true)
	card.modulate.a = 0.0
	card.scale = Vector2(0.35, 0.35)
	card.position = dest + Vector2(40, -50)
	animating += 1
	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(card, "position", dest, 0.38).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(card, "scale", Vector2.ONE, 0.38).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(card, "modulate:a", 1.0, 0.22)
	tween.tween_callback(func() -> void:
		card.set_meta("anim", false)
		animating = maxi(0, animating - 1)
		if threads:
			threads.queue_redraw()
	)


func _dest(card: Control) -> Vector2:
	for id in cards.keys():
		if cards[id] == card:
			return sheet()[id]["at"]
	return card.position


func _process(_delta: float) -> void:
	if animating > 0 and threads:
		threads.queue_redraw()


func _touch(event: InputEvent, id: String, card: Control) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			card.set_meta("press", event.position)
			card.set_meta("origin", card.position)
			cork.move_child(card, cork.get_child_count() - 1)
		else:
			var start: Vector2 = card.get_meta("press", event.position)
			if start.distance_to(event.position) < 10.0:
				_tap(id)
			else:
				card.set_meta("moved", true)
			if threads:
				threads.queue_redraw()
		card.accept_event()
	elif event is InputEventMouseMotion and event.button_mask & MOUSE_BUTTON_MASK_LEFT:
		var start: Vector2 = card.get_meta("press", event.position)
		var origin: Vector2 = card.get_meta("origin", card.position)
		card.position = origin + (event.position - start)
		card.set_meta("moved", true)
		if threads:
			threads.queue_redraw()
		card.accept_event()


func _tap(id: String) -> void:
	if link_from != "" and link_from != id:
		var fresh := GameState.link_clues(link_from, id)
		GameState.notice = "İp gerildi." if fresh else "Bu ip zaten var."
		if fresh and not _strong(link_from, id):
			GameState.notice = "İp zayıf. Panoda duruyor."
		if _conflict(id) or _conflict(link_from):
			GameState.notice = "Çelişki işaretlendi."
		link_from = ""
		stamp = ""
		GameState.updated.emit()
		return
	if link_from == id:
		link_from = ""
		stamp = ""
		render()
		return
	_open_detail(id)


func _open_detail(id: String) -> void:
	detail_id = id
	var spec: Dictionary = sheet()[id]
	var found := Scenario.clue(id)
	var title := str(spec["title"]) if str(spec["title"]) != "" else str(found.get("title", ""))
	detail_title.text = title
	var body := str(spec["text"]) if spec.has("text") else str(found.get("summary", ""))
	var hints: PackedStringArray = []
	for other in _partners(id):
		hints.append(_title_of(other))
	if hints.size() > 0:
		body += "\nİp adayı: " + ", ".join(hints)
	detail_body.text = body
	detail_flag.visible = _conflict(id)
	detail.visible = true


func _title_of(id: String) -> String:
	var spec: Dictionary = sheet().get(id, {})
	if str(spec.get("title", "")) != "":
		return str(spec["title"])
	return str(Scenario.clue(id).get("title", id))


func _partners(id: String) -> Array[String]:
	var out: Array[String] = []
	for pair in links():
		var other := ""
		if pair[0] == id:
			other = pair[1]
		elif pair[1] == id:
			other = pair[0]
		if other != "" and _owned(other) and not out.has(other):
			out.append(other)
	return out


func _arm_link() -> void:
	if detail_id == "":
		return
	link_from = detail_id
	detail.visible = false
	stamp = ""
	render()


func _close_detail() -> void:
	detail.visible = false
	detail_id = ""


func _strong(a: String, b: String) -> bool:
	for pair in links():
		if (pair[0] == a and pair[1] == b) or (pair[0] == b and pair[1] == a):
			return true
	return false


func _string(layer: Control, pile: Dictionary, key: String, dashed: bool) -> void:
	var parts := key.split("|")
	if parts.size() != 2 or not pile.has(parts[0]) or not pile.has(parts[1]):
		return
	var a: Control = pile[parts[0]]
	var b: Control = pile[parts[1]]
	if not a.visible or not b.visible:
		return
	var p1 := a.position + Vector2(a.size.x * 0.5, 6)
	var p2 := b.position + Vector2(b.size.x * 0.5, 6)
	var mid := (p1 + p2) * 0.5 + Vector2(0, -28)
	var pts := PackedVector2Array()
	for step in 12:
		var t := float(step) / 11.0
		var u := 1.0 - t
		pts.append(p1 * u * u + mid * 2.0 * u * t + p2 * t * t)
	var strong := _strong(parts[0], parts[1])
	var color := UiStyle.DANGER if strong or dashed else Color("6e2424")
	if dashed:
		layer.draw_dashed_line(p1, p2, color, 2.4, 8.0)
	else:
		layer.draw_polyline(pts, color, 2.6 if strong else 1.4, true)
	layer.draw_circle(p1, 4.0, color)
	layer.draw_circle(p2, 4.0, color)


func _view_input(event: InputEvent) -> void:
	if event is InputEventMagnifyGesture:
		_zoom_at(event.position, event.factor)
		viewport.accept_event()
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			_zoom_at(event.position, 1.12)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			_zoom_at(event.position, 0.9)
	elif event is InputEventScreenTouch:
		if event.pressed:
			touch[event.index] = event.position
		else:
			touch.erase(event.index)
		pinch = _touch_dist() if touch.size() >= 2 else 0.0
	elif event is InputEventScreenDrag and touch.size() >= 2:
		touch[event.index] = event.position
		var dist := _touch_dist()
		if pinch > 8.0 and dist > 8.0:
			_zoom_at(_touch_mid(), dist / pinch)
		pinch = dist
		viewport.accept_event()
	elif event is InputEventMouseMotion and event.button_mask & MOUSE_BUTTON_MASK_LEFT and touch.size() < 2:
		pan += event.relative
		_apply_view()


func _touch_dist() -> float:
	var pts: Array = touch.values()
	if pts.size() < 2:
		return 0.0
	return (pts[0] as Vector2).distance_to(pts[1])


func _touch_mid() -> Vector2:
	var pts: Array = touch.values()
	return ((pts[0] as Vector2) + (pts[1] as Vector2)) * 0.5


func _zoom_at(at: Vector2, factor: float) -> void:
	var old := zoom
	zoom = clampf(zoom * factor, 0.42, 2.4)
	var before := (at - pan) / old
	pan = at - before * zoom
	_apply_view()


func _apply_view() -> void:
	if cork == null:
		return
	cork.scale = Vector2.ONE * zoom
	var view := viewport.size
	var scaled := CORK * zoom
	if scaled.x <= view.x:
		pan.x = (view.x - scaled.x) * 0.5
	else:
		pan.x = clampf(pan.x, view.x - scaled.x, 0)
	if scaled.y <= view.y:
		pan.y = (view.y - scaled.y) * 0.5
	else:
		pan.y = clampf(pan.y, view.y - scaled.y, 0)
	cork.position = pan


func _fit_view() -> void:
	fitted = false
	_on_view_resized()


func _on_view_resized() -> void:
	if viewport == null or viewport.size.x < 80:
		return
	if not fitted:
		zoom = 1.0
		pan = Vector2(12, 8)
		fitted = true
	_apply_view()
