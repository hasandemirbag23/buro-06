extends Node3D
## Yüz deformasyonu denetimi: her durumu sabitleyip yakın plan kaydeder.
## godot --path . --resolution 640x640 res://tools/face_test.tscn -- behzat zafer
## Çıktı: /tmp/face_<id>_<durum>.png

const Styler := preload("res://scenes/character_styler.gd")
const MeshFactory := preload("res://scenes/mesh_factory.gd")

## durum adı -> üniform değerleri
const STATES := [
	["notr", {}],
	["kirpma_yari", {"f_blink": 0.5}],
	["kirpma_tam", {"f_blink": 1.0}],
	["agiz_acik", {"f_jaw": 0.85}],
	["kas_kalkik", {"f_brow": 1.0}],
	["kizgin", {"f_brow": -0.85, "f_squint": 0.42, "f_sneer": 0.28, "f_smile": -0.32}],
	["gulumseme", {"f_smile": 0.6}],
	["uzgun", {"f_brow_in": 0.95, "f_smile": -0.62, "f_squint": 0.45}],
	["konusma", {"f_jaw": 0.55, "f_brow": 0.15}],
]
const KEYS := ["f_blink", "f_jaw", "f_brow", "f_brow_in", "f_squint", "f_smile", "f_sneer"]


func _ready() -> void:
	add_child(MeshFactory.environment(Color("1a1d24"), Color("8c8274"), 0.0, 0.9))
	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-22, -26, 0)
	key.light_energy = 1.8
	key.light_color = Color("ffe2bd")
	key.shadow_enabled = true
	add_child(key)
	var rim := DirectionalLight3D.new()
	rim.rotation_degrees = Vector3(-18, 158, 0)
	rim.light_energy = 0.8
	rim.light_color = Color("9fb8ff")
	add_child(rim)
	var fill := OmniLight3D.new()
	fill.position = Vector3(0.25, 0.0, 0.45)
	fill.light_energy = 0.5
	add_child(fill)
	var cam := Camera3D.new()
	cam.fov = 14
	add_child(cam)
	cam.current = true

	var args := Array(OS.get_cmdline_user_args())
	if args.has("live"):
		args.erase("live")
		await _live(str(args[0]) if not args.is_empty() else "behzat", cam)
		get_tree().quit()
		return
	for id in (args if not args.is_empty() else ["behzat"]):
		var head := Styler.build_head(id)
		add_child(head)
		var mats: Array = head.get_meta("face_mats", [])
		for row in STATES:
			var name: String = row[0]
			var vals: Dictionary = row[1]
			for m in mats:
				for k in KEYS:
					m.set_shader_parameter(k, float(vals.get(k, 0.0)))
			for yaw in [0.0, 30.0]:
				var dir := Vector3(sin(deg_to_rad(yaw)), 0.06, cos(deg_to_rad(yaw)))
				cam.position = dir * 1.05
				cam.look_at(Vector3(0, -0.022, 0))
				for i in 3:
					await get_tree().process_frame
				await RenderingServer.frame_post_draw
				var tag := "%s_%s%s" % [id, name, "" if yaw == 0.0 else "_q"]
				get_viewport().get_texture().get_image().save_png("/tmp/face_%s.png" % tag)
				print("kaydedildi: /tmp/face_%s.png" % tag)
		head.queue_free()
	get_tree().quit()


## Canlı zincir: CharacterRig -> FaceRig -> gölgelendirici. GameState üzerinden
## konuşturup kare kare kaydeder; kırpma ve ağız hareketi karelerde görünür.
func _live(id: String, cam: Camera3D) -> void:
	var rig: Node3D = preload("res://scenes/character_rig.tscn").instantiate()
	add_child(rig)
	rig.setup(id)
	var face: Node = rig.get_node_or_null("FaceRig")
	if face == null:
		push_error("FaceRig bağlanmadı: %s" % id)
		return
	print("FaceRig bağlandı, materyal sayısı: %d, göz: %d" % [face.mats.size(), face.eyes.size()])
	rig.act("Talking")
	face.talk_for(6.0)
	# Kafa, animasyonla birlikte oynuyor; kamerayı kafa düğümüne kilitle.
	var head_root: Node3D = rig.get_meta("head_root", null)
	cam.fov = 20
	for i in 24:
		for f in 5:
			await get_tree().process_frame
		if head_root and is_instance_valid(head_root):
			# head_root kafatası tepesinde (HEAD_OFFSET); yüz ~5 cm aşağıda
			var at := head_root.global_position + Vector3(0.0, -0.050, 0.0)
			cam.position = at + Vector3(0.05, 0.0, 0.52)
			cam.look_at(at)
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("/tmp/live_%s_%02d.png" % [id, i])
	print("canlı kareler: /tmp/live_%s_*.png" % id)
