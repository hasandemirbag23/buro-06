extends Node3D

const MeshFactory := preload("res://scenes/mesh_factory.gd")
const RIG := preload("res://scenes/character_rig.tscn")
const Brain := preload("res://scenes/npc_brain.gd")

const WOOD_DARK := Color("4a3224")
const PLASTER := Color("3a332c")
const PLASTER_DARK := Color("2a241f")
const CORK := Color("7a4a2c")
const MANILA := Color("c4a36a")
const FEET := 0.17

const DESK := preload("res://assets/furniture/desk.glb")
const CHAIR := preload("res://assets/furniture/chairDesk.glb")
const SCREEN := preload("res://assets/furniture/computerScreen.glb")
const KEYS := preload("res://assets/furniture/computerKeyboard.glb")
const LAMP := preload("res://assets/furniture/lampSquareTable.glb")
const RADIO_MODEL := preload("res://assets/furniture/radio.glb")
const RACK := preload("res://assets/furniture/coatRackStanding.glb")
const BIN := preload("res://assets/furniture/trashcan.glb")
const BOOKS := preload("res://assets/furniture/books.glb")
const BOX := preload("res://assets/furniture/cardboardBoxClosed.glb")
const SHELF := preload("res://assets/interior/Bookshelf.glb")
const DOOR_MODEL := preload("res://assets/interior/Door_1.glb")
const WINDOW_MODEL := preload("res://assets/interior/Window_Large1.glb")
const CURTAIN := preload("res://assets/interior/Curtains_Double.glb")
const PLANT := preload("res://assets/interior/Houseplant_2.glb")
const CEIL := preload("res://assets/interior/Light_Ceiling1.glb")
const CARPET := preload("res://assets/interior/Carpet_1.glb")
const CABINET := preload("res://assets/interior/Drawer_1.glb")

var camera: Camera3D
var aim_target := Vector3.ZERO
var behzat: Node3D
var akbaba: Node3D
var hayalet: Node3D
var arsiv: Node3D
var tubes: Array[OmniLight3D] = []
var _shot: Tween
var _entrances: Array = []
var _blocks: Array[Rect2] = []
var hub := {"brains": {}, "names": {}, "claims": {}, "player": Callable(), "speaker_eye": Vector3.ZERO}
var komiser: Node3D

var shots := {
	"home": [Vector3(0.8, 10.2, 9.4), Vector3(0.2, 0.5, -0.9)],
	"brief": [Vector3(2.4, 2.4, 1.9), Vector3(1.7, 1.0, -1.0)],
	"files": [Vector3(1.5, 2.0, 0.7), Vector3(1.35, 0.9, -0.55)],
	"board": [Vector3(3.5, 2.4, -2.0), Vector3(3.5, 2.15, -5.0)],
	"records": [Vector3(-2.5, 2.2, 3.2), Vector3(-3.85, 1.1, 1.25)],
	"door": [Vector3(3.6, 2.4, 3.2), Vector3(7.0, 1.3, 3.2)],
	"menu": [Vector3(-0.2, 1.85, 1.6), Vector3(-3.3, 1.45, -4.4)],
}


func _ready() -> void:
	_build()
	GameState.updated.connect(_refresh)
	GameState.aimed.connect(_on_aimed)
	Cinematic.started.connect(_on_beat)
	Cinematic.skipped.connect(_on_skip)
	Cinematic.finished.connect(_on_beat_end)
	_refresh()
	_enter(hayalet, Vector3(-1.3, 0, 0), "stand")
	if komiser:
		_enter(komiser, Vector3(0, 0, 1.5), "breathe")
	_establish()


func _process(_delta: float) -> void:
	var t := Time.get_ticks_msec() / 1000.0
	for i in tubes.size():
		var flick := 1.0 if i != 2 else (0.55 if fmod(t * 3.7 + i, 7.0) < 0.12 else 1.0)
		tubes[i].light_energy = (1.5 + 0.1 * sin(t * 4.0 + i)) * flick


