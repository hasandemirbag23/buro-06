extends Node3D

## Sorgu odası: küçük, havasız; metal masa, karşılıklı sandalyeler, sarkan floresan,
## tek yönlü ayna, köşe kamerası. Kamera geçişleri AnimationPlayer, karakterler AnimationTree (rig),
## kanıt düşüşü + ses + CameraShake. Stres GameState'ten okunur.

const MeshFactory := preload("res://scenes/mesh_factory.gd")
const RIG := preload("res://scenes/character_rig.tscn")
const CHAIR := preload("res://assets/furniture/chair.glb")

const SHOT_NODES := {"wide": "Cam_Wide", "closeup": "Cam_SuspectCloseUp", "detective": "Cam_DetectiveCloseUp", "tabletop": "Cam_TableTop", "arrest": "Cam_Arrest", "wall": "Cam_Wall"}

var camera: Camera3D
var cam_rig: Node3D
var cam_shake: Node3D
var look_target: Node3D
var cam_anim: AnimationPlayer
var suspect: Node3D
var behzat: Node3D
var player: Node3D
var lamp_pivot: Node3D
var tube_mat: StandardMaterial3D
var bulb: OmniLight3D
var led: MeshInstance3D
var paper: Node3D
var sfx: AudioStreamPlayer
var shown_suspect := ""
var _escorting := false
var _confessing := false
var _at_wall := false
var _escort: Node3D
var shown_shot := ""
var shake_amp := 0.0
var shake_time := 0.0
var sequence_lock := false
var _enter: Tween
var _cell_door: Node3D
var slap_sound: AudioStreamWAV
var thud_sound: AudioStreamWAV
var flicker_t := 0.0


