extends Node

const UiStyle := preload("res://scenes/ui_style.gd")

const SCENES := {
	"office": preload("res://scenes/office.tscn"),
	"site": preload("res://scenes/site.tscn"),
	"interrogation": preload("res://scenes/interrogation.tscn"),
}
const TABLET := preload("res://scenes/ui/tablet.tscn")
const Archive := preload("res://scenes/case_archive.gd")
const Menu := preload("res://scenes/main_menu.gd")
const MenuStage := preload("res://scenes/menu_stage.gd")
const FACES := {
	"Başkomiser Behzat": ["behzat", "CV"],
	"Akbaba": ["akbaba", "AK"],
	"Hayalet": ["hayalet", "HA"],
	"Komiser": ["player", "KM"],
	"Zafer": ["zafer", "ZF"],
	"Zafer Yılmaz": ["zafer", "ZF"],
	"Tarık Soylu": ["tarik", "TS"],
	"Mert Aksoy": ["mert", "MA"],
	"Haldun Erk": ["haldun", "HE"],
	"Prof. Dr. Haldun Erk": ["haldun", "HE"],
	"Nevzat Şahin": ["nevzat", "NV"],
	"İdris": ["idris", "İD"],
	"Savcı Nilgün Erdem": ["savci", "NE"],
	"Ayşe": ["arsiv", "AY"],
}

var world: Node3D
var stage: Node3D
var ui: CanvasLayer
var hud: PanelContainer
var menu: CanvasLayer
var playing := false
var menu_up := true
var title: Label
var count: Label
var notice: Label
var dialogue: Label
var dialogue_name: Label
var dialogue_aside: Label
var portrait: PanelContainer
var portrait_mark: Label
var dialogue_plate: PanelContainer
var shown_line := ""
var shown_clue := ""
var query_plate: PanelContainer
var office_button: Button
var exit_button: Button
var site_button: Button
var tablet_button: Button
var shown_case := ""
var map_panel: Panel
var call_panel: Panel
var call_from: Label
var call_line: Label
var loading: Label
var clue_panel: Panel
var case_panel: Panel
var query_panel: VBoxContainer
var suspect_row: HBoxContainer
var stress_bar: ProgressBar
var stress_fill: StyleBoxFlat
var bpm_label: Label
var options_box: VBoxContainer
var evidence_button: Button
var report_button: Button
var shown_stress := -1
var shown_scene := ""
var notice_token := 0


func _ready() -> void:
	world = Node3D.new()
	world.name = "World"
	add_child(world)
	stage = MenuStage.new()
	stage.name = "MenuStage"
	add_child(stage)
	_build_ui()
	_add_crt()
	add_child(preload("res://scenes/cinematic_layer.gd").new())
	menu = Menu.new()
	menu.host = self
	add_child(menu)
	GameState.updated.connect(_sync)
	playing = false
	menu_up = true
	_sync()
	menu.open_title()
	_apply_stage()
	if OS.get_cmdline_user_args().has("sorgu"):
		call_deferred("_open_sorgu")


