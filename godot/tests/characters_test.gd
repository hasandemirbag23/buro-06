extends Node3D

## Merkezi karakter sistemi testi: 5 karakter aynı sahnede. Başsız çalışır; pencereli çalışırsa ekran görüntüsü alır.
## Çalıştır: godot --path . res://tests/characters_test.tscn

const CS := preload("res://characters/base/character_state.gd")
const SCENES := {
	"behzat": "res://characters/chief_detective/chief_detective.tscn",
	"akbaba": "res://characters/forensic_expert/forensic_expert.tscn",
	"hayalet": "res://characters/young_officer/young_officer.tscn",
	"savci": "res://characters/prosecutor/prosecutor.tscn",
	"tarik": "res://characters/tarik_soylu/tarik_soylu.tscn",
}
const TABLE := Rect2(-1.0, -0.5, 2.0, 1.0)

var chars: Dictionary = {}
var fails := 0
var noticed := 0


func check(ok: bool, label: String) -> void:
	print(("PASS  " if ok else "FAIL  ") + label)
	if not ok:
		fails += 1


func _ready() -> void:
	Scenario.load_case("episode_01")
	_stage()
	var spots := {"behzat": Vector3(-4, 0, -3), "akbaba": Vector3(-3, 0, 2.5), "hayalet": Vector3(0, 0, 4), "savci": Vector3(3, 0, -3), "tarik": Vector3(4, 0, 2.5)}
	for id in SCENES:
		var node: CharacterBody3D = load(SCENES[id]).instantiate()
		node.position = spots[id]
		add_child(node)
		chars[id] = node
		node.interaction.noticed.connect(func(_o: CharacterBody3D) -> void: noticed += 1)
	for i in 30:
		await get_tree().physics_frame
	await _identity()
	await _states()
	await _animations()
	await _emotion()
	await _interaction()
	await _physics()
	await _missing()
	print("SONUC ", "TAMAM" if fails == 0 else "%d HATA" % fails)
	get_tree().quit(0 if fails == 0 else 1)


func _stage() -> void:
	var data := NavigationMeshSourceGeometryData3D.new()
	data.add_faces(PackedVector3Array([
		Vector3(-6, 0, -5), Vector3(6, 0, -5), Vector3(-6, 0, 5),
		Vector3(6, 0, -5), Vector3(6, 0, 5), Vector3(-6, 0, 5),
	]), Transform3D.IDENTITY)
	## Projected obstruction ajan yarıçapıyla şişmez: kapsül yarıçapı (0.28) + pay kadar elle büyüt.
	var pad := TABLE.grow(0.5)
	data.add_projected_obstruction(PackedVector3Array([
		Vector3(pad.position.x, 0, pad.position.y), Vector3(pad.end.x, 0, pad.position.y),
		Vector3(pad.end.x, 0, pad.end.y), Vector3(pad.position.x, 0, pad.end.y),
	]), -0.5, 3.0, true)
	var mesh := NavigationMesh.new()
	mesh.cell_size = 0.1
	mesh.cell_height = 0.1
	mesh.agent_radius = 0.3
	mesh.agent_height = 1.8
	NavigationServer3D.bake_from_source_geometry_data(mesh, data)
	var region := NavigationRegion3D.new()
	region.navigation_mesh = mesh
	add_child(region)
	var table := StaticBody3D.new()
	table.collision_layer = 16
	table.position = Vector3(0, 0.5, 0)
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(TABLE.size.x, 1.0, TABLE.size.y)
	shape.shape = box
	table.add_child(shape)
	var vis := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = box.size
	vis.mesh = bm
	table.add_child(vis)
	add_child(table)
	var floor := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(12, 10)
	floor.mesh = plane
	add_child(floor)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55, 30, 0)
	add_child(sun)
	var cam := Camera3D.new()
	cam.position = Vector3(0, 9, 8)
	add_child(cam)
	cam.look_at(Vector3(0, 0.5, 0))
	cam.current = true


func _identity() -> void:
	var roles := {}
	for id in chars:
		var c: CharacterBody3D = chars[id]
		check(c.character_id == id and c.full_name() != "" and c.roster_ok, "kimlik %s = %s (%s)" % [id, c.full_name(), c.role])
		check(c.personality.size() == 6, "kişilik 6 değer: %s" % id)
		roles[c.role] = true
	check(roles.size() == 5, "5 farklı rol")
	check(chars["savci"].last_name == "Erdem" and chars["tarik"].last_name == "Soylu", "ad ve soyad ayrımı")


func _states() -> void:
	var c: CharacterBody3D = chars["behzat"]
	check(c.state == CS.State.IDLE, "başlangıç IDLE")
	check(c.request_state(CS.State.SITTING) and c.sitting, "IDLE -> SITTING")
	check(c.request_state(CS.State.WALKING) and c.state == CS.State.WALKING and not c.sitting, "SITTING -> WALKING (otomatik ayağa kalkar)")
	check(not c.request_state(CS.State.TALKING), "WALKING -> TALKING reddedilir")
	check(c.request_state(CS.State.STANDING) and c.request_state(CS.State.TALKING), "STANDING -> TALKING")
	check(c.request_state(CS.State.LISTENING) and c.request_state(CS.State.INVESTIGATING), "TALKING -> LISTENING -> INVESTIGATING")
	check(c.react("Surprise", 0.4) and c.state == CS.State.REACTING, "REACTING girişi")
	await get_tree().create_timer(0.7).timeout
	check(c.state == CS.State.INVESTIGATING, "REACTING bitince önceki duruma döner")
	check(c.request_state(CS.State.IDLE), "-> IDLE")


