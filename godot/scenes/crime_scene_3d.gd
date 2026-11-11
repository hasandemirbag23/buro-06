extends Node3D

const MeshFactory := preload("res://scenes/mesh_factory.gd")
const RIG := preload("res://scenes/character_rig.tscn")
const POLICE_CAR := preload("res://assets/vehicles/police.glb")
const SUV := preload("res://assets/vehicles/suv.glb")
const TRUCK := preload("res://assets/vehicles/truck.glb")
const SHOVEL := preload("res://assets/vehicles/tractorShovel.glb")
const SEDAN := preload("res://assets/vehicles/sedan.glb")
const Props := preload("res://scenes/props_lib.gd")
const FENCE := preload("res://assets/props/cp_Fence.glb")
const STREET := preload("res://assets/props/cp_Light_Street_1.glb")
const KIT := preload("res://assets/props/FirstAidKit.glb")
const SCAFFOLD := preload("res://assets/props/cp_Support_Long.glb")

const SETS := {
	"tower": preload("res://scenes/sets/tower_set.gd"),
	"flat": preload("res://scenes/sets/flat_set.gd"),
	"pavyon": preload("res://scenes/sets/pavyon_set.gd"),
	"eczane": preload("res://scenes/sets/eczane_set.gd"),
	"garaj": preload("res://scenes/sets/garaj_set.gd"),
}
const CONCRETE := Color("8b8f93")
const CONCRETE_DARK := Color("5e6266")
const RUST := Color("7a3b1e")
const MUD := Color("2c2419")
const STEEL := Color("3a3f46")
const AMBER := Color("F59E0B")
const WALK_SPEED := 3.8
const OBSTACLE_LAYER := 16
const NAV_RADIUS := 0.4

var camera: Camera3D
var player: Node3D
var mover: CharacterBody3D
var akbaba: Node3D
var behzat: Node3D
var flash: OmniLight3D
var lamp: OmniLight3D
var _lamp_tween: Tween
var reds: Array[Light3D] = []
var blues: Array[Light3D] = []
var beacon: MeshInstance3D
var spots := {}
var follow_offset := Vector3(6.5, 8.6, 9.4)
var mode := "follow"
var state := "idle"
var aim_target := Vector3.ZERO
var _shot: Tween
var _push: Tween
var _pending := ""
var _obstacles: Array = []
var _nav_map: RID
var _path: PackedVector3Array = PackedVector3Array()
var _path_i := 0
var _stuck := 0.0
var _dest := Vector3.ZERO
var _repaths := 0
var _trail: Array[MeshInstance3D] = []
var _ring: MeshInstance3D
var _pulse := 0.0
var _talk_token := 0
var _step_t := 0.0


func _ready() -> void:
	_build()
	GameState.updated.connect(_refresh)
	Cinematic.started.connect(_on_beat)
	_refresh()
	GameState.greet_site()


func _ppos() -> Vector3:
	return mover.position if mover else Vector3.ZERO


func _process(delta: float) -> void:
	var t := Time.get_ticks_msec() / 1000.0
	var cycle := fmod(t, 1.0)
	var red_on := cycle < 0.09 or (cycle > 0.18 and cycle < 0.27)
	var blue_on := (cycle > 0.5 and cycle < 0.59) or (cycle > 0.68 and cycle < 0.77)
	for lamp in reds:
		lamp.light_energy = 3.2 if red_on else 0.0
	for lamp in blues:
		lamp.light_energy = 3.2 if blue_on else 0.0
	if beacon:
		beacon.visible = fmod(t, 1.6) < 0.25
	if mode == "follow" and camera and mover:
		var goal := _clear_cam(_ppos() + Vector3(0, 1.2, 0), _ppos() + follow_offset)
		camera.position = camera.position.lerp(goal, 1.0 - exp(-4.5 * delta))
		camera.look_at(_ppos() + Vector3(0, 1.0, 0))
	_pulse += delta
	if _ring and _ring.visible:
		var k := 1.0 + 0.12 * sin(_pulse * 6.0)
		_ring.scale = Vector3(k, 1.0, k)
	var best := ""
	var best_d := 3.6
	if mode == "follow" and state == "idle" and mover:
		for id in spots:
			var d := _ppos().distance_to(spots[id]["center"])
			if d < best_d:
				best_d = d
				best = id
	for id in spots:
		var spot: Dictionary = spots[id]
		var icon: Label3D = spot["icon"]
		icon.visible = id == best
		if icon.visible:
			icon.position.y = spot["icon_y"] + 0.08 * sin(t * 4.0)
			icon.modulate.a = clampf((3.6 - best_d) / 1.2, 0.35, 1.0)