func _unhandled_input(event: InputEvent) -> void:
	if not playing or menu_up:
		return
	if GameState.tablet_open or GameState.incoming_call or GameState.pending_clue_id != "" or GameState.show_case:
		return
	if not (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		return
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return
	var origin := camera.project_ray_origin(event.position)
	var end := origin + camera.project_ray_normal(event.position) * 80.0
	var query := PhysicsRayQueryParameters3D.create(origin, end)
	query.collide_with_areas = true
	query.collide_with_bodies = true
	query.collision_mask = 0xFFFFFFFF & ~(16 | 32)
	var hit := camera.get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return
	var node: Object = hit.collider
	if node is Node and node.has_meta("action"):
		_act(str(node.get_meta("action")), hit.position)


func _act(action: String, at: Vector3 = Vector3.ZERO) -> void:
	var scene: Node = world.get_child(0) if world.get_child_count() > 0 else null
	if scene != null and scene.has_method("handle_action") and scene.handle_action(action, at):
		return
	GameState.aimed.emit(action)
	if action == "brief":
		GameState.brief()
	elif action == "board":
		GameState.open_tablet("board")
	elif action == "records":
		GameState.open_records()
	elif action == "files":
		GameState.read_files()
	elif action == "door":
		map_panel.visible = true
	elif action.begins_with("hotspot:"):
		GameState.inspect_hotspot(action.trim_prefix("hotspot:"))


func _sync() -> void:
	_show_world()
	_window_rain(playing and not menu_up and GameState.scene_id == "office")
	if not playing or menu_up:
		_hide_play_ui()
		return
	hud.visible = true
	if Archive:
		Archive.remember(GameState.snapshot())
	var names := {"office": "CİNAYET BÜRO", "site": "OLAY YERİ", "interrogation": "SORGU ODASI"}
	var place: String = str(Scenario.data.get("place", ""))
	title.text = place if GameState.scene_id == "site" and place != "" else str(names.get(GameState.scene_id, ""))
	query_plate.visible = GameState.scene_id == "interrogation" and not GameState.tablet_open
	query_panel.visible = query_plate.visible
	count.text = "%d kanıt" % GameState.clues.size()
	office_button.visible = GameState.scene_id != "office"
	exit_button.visible = GameState.scene_id == "site" and GameState.focus_active
	if site_button:
		site_button.visible = GameState.scene_id != "site"
	var notice_up: bool = GameState.notice != "" and GameState.pending_clue_id == ""
	notice.visible = notice_up
	if notice_up and notice.has_method("play"):
		notice.play(GameState.notice)
	elif notice_up:
		notice.text = GameState.notice
	if notice_up:
		notice_token += 1
		var token := notice_token
		get_tree().create_timer(3.2).timeout.connect(func() -> void:
			if token == notice_token:
				GameState.dismiss_notice()
		)
	var spoken := GameState.line
	var aside := GameState.behzat_line
	var key: String = "%s|%s|%s" % [GameState.speaker, spoken, aside]
	if key != shown_line:
		shown_line = key
		_paint_portrait(GameState.speaker)
		dialogue_name.text = GameState.speaker
		if dialogue.has_method("play"):
			dialogue.play(spoken)
		else:
			dialogue.text = spoken
		dialogue_aside.visible = aside != ""
		if dialogue_aside.has_method("play"):
			dialogue_aside.play("Behzat: %s" % aside if aside != "" else "")
	dialogue_plate.visible = spoken != "" or aside != ""
	if GameState.incoming_call:
		if Cinematic.beat_id != "call_amir":
			Cinematic.play("call_amir")
	elif Cinematic.beat_id == "call_amir":
		Cinematic.skip()
	if query_plate.visible:
		var rows := 2 + int((spoken.length() + aside.length()) / 68.0)
		if aside != "":
			rows += 1
		var band := clampf(float(rows) * 18.0 + 20.0, 64.0, 92.0)
		dialogue_plate.offset_bottom = -236
		dialogue_plate.offset_top = -236.0 - band
	else:
		dialogue_plate.offset_top = -108
		dialogue_plate.offset_bottom = -12
	call_panel.visible = GameState.incoming_call
	if GameState.incoming_call and call_from:
		var ringing: Dictionary = Scenario.data.get("call", {})
		call_from.text = str(ringing.get("from", ""))
		if call_line.has_method("play"):
			call_line.play(str(ringing.get("text", "")))
	_fill_clue()
	_fill_case()
	_fill_query()


func _window_rain(on: bool) -> void:
	if world.get_child_count() == 0:
		return
	var office := world.get_child(0)
	if office.has_method("set_rain"):
		office.set_rain(on)


func _show_world() -> void:
	if not playing:
		if world.get_child_count() > 0:
			for child in world.get_children():
				world.remove_child(child)
				child.free()
			shown_scene = ""
			shown_case = ""
		return
	if shown_scene == GameState.scene_id and shown_case == Scenario.case_id and world.get_child_count() > 0:
		return
	var next := GameState.scene_id
	shown_scene = next
	shown_case = Scenario.case_id
	for child in world.get_children():
		world.remove_child(child)
		child.free()
	var packed: PackedScene = SCENES[next]
	if next == "office":
		world.add_child(packed.instantiate())
		if loading:
			loading.visible = false
		return
	if loading:
		loading.visible = true
	call_deferred("_mount_scene", packed)


func _mount_scene(packed: PackedScene) -> void:
	if GameState.scene_id == "office":
		if loading:
			loading.visible = false
		return
	if world.get_child_count() > 0:
		return
	world.add_child(packed.instantiate())
	if loading:
		loading.visible = false


func _build_ui() -> void:
	ui = CanvasLayer.new()
	ui.layer = 30
	ui.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(ui)
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.theme = UiStyle.theme()
	ui.add_child(root)
	hud = PanelContainer.new()
	hud.set_anchors_preset(Control.PRESET_TOP_WIDE)
	hud.offset_left = 16
	hud.offset_top = 12
	hud.offset_right = -16
	hud.offset_bottom = 60
	var hud_box := StyleBoxFlat.new()
	hud_box.bg_color = Color(0.0784314, 0.0901961, 0.113725, 0.82)
	hud_box.border_color = Color(0.960784, 0.619608, 0.0431373, 0.55)
	hud_box.border_width_bottom = 1
	hud_box.set_corner_radius_all(8)
	hud_box.corner_detail = 8
	hud_box.content_margin_left = 16
	hud_box.content_margin_right = 8
	hud_box.content_margin_top = 4
	hud_box.content_margin_bottom = 4
	hud_box.anti_aliasing = true
	hud.add_theme_stylebox_override("panel", hud_box)
	root.add_child(hud)
	var bar := HBoxContainer.new()
	bar.add_theme_constant_override("separation", 12)
	hud.add_child(bar)
	title = UiStyle.label("CİNAYET BÜRO", 16, UiStyle.LAMP, true)
	title.autowrap_mode = TextServer.AUTOWRAP_OFF
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.add_child(title)
	count = UiStyle.label("0 kanıt", 13, UiStyle.MUTED, true)
	count.autowrap_mode = TextServer.AUTOWRAP_OFF
	count.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	count.custom_minimum_size = Vector2(90, 0)
	bar.add_child(count)
	office_button = UiStyle.button("Ofise dön")
	office_button.custom_minimum_size = Vector2(0, 34)
	office_button.pressed.connect(func() -> void:
		GameState.travel("office")
	)
	bar.add_child(office_button)
	exit_button = UiStyle.button("Geri çık [Esc]")
	exit_button.custom_minimum_size = Vector2(0, 34)
	exit_button.visible = false
	exit_button.pressed.connect(func() -> void:
		var scene: Node = world.get_child(0) if world.get_child_count() > 0 else null
		if scene != null and scene.has_method("exit_focus"):
			scene.exit_focus()
	)
	bar.add_child(exit_button)
	site_button = UiStyle.button("Olay yeri")
	site_button.custom_minimum_size = Vector2(0, 34)
	site_button.pressed.connect(func() -> void:
		GameState.travel("site")
	)
	bar.add_child(site_button)
	tablet_button = UiStyle.button("Görev Tableti")
	tablet_button.custom_minimum_size = Vector2(0, 34)
	tablet_button.pressed.connect(func() -> void:
		if GameState.tablet_open:
			GameState.close_tablet()
		else:
			GameState.open_tablet("home")
	)
	bar.add_child(tablet_button)
	var menu_button := UiStyle.button("Menü")
	menu_button.custom_minimum_size = Vector2(0, 34)
	menu_button.pressed.connect(_open_menu)
	bar.add_child(menu_button)
	notice = UiStyle.typed("", 14, UiStyle.LAMP, true)
	notice.position = Vector2(28, 68)
	notice.size = Vector2(980, 28)
	root.add_child(notice)
	dialogue_plate = PanelContainer.new()
	dialogue_plate.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	dialogue_plate.offset_left = 16
	dialogue_plate.offset_right = -16
	dialogue_plate.offset_top = -108
	dialogue_plate.offset_bottom = -12
	dialogue_plate.visible = false
	dialogue_plate.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed:
			var typing: bool = dialogue.has_method("is_typing") and dialogue.is_typing()
			if dialogue.has_method("finish"):
				dialogue.finish()
			if dialogue_aside.has_method("finish"):
				dialogue_aside.finish()
			if not typing and GameState.scene_id == "site":
				GameState.clear_dialogue()
	)
	root.add_child(dialogue_plate)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	dialogue_plate.add_child(row)
	portrait = PanelContainer.new()
	portrait.custom_minimum_size = Vector2(44, 44)
	row.add_child(portrait)
	portrait_mark = UiStyle.label("", 18, UiStyle.INK, true)
	portrait_mark.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	portrait_mark.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	portrait.add_child(portrait_mark)
	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 2)
	row.add_child(column)
	dialogue_name = UiStyle.label("", 13, UiStyle.LAMP, true)
	column.add_child(dialogue_name)
	dialogue = UiStyle.typed("", 15, Color("ffffff"))
	dialogue.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dialogue.custom_minimum_size = Vector2(0, 0)
	_ink(dialogue)
	column.add_child(dialogue)
	dialogue_aside = UiStyle.typed("", 15, Color("d9d0c2"))
	dialogue_aside.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dialogue_aside.custom_minimum_size = Vector2(0, 0)
	_ink(dialogue_aside)
	column.add_child(dialogue_aside)
	_solid(dialogue_plate, 6)
	map_panel = _paper_panel()
	root.add_child(map_panel)
	var map_box := VBoxContainer.new()
	map_box.set_anchors_preset(Control.PRESET_FULL_RECT)
	map_box.offset_left = 16
	map_box.offset_top = 16
	map_box.offset_right = -16
	map_box.offset_bottom = -16
	map_panel.add_child(map_box)
	map_box.add_child(UiStyle.label("NEREYE?", 13, UiStyle.LAMP, true))
	map_box.add_child(UiStyle.label("Dosya sahaya ya da sorguya gider.", 18))
	var site := UiStyle.button("Olay yeri")
	site.pressed.connect(func() -> void:
		map_panel.visible = false
		GameState.travel("site")
	)
	map_box.add_child(site)
	var room := UiStyle.button("Sorgu odası")
	room.pressed.connect(func() -> void:
		map_panel.visible = false
		GameState.travel("interrogation")
	)
	map_box.add_child(room)
	var stay := UiStyle.button("Kal")
	stay.pressed.connect(func() -> void:
		map_panel.visible = false
	)
	map_box.add_child(stay)
	map_panel.visible = false
	query_plate = PanelContainer.new()
	query_plate.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	query_plate.offset_left = 16
	query_plate.offset_right = -16
	query_plate.offset_top = -228
	query_plate.offset_bottom = -8
	query_plate.visible = false
	_solid(query_plate)
	root.add_child(query_plate)
	query_panel = VBoxContainer.new()
	query_panel.add_theme_constant_override("separation", 6)
	query_plate.add_child(query_panel)
	_build_query()
	call_panel = _overlay()
	root.add_child(call_panel)
	var call_card := Panel.new()
	call_card.set_anchors_preset(Control.PRESET_CENTER)
	call_card.offset_left = -280
	call_card.offset_top = -150
	call_card.offset_right = 280
	call_card.offset_bottom = 150
	call_panel.add_child(call_card)
	var call_box := VBoxContainer.new()
	call_box.set_anchors_preset(Control.PRESET_FULL_RECT)
	call_box.offset_left = 20
	call_box.offset_top = 18
	call_box.offset_right = -20
	call_box.offset_bottom = -18
	call_box.add_theme_constant_override("separation", 8)
	call_card.add_child(call_box)
	call_box.add_child(UiStyle.label("GELEN ARAMA", 13, UiStyle.CRT, true))
	call_from = UiStyle.label("", 28, UiStyle.LAMP)
	call_box.add_child(call_from)
	call_line = UiStyle.typed("", 16)
	call_box.add_child(call_line)
	var call_row := HBoxContainer.new()
	call_box.add_child(call_row)
	var decline := UiStyle.button("Kapat")
	decline.pressed.connect(func() -> void:
		GameState.decline_call()
	)
	var answer := UiStyle.button("Aç")
	answer.pressed.connect(func() -> void:
		GameState.answer_call()
	)
	call_row.add_child(decline)
	call_row.add_child(answer)
	clue_panel = _paper_panel()
	clue_panel.offset_top = -110
	clue_panel.offset_bottom = 110
	root.add_child(clue_panel)
	case_panel = _paper_panel()
	case_panel.offset_left = 180
	case_panel.offset_top = 40
	case_panel.offset_right = -180
	case_panel.offset_bottom = -40
	root.add_child(case_panel)
	var tablet := TABLET.instantiate()
	root.add_child(tablet)
	var load_layer := CanvasLayer.new()
	load_layer.layer = 25
	load_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(load_layer)
	loading = UiStyle.label("Sahne açılıyor", 28, UiStyle.LAMP)
	loading.set_anchors_preset(Control.PRESET_CENTER)
	loading.offset_left = -180
	loading.offset_top = -20
	loading.offset_right = 180
	loading.offset_bottom = 20
	loading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	loading.visible = false
	loading.mouse_filter = Control.MOUSE_FILTER_IGNORE
	load_layer.add_child(loading)


