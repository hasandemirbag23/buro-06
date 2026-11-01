extends Node3D

const RIG := preload("res://scenes/character_rig.tscn")
const MeshFactory := preload("res://scenes/mesh_factory.gd")
const UiStyle := preload("res://scenes/ui_style.gd")

const ORDER := ["behzat", "akbaba", "hayalet", "savci", "tarik", "player", "zafer", "arsiv"]
const CELL_W := 150
const CELL_H := 300
const CARD_W := 280
const TITLE_H := 56
const OUT := "res://docs/concept/character_sheet.png"

var cam: Camera3D
var label: Label
var card: PanelContainer
var card_text: Label
var title_label: Label


func _ready() -> void:
	add_child(MeshFactory.environment(Color("15181f"), Color("8c8274"), 0.0, 1.0))
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-45, 35, 0)
	sun.light_energy = 1.3
	sun.shadow_enabled = true
	add_child(sun)
	var fill := OmniLight3D.new()
	fill.position = Vector3(-2.5, 2.2, 3.0)
	fill.light_energy = 1.2
	fill.omni_range = 9.0
	add_child(fill)
	MeshFactory.block(self, Vector3(30, 0.1, 30), Vector3(0, -0.05, 0), Color("3b3a3d"))
	cam = Camera3D.new()
	cam.fov = 30
	add_child(cam)
	cam.current = true
	var layer := CanvasLayer.new()
	add_child(layer)
	label = UiStyle.label("", 20, Color("f5d78a"), true)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.position = Vector2(460, 10)
	label.size = Vector2(360, 30)
	layer.add_child(label)
	card = PanelContainer.new()
	card.position = Vector2(0, 0)
	card.size = Vector2(CARD_W * 2, CELL_H * 2)
	card.visible = false
	var style := StyleBoxFlat.new()
	style.bg_color = Color("14171D")
	style.border_color = Color("F59E0B")
	style.set_border_width_all(2)
	style.set_corner_radius_all(0)
	style.set_content_margin_all(22)
	card.add_theme_stylebox_override("panel", style)
	layer.add_child(card)
	card_text = UiStyle.label("", 26, UiStyle.INK)
	card_text.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	card.add_child(card_text)
	title_label = UiStyle.label("", 34, UiStyle.LAMP, true)
	title_label.position = Vector2(0, 0)
	title_label.size = Vector2(1280, TITLE_H * 2)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_label.visible = false
	layer.add_child(title_label)
	await get_tree().process_frame
	await _build_sheet()
	get_tree().quit()


func _build_sheet() -> void:
	var cols := 7
	var width := CARD_W + cols * CELL_W
	var height := TITLE_H + ORDER.size() * CELL_H
	var sheet := Image.create(width, height, false, Image.FORMAT_RGBA8)
	sheet.fill(Color("0c1016"))
	# başlık
	title_label.visible = true
	title_label.text = "BÜRO: DOSYA NO 06 — KARAKTER KONSEPT SAYFASI"
	cam.position = Vector3(0, 40, 0)
	cam.look_at(Vector3(0, 0, -1))
	await _frames(2)
	var title_img := _shot(Rect2i(0, 0, 1280, TITLE_H * 2))
	title_img.resize(width, TITLE_H, Image.INTERPOLATE_LANCZOS)
	sheet.blit_rect(title_img, Rect2i(0, 0, width, TITLE_H), Vector2i(0, 0))
	title_label.visible = false
	var designs: Dictionary = RIG.instantiate().get_script().designs()
	var row := 0
	for who in ORDER:
		var design: Dictionary = designs.get(who, {})
		var rig := RIG.instantiate()
		add_child(rig)
		rig.setup(who)
		rig.act("Idle")
		for child in rig.body.get_children():
			if child is Label3D:
				child.visible = false
		var y := TITLE_H + row * CELL_H
		# kart
		card.visible = true
		card_text.text = "%s\n\nYaş: %s\n\n%s" % [design.get("title", who), design.get("age", "-"), design.get("look", "")]
		cam.position = Vector3(0, 40, 0)
		cam.look_at(Vector3(0, 0, -1))
		await _frames(2)
		var card_img := _shot(Rect2i(0, 0, CARD_W * 2, CELL_H * 2))
		card_img.resize(CARD_W, CELL_H, Image.INTERPOLATE_LANCZOS)
		sheet.blit_rect(card_img, Rect2i(0, 0, CARD_W, CELL_H), Vector2i(0, y))
		card.visible = false
		# ön / yan / arka
		var views := [["ÖN", Vector3(0, 1.0, 4.6)], ["YAN", Vector3(4.6, 1.0, 0)], ["ARKA", Vector3(0, 1.0, -4.6)]]
		var col := 0
		for view in views:
			label.position = Vector2(460, 10)
			label.size = Vector2(360, 30)
			label.text = view[0]
			cam.position = view[1]
			cam.look_at(Vector3(0, 0.95, 0))
			await _frames(3)
			var img := _shot(Rect2i(460, 0, 360, 720))
			img.resize(CELL_W, CELL_H, Image.INTERPOLATE_LANCZOS)
			sheet.blit_rect(img, Rect2i(0, 0, CELL_W, CELL_H), Vector2i(CARD_W + col * CELL_W, y))
			col += 1
		# yüz yakın plan
		label.position = Vector2(280, 10)
		label.size = Vector2(720, 30)
		label.text = "YÜZ"
		cam.position = Vector3(0.35, 1.62, 1.05)
		cam.look_at(Vector3(0, 1.58, 0))
		await _frames(3)
		var face := _shot(Rect2i(280, 0, 720, 720))
		face.resize(CELL_W, CELL_W, Image.INTERPOLATE_LANCZOS)
		sheet.blit_rect(face, Rect2i(0, 0, CELL_W, CELL_W), Vector2i(CARD_W + col * CELL_W, y + (CELL_H - CELL_W) / 2))
		col += 1
		# aksiyonlar
		var actions: Array = design.get("animations", {}).keys()
		actions = actions.filter(func(a): return a != "Idle")
		for k in 3:
			if k >= actions.size():
				break
			var action: String = actions[k]
			rig.act(action)
			label.position = Vector2(460, 10)
			label.size = Vector2(360, 30)
			label.text = action
			cam.position = Vector3(1.9, 1.1, 4.2)
			cam.look_at(Vector3(0, 0.95, 0))
			await get_tree().create_timer(0.5).timeout
			var img := _shot(Rect2i(460, 0, 360, 720))
			img.resize(CELL_W, CELL_H, Image.INTERPOLATE_LANCZOS)
			sheet.blit_rect(img, Rect2i(0, 0, CELL_W, CELL_H), Vector2i(CARD_W + col * CELL_W, y))
			col += 1
		rig.queue_free()
		await _frames(1)
		row += 1
	# ızgara çizgileri
	for r in ORDER.size() + 1:
		var yy := TITLE_H + r * CELL_H
		if yy < height:
			sheet.fill_rect(Rect2i(0, yy, width, 1), Color("F59E0B", 0.35))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://docs/concept"))
	sheet.save_png(OUT)
	print("SHEET_OK ", ProjectSettings.globalize_path(OUT))


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw


func _shot(region: Rect2i) -> Image:
	var img := get_viewport().get_texture().get_image()
	var out := img.get_region(region)
	out.convert(Image.FORMAT_RGBA8)
	return out