func _physics_process(delta: float) -> void:
	if state != "walk" or mover == null:
		return
	if _path_i >= _path.size():
		_finish_walk()
		return
	var to := _path[_path_i] - mover.position
	to.y = 0.0
	var dist := to.length()
	if dist < 0.15:
		_path_i += 1
		return
	var dir := to / dist
	var speed := WALK_SPEED
	if _path_i == _path.size() - 1:
		speed = minf(WALK_SPEED, maxf(1.4, dist * 3.5))
	mover.velocity = mover.velocity.move_toward(dir * speed, 20.0 * delta)
	var before := mover.position
	mover.move_and_slide()
	mover.position.y = 0.0
	var flat := Vector3(mover.velocity.x, 0.0, mover.velocity.z)
	if flat.length() > 0.3:
		_step_t -= delta
		if _step_t <= 0.0:
			_step_t = 0.46
			Sound.step("grass" if not _campus() else "concrete")
		player.rotation.y = lerp_angle(player.rotation.y, atan2(flat.x, flat.z), 1.0 - exp(-14.0 * delta))
	if mover.position.distance_to(before) < speed * delta * 0.2:
		_stuck += delta
		if _stuck > 0.5:
			_repath()
	else:
		_stuck = 0.0
	for dot in _trail:
		if dot.visible and dot.position.distance_to(mover.position) < 0.5:
			dot.visible = false


func _on_beat(id: String) -> void:
	if id != "evidence_major" or camera == null or mode != "focus":
		return
	var fov := camera.fov
	var push := create_tween()
	push.tween_property(camera, "fov", fov - 8.0, 0.2)
	push.tween_property(camera, "fov", fov, 0.35)


func _refresh() -> void:
	if akbaba:
		akbaba.pose("talk" if GameState.speaker == "Akbaba" else "kneel")
	if behzat:
		behzat.pose("talk" if GameState.speaker == "Başkomiser Behzat" else "stand")
	for id in spots:
		var spot: Dictionary = spots[id]
		var done: bool = GameState.inspected.has(id)
		spot["icon"].text = "İNCELENDİ" if done else "[ İNCELE ]"
		spot["icon"].modulate = Color("7dcea0") if done else AMBER
		for tent in spot["tents"]:
			MeshFactory.paint(tent, Color("7dcea0") if done else Color("f2d23a"), 0.5, 0.35)
	if state == "talk" and GameState.pending_clue_id == "" and GameState.line == "":
		_return_camera()


func handle_action(action: String, at: Vector3) -> bool:
	if state == "aim" or state == "examine":
		return true
	if action == "walk":
		_go(at, "")
		return true
	if action.begins_with("hotspot:"):
		var id := action.trim_prefix("hotspot:")
		if spots.has(id):
			_go(spots[id]["stand"], id)
			return true
	return false


func _unhandled_input(event: InputEvent) -> void:
	var cancel: bool = event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT
	if event is InputEventKey and event.pressed and not event.echo and event.keycode in [KEY_ESCAPE, KEY_SPACE, KEY_BACKSPACE]:
		cancel = true
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT and state == "talk":
		cancel = true
	if cancel:
		exit_focus()


## İncelemeden çık: kart/diyalog kapanır, kamera oyuncuya döner, yürüme serbest.
func exit_focus() -> void:
	_stop_walk()
	_talk_token += 1
	if GameState.pending_clue_id != "":
		GameState.dismiss_clue()
	GameState.clear_dialogue()
	if player:
		player.pose("breathe")
	_return_camera()


# ---- Yürüme ----

func _nav_path(from: Vector3, to: Vector3) -> PackedVector3Array:
	if not _nav_map.is_valid():
		return PackedVector3Array([from, to])
	var a := NavigationServer3D.map_get_closest_point(_nav_map, from)
	var b := NavigationServer3D.map_get_closest_point(_nav_map, to)
	return NavigationServer3D.map_get_path(_nav_map, a, b, true)


func _go(target: Vector3, then_id: String) -> void:
	if mover == null:
		return
	GameState.clear_dialogue()
	_cancel_focus()
	target.y = 0.0
	var path := _nav_path(_ppos(), target)
	_pending = then_id
	if path.size() < 2:
		if then_id != "":
			_begin_focus(then_id)
		else:
			_stop_walk()
		return
	_path = path
	_path_i = 1
	_stuck = 0.0
	_repaths = 0
	_dest = target
	state = "walk"
	mover.velocity = Vector3.ZERO
	player.pose("walk")
	_show_trail(path)


func _repath() -> void:
	_stuck = 0.0
	_repaths += 1
	if _repaths <= 2:
		var path := _nav_path(_ppos(), _dest)
		if path.size() >= 2:
			_path = path
			_path_i = 1
			mover.velocity = Vector3.ZERO
			_show_trail(path)
			return
	_finish_walk(true)