func _refresh() -> void:
	var speaking: Node3D = null
	for brain in hub["brains"].values():
		if brain.display_name == GameState.speaker:
			speaking = brain.rig
	hub["speaker_eye"] = (speaking.global_position + Vector3(0, 1.4, 0)) if speaking else Vector3.ZERO
	for brain in hub["brains"].values():
		brain.on_speaker(GameState.speaker)
	_lay_copies()


func _on_aimed(action: String) -> void:
	if shots.has(action):
		_dolly(shots[action][0], shots[action][1])


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		_dolly(shots["home"][0], shots["home"][1])


func _establish() -> void:
	var home_at: Vector3 = shots["home"][0]
	var home_look: Vector3 = shots["home"][1]
	camera.position = home_at + Vector3(0.5, 1.6, 2.2)
	camera.look_at(home_look)
	if GameState.incoming_call:
		_dolly(shots["brief"][0], shots["brief"][1])
	else:
		_dolly(home_at, home_look)


func _on_beat(id: String) -> void:
	if id == "call_savci":
		_dolly(shots["brief"][0], shots["brief"][1])
		if behzat and hub["brains"].has("behzat"):
			hub["brains"]["behzat"].react("Talking", 6.0)
	elif id == "radio" and hayalet and hub["brains"].has("hayalet"):
		hub["brains"]["hayalet"].react("UseRadio", 5.0)


func _on_beat_end(id: String) -> void:
	pass


func _on_skip(id: String) -> void:
	if not (id.begins_with("travel") or id.begins_with("call")):
		return
	if _shot:
		_shot.kill()
	var key: String = "brief" if GameState.incoming_call or id == "call_savci" else "home"
	var shot_at: Vector3 = shots[key][0]
	var shot_look: Vector3 = shots[key][1]
	camera.position = shot_at
	aim_target = shot_look
	camera.look_at(aim_target)
	for item in _entrances:
		var rig: Node3D = item["rig"]
		if not is_instance_valid(rig):
			continue
		var tw: Tween = item["tween"]
		if tw:
			tw.kill()
		rig.position = item["home"]
		rig.pose(str(item["clip"]))
	_entrances.clear()


func _dolly(at: Vector3, look: Vector3) -> void:
	aim_target = look
	if camera == null:
		return
	if _shot:
		_shot.kill()
	_shot = create_tween()
	_shot.tween_property(camera, "position", at, 0.65).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_shot.parallel().tween_method(_look, 0.0, 1.0, 0.65)


func _look(_weight: float) -> void:
	if camera:
		camera.look_at(aim_target)


func _build() -> void:
	add_child(MeshFactory.environment(Color("0b0d11"), Color("8c8274"), 0.0, 0.85, true))
	_shell()
	_lights()
	_window()
	_map()
	_board()
	_archives()
	_desks()
	_radio()
	_door()
	_people()
	_bake_nav()
	_brains()
	camera = Camera3D.new()
	camera.current = true
	camera.fov = 42.0
	camera.position = shots["home"][0]
	add_child(camera)
	camera.look_at(shots["home"][1])