func _solid(panel: PanelContainer, pad := 10) -> void:
	var box := StyleBoxFlat.new()
	box.bg_color = Color(0, 0, 0, 1)
	box.border_color = Color(0.96, 0.7, 0.28, 0.9)
	box.set_border_width_all(1)
	box.set_corner_radius_all(8)
	box.content_margin_left = 12
	box.content_margin_right = 12
	box.content_margin_top = pad
	box.content_margin_bottom = pad
	panel.add_theme_stylebox_override("panel", box)


func _ink(label: Label) -> void:
	label.add_theme_color_override("font_color", Color("ffffff"))
	label.add_theme_constant_override("shadow_outline_size", 0)


func _build_query() -> void:
	# üst şerit: şüpheli seçimi + nabız + animasyonlu stres çubuğu
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 10)
	query_panel.add_child(top)
	suspect_row = HBoxContainer.new()
	suspect_row.add_theme_constant_override("separation", 6)
	top.add_child(suspect_row)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(spacer)
	bpm_label = UiStyle.label("75 BPM", 15, UiStyle.CRT, true)
	bpm_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	top.add_child(bpm_label)
	var stress_title := UiStyle.label("STRES", 13, UiStyle.MUTED, true)
	stress_title.autowrap_mode = TextServer.AUTOWRAP_OFF
	top.add_child(stress_title)
	stress_bar = ProgressBar.new()
	stress_bar.min_value = 0
	stress_bar.max_value = 100
	stress_bar.value = 0
	stress_bar.show_percentage = false
	stress_bar.custom_minimum_size = Vector2(220, 14)
	stress_bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var track := StyleBoxFlat.new()
	track.bg_color = Color("0c1016")
	track.border_color = Color("3a3f48")
	track.set_border_width_all(1)
	track.set_corner_radius_all(6)
	stress_fill = StyleBoxFlat.new()
	stress_fill.bg_color = UiStyle.CRT
	stress_fill.set_corner_radius_all(6)
	stress_bar.add_theme_stylebox_override("background", track)
	stress_bar.add_theme_stylebox_override("fill", stress_fill)
	top.add_child(stress_bar)
	# alt: solda diyalog seçenekleri, sağda Kanıt Göster + kamera
	var body := HBoxContainer.new()
	body.add_theme_constant_override("separation", 12)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	query_panel.add_child(body)
	options_box = VBoxContainer.new()
	options_box.add_theme_constant_override("separation", 4)
	options_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(options_box)
	var right := VBoxContainer.new()
	right.add_theme_constant_override("separation", 6)
	right.custom_minimum_size = Vector2(300, 0)
	right.alignment = BoxContainer.ALIGNMENT_END
	body.add_child(right)
	var cams := HBoxContainer.new()
	cams.add_theme_constant_override("separation", 4)
	cams.alignment = BoxContainer.ALIGNMENT_END
	right.add_child(cams)
	for shot in [["wide", "Geniş"], ["closeup", "Şüpheli"], ["detective", "Komiser"], ["tabletop", "Masa"]]:
		var button := UiStyle.button(shot[1])
		button.custom_minimum_size = Vector2(0, 32)
		button.add_theme_font_size_override("font_size", 13)
		button.pressed.connect(GameState.set_shot.bind(shot[0]))
		cams.add_child(button)
	report_button = UiStyle.button("Dosya kapandı — tutanağı aç")
	report_button.pressed.connect(func() -> void:
		GameState.open_case_report()
	)
	report_button.visible = false
	right.add_child(report_button)
	evidence_button = UiStyle.button("KANIT GÖSTER")
	evidence_button.custom_minimum_size = Vector2(0, 36)
	evidence_button.add_theme_font_size_override("font_size", 15)
	evidence_button.add_theme_color_override("font_color", UiStyle.LAMP)
	evidence_button.pressed.connect(_open_picker)
	right.add_child(evidence_button)