func _ready() -> void:
	_build()
	GameState.updated.connect(_refresh)
	GameState.slammed.connect(_on_slam)
	_refresh()
	var sway := create_tween().set_loops()
	sway.tween_property(lamp_pivot, "rotation_degrees:z", 2.2, 2.1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	sway.tween_property(lamp_pivot, "rotation_degrees:z", -2.2, 2.1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _process(delta: float) -> void:
	# Subtle CameraShake: el kamerası titremesi + darbe sönümü
	shake_time += delta
	shake_amp = lerpf(shake_amp, 0.0, 1.0 - exp(-delta * 5.5))
	var idle := 0.0035
	var amp := idle + shake_amp
	cam_shake.position = Vector3(
		sin(shake_time * 13.1) * amp + sin(shake_time * 2.3) * idle,
		cos(shake_time * 11.7) * amp * 0.8 + cos(shake_time * 1.7) * idle,
		0.0)
	cam_shake.rotation_degrees.z = sin(shake_time * 9.3) * amp * 6.0
	camera.look_at(look_target.global_position + cam_shake.position * 0.5)
	# floresan vızıltısı / titremesi
	flicker_t += delta
	var flicker := 1.0
	if fmod(flicker_t, 6.3) < 0.18:
		flicker = 0.55 + 0.45 * absf(sin(flicker_t * 90.0))
	bulb.light_energy = 5.2 * flicker
	tube_mat.emission_energy_multiplier = 2.4 * flicker
	# köşe kamerası LED
	led.material_override.emission_energy_multiplier = 3.0 if fmod(flicker_t, 1.4) < 0.12 else 0.4


func shake(strength: float) -> void:
	shake_amp = maxf(shake_amp, strength)


## Kamera geçişi: AnimationPlayer ile rig ve bakış hedefi birlikte hareket eder.
func set_shot(mode: String) -> void:
	if not SHOT_NODES.has(mode):
		return
	var marker := get_node(SHOT_NODES[mode]) as Marker3D
	var target_at: Vector3 = marker.position
	var target_look: Vector3 = marker.get_meta("look")
	var anim := Animation.new()
	anim.length = 0.55
	var pos_track := anim.add_track(Animation.TYPE_POSITION_3D)
	anim.track_set_path(pos_track, NodePath("CamRig"))
	anim.position_track_insert_key(pos_track, 0.0, cam_rig.position)
	anim.position_track_insert_key(pos_track, anim.length, target_at)
	var look_track := anim.add_track(Animation.TYPE_POSITION_3D)
	anim.track_set_path(look_track, NodePath("LookTarget"))
	anim.position_track_insert_key(look_track, 0.0, look_target.position)
	anim.position_track_insert_key(look_track, anim.length, target_look)
	var fov_track := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(fov_track, NodePath("CamRig/Shake/Camera:fov"))
	anim.track_insert_key(fov_track, 0.0, camera.fov)
	anim.track_insert_key(fov_track, anim.length, float(marker.get_meta("fov")))
	anim.track_set_interpolation_type(fov_track, Animation.INTERPOLATION_CUBIC)
	var lib: AnimationLibrary = cam_anim.get_animation_library("")
	if lib.has_animation("move"):
		lib.remove_animation("move")
	lib.add_animation("move", anim)
	cam_anim.play("move")


func _refresh() -> void:
	if GameState.shot != shown_shot and not sequence_lock:
		shown_shot = GameState.shot
		set_shot(GameState.shot)
	if behzat:
		if GameState.behzat_line != "":
			behzat.act("TalkToSuspect")
		else:
			behzat.act("Confident")
	_place_suspect()
	_face()
	_lay_files()


func _open_cell_door() -> void:
	if _cell_door:
		_cell_door.rotation_degrees.y = 0.0


func _face() -> void:
	if suspect and Cinematic.liar == GameState.active_suspect:
		suspect.set_expression("nervous")


func _place_suspect() -> void:
	if _escorting:
		return
	if GameState.active_suspect == shown_suspect and suspect:
		if _at_wall or _confessing:
			return
		suspect.play(GameState.anims[GameState.active_suspect])
		return
	if _enter:
		_enter.kill()
	if suspect:
		suspect.queue_free()
		suspect = null
	if _escort:
		_escort.queue_free()
		_escort = null
	_at_wall = false
	shown_suspect = GameState.active_suspect
	if GameState.active_suspect == "":
		return
	var home := Vector3(0.0, 0.0, -0.52)
	var outside := Vector3(3.2, 0.0, 1.62)
	var trail := Vector3(0.95, 0.0, 0.0)
	suspect = RIG.instantiate()
	suspect.position = outside
	suspect.rotation_degrees.y = -90
	suspect.seated = false
	add_child(suspect)
	suspect.setup(GameState.active_suspect)
	suspect.act("Cuffed")
	suspect.wear_cuffs()
	_hide_tag(suspect)
	_escort = RIG.instantiate()
	_escort.position = outside + trail
	_escort.rotation_degrees.y = -90
	add_child(_escort)
	_escort.setup("hayalet")
	_escort.pose("walk")
	_hide_tag(_escort)
	_pace(suspect, 0.45)
	_pace(_escort, 0.45)
	_open_cell_door()
	_escorting = true
	sequence_lock = true
	_go_marker("arrest")
	Cinematic.play("arrest")
	var inside := Vector3(1.7, 0.0, 1.62)
	var flank := Vector3(0.85, 0.0, -1.25)
	_enter = create_tween()
	_enter.tween_property(_cell_door, "rotation_degrees:y", 100.0, 1.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_enter.tween_property(suspect, "position", inside, 2.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_enter.parallel().tween_property(_escort, "position", inside + trail, 2.8)
	_enter.tween_callback(func() -> void:
		if suspect:
			suspect.rotation_degrees.y = -180
		if _escort:
			_escort.rotation_degrees.y = -180
	)
	_enter.tween_property(suspect, "position", home, 4.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_enter.parallel().tween_property(_escort, "position", flank, 4.4)
	_enter.tween_callback(func() -> void:
		_escorting = false
		sequence_lock = false
		_pace(suspect, 1.0)
		_pace(_escort, 1.0)
		if _escort:
			_escort.pose("stand")
			_escort.rotation_degrees.y = -180
		if suspect:
			suspect.rotation_degrees.y = 0
			suspect.seated = true
			suspect.state = ""
			suspect.play(GameState.anims.get(GameState.active_suspect, "IDLE"))
			suspect.wear_cuffs()
			_face()
		GameState.shot = "closeup"
		shown_shot = "closeup"
		set_shot("closeup")
	)


## Kanıt masaya iner: masa üstü kamera → kâğıt düşer → ses + sarsıntı → şüpheli yüzü.
func _on_slam(clue_id: String) -> void:
	var found := Scenario.clue(clue_id)
	if paper:
		paper.queue_free()
	paper = Node3D.new()
	add_child(paper)
	var sheet := MeshFactory.box(paper, Vector3(0.3, 0.012, 0.42), Vector3.ZERO, Color("e3d6b4"), 0.9)
	MeshFactory.box(paper, Vector3(0.24, 0.001, 0.02), Vector3(0, 0.0075, -0.14), Color("2a2118"))
	MeshFactory.box(paper, Vector3(0.2, 0.001, 0.012), Vector3(-0.02, 0.0075, -0.09), Color("5a5048"))
	MeshFactory.box(paper, Vector3(0.22, 0.001, 0.012), Vector3(0.01, 0.0075, -0.05), Color("5a5048"))
	MeshFactory.box(paper, Vector3(0.1, 0.001, 0.05), Vector3(0.08, 0.0075, 0.12), Color("DC2626"), 0.6, 0.3)
	var tag := MeshFactory.label(paper, found.get("title", "KANIT"), Vector3(0, 0.03, 0.02), Color("2a2118"), 0.32)
	tag.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	tag.rotation_degrees.x = -90
	sheet.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	paper.position = Vector3(0.35, 1.25, 0.62)
	paper.rotation_degrees = Vector3(-35, 20, 12)
	var land := Vector3(0.12, 0.775, -0.02)
	sequence_lock = true
	_go_marker("tabletop")
	var fall := create_tween()
	fall.tween_property(paper, "position", land, 0.42).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	fall.parallel().tween_property(paper, "rotation_degrees", Vector3(0, -8 + randf() * 16.0, 0), 0.42)
	fall.tween_callback(_paper_landed)
	fall.tween_interval(0.75)
	fall.tween_callback(func() -> void:
		if GameState.anims.get(GameState.active_suspect, "") == "BROKEN_CONFESS":
			_start_confession()
			return
		sequence_lock = false
		shown_shot = GameState.shot
		set_shot(GameState.shot)
	)
	if suspect and GameState.anims.get(GameState.active_suspect, "") == "ANGRY_SLAM":
		get_tree().create_timer(0.5).timeout.connect(func() -> void:
			if suspect:
				suspect.slam_table()
			_play(thud_sound, -4.0)
			shake(0.05)
		)


func _start_confession() -> void:
	if suspect == null or _confessing or _at_wall:
		sequence_lock = false
		return
	_confessing = true
	sequence_lock = true
	suspect.seated = false
	suspect.act("Cuffed")
	suspect.wear_cuffs()
	var wall_spot := Vector3(0.55, 0.0, -1.7)
	if _escort == null:
		_escort = RIG.instantiate()
		_escort.position = suspect.position + Vector3(0.7, 0.0, 0.3)
		add_child(_escort)
		_escort.setup("hayalet")
	_escort.pose("walk")
	_go_marker("wall")
	var turn := create_tween()
	turn.tween_property(suspect, "rotation_degrees:y", 180.0, 0.4)
	turn.parallel().tween_property(suspect, "position", wall_spot, 1.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	turn.parallel().tween_property(_escort, "position", wall_spot + Vector3(0.78, 0.0, 0.2), 1.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	turn.tween_callback(func() -> void:
		if _escort:
			_escort.rotation_degrees.y = -70
			_escort.act("GrabArm")
		if suspect:
			suspect.rotation_degrees.y = 180
			suspect.act("Breakdown")
			suspect.wear_cuffs()
		_confessing = false
		_at_wall = true
		sequence_lock = false
	)


func _paper_landed() -> void:
	_play(slap_sound, -6.0)
	shake(0.03)
	var kick := create_tween()
	kick.tween_property(lamp_pivot, "rotation_degrees:z", 5.0, 0.08)
	kick.tween_property(lamp_pivot, "rotation_degrees:z", -3.0, 0.14)


func _pace(rig: Node, scale: float) -> void:
	if rig and rig.get("player") is AnimationPlayer:
		(rig.player as AnimationPlayer).speed_scale = scale


func _hide_tag(rig: Node) -> void:
	for tag in rig.find_children("*", "Label3D", true, false):
		tag.visible = false


func _go_marker(mode: String) -> void:
	shown_shot = mode
	set_shot(mode)


func _play(stream: AudioStream, volume_db: float) -> void:
	sfx.stream = stream
	sfx.volume_db = volume_db
	sfx.play()


func _lay_files() -> void:
	var existing := get_node_or_null("Files")
	if existing:
		existing.queue_free()
	var pile := Node3D.new()
	pile.name = "Files"
	add_child(pile)
	var index := 0
	for clue_id in GameState.table_clues:
		var card := MeshFactory.box(pile, Vector3(0.26, 0.012, 0.36), Vector3(-0.55 + index * 0.14, 0.775 + index * 0.012, 0.22 - index * 0.04), Color("d8c7a1"), 0.9)
		card.rotation_degrees.y = -14 + index * 7
		var tag := MeshFactory.label(card, Scenario.clue(clue_id).get("icon", "DOSYA"), Vector3(0, 0.012, 0), Color("2a2118"), 0.3)
		tag.billboard = BaseMaterial3D.BILLBOARD_DISABLED
		tag.rotation_degrees.x = -90
		index += 1


func _build() -> void:
	add_child(MeshFactory.environment(Color("0a0907"), Color("5a5244"), 0.015, 0.9, false))
	_room()
	_table()
	_props()
	_people()
	_cameras()
	_sounds()


func _room() -> void:
	var wall_mat := MeshFactory.pbr("plastered_wall_02", Color(0.56, 0.6, 0.5), Vector2(2.2, 1.4), 1.0)
	var floor_mat := MeshFactory.pbr("concrete_floor_worn_001", Color(0.42, 0.4, 0.37), Vector2(3.0, 3.0), 1.0)
	var ceil_mat := MeshFactory.pbr("plastered_wall_02", Color(0.3, 0.3, 0.27), Vector2(2.0, 2.0), 1.0)
	MeshFactory.textured_box(self, Vector3(5.2, 0.2, 5.0), Vector3(0, -0.1, 0.3), floor_mat)
	MeshFactory.textured_box(self, Vector3(5.2, 0.2, 5.0), Vector3(0, 3.1, 0.3), ceil_mat)
	MeshFactory.textured_box(self, Vector3(5.2, 3.0, 0.2), Vector3(0, 1.5, -2.3), wall_mat)
	MeshFactory.textured_box(self, Vector3(5.2, 3.0, 0.2), Vector3(0, 1.5, 2.9), wall_mat)
	MeshFactory.textured_box(self, Vector3(0.2, 3.0, 5.0), Vector3(-2.7, 1.5, 0.3), wall_mat)
	# sağ duvar kapı boşluğu: z 1.12 .. 2.12
	MeshFactory.textured_box(self, Vector3(0.2, 3.0, 3.32), Vector3(2.7, 1.5, -0.54), wall_mat)
	MeshFactory.textured_box(self, Vector3(0.2, 3.0, 0.68), Vector3(2.7, 1.5, 2.46), wall_mat)
	MeshFactory.textured_box(self, Vector3(0.2, 0.85, 1.0), Vector3(2.7, 2.575, 1.62), wall_mat)
	MeshFactory.box(self, Vector3(0.08, 2.2, 0.08), Vector3(2.52, 1.08, 1.08), Color("2a241c"), 0.75)
	MeshFactory.box(self, Vector3(0.08, 2.2, 0.08), Vector3(2.52, 1.08, 2.16), Color("2a241c"), 0.75)
	MeshFactory.box(self, Vector3(0.08, 0.08, 1.16), Vector3(2.52, 2.16, 1.62), Color("2a241c"), 0.75)
	_cell_door = Node3D.new()
	_cell_door.name = "CellDoor"
	_cell_door.position = Vector3(2.56, 1.05, 2.12)
	add_child(_cell_door)
	MeshFactory.box(_cell_door, Vector3(0.05, 2.08, 0.96), Vector3(0, 0, -0.5), Color("3b3630"), 0.8)
	MeshFactory.box(_cell_door, Vector3(0.04, 0.03, 0.1), Vector3(-0.045, 0.0, -0.86), Color("c6a15b"), 0.25)
	var door_sign := MeshFactory.label(self, "GÖZALTI", Vector3(2.42, 2.38, 1.62), Color("e7e1d6"), 0.32)
	door_sign.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	var porch := OmniLight3D.new()
	porch.position = Vector3(2.15, 1.7, 1.62)
	porch.light_color = Color("f3dfa0")
	porch.light_energy = 3.0
	porch.omni_range = 3.4
	porch.shadow_enabled = false
	add_child(porch)
	# süpürgelik + soluk boya şeridi
	for z in [-2.19, 2.79]:
		MeshFactory.box(self, Vector3(5.2, 0.12, 0.03), Vector3(0, 0.06, z), Color("2a2622"), 0.9)
		MeshFactory.box(self, Vector3(5.2, 1.1, 0.012), Vector3(0, 0.67, z), Color(0.33, 0.36, 0.3), 0.95)
	MeshFactory.box(self, Vector3(0.03, 0.12, 5.0), Vector3(-2.59, 0.06, 0.3), Color("2a2622"), 0.9)
	MeshFactory.box(self, Vector3(0.012, 1.1, 5.0), Vector3(-2.59, 0.67, 0.3), Color(0.33, 0.36, 0.3), 0.95)
	MeshFactory.box(self, Vector3(0.03, 0.12, 3.32), Vector3(2.59, 0.06, -0.54), Color("2a2622"), 0.9)
	MeshFactory.box(self, Vector3(0.012, 1.1, 3.32), Vector3(2.59, 0.67, -0.54), Color(0.33, 0.36, 0.3), 0.95)
	MeshFactory.box(self, Vector3(0.03, 0.12, 0.68), Vector3(2.59, 0.06, 2.46), Color("2a2622"), 0.9)
	MeshFactory.box(self, Vector3(0.012, 1.1, 0.68), Vector3(2.59, 0.67, 2.46), Color(0.33, 0.36, 0.3), 0.95)
	# lekeler / nem izleri
	for spot in [[Vector3(-1.4, 2.4, -2.18), Vector2(0.9, 0.5)], [Vector3(1.9, 1.9, -2.18), Vector2(0.5, 0.8)], [Vector3(2.58, 2.5, -1.2), Vector2(0.7, 0.6)]]:
		var stain := MeshFactory.box(self, Vector3(spot[1].x, spot[1].y, 0.006), spot[0], Color(0.22, 0.2, 0.16, 0.55), 1.0)
		if spot[0].x > 2.5:
			stain.rotation_degrees.y = 90
		stain.material_override.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	# tek yönlü gözlem camı (sol duvar)
	MeshFactory.box(self, Vector3(0.06, 1.3, 2.2), Vector3(-2.6, 1.55, -0.2), Color("1b1a18"), 0.6)
	var glass := MeshFactory.box(self, Vector3(0.02, 1.14, 2.04), Vector3(-2.56, 1.55, -0.2), Color(0.08, 0.1, 0.11), 0.03)
	glass.material_override.metallic = 0.95
	glass.material_override.metallic_specular = 0.9
	MeshFactory.label(self, "GÖZLEM", Vector3(-2.52, 2.32, -0.2), Color("9a9184"), 0.3)
	# sarkan floresan
	lamp_pivot = Node3D.new()
	lamp_pivot.position = Vector3(0, 3.0, 0)
	add_child(lamp_pivot)
	for x in [-0.5, 0.5]:
		MeshFactory.cylinder(lamp_pivot, 0.006, 0.7, Vector3(x, -0.35, 0), Color("6a6a6a"))
	MeshFactory.box(lamp_pivot, Vector3(1.3, 0.07, 0.2), Vector3(0, -0.72, 0), Color("3a3a3a"), 0.5)
	var tube := MeshFactory.cylinder(lamp_pivot, 0.02, 1.2, Vector3(0, -0.77, 0), Color("f1e2a6"), 2.4)
	tube.rotation_degrees.z = 90
	tube_mat = tube.material_override
	bulb = OmniLight3D.new()
	bulb.position = Vector3(0, -0.9, 0)
	bulb.light_color = Color("f3dfa0")
	bulb.light_energy = 5.2
	bulb.omni_range = 6.5
	bulb.shadow_enabled = true
	bulb.shadow_blur = 1.5
	lamp_pivot.add_child(bulb)
	# köşe kamerası
	var bracket := Node3D.new()
	bracket.position = Vector3(2.45, 2.75, -2.05)
	add_child(bracket)
	bracket.look_at(Vector3(0, 0.9, 0))
	MeshFactory.box(bracket, Vector3(0.12, 0.1, 0.22), Vector3(0, 0, 0.05), Color("2b2b2b"), 0.5)
	MeshFactory.cylinder(bracket, 0.035, 0.06, Vector3(0, 0, 0.2), Color("111111")).rotation_degrees.x = 90
	MeshFactory.box(bracket, Vector3(0.03, 0.16, 0.03), Vector3(0, 0.12, -0.03), Color("2b2b2b"))
	led = MeshFactory.sphere(bracket, 0.012, Vector3(0.045, 0.04, 0.12), Color("ff2a2a"), 3.0)


func _table() -> void:
	var metal := MeshFactory.pbr("rusty_metal_02", Color(0.55, 0.57, 0.58), Vector2(1.5, 1.0), 0.7)
	metal.metallic = 0.5
	MeshFactory.textured_box(self, Vector3(1.6, 0.05, 0.9), Vector3(0, 0.75, 0), metal)
	for corner in [Vector3(-0.72, 0.36, -0.38), Vector3(0.72, 0.36, -0.38), Vector3(-0.72, 0.36, 0.38), Vector3(0.72, 0.36, 0.38)]:
		MeshFactory.box(self, Vector3(0.05, 0.72, 0.05), corner, Color("4a4d50"), 0.4)
	MeshFactory.box(self, Vector3(1.5, 0.04, 0.04), Vector3(0, 0.2, -0.38), Color("4a4d50"), 0.4)
	MeshFactory.box(self, Vector3(1.5, 0.04, 0.04), Vector3(0, 0.2, 0.38), Color("4a4d50"), 0.4)
	_chair(Vector3(0.0, 0, -0.95), 0.0)
	_chair(Vector3(0.0, 0, 0.95), 180.0)


func _chair(at: Vector3, yaw: float) -> void:
	var pivot := Node3D.new()
	pivot.position = at
	pivot.rotation_degrees.y = yaw
	add_child(pivot)
	var chair := MeshFactory.place(pivot, CHAIR, Vector3(-0.2, 0, 0.2), 0.0, 2.0)
	for mesh in chair.find_children("*", "MeshInstance3D", true, false):
		var m := mesh as MeshInstance3D
		m.material_override = MeshFactory.material(Color("3a3d42"), 0.55)
		m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON


func _props() -> void:
	# su bardağı
	var glass := MeshFactory.cylinder(self, 0.035, 0.11, Vector3(0.55, 0.83, 0.25), Color(0.85, 0.9, 0.95, 0.3))
	glass.material_override.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass.material_override.roughness = 0.05
	var water := MeshFactory.cylinder(self, 0.03, 0.06, Vector3(0.55, 0.81, 0.25), Color(0.6, 0.75, 0.85, 0.5))
	water.material_override.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	# dosya klasörü
	var folder := MeshFactory.box(self, Vector3(0.32, 0.03, 0.44), Vector3(-0.5, 0.79, -0.2), Color("8a5a3a"), 0.9)
	folder.rotation_degrees.y = 6
	MeshFactory.box(folder, Vector3(0.22, 0.004, 0.06), Vector3(0.0, 0.017, -0.12), Color("e7d7b1"), 0.9)
	var folder_tag := MeshFactory.label(folder, "DOSYA NO 06", Vector3(0, 0.02, -0.12), Color("2a2118"), 0.22)
	folder_tag.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	folder_tag.rotation_degrees.x = -90
	# delil poşetleri
	_evidence_bag(Vector3(0.52, 0.78, -0.22), -12.0, Color("111111"), Vector3(0.07, 0.012, 0.14))
	_evidence_bag(Vector3(-0.15, 0.78, -0.3), 18.0, Color("c9b7a0"), Vector3(0.1, 0.01, 0.07))
	# köşede eski radyatör / kül tablası
	MeshFactory.box(self, Vector3(0.9, 0.55, 0.1), Vector3(-1.4, 0.35, -2.18), Color("6b6a63"), 0.6)
	for i in 8:
		MeshFactory.box(self, Vector3(0.06, 0.5, 0.12), Vector3(-1.78 + i * 0.11, 0.35, -2.17), Color("75746c"), 0.6)
	MeshFactory.cylinder(self, 0.06, 0.02, Vector3(-0.1, 0.785, 0.3), Color("2a2a2a"))


func _evidence_bag(at: Vector3, yaw: float, item_color: Color, item_size: Vector3) -> void:
	var bag := Node3D.new()
	bag.position = at
	bag.rotation_degrees.y = yaw
	add_child(bag)
	MeshFactory.box(bag, item_size, Vector3(0, item_size.y * 0.5 + 0.004, 0), item_color, 0.4)
	var film := MeshFactory.box(bag, Vector3(0.2, 0.03, 0.28), Vector3(0, 0.015, 0), Color(0.9, 0.93, 0.95, 0.35), 0.15)
	film.material_override.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	MeshFactory.box(bag, Vector3(0.2, 0.002, 0.04), Vector3(0, 0.031, -0.11), Color("DC2626"), 0.7)
	var tag := MeshFactory.label(bag, "DELİL", Vector3(0, 0.034, -0.11), Color("ffffff"), 0.18)
	tag.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	tag.rotation_degrees.x = -90


func _people() -> void:
	player = RIG.instantiate()
	player.position = Vector3(0.0, 0.0, 0.52)
	player.rotation_degrees.y = 180
	player.seated = true
	add_child(player)
	player.setup("player")
	_hide_tag(player)
	behzat = RIG.instantiate()
	behzat.position = Vector3(-1.9, 0, 1.6)
	behzat.rotation_degrees.y = 135
	add_child(behzat)
	behzat.setup("behzat")
	behzat.act("Confident")
	var face := SpotLight3D.new()
	face.name = "FaceKey"
	face.position = Vector3(0.35, 1.55, 0.15)
	face.light_color = Color("ffd8b0")
	face.light_energy = 4.5
	face.spot_range = 3.2
	face.spot_angle = 28.0
	face.shadow_enabled = false
	add_child(face)
	face.look_at(Vector3(0.0, 1.18, -0.52))


func _cameras() -> void:
	cam_rig = Node3D.new()
	cam_rig.name = "CamRig"
	add_child(cam_rig)
	cam_shake = Node3D.new()
	cam_shake.name = "Shake"
	cam_rig.add_child(cam_shake)
	camera = Camera3D.new()
	camera.name = "Camera"
	camera.current = true
	camera.fov = 50
	camera.near = 0.05
	camera.v_offset = 0.0
	cam_shake.add_child(camera)
	look_target = Node3D.new()
	look_target.name = "LookTarget"
	add_child(look_target)
	cam_anim = AnimationPlayer.new()
	cam_anim.name = "CameraAnim"
	cam_anim.add_animation_library("", AnimationLibrary.new())
	add_child(cam_anim)
	_marker("Cam_Wide", Vector3(0.28, 1.18, 0.85), Vector3(0.0, 1.08, -0.5), 32.0)
	_marker("Cam_SuspectCloseUp", Vector3(0.22, 1.4, 1.25), Vector3(0.0, 1.42, -0.52), 36.0)
	_marker("Cam_DetectiveCloseUp", Vector3(-0.15, 1.22, -0.15), Vector3(0.0, 1.16, 0.5), 24.0)
	_marker("Cam_TableTop", Vector3(0.25, 1.75, 0.95), Vector3(0.05, 0.62, -0.05), 40.0)
	_marker("Cam_Arrest", Vector3(-1.15, 1.42, -0.15), Vector3(1.35, 1.15, 1.15), 46.0)
	_marker("Cam_Wall", Vector3(1.55, 1.42, -0.85), Vector3(0.55, 1.2, -1.65), 34.0)
	var start := get_node("Cam_Wide") as Marker3D
	cam_rig.position = start.position
	look_target.position = start.get_meta("look")
	camera.fov = float(start.get_meta("fov"))
	shown_shot = ""


func _marker(name: String, at: Vector3, look: Vector3, fov: float) -> void:
	var marker := Marker3D.new()
	marker.name = name
	marker.position = at
	marker.set_meta("look", look)
	marker.set_meta("fov", fov)
	add_child(marker)


func _sounds() -> void:
	sfx = AudioStreamPlayer.new()
	add_child(sfx)
	slap_sound = _synth(0.16, func(t: float, n: float) -> float: return n * exp(-t * 34.0) * 0.9 + sin(t * 2200.0) * exp(-t * 60.0) * 0.2)
	thud_sound = _synth(0.38, func(t: float, n: float) -> float: return sin(t * 2.0 * PI * 68.0) * exp(-t * 9.0) * 0.9 + n * exp(-t * 28.0) * 0.35)


## Basit prosedürel ses (PCM16 mono).
func _synth(duration: float, shape: Callable) -> AudioStreamWAV:
	var rate := 22050
	var count := int(duration * rate)
	var bytes := PackedByteArray()
	bytes.resize(count * 2)
	var rng := RandomNumberGenerator.new()
	rng.seed = 6
	for i in count:
		var t := float(i) / rate
		var n := rng.randf_range(-1.0, 1.0)
		var v: float = clampf(shape.call(t, n), -1.0, 1.0)
		var s := int(v * 32000.0)
		bytes.encode_s16(i * 2, s)
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = rate
	wav.stereo = false
	wav.data = bytes
	return wav