func _shell() -> void:
	var floor := MeshFactory.block(self, Vector3(14.4, 0.16, 11.2), Vector3(0, 0.08, 0.2), Color("5a4030"), 0.92)
	_skin(floor, MeshFactory.pbr("wood_floor_worn", Color("c4a07a"), Vector2(4.5, 3.5)))
	_drop(CARPET, Vector3(0.3, FEET, 0.5), 0.0, 1.7)
	var plaster := MeshFactory.pbr("plastered_wall_02", Color("b7aea2"), Vector2(2.5, 1.2))
	var walls: Array[StaticBody3D] = [
		MeshFactory.block(self, Vector3(2.55, 3.5, 0.18), Vector3(-5.925, 1.75, -5.2), PLASTER),
		MeshFactory.block(self, Vector3(9.15, 3.5, 0.18), Vector3(2.625, 1.75, -5.2), PLASTER),
		MeshFactory.block(self, Vector3(2.7, 0.9, 0.18), Vector3(-3.3, 0.45, -5.2), PLASTER),
		MeshFactory.block(self, Vector3(2.7, 0.4, 0.18), Vector3(-3.3, 3.3, -5.2), PLASTER),
		MeshFactory.block(self, Vector3(0.18, 3.5, 11.2), Vector3(-7.1, 1.75, 0.2), PLASTER_DARK),
		MeshFactory.block(self, Vector3(0.18, 3.5, 11.2), Vector3(7.1, 1.75, 0.2), PLASTER_DARK),
		MeshFactory.block(self, Vector3(14.4, 0.5, 0.18), Vector3(0, 0.25, 5.7), PLASTER_DARK),
	]
	for wall in walls:
		_skin(wall, plaster)
	MeshFactory.box(self, Vector3(14.0, 0.12, 0.08), Vector3(0, 0.2, -5.08), WOOD_DARK)
	MeshFactory.box(self, Vector3(0.08, 0.12, 10.8), Vector3(-6.98, 0.2, 0.2), WOOD_DARK)
	MeshFactory.box(self, Vector3(0.08, 0.12, 10.8), Vector3(6.98, 0.2, 0.2), WOOD_DARK)
	MeshFactory.box(self, Vector3(14.4, 1.1, 0.04), Vector3(0, 0.75, -5.09), Color("4a4238"), 0.9)
	MeshFactory.box(self, Vector3(18, 0.1, 6), Vector3(-3.3, -0.05, -8.5), Color("0e1218"), 0.95)
	MeshFactory.box(self, Vector3(14.4, 0.05, 0.05), Vector3(0, 1.3, -5.06), WOOD_DARK)
	MeshFactory.box(self, Vector3(1.4, 0.7, 0.04), Vector3(-4.6, 1.6, -5.05), Color("2a221c"), 0.95)


func _lights() -> void:
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-62, 28, 0)
	fill.light_color = Color("cfd4dc")
	fill.light_energy = 0.55
	fill.shadow_enabled = true
	fill.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
	fill.directional_shadow_max_distance = 18.0
	add_child(fill)
	_tube(Vector3(-3.6, 3.45, -2.2))
	_tube(Vector3(1.4, 3.45, -2.2))
	_tube(Vector3(-3.6, 3.45, 2.0))
	_tube(Vector3(3.6, 3.45, 1.6))
	for at in [Vector3(-3.6, 3.48, -2.2), Vector3(1.4, 3.48, -2.2), Vector3(-3.6, 3.48, 2.0), Vector3(3.6, 3.48, 1.6)]:
		_drop(CEIL, at, 0.0, 0.62)
	var foot := Vector3(2.05, 0.95, -0.95)
	_drop(LAMP, foot, 40.0, 1.35, Vector3(0.06, 0.0, -0.06))
	var desk := OmniLight3D.new()
	desk.position = foot + Vector3(0.0, 0.35, 0.0)
	desk.light_color = Color("e6b450")
	desk.light_energy = 0.35
	desk.omni_range = 2.4
	desk.shadow_enabled = false
	add_child(desk)


func _tube(at: Vector3) -> void:
	var lamp := OmniLight3D.new()
	lamp.position = at + Vector3(0, -0.2, 0)
	lamp.light_color = Color("dfe3cf")
	lamp.light_energy = 1.6
	lamp.omni_range = 8.5
	lamp.shadow_enabled = false
	add_child(lamp)
	tubes.append(lamp)