func _finish_walk(blocked := false) -> void:
	var id := _pending
	_clear_trail()
	if mover:
		mover.velocity = Vector3.ZERO
	if blocked or id == "":
		_stop_walk()
		return
	_begin_focus(id)


func _stop_walk() -> void:
	if state == "walk":
		state = "idle"
		if player:
			player.pose("breathe")
	_pending = ""
	_clear_trail()


func _show_trail(path: PackedVector3Array) -> void:
	_clear_trail()
	var carry := 0.0
	for i in range(1, path.size()):
		var a := path[i - 1]
		var b := path[i]
		var seg := a.distance_to(b)
		var at := carry
		while at < seg and _trail.size() < 60:
			var p := a.lerp(b, at / maxf(seg, 0.001))
			var dot := MeshFactory.sphere(self, 0.05, Vector3(p.x, 0.06, p.z), AMBER, 1.4)
			_trail.append(dot)
			at += 0.7
		carry = at - seg
	if _ring:
		var last := path[path.size() - 1]
		_ring.position = Vector3(last.x, 0.03, last.z)
		_ring.visible = true


func _clear_trail() -> void:
	for dot in _trail:
		if is_instance_valid(dot):
			dot.queue_free()
	_trail.clear()
	if _ring:
		_ring.visible = false


# ---- İnceleme akışı: yürü -> kadraj -> incele -> kanıt kartı -> diyalog -> geri dön ----

func _cancel_focus() -> void:
	if _shot:
		_shot.kill()
	if _push:
		_push.kill()
	mode = "follow"
	_set_lamp(0.0)
	GameState.set_focus(false)
	if state != "walk":
		state = "idle"


func _return_camera() -> void:
	_cancel_focus()
	state = "idle" if state != "walk" else state
	_pending = "" if state != "walk" else _pending
	GameState.set_focus(false)
	if camera:
		var back := create_tween()
		back.tween_property(camera, "fov", 50.0, 0.3)


func _clear_cam(look: Vector3, cam: Vector3) -> Vector3:
	var world := get_world_3d()
	if world == null:
		return cam
	var query := PhysicsRayQueryParameters3D.create(look, cam, OBSTACLE_LAYER)
	var hit := world.direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return cam
	var toward: Vector3 = (look - cam).normalized()
	var fixed: Vector3 = hit.position + toward * 0.45
	if fixed.distance_to(look) < 1.3:
		fixed = look + (cam - look).normalized() * 1.3
	return fixed


func _begin_focus(id: String) -> void:
	player.pose("breathe")
	GameState.set_focus(true)
	var spot: Dictionary = spots[id]
	var face: Vector3 = spot["center"] - _ppos()
	player.rotation.y = atan2(face.x, face.z)
	state = "aim"
	mode = "focus"
	aim_target = spot["look"]
	lamp.position = spot["center"] + Vector3(0, 1.3, 0.9)
	_set_lamp(3.2)
	var cam_at := _clear_cam(aim_target, spot["cam"])
	if _shot:
		_shot.kill()
	_shot = create_tween()
	_shot.tween_property(camera, "position", cam_at, 0.7).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_shot.parallel().tween_method(_look, 0.0, 1.0, 0.7)
	_shot.tween_callback(_examine.bind(id, cam_at))


