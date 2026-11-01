extends CanvasLayer

## Kararma, atmosfer ve atlama. Fare dünyaya geçer; kontrol kilitlenmez.

const UiStyle := preload("res://scenes/ui_style.gd")

var fade: ColorRect
var grade: ColorRect
var caption: Label
var skip_button: Button
var card: Panel
var _fade: Tween


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 20
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	grade = ColorRect.new()
	grade.set_anchors_preset(Control.PRESET_FULL_RECT)
	grade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	grade.color = Color(0, 0, 0, 0)
	root.add_child(grade)
	fade = ColorRect.new()
	fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade.color = Color(0.03, 0.035, 0.045, 0)
	root.add_child(fade)
	caption = UiStyle.label("", 28, Color("ffe7a3"))
	caption.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 1))
	caption.add_theme_constant_override("shadow_outline_size", 0)
	caption.set_anchors_preset(Control.PRESET_CENTER)
	caption.offset_left = -280
	caption.offset_top = -24
	caption.offset_right = 280
	caption.offset_bottom = 24
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
	caption.visible = false
	root.add_child(caption)
	skip_button = UiStyle.button("Atla")
	skip_button.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	skip_button.offset_left = -120
	skip_button.offset_top = 70
	skip_button.offset_right = -16
	skip_button.offset_bottom = 112
	skip_button.visible = false
	skip_button.pressed.connect(Cinematic.skip)
	root.add_child(skip_button)
	card = Panel.new()
	card.set_anchors_preset(Control.PRESET_CENTER)
	card.offset_left = -280
	card.offset_top = -130
	card.offset_right = 280
	card.offset_bottom = 130
	card.visible = false
	root.add_child(card)
	Cinematic.started.connect(_on_started)
	Cinematic.skipped.connect(_on_skipped)
	Cinematic.finished.connect(_on_finished)


func _unhandled_input(event: InputEvent) -> void:
	if not Cinematic.playing:
		return
	var focus := get_viewport().gui_get_focus_owner()
	if focus is LineEdit:
		return
	if not event is InputEventKey:
		return
	var pressed := event as InputEventKey
	if pressed.pressed and not pressed.echo and (pressed.keycode == KEY_ESCAPE or pressed.keycode == KEY_SPACE):
		Cinematic.skip()
		get_viewport().set_input_as_handled()


func _on_started(id: String) -> void:
	var beat := Cinematic.spec(id)
	_paint_grade()
	if _fade:
		_fade.kill()
	fade.color.a = 0.0
	caption.visible = false
	card.visible = false
	for child in card.get_children():
		child.queue_free()
	var show_skip := bool(beat.get("fade", false)) or id == "call_savci" or id == "radio" or id == "confession"
	skip_button.visible = show_skip
	var title := str(beat.get("caption", ""))
	if title != "" and not bool(beat.get("fade", false)):
		caption.text = title
		caption.modulate.a = 1.0
		caption.visible = true
	if bool(beat.get("fade", false)):
		fade.color.a = 1.0
		caption.text = str(Scenario.data.get("place", "")) if id == "travel_site" else str(beat.get("caption", ""))
		caption.visible = caption.text != ""
		_fade = create_tween()
		_fade.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		_fade.tween_interval(0.12)
		_fade.tween_property(fade, "color:a", 0.0, 0.34)
		_fade.parallel().tween_property(caption, "modulate:a", 0.0, 0.34)
	if id == "call_savci":
		_savci(str(beat.get("line", "")))


func _on_skipped(_id: String) -> void:
	if _fade:
		_fade.kill()
	fade.color.a = 0.0
	caption.visible = false
	card.visible = false


func _on_finished(_id: String) -> void:
	skip_button.visible = false
	card.visible = false
	caption.visible = false
	_paint_grade()


func _paint_grade() -> void:
	var next := Cinematic.grade()
	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(grade, "color", next, 0.35)


func _savci(line: String) -> void:
	card.visible = true
	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_FULL_RECT)
	box.offset_left = 18
	box.offset_top = 16
	box.offset_right = -18
	box.offset_bottom = -16
	box.add_theme_constant_override("separation", 8)
	card.add_child(box)
	box.add_child(UiStyle.label("SAVCI", 13, UiStyle.CRT, true))
	box.add_child(UiStyle.label("Nilgün Erdem", 26, UiStyle.INK))
	box.add_child(UiStyle.typed(line, 16))
	var close := UiStyle.button("Kapat")
	close.pressed.connect(Cinematic.skip)
	box.add_child(close)