func _window() -> void:
	_drop(WINDOW_MODEL, Vector3(-3.3, 0.92, -5.16), 0.0, 1.28)
	_drop(CURTAIN, Vector3(-3.3, 0.9, -4.92), 0.0, 0.6, Vector3(0.04, 0.0, -0.12))
	var heights := [2.4, 5.2, 3.3, 6.4, 2.8, 4.6, 3.8, 5.6, 3.1]
	for i in heights.size():
		var h: float = heights[i]
		var x := -6.6 + i * 0.82
		MeshFactory.box(self, Vector3(0.68, h, 0.6), Vector3(x, h * 0.5 - 0.6, -8.6), Color("161c24"))
		for k in int(h / 1.1):
			if (i * 3 + k) % 4 == 0:
				continue
			MeshFactory.box(self, Vector3(0.18, 0.2, 0.03), Vector3(x - 0.16 + (k % 2) * 0.3, 0.3 + k * 1.05, -8.28), Color("e6b450"), 0.4, 1.4)
	MeshFactory.box(self, Vector3(0.12, 0.6, 0.12), Vector3(-2.2, 7.0, -8.6), Color("161c24"))
	MeshFactory.sphere(self, 0.06, Vector3(-2.2, 7.35, -8.6), Color("DC2626"), 2.0)
	var glow := OmniLight3D.new()
	glow.position = Vector3(-3.3, 2.0, -6.6)
	glow.light_color = Color("7a93b8")
	glow.light_energy = 1.1
	glow.omni_range = 5.0
	glow.shadow_enabled = false
	add_child(glow)


var window_rain: GPUParticles3D


func set_rain(on: bool) -> void:
	if not on:
		if window_rain:
			window_rain.emitting = false
			window_rain.visible = false
		return
	if window_rain == null:
		window_rain = GPUParticles3D.new()
		window_rain.position = Vector3(-3.3, 6.0, -6.9)
		window_rain.amount = 120
		window_rain.lifetime = 1.4
		window_rain.visibility_aabb = AABB(Vector3(-5, -8, -3), Vector3(10, 12, 6))
		var process := ParticleProcessMaterial.new()
		process.direction = Vector3(0.15, -1, 0.0)
		process.spread = 6.0
		process.initial_velocity_min = 8.0
		process.initial_velocity_max = 11.0
		process.gravity = Vector3(0, -4, 0)
		process.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
		process.emission_box_extents = Vector3(3.5, 0.2, 1.2)
		window_rain.process_material = process
		var drop := QuadMesh.new()
		drop.size = Vector2(0.015, 0.22)
		var drop_mat := StandardMaterial3D.new()
		drop_mat.albedo_color = Color(0.75, 0.82, 0.92, 0.45)
		drop_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		drop_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		drop.material = drop_mat
		window_rain.draw_pass_1 = drop
		add_child(window_rain)
	window_rain.visible = true
	window_rain.emitting = true


func _map() -> void:
	MeshFactory.box(self, Vector3(1.7, 1.35, 0.06), Vector3(-0.2, 2.2, -5.08), Color("d8c7a1"), 0.7)
	MeshFactory.box(self, Vector3(1.15, 0.03, 0.02), Vector3(-0.15, 2.35, -5.02), Color("8a3a32"))
	MeshFactory.box(self, Vector3(0.03, 0.7, 0.02), Vector3(-0.45, 2.1, -5.02), Color("2a3a4a"))
	MeshFactory.box(self, Vector3(0.5, 0.03, 0.02), Vector3(0.15, 1.9, -5.02), Color("2a3a4a"))
	MeshFactory.label(self, "ANKARA", Vector3(-0.2, 2.7, -4.95), Color("2a2118"), 0.7)
	MeshFactory.label(self, str(Scenario.data.get("place", "")), Vector3(0.25, 1.75, -4.95), Color("8a3a32"), 0.45)


