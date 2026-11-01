extends Node3D
## Karakter vitrini: tüm karakterler yan yana; kamera açıları, yüz yakınlaştırma, ışık ön ayarları, materyal karşılaştırma.
## Tuşlar: A/D karakter seç | 0 genel | 1 ön | 2 yan | 3 45° | 4 yüz | L ışık | F sis | M görünüm modu | P ekran görüntüsü
## Otomasyon: godot --path . res://scenes/CharacterShowcase.tscn -- shots [id ...]  -> /tmp/showcase_<id>_<açı>_<ışık>.png

const RIG := preload("res://scenes/character_rig.tscn")
const IDS := ["behzat", "hayalet", "akbaba", "player", "savci", "arsiv", "tarik", "zafer", "mert", "haldun", "nevzat", "idris"]
const EPISODE_OF := {"mert": "episode_02", "haldun": "episode_02", "nevzat": "episode_03", "idris": "episode_03"}
const SPACING := 1.5
const COLS := 6
const ROW_GAP := 2.6
const LIGHTS := {
	"sinema": {"key": Color("ffd9a0"), "key_e": 1.9, "key_rot": Vector3(-28, -38, 0), "rim": Color("86a6e8"), "rim_e": 0.35, "fill_e": 0.18, "amb": Color("2a3140"), "amb_e": 0.8, "fog": 0.012},
	"ofis": {"key": Color("ffe6bd"), "key_e": 1.2, "key_rot": Vector3(-60, -15, 0), "rim": Color("9fb8ff"), "rim_e": 0.4, "fill_e": 0.35, "amb": Color("5a5750"), "amb_e": 1.0, "fog": 0.0},
	"sert": {"key": Color("fff0d8"), "key_e": 2.6, "key_rot": Vector3(-14, -62, 0), "rim": Color("4a6cd0"), "rim_e": 0.7, "fill_e": 0.05, "amb": Color("14161c"), "amb_e": 0.4, "fog": 0.0},
	"gece": {"key": Color("c8d6ff"), "key_e": 0.7, "key_rot": Vector3(-35, 25, 0), "rim": Color("ffb35c"), "rim_e": 1.4, "fill_e": 0.1, "amb": Color("1c2433"), "amb_e": 0.9, "fog": 0.02},
	"gun": {"key": Color("fff4e6"), "key_e": 1.5, "key_rot": Vector3(-50, -25, 0), "rim": Color("bcd2ff"), "rim_e": 0.3, "fill_e": 0.5, "amb": Color("7b8594"), "amb_e": 1.3, "fog": 0.0},
}
const ANGLES := ["front", "side", "q", "face"]
const VIEW_MODES := [Viewport.DEBUG_DRAW_DISABLED, Viewport.DEBUG_DRAW_UNSHADED, Viewport.DEBUG_DRAW_NORMAL_BUFFER, Viewport.DEBUG_DRAW_WIREFRAME]

var rigs: Dictionary = {}
var cam: Camera3D
var key: DirectionalLight3D
var rim: DirectionalLight3D
var fill: OmniLight3D
var env: Environment
var selected := 0
var angle := "front"
var overview := true
var light_name := "sinema"
var view_mode := 0
var fog_on := true
var _target_pos := Vector3.ZERO
var _target_look := Vector3.ZERO
var _fov := 30.0


func _ready() -> void:
	_build_stage()
	for i in IDS.size():
		var id: String = IDS[i]
		Scenario.load_case(EPISODE_OF.get(id, "episode_01"))
		var rig := RIG.instantiate()
		add_child(rig)
		rig.setup(id)
		rig.pose("breathe")
		for label in rig.find_children("*", "Label3D", true, false):
			label.visible = false
		rig.position = Vector3(((i % COLS) - (COLS - 1) * 0.5) * SPACING, 0, -(i / COLS) * ROW_GAP)
		rigs[id] = rig
	_apply_light(light_name)
	_frame(true)
	var args := Array(OS.get_cmdline_user_args())
	if args.has("shots"):
		args.erase("shots")
		_auto_shots(args)


func _build_stage() -> void:
	env = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("12141a")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.ssao_enabled = true
	env.ssao_intensity = 1.2
	env.ssao_radius = 0.25
	env.glow_enabled = true
	env.glow_intensity = 0.25
	env.fog_enabled = true
	env.fog_light_color = Color("3a4252")
	env.fog_density = 0.0
	env.volumetric_fog_enabled = true
	env.volumetric_fog_density = 0.0
	env.volumetric_fog_albedo = Color("8a93a6")
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	key = DirectionalLight3D.new()
	key.shadow_enabled = true
	key.directional_shadow_max_distance = 12.0
	add_child(key)
	rim = DirectionalLight3D.new()
	rim.rotation_degrees = Vector3(-15, 155, 0)
	add_child(rim)
	fill = OmniLight3D.new()
	fill.position = Vector3(0, 1.4, 3.5)
	fill.omni_range = 14.0
	add_child(fill)
	var floor_mesh := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(30, 14)
	floor_mesh.position = Vector3(0, 0, -3)
	floor_mesh.mesh = plane
	var floor_mat := StandardMaterial3D.new()
	floor_mat.albedo_color = Color("0c0d10")
	floor_mat.roughness = 0.95
	floor_mat.metallic_specular = 0.15
	floor_mesh.material_override = floor_mat
	add_child(floor_mesh)
	var wall := MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = Vector2(30, 6)
	wall.mesh = quad
	wall.position = Vector3(0, 3, -5.0)
	var wall_mat := StandardMaterial3D.new()
	wall_mat.albedo_color = Color("23262d")
	wall_mat.roughness = 0.95
	wall.material_override = wall_mat
	add_child(wall)
	cam = Camera3D.new()
	cam.current = true
	add_child(cam)


