extends Control

## BÜRO-OS v2.4 kabuğu: durum çubuğu, açılış, bildirim, uygulama geçişi.
## Açıkken sahne ağacı duraklar; bu düğüm PROCESS_MODE_ALWAYS ile çalışmaya devam eder.

const Kit := preload("res://scenes/ui/tablet/tablet_kit.gd")
const UiStyle := preload("res://scenes/ui_style.gd")

const APPS := {
	"home": preload("res://scenes/ui/tablet/home.tscn"),
	"chat": preload("res://scenes/ui/tablet/chat.tscn"),
	"esorgu": preload("res://scenes/ui/tablet/esorgu.tscn"),
	"phone": preload("res://scenes/ui/tablet/phone.tscn"),
	"board": preload("res://scenes/ui/tablet/board.tscn"),
	"files": preload("res://scenes/ui/tablet/files.tscn"),
}

var device: Control
var frame: PanelContainer
var boot: Panel
var host: Control
var banner: PanelContainer
var banner_label: Label
var net: Label
var clock: Label
var battery: Label
var evidence: Label
const NAMES := {
	"chat": "BüroChat",
	"esorgu": "E-Sorgu",
	"phone": "Maktulün Telefonu",
	"board": "Kanıt Panosu",
	"files": "Dosyalar",
}

var open := false
var app := ""
var clue_count := -1
var desktop: Control
var window_layer: Control
var taskbar: HBoxContainer
var windows := {}
var cascade := 0
var shown_case := ""


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	theme = UiStyle.theme()
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var dimmer := ColorRect.new()
	dimmer.set_anchors_preset(Control.PRESET_FULL_RECT)
	dimmer.color = Color(0, 0, 0, 0.62)
	dimmer.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dimmer)
	device = Control.new()
	device.set_anchors_preset(Control.PRESET_FULL_RECT)
	device.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(device)
	frame = PanelContainer.new()
	frame.set_anchors_preset(Control.PRESET_FULL_RECT)
	frame.add_theme_stylebox_override("panel", Kit.box(Kit.BG, Color("3a2a24"), 18, 1, 0))
	device.add_child(frame)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	frame.add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	margin.add_child(column)
	column.add_child(_status())
	host = Control.new()
	Kit.fill(host)
	column.add_child(host)
	column.add_child(_dock())
	boot = Panel.new()
	boot.set_anchors_preset(Control.PRESET_FULL_RECT)
	boot.add_theme_stylebox_override("panel", Kit.box(Kit.BG, Kit.BG, 18, 0, 0))
	boot.visible = false
	boot.mouse_filter = Control.MOUSE_FILTER_STOP
	device.add_child(boot)
	var boot_box := VBoxContainer.new()
	boot_box.set_anchors_preset(Control.PRESET_CENTER)
	boot_box.offset_left = -200
	boot_box.offset_right = 200
	boot_box.offset_top = -70
	boot_box.offset_bottom = 70
	boot_box.alignment = BoxContainer.ALIGNMENT_CENTER
	boot.add_child(boot_box)
	boot_box.add_child(_centered("BÜRO-OS", 34, UiStyle.LAMP))
	boot_box.add_child(_centered("v2.4", 16, UiStyle.INK))
	boot_box.add_child(_centered("emniyet iç ağına bağlanıyor", 13, UiStyle.MUTED))
	banner = Kit.panel(Color("241c12"), UiStyle.LAMP, 10)
	banner.set_anchors_preset(Control.PRESET_CENTER_TOP)
	banner.offset_left = -260
	banner.offset_right = 260
	banner.offset_top = -70
	banner.position = Vector2(0, -70)
	banner.visible = false
	banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	banner_label = Kit.line("", 15, UiStyle.LAMP, true)
	banner.add_child(banner_label)
	add_child(banner)
	resized.connect(_fit)
	_fit()
	GameState.updated.connect(refresh)
	refresh()


func _process(_delta: float) -> void:
	if not visible:
		return
	clock.text = Time.get_time_string_from_system().substr(0, 5)


func _status() -> Control:
	var bar := HBoxContainer.new()
	bar.add_theme_constant_override("separation", 12)
	bar.add_child(Kit.line("BÜRO-OS v2.4", 14, UiStyle.LAMP, true))
	net = Kit.line("İÇ AĞ", 13, UiStyle.MUTED, true)
	bar.add_child(net)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.add_child(spacer)
	evidence = Kit.line("0 kanıt", 13, UiStyle.CRT, true)
	bar.add_child(evidence)
	clock = Kit.line("00:00", 14, UiStyle.INK, true)
	bar.add_child(clock)
	battery = Kit.line("%100", 13, UiStyle.MUTED, true)
	bar.add_child(battery)
	return bar