func _board() -> void:
	MeshFactory.box(self, Vector3(2.5, 1.9, 0.08), Vector3(3.5, 2.15, -5.08), WOOD_DARK)
	MeshFactory.zone(self, Vector3(2.25, 1.65, 0.08), Vector3(3.5, 2.15, -5.0), CORK, "board", 0.9)
	MeshFactory.label(self, "DELİL", Vector3(3.5, 3.15, -4.9), Color("e7e1d6"), 0.55)
	var pins := [
		Vector3(2.85, 2.55, -4.9),
		Vector3(3.55, 2.7, -4.9),
		Vector3(4.15, 2.35, -4.9),
		Vector3(3.2, 1.85, -4.9),
		Vector3(3.95, 1.7, -4.9),
	]
	var marks := ["Z", "T", "?", "M", "14"]
	for i in pins.size():
		MeshFactory.box(self, Vector3(0.28, 0.36, 0.02), pins[i], Color("f4efe6"))
		MeshFactory.box(self, Vector3(0.22, 0.22, 0.015), pins[i] + Vector3(0, 0.04, 0.02), Color("6a5344"))
		MeshFactory.label(self, marks[i], pins[i] + Vector3(0, -0.12, 0.04), Color("2a2118"), 0.4)
		MeshFactory.sphere(self, 0.02, pins[i] + Vector3(0, 0.2, 0.03), Color("b42323"))
	_cord(pins[0], pins[1])
	_cord(pins[1], pins[2])
	_cord(pins[0], pins[3])
	_cord(pins[3], pins[4])
	_cord(pins[2], pins[4])


func _cord(a: Vector3, b: Vector3) -> void:
	var span := b - a
	var rope := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.012, 0.012, a.distance_to(b))
	rope.mesh = mesh
	rope.position = (a + b) * 0.5
	add_child(rope)
	rope.look_at(b, Vector3.UP)
	MeshFactory.paint(rope, Color("b42323"), 0.45)


func _archives() -> void:
	for i in 3:
		_drop(SHELF, Vector3(-6.72, FEET, -2.3 + i * 1.7), 90.0, 0.52, Vector3.ZERO, true)
	_drop(CABINET, Vector3(-6.45, FEET, 3.35), 90.0, 0.62, Vector3.ZERO, true)


func _desks() -> void:
	_station(Vector3(1.7, FEET, -0.8), 0.0, true)
	var folder := MeshFactory.zone(self, Vector3(0.42, 0.08, 0.32), Vector3(1.35, 1.0, -0.55), Color("8c2f2f"), "files", 0.7)
	folder.rotation_degrees.y = -7
	_drop(BOOKS, Vector3(2.15, 0.96, -0.7), 18.0, 1.8, Vector3(0.07, 0.0, -0.04))
	_chair_at(Vector3(1.7, FEET, -1.55), 0.0)
	_station(Vector3(-1.5, FEET, -0.55), 0.0, false)
	_drop(BOOKS, Vector3(-1.15, 0.96, -0.45), -12.0, 1.6, Vector3(0.07, 0.0, -0.04))
	_chair_at(Vector3(-1.5, FEET, -1.35), 0.0)
	_station(Vector3(-3.8, FEET, 1.35), 0.0, false)
	_drop(SCREEN, Vector3(-3.85, 0.96, 1.2), 180.0, 1.7, Vector3(0.19, 0.0, -0.05))
	_drop(KEYS, Vector3(-3.85, 0.96, 1.55), 180.0, 1.8, Vector3(0.14, 0.0, -0.06))
	_ghost(MeshFactory.zone(self, Vector3(0.55, 0.45, 0.35), Vector3(-3.85, 1.2, 1.2), Color("14301c"), "records"))
	_chair_at(Vector3(-3.8, FEET, 2.15), 180.0)
	_station(Vector3(4.6, FEET, 1.8), 0.0, true)
	_chair_at(Vector3(4.6, FEET, 2.55), 0.0)
	_drop(RACK, Vector3(5.7, FEET, -3.6), 20.0, 2.15, Vector3.ZERO, true)
	_drop(BIN, Vector3(6.15, FEET, 3.4), 10.0, 2.0, Vector3.ZERO, true)
	_drop(BOX, Vector3(6.0, FEET, 4.35), 8.0, 2.1, Vector3(0.1, 0.0, -0.1), true)
	_drop(BOX, Vector3(6.15, FEET + 0.58, 4.35), -6.0, 1.7, Vector3(0.1, 0.0, -0.1))
	_drop(PLANT, Vector3(-5.3, FEET, -4.55), 0.0, 2.4, Vector3.ZERO, true)