func _apply_light(name: String) -> void:
	var p: Dictionary = LIGHTS[name]
	light_name = name
	key.light_color = p["key"]
	key.light_energy = p["key_e"]
	key.rotation_degrees = p["key_rot"]
	rim.light_color = p["rim"]
	rim.light_energy = p["rim_e"]
	fill.light_energy = p["fill_e"]
	fill.shadow_enabled = false
	env.ambient_light_color = p["amb"]
	env.ambient_light_energy = p["amb_e"]
	var density: float = p["fog"] if fog_on else 0.0
	env.volumetric_fog_density = density
	env.fog_density = density * 0.4


## Yüz yakın plan kamerası için başın dünya konumu.
func head_position(id: String) -> Vector3:
	var rig: Node3D = rigs[id]
	if rig.has_meta("head_root"):
		return (rig.get_meta("head_root") as Node3D).global_position
	return rig.global_position + Vector3(0, 1.62, 0)


func face_camera(id: String, deg_yaw := 12.0) -> Dictionary:
	var rig: Node3D = rigs[id]
	var head := head_position(id)
	var basis := Basis.IDENTITY
	if rig.has_meta("head_root"):
		basis = (rig.get_meta("head_root") as Node3D).global_transform.basis
	var dir := Basis(Vector3.UP, deg_to_rad(deg_yaw)) * Vector3(0, 0.02, 1.0)
	return {"pos": head + basis * (dir * 0.95), "look": head + basis * Vector3(0, -0.012, 0), "fov": 17.0, "up": basis.y}


func _frame(snap := false) -> void:
	var up := Vector3.UP
	if overview:
		_target_pos = Vector3(0, 4.6, 11.0)
		_target_look = Vector3(0, 0.95, -1.1)
		_fov = 38.0
	else:
		var id: String = IDS[selected]
		var rig: Node3D = rigs[id]
		var c := rig.global_position
		match angle:
			"front":
				_target_pos = c + Vector3(0, 1.15, 4.4)
				_target_look = c + Vector3(0, 0.95, 0)
				_fov = 30.0
			"side":
				_target_pos = c + Vector3(4.4, 1.15, 0)
				_target_look = c + Vector3(0, 0.95, 0)
				_fov = 30.0
			"q":
				_target_pos = c + Vector3(3.1, 1.15, 3.1)
				_target_look = c + Vector3(0, 0.95, 0)
				_fov = 30.0
			"face":
				var f := face_camera(id, 14.0)
				_target_pos = f["pos"]
				_target_look = f["look"]
				_fov = f["fov"]
				up = f["up"]
	cam.fov = _fov if snap else cam.fov
	if snap:
		cam.position = _target_pos
	cam.look_at(_target_look, up)
	set_process(true)


func _process(delta: float) -> void:
	var t := 1.0 - exp(-8.0 * delta)
	cam.position = cam.position.lerp(_target_pos, t)
	cam.fov = lerpf(cam.fov, _fov, t)
	cam.look_at(_target_look, Vector3.UP if angle != "face" or overview else (face_camera(IDS[selected])["up"]))


func _unhandled_key_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed):
		return
	match event.keycode:
		KEY_A:
			selected = (selected + IDS.size() - 1) % IDS.size()
			overview = false
		KEY_D:
			selected = (selected + 1) % IDS.size()
			overview = false
		KEY_0:
			overview = true
		KEY_1, KEY_2, KEY_3, KEY_4:
			angle = ANGLES[event.keycode - KEY_1]
			overview = false
		KEY_L:
			var names := LIGHTS.keys()
			_apply_light(names[(names.find(light_name) + 1) % names.size()])
		KEY_F:
			fog_on = not fog_on
			_apply_light(light_name)
		KEY_M:
			view_mode = (view_mode + 1) % VIEW_MODES.size()
			get_viewport().debug_draw = VIEW_MODES[view_mode]
		KEY_P:
			save_shot("manual")
	_frame()


func save_shot(tag: String) -> void:
	var id: String = IDS[selected]
	var path := "/tmp/showcase_%s_%s_%s.png" % [id if not overview else "all", angle if not overview else "overview", light_name]
	get_viewport().get_texture().get_image().save_png(path)
	print("kaydedildi: ", path)


func _auto_shots(ids: Array) -> void:
	if ids.is_empty():
		ids = IDS.duplicate()
	for light in ["sinema", "ofis", "gece"]:
		_apply_light(light)
		overview = true
		_frame(true)
		for i in 8:
			await get_tree().process_frame
		save_shot("auto")
	_apply_light("sinema")
	for id in ids:
		selected = IDS.find(id)
		overview = false
		for a in ANGLES:
			angle = a
			_frame(true)
			for i in 6:
				await get_tree().process_frame
			save_shot("auto")
	get_tree().quit()