func _dock() -> Control:
	var bar := HBoxContainer.new()
	bar.add_theme_constant_override("separation", 6)
	var home := UiStyle.button("Masaüstü")
	home.custom_minimum_size = Vector2(0, 34)
	home.add_theme_font_size_override("font_size", 13)
	home.pressed.connect(_clear_windows)
	bar.add_child(home)
	bar.add_child(Kit.line("DOSYA NO 06", 13, UiStyle.MUTED, true))
	taskbar = HBoxContainer.new()
	taskbar.add_theme_constant_override("separation", 4)
	taskbar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.add_child(taskbar)
	var close := UiStyle.button("Kapat")
	close.custom_minimum_size = Vector2(0, 34)
	close.pressed.connect(func() -> void:
		GameState.close_tablet()
	)
	bar.add_child(close)
	return bar


func _centered(text: String, size: int, color: Color) -> Label:
	var label := Kit.line(text, size, color, true)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return label


func _fit() -> void:
	var margin := 12.0 if size.x < 860 else 52.0
	var top := 18.0 if size.y < 700 else 36.0
	frame.offset_left = margin
	frame.offset_right = -margin
	frame.offset_top = top
	frame.offset_bottom = -top
	boot.offset_left = margin
	boot.offset_right = -margin
	boot.offset_top = top
	boot.offset_bottom = -top


func refresh() -> void:
	if shown_case != Scenario.case_id:
		shown_case = Scenario.case_id
		for id in windows.keys():
			if is_instance_valid(windows[id]):
				windows[id].free()
		windows.clear()
		if desktop != null:
			desktop.free()
			desktop = null
		if window_layer != null:
			window_layer.free()
			window_layer = null
		cascade = 0
		clue_count = -1
	var now_open := GameState.tablet_open
	visible = now_open
	mouse_filter = Control.MOUSE_FILTER_STOP if now_open else Control.MOUSE_FILTER_IGNORE
	if now_open and not open:
		_boot()
		get_tree().paused = true
	elif not now_open and open:
		get_tree().paused = false
	open = now_open
	if clue_count >= 0 and now_open and GameState.clues.size() > clue_count:
		var found := Scenario.clue(GameState.clues[GameState.clues.size() - 1])
		_notify("Yeni delil  ·  " + str(found.get("title", "Kanıt")))
		_buzz()
	clue_count = GameState.clues.size()
	if not now_open:
		return
	evidence.text = "%d kanıt" % GameState.clues.size()
	battery.text = "%%%d" % clampi(64 + GameState.clues.size() * 3, 40, 100)
	_ensure_desktop()
	if desktop.has_method("render"):
		desktop.render()
	var next: String = GameState.tablet_app if APPS.has(GameState.tablet_app) else "home"
	app = next
	if next != "home":
		_open_window(next)
	_sync_taskbar()


func _boot() -> void:
	boot.visible = true
	boot.modulate.a = 1.0
	net.text = "BAĞLANIYOR…"
	net.add_theme_color_override("font_color", UiStyle.LAMP)
	frame.modulate.a = 0.0
	var tween := _tween()
	tween.tween_property(frame, "modulate:a", 1.0, 0.32)
	tween.tween_interval(0.5)
	tween.tween_property(boot, "modulate:a", 0.0, 0.25)
	tween.tween_callback(func() -> void:
		boot.visible = false
		net.text = "●  BAĞLI"
		net.add_theme_color_override("font_color", UiStyle.CRT)
	)


func _notify(text: String) -> void:
	banner_label.text = text
	banner.visible = true
	banner.position.y = -70
	var tween := _tween()
	tween.tween_property(banner, "position:y", 78.0, 0.28).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_interval(2.2)
	tween.tween_property(banner, "position:y", -70.0, 0.24)


func _buzz() -> void:
	Input.vibrate_handheld(40)
	var tween := _tween()
	tween.tween_property(device, "position:x", 8.0, 0.04)
	tween.tween_property(device, "position:x", -8.0, 0.05)
	tween.tween_property(device, "position:x", 0.0, 0.05)


func _ensure_desktop() -> void:
	if desktop != null:
		return
	desktop = APPS["home"].instantiate()
	Kit.cover(desktop)
	host.add_child(desktop)
	window_layer = Control.new()
	Kit.cover(window_layer)
	window_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	host.add_child(window_layer)