const DESK_SHEETS := [
	"clue_cut_rail", "clue_guard_log",
	"clue_stove_valve", "clue_door_note",
	"clue_mirror_note", "clue_cloak_ticket",
	"clue_e4_letter", "clue_e4_note",
	"clue_e5_seal", "clue_e5_ticket",
]
var _shown_sheets := ""


func _lay_copies() -> void:
	var have: Array[String] = []
	for id in DESK_SHEETS:
		if GameState.clues.has(id) and not Scenario.clue(id).is_empty():
			have.append(id)
	var key := ",".join(have)
	if key == _shown_sheets:
		return
	_shown_sheets = key
	var old := get_node_or_null("DeskCopies")
	if old:
		old.name = "DeskCopiesOld"
		old.queue_free()
	if have.is_empty():
		return
	var pile := Node3D.new()
	pile.name = "DeskCopies"
	add_child(pile)
	for i in have.size():
		var found := Scenario.clue(have[i])
		var col := i % 3
		var row := i / 3
		var at := Vector3(1.58 + col * 0.18, 1.02 + i * 0.003, -1.02 + row * 0.26)
		var sheet := MeshFactory.box(pile, Vector3(0.16, 0.004, 0.22), at, Color("e7dcc4"), 0.92)
		sheet.rotation_degrees.y = -16.0 + col * 9.0
		MeshFactory.box(sheet, Vector3(0.11, 0.001, 0.008), Vector3(0, 0.003, -0.06), Color("2a2118"))
		MeshFactory.box(sheet, Vector3(0.09, 0.001, 0.006), Vector3(-0.01, 0.003, -0.03), Color("5a5048"))
		MeshFactory.box(sheet, Vector3(0.04, 0.001, 0.03), Vector3(0.04, 0.003, 0.06), Color("8c2f2f"), 0.6)
		var tag := MeshFactory.label(sheet, str(found.get("icon", "DELİL")), Vector3(0, 0.02, 0.01), Color("2a2118"), 0.28)
		tag.billboard = BaseMaterial3D.BILLBOARD_DISABLED
		tag.rotation_degrees.x = -90
		tag.fixed_size = false


func _station(center: Vector3, yaw: float, brief: bool) -> void:
	_drop(DESK, center, yaw, 2.05, Vector3(0.355, 0.0, -0.185), true)
	if brief:
		var zone := MeshFactory.zone(self, Vector3(1.4, 0.12, 0.7), center + Vector3(0, 0.82, 0), MANILA, "brief", 0.7)
		_ghost(zone)
		var stack := MeshFactory.box(self, Vector3(0.24, 0.05, 0.32), center + Vector3(-0.35, 0.84, 0.02), MANILA)
		stack.rotation_degrees.y = 8


func _chair_at(at: Vector3, yaw: float) -> void:
	_drop(CHAIR, at, yaw, 1.8, Vector3(0.165, 0.0, -0.155), true)


func _drop(scene: PackedScene, feet: Vector3, yaw: float, scale: float, local_feet: Vector3 = Vector3.ZERO, solid := false) -> Node3D:
	var offset := Basis(Vector3.UP, deg_to_rad(yaw)) * (local_feet * scale)
	var node := MeshFactory.place(self, scene, feet - offset, yaw, scale)
	_cast(node)
	if solid:
		_footprint(node)
	return node