func _fill_query() -> void:
	if not query_panel.visible:
		return
	for child in suspect_row.get_children():
		child.queue_free()
	for person in Scenario.data.get("suspects", []):
		var id: String = person["id"]
		var label: String = str(person["character"]["name"])
		if GameState.confessed[id]:
			label += " · itiraf"
		var button := UiStyle.button(label)
		button.custom_minimum_size = Vector2(0, 34)
		button.add_theme_font_size_override("font_size", 14)
		if id == GameState.active_suspect:
			button.add_theme_color_override("font_color", UiStyle.LAMP)
		button.pressed.connect(GameState.select_suspect.bind(id))
		suspect_row.add_child(button)
	var suspect_id := GameState.active_suspect
	var stress := int(GameState.stress[suspect_id]) if suspect_id != "" else 0
	var rate := int(GameState.bpm[suspect_id]) if suspect_id != "" else 75
	bpm_label.text = "%d BPM" % rate
	if stress != shown_stress:
		shown_stress = stress
		var tween := create_tween()
		tween.tween_property(stress_bar, "value", float(stress), 0.6).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tween.parallel().tween_method(_paint_stress, stress_fill.bg_color, _stress_color(stress), 0.6)
		if stress >= 35:
			var pulse := create_tween()
			pulse.tween_property(stress_bar, "modulate", Color(1.4, 1.1, 1.1), 0.12)
			pulse.tween_property(stress_bar, "modulate", Color.WHITE, 0.3)
	for child in options_box.get_children():
		child.queue_free()
	if suspect_id == "":
		options_box.add_child(UiStyle.label("Şüpheliyi seç.", 14, UiStyle.MUTED))
	else:
		var options := GameState.dialogue_options()
		var index := 0
		for option in options:
			var button := UiStyle.button("› " + str(option["text"]))
			button.alignment = HORIZONTAL_ALIGNMENT_LEFT
			button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			button.clip_text = false
			button.custom_minimum_size = Vector2(0, 30)
			button.add_theme_font_size_override("font_size", 14)
			if str(option.get("requires", "")) != "":
				button.add_theme_color_override("font_color", UiStyle.LAMP)
			button.pressed.connect(GameState.choose_option.bind(index))
			options_box.add_child(button)
			index += 1
	evidence_button.disabled = suspect_id == "" or GameState.clues.is_empty()
	report_button.visible = GameState.case_is_closed()


