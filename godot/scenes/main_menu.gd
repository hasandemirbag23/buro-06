extends CanvasLayer

## Ana menü. Arka planda büro kalır; klasörler kâğıt dosyadır.

const UiStyle := preload("res://scenes/ui_style.gd")
const Archive := preload("res://scenes/case_archive.gd")

const STAMP := {
	"Açılmamış": Color("9a9184"),
	"Devam ediyor": Color("F59E0B"),
	"Çözüldü": Color("b6f5a8"),
	"Eksik delil": Color("DC2626"),
	"Kapatıldı": Color("efe6d6"),
}

var host: Node
var page := "home"
var home: Control
var files: Control
var settings: Control
var credits: Control
var file_list: VBoxContainer
var note: Label
var continue_button: Button
var back_button: Button
var sway := true


func _ready() -> void:
	layer = 40
	process_mode = Node.PROCESS_MODE_ALWAYS
	Archive.boot()
	_build()
	_apply_audio()
	visible = false


func _process(_delta: float) -> void:
	if host and host.get("stage") and not bool(host.get("playing")):
		return
	if not visible or not sway or page != "home":
		return
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		return
	var t := Time.get_ticks_msec() / 1000.0
	cam.h_offset = sin(t * 0.17) * 0.42
	cam.v_offset = cos(t * 0.11) * 0.06


func open_title() -> void:
	visible = true
	sway = host == null or not host.get("playing")
	_show("home")
	if sway and host and host.has_method("frame_menu"):
		host.frame_menu()


func _build() -> void:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	root.theme = UiStyle.theme()
	add_child(root)
	var wash := ColorRect.new()
	wash.set_anchors_preset(Control.PRESET_FULL_RECT)
	wash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wash.color = Color(0.02, 0.025, 0.035, 0.12)
	root.add_child(wash)
	home = _column(false)
	root.add_child(home.get_meta("shell"))
	home.add_child(UiStyle.label("CİNAYET BÜRO", 13, UiStyle.LAMP, true))
	home.add_child(UiStyle.label("BÜRO", 64, UiStyle.INK))
	home.add_child(UiStyle.label("DOSYA NO 06", 20, UiStyle.LAMP, true))
	home.add_child(UiStyle.label("03:17  ·  Ankara  ·  gece vardiyası", 13, UiStyle.MUTED, true))
	home.add_child(_gap(22))
	home.add_child(_item("Yeni Dosya", _show.bind("files")))
	continue_button = _item("Kaldığın Yerden Devam Et", _resume)
	home.add_child(continue_button)
	back_button = _item("Oyuna dön", _back)
	home.add_child(back_button)
	home.add_child(_item("Dosyalar", _show.bind("files")))
	home.add_child(_item("Ayarlar", _show.bind("settings")))
	home.add_child(_item("Jenerik", _show.bind("credits")))
	files = _column(true)
	root.add_child(files.get_meta("shell"))
	files.add_child(UiStyle.label("SORUŞTURMA DOSYALARI", 13, UiStyle.LAMP, true))
	files.add_child(UiStyle.label("Her klasör bir vaka.", 16, UiStyle.INK))
	note = UiStyle.label("", 14, UiStyle.DANGER)
	files.add_child(note)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.custom_minimum_size = Vector2(0, 360)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	files.add_child(scroll)
	file_list = VBoxContainer.new()
	file_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	file_list.add_theme_constant_override("separation", 10)
	scroll.add_child(file_list)
	files.add_child(_item("Geri", _show.bind("home")))
	settings = _column(true)
	root.add_child(settings.get_meta("shell"))
	settings.add_child(UiStyle.label("AYARLAR", 13, UiStyle.LAMP, true))
	settings.add_child(_slider("Ana ses", "master"))
	settings.add_child(_slider("Müzik", "music"))
	settings.add_child(_slider("Ortam (yağmur, sokak)", "ambient"))
	settings.add_child(_slider("Efektler", "sfx"))
	settings.add_child(_slider("Diyalog sesi", "voice"))
	var full := CheckButton.new()
	full.text = "Tam ekran"
	full.button_pressed = bool(Archive.settings.get("fullscreen", false))
	full.toggled.connect(_fullscreen)
	settings.add_child(full)
	settings.add_child(_item("Geri", _show.bind("home")))
	credits = _column(true)
	root.add_child(credits.get_meta("shell"))
	credits.add_child(UiStyle.label("JENERİK", 13, UiStyle.LAMP, true))
	credits.add_child(UiStyle.label("BÜRO: DOSYA NO 06", 28, UiStyle.INK))
	var roll := UiStyle.label("Cinayet Büro gece vardiyası.\n\nBaşkomiser Behzat\nAkbaba — olay yeri\nHayalet — istihbarat\nAyşe — arşiv\nSavcı Nilgün Erdem\n\nOfis, masa lambası.\nDosyalar rafta durur.", 16, UiStyle.MUTED)
	credits.add_child(roll)
	credits.add_child(_item("Geri", _show.bind("home")))