## Yerleştirilen modelin zemindeki izini NPC navmesh engeli olarak kaydet.
func _footprint(node: Node3D) -> void:
	var box := AABB()
	var first := true
	for mi in node.find_children("*", "MeshInstance3D", true, false):
		var m := mi as MeshInstance3D
		if m.mesh == null:
			continue
		var part: AABB = m.global_transform * m.mesh.get_aabb()
		box = part if first else box.merge(part)
		first = false
	if first or box.position.y > 0.8 or box.size.y < 0.25:
		return
	_blocks.append(Rect2(box.position.x, box.position.z, box.size.x, box.size.z))


func _bake_nav() -> void:
	var data := NavigationMeshSourceGeometryData3D.new()
	var x0 := -6.6
	var x1 := 6.6
	var z0 := -4.8
	var z1 := 5.3
	data.add_faces(PackedVector3Array([
		Vector3(x0, FEET, z0), Vector3(x1, FEET, z0), Vector3(x0, FEET, z1),
		Vector3(x1, FEET, z0), Vector3(x1, FEET, z1), Vector3(x0, FEET, z1),
	]), Transform3D.IDENTITY)
	for r in _blocks:
		var outline := PackedVector3Array([
			Vector3(r.position.x, 0, r.position.y), Vector3(r.end.x, 0, r.position.y),
			Vector3(r.end.x, 0, r.end.y), Vector3(r.position.x, 0, r.end.y),
		])
		data.add_projected_obstruction(outline, FEET - 0.5, 3.0, true)
	var mesh := NavigationMesh.new()
	mesh.cell_size = 0.1
	mesh.cell_height = 0.1
	mesh.agent_radius = 0.3
	mesh.agent_height = 1.8
	mesh.agent_max_climb = 0.3
	NavigationServer3D.bake_from_source_geometry_data(mesh, data)
	var region := NavigationRegion3D.new()
	region.navigation_mesh = mesh
	add_child(region)
	NavigationServer3D.map_force_update(get_world_3d().navigation_map)


## NPC'lerin "oyuncu" saydığı noktalar: komiser, kamera ve kameranın baktığı yer.
func notice_points() -> Array:
	var out: Array = []
	if komiser:
		out.append(komiser.global_position)
	if camera and camera.global_position.y < 4.0:
		out.append(Vector3(camera.global_position.x, 0.0, camera.global_position.z))
		if camera.global_position.distance_to(aim_target) < 5.0:
			out.append(Vector3(aim_target.x, 0.0, aim_target.z))
	return out