func _stress_color(stress: int) -> Color:
	if stress >= 70:
		return UiStyle.DANGER
	if stress >= 35:
		return UiStyle.LAMP
	return UiStyle.CRT


func _paint_stress(color: Color) -> void:
	stress_fill.bg_color = color


func _pick_clue(clue_id: String, layer: AcceptDialog) -> void:
	GameState.slam_evidence(clue_id)
	layer.hide()


func _open_picker() -> void:
	var layer := AcceptDialog.new()
	layer.theme = UiStyle.theme()
	layer.title = "Masaya vurulacak kanıt"
	layer.dialog_text = "Envanter boş." if GameState.clues.is_empty() else ""
	var list := VBoxContainer.new()
	layer.add_child(list)
	for id in GameState.clues:
		var found := Scenario.clue(id)
		var used: bool = GameState.active_suspect != "" and bool(GameState.used[GameState.active_suspect].has(id))
		var button := UiStyle.button("%s  %s" % [found.get("title", id), "vuruldu" if used else ""])
		button.pressed.connect(_pick_clue.bind(id, layer))
		list.add_child(button)
	ui.add_child(layer)
	layer.popup_centered()
	layer.confirmed.connect(layer.queue_free)
	layer.canceled.connect(layer.queue_free)


func _open_menu() -> void:
	if playing:
		Archive.remember(GameState.snapshot())
	menu_up = true
	menu.open_title()
	_apply_stage()
	_sync()


