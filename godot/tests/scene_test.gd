extends Node

## Olay yeri testi: her set için yaratılır, hotspot duruş noktalarına navmesh yolu aranır,
## başlangıç noktasından karşı uçlara yol ve engel içinde durmama kontrol edilir.
## Çalıştır: godot --path . res://tests/scene_test.tscn   (pencere gerekir: render ve fizik)

const SCENE := preload("res://scenes/crime_scene_3d.gd")
var fails := 0
var logged := 0


func check(ok: bool, label: String) -> void:
	if not ok:
		fails += 1
		print("FAIL  ", label)


func _ready() -> void:
	for id in ["episode_01", "episode_02", "episode_03", "episode_04", "episode_05"]:
		await _probe(id)
	print("SCENE_", "OK" if fails == 0 else "FAIL %d" % fails)
	get_tree().quit(0 if fails == 0 else 1)


func _probe(id: String) -> void:
	GameState.open_case(id)
	var scene := Node3D.new()
	scene.set_script(SCENE)
	add_child(scene)
	for i in 40:
		await get_tree().physics_frame
	var map: RID = scene._nav_map
	var start: Vector3 = scene._ppos()
	var which := str(Scenario.data.get("set", "tower"))
	for key in scene.spots:
		var stand: Vector3 = scene.spots[key]["stand"]
		stand.y = 0.0
		var path := NavigationServer3D.map_get_path(map, start, stand, true)
		var ok := path.size() >= 2 and path[path.size() - 1].distance_to(stand) < 0.7
		check(ok, "%s/%s: %s duruş noktasına yol" % [id, which, key])
	var rect: Rect2 = scene._walk_bounds()
	var probes := [
		Vector2(rect.position.x + 1.0, rect.position.y + 1.0), Vector2(rect.end.x - 1.0, rect.position.y + 1.0),
		Vector2(rect.position.x + 1.0, rect.end.y - 1.0), Vector2(rect.end.x - 1.0, rect.end.y - 1.0),
	]
	var reachable := 0
	for q in probes:
		var target := Vector3(q.x, 0, q.y)
		var snapped: Vector3 = NavigationServer3D.map_get_closest_point(map, target)
		var path := NavigationServer3D.map_get_path(map, start, snapped, true)
		if path.size() >= 2 and path[path.size() - 1].distance_to(snapped) < 0.7:
			reachable += 1
	check(reachable >= 3, "%s/%s: köşelere ulaşım %d/4" % [id, which, reachable])
	check(scene.get_child_count() > 60, "%s/%s: sahne dolu" % [id, which])
	# Engel içinde duran karakter yok mu?
	for body in scene.get_children():
		if body is StaticBody3D and (body as StaticBody3D).collision_layer == scene.OBSTACLE_LAYER:
			var box := (body as StaticBody3D).get_child(0).shape as BoxShape3D
			if box and (body as StaticBody3D).position.distance_to(start) < 0.01:
				check(false, "%s: başlangıç engel içinde" % id)
	print("%s (%s): %d engel, %d hotspot" % [id, which, scene._obstacles.size(), scene.spots.size()])
	scene.queue_free()
	await get_tree().process_frame