func _cast(node: Node) -> void:
	if node is GeometryInstance3D:
		(node as GeometryInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	for child in node.get_children():
		_cast(child)


func _skin(body: Node, mat: Material) -> void:
	for child in body.get_children():
		if child is MeshInstance3D:
			(child as MeshInstance3D).material_override = mat


func _ghost(area: Node) -> void:
	for child in area.get_children():
		if child is MeshInstance3D:
			(child as MeshInstance3D).visible = false


func _radio() -> void:
	_drop(RADIO_MODEL, Vector3(-3.15, 0.96, 1.7), -25.0, 1.5, Vector3(0.15, 0.0, -0.05))


func _door() -> void:
	_drop(DOOR_MODEL, Vector3(7.02, FEET, 3.2), 90.0, 0.62, Vector3(-0.87, 0.0, 0.0))
	_ghost(MeshFactory.zone(self, Vector3(1.6, 2.4, 1.8), Vector3(6.9, 1.25, 3.2), Color("3d2a1c"), "door", 0.8))
	MeshFactory.label(self, "OLAY YERİ", Vector3(6.75, 2.55, 3.2), Color("7dcea0"), 0.5)


func _people() -> void:
	behzat = _person("behzat", Vector3(1.7, FEET, -1.48), 0, "sit")
	akbaba = _person("akbaba", Vector3(-2.6, FEET, -0.5), 90, "breathe")
	hayalet = _person("hayalet", Vector3(-4.75, FEET, 2.05), 90, "stand")
	arsiv = _person("arsiv", Vector3(-5.85, FEET, -0.6), -90, "stand")
	komiser = _person("player", Vector3(1.4, FEET, 2.6), 180, "breathe")
	komiser.name = "PlayerRig"
	_blocks.append(Rect2(1.1, 2.3, 0.6, 0.6))
	hub["player"] = notice_points


func _brains() -> void:
	var read := {"action": "ReviewDocuments"}
	_brain(behzat, "behzat", {"seated": true, "slot": Vector3(1.7, FEET, 0.25), "work": [
		{"action": "ReviewDocuments", "min": 9, "max": 15, "w": 3.0},
		{"action": "DrinkingTea", "min": 4, "max": 6, "w": 1.5},
		{"action": "UseRadio", "min": 5, "max": 8, "w": 1.0}]})
	_brain(akbaba, "akbaba", {"slot": Vector3(-3.5, FEET, -0.5), "work": [
		{"action": "ReviewDocuments", "min": 8, "max": 14, "w": 3.0},
		{"action": "Thinking", "min": 4, "max": 6, "w": 1.0}], "tasks": [
		{"kind": "visit", "partner": "hayalet", "min": 8, "max": 12, "w": 2.0},
		{"kind": "visit", "partner": "behzat", "min": 6, "max": 9, "w": 1.5},
		{"kind": "visit", "partner": "arsiv", "min": 6, "max": 9, "w": 1.0},
		{"kind": "spot", "spot": Vector3(3.5, FEET, -4.1), "yaw": 180, "action": "Thinking", "min": 6, "max": 10, "w": 1.5}]})
	_brain(hayalet, "hayalet", {"slot": Vector3(-4.7, FEET, 3.1), "delay": 2.0, "work": [
		{"action": "UseRadio", "min": 5, "max": 9, "w": 1.5},
		{"action": "Standing", "min": 5, "max": 9, "w": 1.5},
		{"action": "LookingAround", "min": 3, "max": 5, "w": 1.0}], "tasks": [
		{"kind": "visit", "partner": "arsiv", "min": 6, "max": 10, "w": 1.0}]})
	_brain(arsiv, "arsiv", {"slot": Vector3(-4.95, FEET, -0.6), "delay": 3.0, "work": [
		{"action": "ReviewDocuments", "min": 8, "max": 14, "w": 3.0},
		{"action": "Thinking", "min": 3, "max": 5, "w": 1.0}], "tasks": [
		{"kind": "spot", "spot": Vector3(-5.6, FEET, 3.1), "yaw": -90, "action": "ReviewDocuments", "min": 7, "max": 11, "w": 1.5},
		{"kind": "visit", "partner": "hayalet", "min": 6, "max": 10, "w": 1.0}]})


func _brain(rig: Node3D, id: String, cfg: Dictionary) -> void:
	var brain := Brain.new()
	brain.name = "Brain_" + id
	add_child(brain)
	brain.setup(rig, id, hub, cfg)


func _enter(rig: Node3D, offset: Vector3, clip: String) -> void:
	var home := rig.position
	rig.position = home + offset
	rig.pose("walk")
	var tw := create_tween()
	tw.tween_property(rig, "position", home, 0.65).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_callback(func() -> void:
		if is_instance_valid(rig):
			rig.pose(clip)
	)
	_entrances.append({"rig": rig, "home": home, "clip": clip, "tween": tw})


func _person(id: String, pos: Vector3, yaw: float, clip: String, sink := 0.0) -> Node3D:
	var rig := RIG.instantiate()
	rig.position = pos + Vector3(0, sink, 0)
	rig.rotation_degrees.y = yaw
	add_child(rig)
	rig.setup(id)
	rig.pose(clip)
	return rig