func _examine(id: String, cam_at: Vector3) -> void:
	state = "examine"
	var spot: Dictionary = spots[id]
	player.pose("kneel")
	for tent in spot["tents"]:
		tent.scale = Vector3(0.2, 0.2, 0.2)
		var pop := create_tween()
		pop.tween_property(tent, "scale", Vector3(1.25, 1.25, 1.25), 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		pop.tween_property(tent, "scale", Vector3.ONE, 0.12)
	if id == "hotspot_column" and akbaba:
		akbaba.play("PHOTO")
	flash.position = spot["center"] + Vector3(0, 1.6, 0.8)
	flash.light_energy = 16.0
	var fade := create_tween()
	fade.tween_property(flash, "light_energy", 0.0, 0.3)
	if _push:
		_push.kill()
	_push = create_tween()
	_push.tween_property(camera, "position", cam_at + (aim_target - cam_at) * 0.15, 1.4).set_trans(Tween.TRANS_SINE)
	if _shot:
		_shot.kill()
	_shot = create_tween()
	_shot.tween_interval(0.9)
	_shot.tween_callback(GameState.inspect_hotspot.bind(id))
	_shot.tween_interval(1.3)
	_shot.tween_callback(_after_examine)


func _after_examine() -> void:
	player.pose("breathe")
	state = "talk"
	_pending = ""
	_refresh()
	_talk_token += 1
	var token := _talk_token
	get_tree().create_timer(14.0).timeout.connect(func() -> void:
		if token == _talk_token and state == "talk" and GameState.pending_clue_id == "":
			exit_focus()
	)


func _set_lamp(energy: float) -> void:
	if lamp == null:
		return
	if _lamp_tween:
		_lamp_tween.kill()
	_lamp_tween = create_tween()
	_lamp_tween.tween_property(lamp, "light_energy", energy, 0.4)


func _look(_w: float) -> void:
	camera.look_at(aim_target)


# ---- Engeller ve gezinme ağı ----

func _block(center: Vector3, size: Vector2, yaw_deg := 0.0, height := 2.0) -> void:
	_obstacles.append({"c": center, "s": size, "y": yaw_deg})
	var body := StaticBody3D.new()
	body.collision_layer = OBSTACLE_LAYER
	body.collision_mask = 0
	body.position = Vector3(center.x, height * 0.5, center.z)
	body.rotation_degrees.y = yaw_deg
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(size.x, height, size.y)
	shape.shape = box
	body.add_child(shape)
	add_child(body)


func _block_prop(node: Node3D, pad := 0.08) -> void:
	var frame := Transform3D(node.basis.orthonormalized(), node.position)
	var inv := frame.affine_inverse()
	var box := AABB()
	var first := true
	for mi in node.find_children("*", "MeshInstance3D", true, false):
		var m := mi as MeshInstance3D
		var local: AABB = (inv * m.global_transform) * m.get_aabb()
		if first:
			box = local
			first = false
		else:
			box = box.merge(local)
	if first:
		return
	var center: Vector3 = frame * box.get_center()
	_block(Vector3(center.x, 0.0, center.z), Vector2(box.size.x + pad * 2.0, box.size.z + pad * 2.0), node.rotation_degrees.y, maxf(box.end.y, 1.0))


func _walk_bounds() -> Rect2:
	match _set_name():
		"flat":
			return Rect2(-4.4, -3.2, 21.9, 19.2)
		"pavyon":
			return Rect2(-13.0, -3.5, 27.0, 19.5)
		"eczane":
			return Rect2(-7.6, 0.4, 12.6, 11.2)
		"garaj":
			return Rect2(-7.8, 0.6, 14.6, 10.6)
	return Rect2(-14.5, -7.6, 33.5, 23.6)


func _bake_nav() -> void:
	var rect := _walk_bounds()
	var data := NavigationMeshSourceGeometryData3D.new()
	var x0 := rect.position.x
	var z0 := rect.position.y
	var x1 := rect.end.x
	var z1 := rect.end.y
	data.add_faces(PackedVector3Array([
		Vector3(x0, 0, z0), Vector3(x1, 0, z0), Vector3(x0, 0, z1),
		Vector3(x1, 0, z0), Vector3(x1, 0, z1), Vector3(x0, 0, z1),
	]), Transform3D.IDENTITY)
	for o in _obstacles:
		var c: Vector3 = o["c"]
		var s: Vector2 = o["s"]
		var basis := Basis(Vector3.UP, deg_to_rad(float(o["y"])))
		var outline := PackedVector3Array()
		s += Vector2(0.5, 0.5)
		for corner in [Vector3(-s.x, 0, -s.y), Vector3(s.x, 0, -s.y), Vector3(s.x, 0, s.y), Vector3(-s.x, 0, s.y)]:
			outline.append(c + basis * (corner * 0.5))
		data.add_projected_obstruction(outline, -0.5, 3.5, true)
	var mesh := NavigationMesh.new()
	mesh.cell_size = 0.1
	mesh.cell_height = 0.1
	mesh.agent_radius = NAV_RADIUS
	mesh.agent_height = 1.8
	mesh.agent_max_climb = 0.3
	NavigationServer3D.bake_from_source_geometry_data(mesh, data)
	var region := NavigationRegion3D.new()
	region.navigation_mesh = mesh
	add_child(region)
	_nav_map = get_world_3d().navigation_map
	NavigationServer3D.map_force_update(_nav_map)
	_ring = MeshFactory.cylinder(self, 0.38, 0.012, Vector3(0, 0.03, 0), Color("7dcea0"), 1.2)
	_ring.visible = false


func _build() -> void:
	add_child(MeshFactory.environment(Color("070a10"), Color("2c3850"), 0.012, 1.05, true))
	var moon := DirectionalLight3D.new()
	moon.rotation_degrees = Vector3(-55, 35, 0)
	moon.light_color = Color("8fa4c8")
	moon.light_energy = 0.7
	moon.shadow_enabled = true
	add_child(moon)
	_ground()
	var which := _set_name()
	var set_node: Node3D = SETS.get(which, SETS["tower"]).new()
	set_node.host = self
	add_child(set_node)
	set_node.build()
	_cars()
	if which != "pavyon" and which != "eczane" and which != "garaj":
		_yard()
		_forensics()
		_perimeter()
	set_node.details()
	if which != "flat":
		_rain()
	_people()
	_bake_nav()
	lamp = OmniLight3D.new()
	lamp.light_color = Color("fff1d0")
	lamp.light_energy = 0.0
	lamp.omni_range = 5.0
	lamp.shadow_enabled = false
	add_child(lamp)
	flash = OmniLight3D.new()
	flash.light_energy = 0.0
	flash.omni_range = 7.0
	flash.shadow_enabled = false
	add_child(flash)
	camera = Camera3D.new()
	camera.fov = 50.0
	camera.current = true
	camera.position = _ppos() + follow_offset + Vector3(2.2, 2.8, 3.2)
	add_child(camera)
	camera.look_at(_ppos() + Vector3(0, 1.0, 0))


func _set_name() -> String:
	return str(Scenario.data.get("set", "tower"))


func _campus() -> bool:
	return _set_name() != "tower"


func _ground() -> void:
	var mud := Color("2a2e33") if _campus() else Color("3a3024")
	var ground := MeshFactory.block(self, Vector3(70, 0.4, 70), Vector3(0, -0.2, 0), mud, 0.5)
	if not _campus():
		_skin(ground, MeshFactory.pbr("brown_mud_leaves_01", Color("d7c4a4"), Vector2(10, 10)))
	ground.set_meta("action", "walk")
	for p in [[Vector3(-1.5, 0.004, 6.5), Vector2(3.2, 2.1)], [Vector3(6.5, 0.004, 5.2), Vector2(2.2, 1.6)], [Vector3(-6, 0.004, 3), Vector2(4.0, 2.4)], [Vector3(2.5, 0.004, -3.5), Vector2(2.8, 1.5)], [Vector3(11, 0.004, 9), Vector2(3.5, 2.0)]]:
		var puddle := MeshFactory.cylinder(self, 1.0, 0.008, p[0], Color("16202c"))
		var span: Vector2 = p[1]
		puddle.scale = Vector3(span.x, 1.0, span.y)
		var mat: StandardMaterial3D = puddle.material_override
		mat.roughness = 0.04
		mat.metallic = 0.35
	if _campus():
		MeshFactory.box(self, Vector3(18, 0.04, 2.2), Vector3(0, 0.02, 11.2), Color("3a3f46"), 0.8)
		return
	for i in 14:
		var rut := MeshFactory.box(self, Vector3(0.6 + (i % 3) * 0.4, 0.02, 0.25), Vector3(-9 + i * 1.6, 0.01, 11 + (i % 2) * 0.8), Color("1f1a12"), 0.7)
		rut.rotation_degrees.y = -20 + (i % 4) * 9
	MeshFactory.box(self, Vector3(3.5, 1.1, 2.2), Vector3(-12, 0.5, 6), Color("a08a62"), 0.95)
	_block(Vector3(-12, 0, 6), Vector2(3.6, 2.3), 0.0, 1.6)
	MeshFactory.box(self, Vector3(2.4, 0.6, 1.4), Vector3(-12, 1.3, 6), Color("ab9468"), 0.95)


func _cars() -> void:
	_police_car(Vector3(-4.5, 0, 12.5), 24.0)
	_police_car(Vector3(9.0, 0, 14.0), -32.0)


func _police_car(at: Vector3, yaw: float) -> void:
	var car := _prop(POLICE_CAR, at, yaw, 1.65)
	MeshFactory.box(car, Vector3(0.42, 0.05, 0.16), Vector3(-0.12, 1.22, 0.05), Color("DC2626"), 0.2, 1.2)
	MeshFactory.box(car, Vector3(0.42, 0.05, 0.16), Vector3(0.12, 1.22, 0.05), Color("2563eb"), 0.2, 1.2)
	var red := OmniLight3D.new()
	red.position = Vector3(-0.15, 1.4, 0.05)
	red.light_color = Color("ff2a2a")
	red.omni_range = 16.0
	red.shadow_enabled = false
	car.add_child(red)
	reds.append(red)
	var blue := OmniLight3D.new()
	blue.position = Vector3(0.15, 1.4, 0.05)
	blue.light_color = Color("2a6bff")
	blue.omni_range = 16.0
	blue.shadow_enabled = false
	car.add_child(blue)
	blues.append(blue)
	for x in [-0.4, 0.4]:
		MeshFactory.box(car, Vector3(0.22, 0.1, 0.04), Vector3(x, 0.48, 1.48), Color("fff6d8"), 0.2, 0.8)
	var head := SpotLight3D.new()
	head.position = Vector3(0, 0.5, 1.5)
	head.light_color = Color("fff1cf")
	head.light_energy = 3.0
	head.spot_range = 14.0
	head.spot_angle = 38.0
	head.shadow_enabled = false
	car.add_child(head)
	_reskin(car, "S6")


## Kenney aracının görünümünü Tripo aracıyla değiştirir. Kenney düğümü (çarpışma kutusu,
## ışıklar) yerinde kalır, yalnız mesh'leri gizlenir. Tripo araçları X ekseninde, önü -X.
func _reskin(node: Node3D, id: String) -> void:
	for mi in node.find_children("*", "MeshInstance3D", true, false):
		(mi as MeshInstance3D).visible = false
	var wrap := Node3D.new()
	wrap.scale = Vector3.ONE / node.scale.x
	wrap.rotation_degrees.y = 90.0
	node.add_child(wrap)
	var car := Props.make(id)
	wrap.add_child(car)
	_cast(car)
	if id == "S6":
		for side in [-1.0, 1.0]:
			var tag := MeshFactory.label(car, "POLİS", Vector3(0.2, 0.85, side * 1.07), Color("f4f6fa"), 0.5)
			tag.billboard = BaseMaterial3D.BILLBOARD_DISABLED
			tag.fixed_size = false
			tag.rotation_degrees.y = 0.0 if side > 0 else 180.0


func _forensics() -> void:
	_floodlight(Vector3(2.8, 0, 1.0), Vector3(0.2, 0.3, 3.4))
	_floodlight(Vector3(-5.8, 0, 2.2), Vector3(-3.5, 1.6, -1.0))
	var case_at := Vector3(2.2, 0, 5.4)
	_block(case_at + Vector3(0.4, 0, 0.1), Vector2(1.5, 0.7), 0.0, 0.6)
	_prop(KIT, case_at + Vector3(0.9, 0.2, 0.2), 25.0, 0.32, Vector3(0, -0.6, 0), false)
	MeshFactory.box(self, Vector3(0.7, 0.25, 0.5), case_at + Vector3(0, 0.125, 0), Color("1a1a1a"), 0.5)
	var lid := MeshFactory.box(self, Vector3(0.7, 0.04, 0.5), case_at + Vector3(0, 0.45, -0.22), Color("1a1a1a"), 0.5)
	lid.rotation_degrees.x = -70
	MeshFactory.box(self, Vector3(0.6, 0.02, 0.4), case_at + Vector3(0, 0.26, 0), Color("4a4a4a"), 0.9)
	for i in 3:
		MeshFactory.cylinder(self, 0.03, 0.12, case_at + Vector3(-0.18 + i * 0.18, 0.32, 0.05), [Color("f2d23a"), Color("9fd7ff"), Color("e7e1d6")][i])
	var tri := Vector3(-1.4, 0, 5.2)
	_block(tri, Vector2(0.5, 0.5), 0.0, 1.6)
	for i in 3:
		var leg := MeshFactory.cylinder(self, 0.015, 1.5, tri + Vector3(0, 0.75, 0), Color("222222"))
		leg.rotation_degrees = Vector3(14 * cos(i * 2.09), i * 120.0, 14 * sin(i * 2.09))
	MeshFactory.box(self, Vector3(0.22, 0.14, 0.14), tri + Vector3(0, 1.55, 0), Color("111111"), 0.4)
	MeshFactory.cylinder(self, 0.05, 0.1, tri + Vector3(0, 1.55, 0.1), Color("222222")).rotation_degrees.x = 90
	for i in 3:
		var bag := MeshFactory.box(self, Vector3(0.22, 0.02, 0.3), Vector3(1.6 + i * 0.28, 0.02, 6.4), Color(0.9, 0.93, 0.97, 0.7))
		bag.rotation_degrees.y = i * 12
		MeshFactory.box(self, Vector3(0.2, 0.022, 0.05), bag.position + Vector3(0, 0.002, -0.12), Color("DC2626"))


func _yard() -> void:
	if _campus():
		_reskin(_prop(SEDAN, Vector3(12.5, 0.0, 9.5), 150.0, 1.55), "S5")
		_reskin(_prop(SEDAN, Vector3(-9.5, 0.0, 9.0), 150.0, 1.55), "S5")
		_prop(STREET, Vector3(8.4, 0.0, 5.4), -40.0, 1.75)
		_prop(STREET, Vector3(-8.2, 0.0, 11.0), 20.0, 1.75)
		return
	_prop(SUV, Vector3(5.2, 0.0, 8.2), 18.0, 1.6)
	_prop(TRUCK, Vector3(12.5, 0.0, -8.5), -30.0, 1.75)
	_prop(SHOVEL, Vector3(17.2, 0.0, 1.4), 80.0, 1.7)
	_reskin(_prop(SEDAN, Vector3(-9.5, 0.0, 9.0), 150.0, 1.55), "S5")
	_prop(STREET, Vector3(8.4, 0.0, 5.4), -40.0, 1.75)
	_prop(STREET, Vector3(-8.2, 0.0, 11.0), 20.0, 1.75)
	_prop(SCAFFOLD, Vector3(-5.4, 0.0, -2.4), 15.0, 1.15, Vector3(0.55, -1.78, 0.0))
	for i in 8:
		_prop(FENCE, Vector3(13.5, 0.0, -6.0 + i * 0.85), 90.0, 1.15)


func _prop(scene: PackedScene, feet: Vector3, yaw: float, scale: float, local_feet: Vector3 = Vector3.ZERO, solid := true) -> Node3D:
	var offset := Basis(Vector3.UP, deg_to_rad(yaw)) * (local_feet * scale)
	var node := MeshFactory.place(self, scene, feet - offset, yaw, scale)
	_cast(node)
	if solid:
		_block_prop(node)
	return node


func _cast(node: Node) -> void:
	if node is GeometryInstance3D:
		(node as GeometryInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	for child in node.get_children():
		_cast(child)


func _skin(body: Node, mat: Material) -> void:
	for child in body.get_children():
		if child is MeshInstance3D:
			(child as MeshInstance3D).material_override = mat


func _floodlight(at: Vector3, target: Vector3) -> void:
	_block(at + Vector3(0.3, 0, 0.15), Vector2(1.0, 0.8), 0.0, 2.3)
	for i in 3:
		var leg := MeshFactory.cylinder(self, 0.02, 2.2, at + Vector3(0, 1.1, 0), Color("c9a22a"))
		leg.rotation_degrees = Vector3(12 * cos(i * 2.09), i * 120.0, 12 * sin(i * 2.09))
	var head := Node3D.new()
	head.position = at + Vector3(0, 2.3, 0)
	add_child(head)
	head.look_at(target, Vector3.UP)
	MeshFactory.box(head, Vector3(0.6, 0.4, 0.2), Vector3.ZERO, Color("c9a22a"), 0.5)
	MeshFactory.box(head, Vector3(0.5, 0.3, 0.04), Vector3(0, 0, -0.11), Color("fff8e2"), 0.2, 2.2)
	var lamp := SpotLight3D.new()
	lamp.position = Vector3(0, 0, -0.15)
	lamp.light_color = Color("f4f0e4")
	lamp.light_energy = 8.0
	lamp.spot_range = 13.0
	lamp.spot_angle = 42.0
	lamp.spot_angle_attenuation = 0.8
	lamp.shadow_enabled = false
	head.add_child(lamp)
	MeshFactory.box(self, Vector3(0.5, 0.3, 0.3), at + Vector3(0.6, 0.15, 0.3), Color("DC2626"), 0.6)


func _perimeter() -> void:
	var points := [Vector3(-6.5, 0, 7.5), Vector3(-6.5, 0, -3.5), Vector3(3.5, 0, -3.5), Vector3(4.0, 0, 6.0), Vector3(-0.5, 0, 7.5)]
	for i in points.size():
		var a: Vector3 = points[i]
		var b: Vector3 = points[(i + 1) % points.size()]
		if i == points.size() - 1:
			break
		_tape(a, b)
	_tape(Vector3(4.0, 0, 6.0), Vector3(6.8, 0, 11.6))
	_tape(Vector3(6.8, 0, 11.6), Vector3(3.6, 0, 12.2))


func _tape(a: Vector3, b: Vector3) -> void:
	for p in [a, b]:
		MeshFactory.cylinder(self, 0.035, 1.1, p + Vector3(0, 0.55, 0), Color("d8d2c8"))
		MeshFactory.cylinder(self, 0.18, 0.04, p + Vector3(0, 0.02, 0), Color("1a1a1a"))
	var mid := (a + b) * 0.5 + Vector3(0, 0.95, 0)
	var strip := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.02, 0.1, a.distance_to(b))
	strip.mesh = mesh
	strip.position = mid
	add_child(strip)
	strip.look_at(b + Vector3(0, 0.95, 0), Vector3.UP)
	MeshFactory.paint(strip, Color("f2d23a"), 0.6, 0.1)
	var text := Label3D.new()
	text.text = "POLİS ŞERİDİ  GEÇMEYİNİZ  "
	text.text = text.text.repeat(max(1, int(a.distance_to(b) / 2.6)))
	text.pixel_size = 0.004
	text.font_size = 40
	text.modulate = Color("1a1408")
	text.position = Vector3(0.012, 0, 0)
	text.rotation_degrees.y = 90
	text.scale = Vector3.ONE * 0.45
	strip.add_child(text)


func _rain() -> void:
	var rain := GPUParticles3D.new()
	rain.position = Vector3(0, 12, 2)
	rain.amount = 80
	rain.lifetime = 1.6
	rain.visibility_aabb = AABB(Vector3(-22, -14, -22), Vector3(44, 28, 44))
	var process := ParticleProcessMaterial.new()
	process.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	process.emission_box_extents = Vector3(20, 0.5, 20)
	process.direction = Vector3(0.12, -1, 0.04)
	process.spread = 4.0
	process.initial_velocity_min = 11.0
	process.initial_velocity_max = 15.0
	process.gravity = Vector3(0, -7, 0)
	rain.process_material = process
	var drop := QuadMesh.new()
	drop.size = Vector2(0.018, 0.34)
	var drop_mat := StandardMaterial3D.new()
	drop_mat.albedo_color = Color(0.72, 0.8, 0.95, 0.4)
	drop_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	drop_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	drop_mat.billboard_mode = BaseMaterial3D.BILLBOARD_FIXED_Y
	drop.material = drop_mat
	rain.draw_pass_1 = drop
	rain.emitting = true
	add_child(rain)


func _people() -> void:
	var apos := Vector3(-2.4, 0, 3.6)
	var ayaw := 90.0
	if _set_name() == "flat":
		apos = Vector3(-3.3, 0, 3.4)
	elif _set_name() == "pavyon":
		apos = Vector3(-2.6, 0, 5.6)
		ayaw = 60.0
	elif _set_name() == "eczane":
		apos = Vector3(4.4, 0, 9.4)
		ayaw = 200.0
	elif _set_name() == "garaj":
		apos = Vector3(5.4, 0, 7.2)
		ayaw = 160.0
	akbaba = _spawn("akbaba", apos, ayaw)
	akbaba.pose("kneel")
	_block(apos, Vector2(0.9, 0.9), 0.0, 1.8)
	var cpos := Vector3(0.8, 0, 9.4)
	behzat = _spawn("behzat", cpos, 180.0)
	behzat.pose("stand")
	_block(cpos, Vector2(0.8, 0.8), 0.0, 1.8)
	mover = CharacterBody3D.new()
	mover.motion_mode = CharacterBody3D.MOTION_MODE_FLOATING
	mover.collision_layer = 0
	mover.collision_mask = OBSTACLE_LAYER
	mover.position = Vector3(3.0, 0, 10.4)
	var cap := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.28
	capsule.height = 1.7
	cap.shape = capsule
	cap.position.y = 0.9
	mover.add_child(cap)
	add_child(mover)
	player = RIG.instantiate()
	player.rotation_degrees.y = 200.0
	mover.add_child(player)
	player.setup("player")
	player.pose("breathe")


func _spawn(who: String, pos: Vector3, yaw: float) -> Node3D:
	var rig := RIG.instantiate()
	rig.position = pos
	rig.rotation_degrees.y = yaw
	add_child(rig)
	rig.setup(who)
	return rig


func _spot(id: String, zone: Area3D, center: Vector3, stand: Vector3, cam: Vector3, look: Vector3, icon_at: Vector3, tent_offsets: Array, number: String) -> void:
	var mesh: MeshInstance3D = null
	for child in zone.get_children():
		if child is MeshInstance3D:
			mesh = child
	if mesh:
		mesh.visible = false
	var icon := MeshFactory.label(self, "[ İNCELE ]", icon_at, AMBER, 0.6)
	icon.fixed_size = true
	icon.pixel_size = 0.0008
	icon.visible = false
	var tents: Array[MeshInstance3D] = []
	for offset in tent_offsets:
		var pos: Vector3 = Vector3(center.x, 0, center.z) + offset
		var tent := MeshFactory.box(self, Vector3(0.2, 0.26, 0.02), pos + Vector3(0, 0.12, -0.06), Color("f2d23a"), 0.5, 0.35)
		tent.rotation_degrees.x = -28
		var back := MeshFactory.box(tent, Vector3(0.2, 0.26, 0.02), Vector3(0, 0, 0.12), Color("f2d23a"), 0.5, 0.35)
		back.rotation_degrees.x = 56
		var num := MeshFactory.label(tent, number, Vector3(0, 0.0, -0.015), Color("1a1408"), 0.35)
		num.billboard = BaseMaterial3D.BILLBOARD_DISABLED
		num.rotation_degrees.y = 180
		tents.append(tent)
	spots[id] = {
		"center": center,
		"stand": stand,
		"cam": cam,
		"look": look,
		"icon": icon,
		"icon_y": icon_at.y,
		"tents": tents,
	}