func _open_window(app_id: String) -> void:
	if windows.has(app_id) and is_instance_valid(windows[app_id]):
		_raise(windows[app_id])
		var body: Node = windows[app_id].find_child("Body", true, false)
		if body and body.get_child_count() > 0 and body.get_child(0).has_method("render"):
			body.get_child(0).render()
		return
	var win := PanelContainer.new()
	win.name = app_id
	win.add_theme_stylebox_override("panel", Kit.box(Kit.BG, UiStyle.LAMP, 10, 1, 0))
	win.mouse_filter = Control.MOUSE_FILTER_STOP
	win.clip_contents = true
	var area := host.size
	if area.x < 80:
		area = Vector2(1100, 620)
	var wide := area.x >= 860
	var span := Vector2(1000, 580) if app_id == "board" else Vector2(640, 460)
	win.size = Vector2(min(span.x, area.x - 16), min(span.y, area.y - 12)) if wide else area - Vector2(12, 12)
	win.custom_minimum_size = win.size
	win.position = Vector2(8, 8) if not wide else Vector2(24 + cascade * 34, 10 + cascade * 26)
	cascade = (cascade + 1) % 4
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 0)
	win.add_child(column)
	var title := HBoxContainer.new()
	title.custom_minimum_size = Vector2(0, 34)
	title.add_theme_constant_override("separation", 6)
	title.mouse_filter = Control.MOUSE_FILTER_STOP
	var grip := Kit.line("  " + NAMES.get(app_id, app_id), 14, UiStyle.LAMP, true)
	grip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title.add_child(grip)
	var shut := UiStyle.button("×")
	shut.custom_minimum_size = Vector2(32, 28)
	shut.focus_mode = Control.FOCUS_NONE
	shut.pressed.connect(_close_window.bind(app_id))
	title.add_child(shut)
	title.gui_input.connect(_drag.bind(win))
	column.add_child(title)
	var body := Control.new()
	body.name = "Body"
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.custom_minimum_size = Vector2(0, win.size.y - 40)
	column.add_child(body)
	var node := (APPS[app_id] as PackedScene).instantiate()
	Kit.cover(node)
	body.add_child(node)
	win.modulate.a = 0.0
	window_layer.add_child(win)
	if node.has_method("render"):
		node.render()
	windows[app_id] = win
	_raise(win)
	var tween := _tween()
	tween.tween_property(win, "modulate:a", 1.0, 0.18)


func _drag(event: InputEvent, win: Control) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		win.set_meta("drag", event.pressed)
		win.set_meta("grab", window_layer.get_local_mouse_position() - win.position)
		if event.pressed:
			_raise(win)
	elif event is InputEventMouseMotion and win.get_meta("drag", false):
		var next: Vector2 = window_layer.get_local_mouse_position() - win.get_meta("grab")
		next.x = clampf(next.x, 0, maxf(0, window_layer.size.x - win.size.x))
		next.y = clampf(next.y, 0, maxf(0, window_layer.size.y - 36))
		win.position = next


func _raise(win: Control) -> void:
	window_layer.move_child(win, window_layer.get_child_count() - 1)
	for id in windows.keys():
		var other: Control = windows[id]
		if is_instance_valid(other):
			var border := UiStyle.LAMP if other == win else Kit.LINE
			other.add_theme_stylebox_override("panel", Kit.box(Kit.BG, border, 10, 1, 0))


func _close_window(app_id: String) -> void:
	if windows.has(app_id) and is_instance_valid(windows[app_id]):
		windows[app_id].queue_free()
	windows.erase(app_id)
	if GameState.tablet_app == app_id:
		GameState.tablet_app = "home"
		app = "home"
	_sync_taskbar()


func _clear_windows() -> void:
	for id in windows.keys():
		if is_instance_valid(windows[id]):
			windows[id].queue_free()
	windows.clear()
	GameState.tablet_app = "home"
	app = "home"
	_sync_taskbar()


func _sync_taskbar() -> void:
	if taskbar == null:
		return
	for child in taskbar.get_children():
		child.queue_free()
	for id in windows.keys():
		var button := UiStyle.button(NAMES.get(id, id))
		button.custom_minimum_size = Vector2(0, 30)
		button.add_theme_font_size_override("font_size", 13)
		if id == app:
			button.add_theme_color_override("font_color", UiStyle.LAMP)
		button.pressed.connect(GameState.open_tablet.bind(id))
		taskbar.add_child(button)


func _tween() -> Tween:
	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	return tween