func _open_sorgu() -> void:
	start_case("episode_01")
	for id in Scenario.data.get("arrestClueIds", []):
		if not GameState.clues.has(str(id)):
			GameState.clues.append(str(id))
	GameState.savci_called = true
	GameState.incoming_call = false
	GameState.briefing_done = true
	GameState.travel("interrogation")
	var people: Array = Scenario.data.get("suspects", [])
	if not people.is_empty():
		GameState.select_suspect(str(people[0].get("id", "")))


func start_case(id: String) -> void:
	get_tree().paused = false
	playing = true
	menu_up = false
	menu.visible = false
	_apply_stage()
	_quiet_camera()
	if not GameState.open_case(id):
		playing = false
		menu_up = true
		menu.visible = true
		_apply_stage()
		return
	_frame_play()


func resume_case(id: String) -> void:
	get_tree().paused = false
	var snap := Archive.slot(id)
	if snap.is_empty():
		start_case(id)
		return
	if not Scenario.load_case(id):
		return
	playing = true
	menu_up = false
	menu.visible = false
	_apply_stage()
	_quiet_camera()
	GameState.apply_snapshot(snap)
	_frame_play()


func review_case(id: String) -> void:
	resume_case(id)
	GameState.show_case = true
	GameState.updated.emit()


func close_menu() -> void:
	menu_up = false
	menu.visible = false
	_apply_stage()
	_quiet_camera()
	_sync()


