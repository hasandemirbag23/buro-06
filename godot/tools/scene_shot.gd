extends Node
## Sahne render aracı (görsel kontrol). Kullanım:
## godot --path . --resolution 1600x900 res://tools/scene_shot.tscn -- <office|interrogation|episode_0N> [çıktı_öneki]
## Oyun kamerasından ve geniş açıdan iki PNG yazar: <önek>_game.png, <önek>_wide.png

func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	var what := args[0] if args.size() > 0 else "office"
	var out := args[1] if args.size() > 1 else "/tmp/shot_" + what
	GameState.open_case(what if what.begins_with("episode") else "episode_01")
	var scene: Node3D
	match what:
		"office":
			scene = (load("res://scenes/CrimeOffice3D.tscn") as PackedScene).instantiate()
		"interrogation":
			scene = (load("res://scenes/interrogation.tscn") as PackedScene).instantiate()
		_:
			scene = Node3D.new()
			scene.set_script(load("res://scenes/crime_scene_3d.gd"))
	add_child(scene)
	for i in 50:
		await get_tree().process_frame
	await _save(out + "_game.png")
	var cam := Camera3D.new()
	scene.add_child(cam)
	cam.fov = 60
	if what.begins_with("episode"):
		cam.position = Vector3(0, 9, 34)
		cam.look_at(Vector3(0, 5, -20))
	elif what == "office":
		cam.position = Vector3(0, 3.1, 5.2)
		cam.look_at(Vector3(0, 0.9, -1.5))
	else:
		cam.position = Vector3(1.6, 1.9, 2.0)
		cam.look_at(Vector3(0, 0.8, 0))
	cam.current = true
	for i in 6:
		await get_tree().process_frame
	await _save(out + "_wide.png")
	get_tree().quit()


func _save(path: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(path)
	print("kaydedildi: ", path)