func _show(next: String) -> void:
	page = next
	home.get_meta("shell").visible = next == "home"
	files.get_meta("shell").visible = next == "files"
	settings.get_meta("shell").visible = next == "settings"
	credits.get_meta("shell").visible = next == "credits"
	if next == "home":
		var live := host != null and bool(host.get("playing"))
		back_button.visible = live
		continue_button.visible = not live
		var cont := Archive.continue_id()
		continue_button.disabled = cont == ""
		continue_button.text = "Kaldığın Yerden Devam Et" if cont != "" else "Kayıt yok"
	if next == "files":
		_folders()


func _folders() -> void:
	for child in file_list.get_children():
		child.queue_free()
	note.text = ""
	var rows: Array = Scenario.catalog.duplicate()
	rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(str(a.get("fileNo", "0"))) < int(str(b.get("fileNo", "0")))
	)
	for row in rows:
		file_list.add_child(_folder(row))


func _folder(row: Dictionary) -> Control:
	var state := Archive.status(row)
	var card := PanelContainer.new()
	var paper := StyleBoxFlat.new()
	paper.bg_color = Color("c4a36a")
	paper.border_color = Color("3a2a1c")
	paper.set_border_width_all(1)
	paper.set_corner_radius_all(3)
	paper.content_margin_left = 14
	paper.content_margin_right = 14
	paper.content_margin_top = 12
	paper.content_margin_bottom = 12
	card.add_theme_stylebox_override("panel", paper)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 2)
	card.add_child(box)
	var head := HBoxContainer.new()
	box.add_child(head)
	var no := UiStyle.label("DOSYA  " + str(row.get("fileNo", "")), 13, Color("6b4428"), true)
	no.autowrap_mode = TextServer.AUTOWRAP_OFF
	no.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(no)
	var stamp := UiStyle.label(state.to_upper(), 12, STAMP.get(state, UiStyle.DANGER), true)
	stamp.autowrap_mode = TextServer.AUTOWRAP_OFF
	stamp.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	head.add_child(stamp)
	var title := "Mühürlü" if str(row.get("status", "")) != "open" else str(row.get("title", ""))
	box.add_child(UiStyle.label(title, 22, Color("2a2118")))
	box.add_child(UiStyle.label(str(row.get("logline", "")), 14, Color("4a3a2c")))
	var meta := UiStyle.label("Şehir %s   ·   Maktul %s   ·   Tarih %s" % [str(row.get("city", "—")), str(row.get("victim", "—")), str(row.get("date", "—"))], 13, Color("3d3428"), true)
	meta.autowrap_mode = TextServer.AUTOWRAP_OFF
	box.add_child(meta)
	var button := UiStyle.button(_verb(state, row))
	button.pressed.connect(_pick.bind(row))
	box.add_child(button)
	return card