func frame_menu() -> void:
	if not playing:
		_apply_stage()
		return
	_frame_shot("menu")


func _apply_stage() -> void:
	var title := menu_up and not playing
	if stage == null:
		return
	stage.visible = title
	var cam: Camera3D = stage.get("camera")
	if cam:
		cam.current = title
	stage.set("drift", title)


func _frame_play() -> void:
	if GameState.scene_id != "office":
		return
	_frame_shot("brief" if GameState.incoming_call else "home")


func _frame_shot(key: String) -> void:
	if world.get_child_count() == 0:
		return
	var office := world.get_child(0)
	if not office.has_method("_dolly"):
		return
	var shots: Variant = office.get("shots")
	if not (shots is Dictionary) or not (shots as Dictionary).has(key):
		return
	shots = shots as Dictionary
	var at: Vector3 = shots[key][0]
	var look: Vector3 = shots[key][1]
	office._dolly(at, look)


func _quiet_camera() -> void:
	var cam := get_viewport().get_camera_3d()
	if cam:
		cam.h_offset = 0.0
		cam.v_offset = 0.0


func _hide_play_ui() -> void:
	hud.visible = false
	notice.visible = false
	dialogue_plate.visible = false
	query_plate.visible = false
	query_panel.visible = false
	call_panel.visible = false
	clue_panel.visible = false
	case_panel.visible = false
	map_panel.visible = false


func _paint_portrait(speaker: String) -> void:
	var face: Array = FACES.get(speaker, ["", "—"])
	var id := str(face[0])
	var mark := str(face[1])
	var hex := "#2a2420"
	var block: Dictionary = Scenario.data.get("characters", {}).get(id, {})
	if not block.is_empty():
		hex = str(block.get("primary", hex))
	else:
		for person in Scenario.data.get("suspects", []):
			if str(person["character"]["name"]) == speaker:
				hex = str(person["character"]["primary"])
	var box := StyleBoxFlat.new()
	box.bg_color = Color(hex)
	box.set_corner_radius_all(8)
	portrait.add_theme_stylebox_override("panel", box)
	portrait_mark.text = mark


func _fill_clue() -> void:
	for child in clue_panel.get_children():
		child.queue_free()
	clue_panel.visible = GameState.pending_clue_id != ""
	if GameState.pending_clue_id == "":
		return
	if GameState.pending_clue_id != shown_clue:
		shown_clue = GameState.pending_clue_id
		clue_panel.pivot_offset = Vector2(300, 180)
		clue_panel.scale = Vector2(0.92, 0.92)
		var punch := create_tween()
		punch.tween_property(clue_panel, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	var found := Scenario.clue(GameState.pending_clue_id)
	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_FULL_RECT)
	box.offset_left = 18
	box.offset_top = 18
	box.offset_right = -18
	box.offset_bottom = -18
	clue_panel.add_child(box)
	box.add_child(UiStyle.label("KANIT AÇILDI", 12, UiStyle.BLOOD, true))
	box.add_child(UiStyle.label(str(found.get("title", "")), 26, UiStyle.LAMP))
	box.add_child(UiStyle.typed(str(found.get("summary", "")), 16))
	var ok := UiStyle.button("Dosyaya işle")
	ok.pressed.connect(func() -> void:
		GameState.dismiss_clue()
	)
	box.add_child(ok)