func _anim_of(c: CharacterBody3D) -> String:
	var pb: Variant = c.rig.tree.get("parameters/playback")
	return str(pb.get_current_node()) if pb else ""


func _animations() -> void:
	chars["behzat"].controller.sit()
	chars["akbaba"].request_state(CS.State.INVESTIGATING)
	chars["hayalet"].controller.move_to(Vector3(-5, 0, -4), false)
	chars["savci"].request_state(CS.State.TALKING)
	chars["tarik"].request_state(CS.State.STANDING)
	chars["tarik"].emotion.set_emotion("angry", 0.8, 5.0)
	await get_tree().create_timer(1.2).timeout
	var seen := {}
	for id in chars:
		seen[_anim_of(chars[id])] = true
		print("  anim %s -> %s (%s)" % [id, _anim_of(chars[id]), chars[id].state_name()])
	check(seen.size() >= 3, "en az 3 farklı animasyon aynı anda (%d)" % seen.size())
	check(chars["hayalet"].movement_state() == "walking", "hareket durumu walking")
	chars["hayalet"].controller.stop()
	if DisplayServer.get_name() != "headless":
		get_viewport().get_texture().get_image().save_png("/tmp/characters_lab.png")


func _emotion() -> void:
	var low: CharacterBody3D = chars["hayalet"]
	var high: CharacterBody3D = chars["savci"]
	low.emotion.stress = 0.0
	high.emotion.stress = 0.0
	low.emotion.add_stress(50.0)
	high.emotion.add_stress(50.0)
	check(low.emotion.stress > high.emotion.stress, "stres direnci: %.1f > %.1f" % [low.emotion.stress, high.emotion.stress])
	var ag: CharacterBody3D = chars["behzat"]
	ag.emotion.stress = 0.0
	ag.emotion.add_stress(60.0)
	check(ag.emotion_name() == "angry", "agresif karakter öfkelenir (%s)" % ag.emotion_name())
	chars["hayalet"].emotion.add_stress(40.0)
	check(chars["hayalet"].emotion_name() in ["nervous", "afraid"], "düşük agresyon gerilir/korkar (%s)" % chars["hayalet"].emotion_name())
	for id in chars:
		chars[id].emotion.stress = 0.0
		chars[id].emotion.set_emotion("neutral", 0.0, 0.0)


func _interaction() -> void:
	for id in chars:
		chars[id].request_state(CS.State.IDLE) if chars[id].state != CS.State.SITTING else chars[id].request_state(CS.State.STANDING)
		chars[id].controller.stop()
	var a: CharacterBody3D = chars["akbaba"]
	var b: CharacterBody3D = chars["savci"]
	a.global_position = Vector3(-3, 0, 3)
	b.global_position = Vector3(-2, 0, 3)
	for i in 10:
		await get_tree().physics_frame
	check(noticed > 0 and (a.interaction.nearby.has(b) or b.interaction.nearby.has(a)), "algı alanı: karakter fark etme (%d olay)" % noticed)
	check(a.interaction.interact_with(b, 2.5), "etkileşim başlatıldı")
	await get_tree().create_timer(0.3).timeout
	check(a.state == CS.State.TALKING and b.state == CS.State.LISTENING, "TALKING / LISTENING")
	check(a.interaction_state() == "conversing" and b.gaze_target() == a, "konuşma durumu ve karşılıklı bakış")
	await get_tree().create_timer(3.5).timeout
	check(a.interaction_state() == "none" and not a.state in [CS.State.TALKING, CS.State.LISTENING], "konuşma kendiliğinden bitti")


func _inside_table(p: Vector3) -> bool:
	return TABLE.grow(0.05).has_point(Vector2(p.x, p.z))


func _physics() -> void:
	var a: CharacterBody3D = chars["akbaba"]
	var b: CharacterBody3D = chars["tarik"]
	a.global_position = Vector3(-3, 0, 0)
	b.global_position = Vector3(3, 0, 0)
	a.request_state(CS.State.IDLE)
	b.request_state(CS.State.IDLE)
	var done := {"a": false, "b": false}
	a.controller.arrived.connect(func() -> void: done["a"] = true, CONNECT_ONE_SHOT)
	b.controller.arrived.connect(func() -> void: done["b"] = true, CONNECT_ONE_SHOT)
	check(a.controller.move_to(Vector3(3, 0, 0)) and b.controller.move_to(Vector3(-3, 0, 0)), "iki karakter karşılıklı yürüyüşe geçti")
	var min_d := 99.0
	var in_table := false
	var t := 0.0
	while t < 20.0 and not (done["a"] and done["b"]):
		await get_tree().physics_frame
		t += get_physics_process_delta_time()
		min_d = minf(min_d, a.global_position.distance_to(b.global_position))
		in_table = in_table or _inside_table(a.global_position) or _inside_table(b.global_position)
	print("  min mesafe %.2f, süre %.1f sn" % [min_d, t])
	check(done["a"] and done["b"], "ikisi de hedefe vardı")
	check(not in_table, "masanın içinden geçmedi")
	check(min_d > 0.45, "karakterler birbirinin içine girmedi (%.2f)" % min_d)
	check(a.global_position.distance_to(Vector3(3, 0, 0)) < 0.7 and b.global_position.distance_to(Vector3(-3, 0, 0)) < 0.7, "hedef konumlar doğru")


func _missing() -> void:
	var ghost: CharacterBody3D = load("res://characters/base/character_base.tscn").instantiate()
	ghost.character_id = "olmayan_karakter"
	add_child(ghost)
	await get_tree().physics_frame
	check(not ghost.roster_ok and ghost.state == CS.State.IDLE, "kadroda olmayan karakter çökmeden uyarı verir")