func _verb(state: String, row: Dictionary) -> String:
	if str(row.get("status", "")) != "open":
		return "Mühürlü"
	if state == "Açılmamış":
		return "Dosyayı aç"
	if state == "Devam ediyor" or state == "Eksik delil":
		return "Devam et"
	return "Tutanağı gör"


func _pick(row: Dictionary) -> void:
	if host == null:
		return
	var state := Archive.status(row)
	if str(row.get("status", "")) != "open":
		note.text = "Dosya %s mühürlü. Senaryosu yazılmadı." % str(row.get("fileNo", ""))
		return
	var id := str(row.get("id", ""))
	if state == "Açılmamış":
		host.start_case(id)
	elif state == "Çözüldü" or state == "Kapatıldı":
		host.review_case(id)
	else:
		host.resume_case(id)


func _back() -> void:
	if host and host.has_method("close_menu"):
		host.close_menu()


func _resume() -> void:
	var id := Archive.continue_id()
	if id != "" and host:
		host.resume_case(id)


func _slider(caption: String, key: String) -> Control:
	var box := VBoxContainer.new()
	box.add_child(UiStyle.label(caption, 14, UiStyle.MUTED, true))
	var slider := HSlider.new()
	slider.min_value = 0
	slider.max_value = 100
	slider.step = 1
	slider.value = float(Archive.settings.get(key, 70))
	slider.custom_minimum_size = Vector2(280, 28)
	slider.value_changed.connect(_set_audio.bind(key))
	box.add_child(slider)
	return box


func _set_audio(value: float, key: String) -> void:
	Archive.settings[key] = value
	Archive.save_settings()
	_apply_audio()


func _fullscreen(on: bool) -> void:
	Archive.settings["fullscreen"] = on
	Archive.save_settings()
	if DisplayServer.get_name() == "headless":
		return
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if on else DisplayServer.WINDOW_MODE_WINDOWED)


func _apply_audio() -> void:
	Sound.apply_settings()


func _column(dim: bool) -> VBoxContainer:
	var shell := Control.new()
	shell.set_anchors_preset(Control.PRESET_LEFT_WIDE)
	shell.offset_left = 52
	shell.offset_top = 64
	shell.offset_right = 460
	shell.offset_bottom = -48
	if dim:
		var back := ColorRect.new()
		back.set_anchors_preset(Control.PRESET_FULL_RECT)
		back.color = Color(0.04, 0.045, 0.055, 0.62)
		back.mouse_filter = Control.MOUSE_FILTER_IGNORE
		shell.add_child(back)
	var edge := ColorRect.new()
	edge.set_anchors_preset(Control.PRESET_LEFT_WIDE)
	edge.offset_right = 2
	edge.color = Color("F59E0B")
	edge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shell.add_child(edge)
	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_FULL_RECT)
	box.offset_left = 28
	box.offset_top = 8
	box.offset_right = -12
	box.offset_bottom = -8
	box.add_theme_constant_override("separation", 6)
	box.set_meta("shell", shell)
	shell.add_child(box)
	return box


func _item(text: String, call: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.custom_minimum_size = Vector2(0, 40)
	button.flat = true
	var empty := StyleBoxEmpty.new()
	var hover := StyleBoxFlat.new()
	hover.bg_color = Color(0, 0, 0, 0)
	hover.border_width_left = 3
	hover.border_color = Color("F59E0B")
	hover.content_margin_left = 12
	var press := hover.duplicate()
	press.border_color = Color("DC2626")
	button.add_theme_stylebox_override("normal", empty)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", press)
	button.add_theme_stylebox_override("focus", empty)
	button.add_theme_color_override("font_color", UiStyle.INK)
	button.add_theme_color_override("font_hover_color", UiStyle.LAMP)
	button.add_theme_color_override("font_pressed_color", UiStyle.DANGER)
	button.add_theme_font_size_override("font_size", 18)
	button.pressed.connect(call)
	return button


func _gap(px: float) -> Control:
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, px)
	return gap