func _fill_case() -> void:
	for child in case_panel.get_children():
		child.queue_free()
	case_panel.visible = GameState.show_case and playing and not menu_up
	if not case_panel.visible:
		return
	case_panel.offset_left = -420
	case_panel.offset_top = -300
	case_panel.offset_right = 420
	case_panel.offset_bottom = 280
	var scroll := ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll.offset_bottom = -56
	case_panel.add_child(scroll)
	var box := VBoxContainer.new()
	box.custom_minimum_size = Vector2(720, 0)
	box.add_theme_constant_override("separation", 6)
	scroll.add_child(box)
	var rows: Array = Scenario.data.get("clues", [])
	var missed: Array[String] = []
	for item in rows:
		var id := str(item.get("id", ""))
		if id != "" and not GameState.clues.has(id):
			missed.append(id)
	var people: Array = Scenario.data.get("suspects", [])
	var told := 0
	for person in people:
		if bool(GameState.confessed.get(str(person.get("id", "")), false)):
			told += 1
	var state := "Çözüldü"
	if GameState.sealed:
		state = "Kapatıldı"
	elif missed.size() > 0 and told == people.size() and not people.is_empty():
		state = "Eksik delil"
	elif missed.size() > 0:
		state = "Devam ediyor"
	box.add_child(UiStyle.label("DOSYA NO %s" % str(Scenario.data.get("fileNo", "")), 12, UiStyle.BLOOD, true))
	box.add_child(UiStyle.label(state, 30, UiStyle.LAMP))
	box.add_child(UiStyle.typed(str(Scenario.data.get("report", "")), 16))
	box.add_child(UiStyle.label("İTİRAF", 13, UiStyle.CRT, true))
	for person in people:
		var name := str(person["character"]["name"])
		var did := bool(GameState.confessed.get(str(person.get("id", "")), false))
		box.add_child(UiStyle.label("%s  ·  %s" % [name, "itiraf etti" if did else "sustu"], 16, UiStyle.INK if did else UiStyle.DANGER))
	box.add_child(UiStyle.label("TOPLANAN KANIT", 13, UiStyle.CRT, true))
	if GameState.clues.is_empty():
		box.add_child(UiStyle.label("Yok.", 14, UiStyle.MUTED))
	for id in GameState.clues:
		box.add_child(UiStyle.label(str(Scenario.clue(id).get("title", id)), 14))
	box.add_child(UiStyle.label("KAÇIRILAN KANIT", 13, UiStyle.DANGER, true))
	if missed.is_empty():
		box.add_child(UiStyle.label("Eksik yok.", 14, UiStyle.MUTED))
	for id in missed:
		box.add_child(UiStyle.label(str(Scenario.clue(id).get("title", id)), 14, UiStyle.DANGER))
	var grade := "Sıkı dosya"
	if missed.size() > 0:
		grade = "Eksik delil"
	elif GameState.wrong_slams > 2:
		grade = "Dağınık kapandı"
	box.add_child(UiStyle.label("PERFORMANS", 13, UiStyle.LAMP, true))
	box.add_child(UiStyle.label("Kanıt %d/%d  ·  İtiraf %d/%d  ·  Boş vuruş %d  ·  %s" % [GameState.clues.size(), rows.size(), told, people.size(), GameState.wrong_slams, grade], 15))
	var row := HBoxContainer.new()
	row.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	row.offset_top = -48
	case_panel.add_child(row)
	var back := UiStyle.button("Büroya dön")
	back.pressed.connect(func() -> void:
		GameState.close_case_report()
	)
	var seal := UiStyle.button("Dosyayı kapat")
	seal.pressed.connect(_seal_file)
	var nxt := Archive.next_case(Scenario.case_id)
	var onward := UiStyle.button("Sonraki dosya")
	onward.disabled = nxt.is_empty()
	onward.pressed.connect(func() -> void:
		var follow := Archive.next_case(Scenario.case_id)
		if follow.is_empty():
			return
		start_case(str(follow.get("id", "")))
	)
	row.add_child(back)
	row.add_child(seal)
	row.add_child(onward)


func _seal_file() -> void:
	GameState.sealed = true
	GameState.show_case = false
	Archive.remember(GameState.snapshot())
	playing = false
	menu_up = true
	menu.open_title()
	_sync()


func _overlay() -> Panel:
	var panel := Panel.new()
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	var box := StyleBoxFlat.new()
	box.bg_color = Color(0.02, 0.03, 0.05, 0.92)
	panel.add_theme_stylebox_override("panel", box)
	return panel


func _paper_panel() -> Panel:
	var panel := Panel.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left = -300
	panel.offset_top = -180
	panel.offset_right = 300
	panel.offset_bottom = 180
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	return panel


func _add_crt() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 100
	add_child(layer)
	var rect := ColorRect.new()
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mat := ShaderMaterial.new()
	mat.shader = load("res://theme/crt_overlay.gdshader")
	rect.material = mat
	layer.add_child(rect)
