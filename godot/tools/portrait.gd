extends Node3D
## Karakter portre aracı: her karakterin yüzünü yakın çeker. /tmp/portrait_<id>.png
## Çalıştır: godot --path . res://tools/portrait.tscn -- behzat hayalet ...

const RIG := preload("res://scenes/character_rig.tscn")
const MeshFactory := preload("res://scenes/mesh_factory.gd")
const ALL := ["behzat", "akbaba", "hayalet", "savci", "tarik", "player", "zafer", "mert", "haldun", "nevzat", "idris", "arsiv"]


func _ready() -> void:
	add_child(MeshFactory.environment(Color("1a1d24"), Color("8c8274"), 0.0, 0.9))
	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-30, -35, 0)
	key.light_energy = 1.6
	key.light_color = Color("ffe2bd")
	key.shadow_enabled = true
	add_child(key)
	var rim := DirectionalLight3D.new()
	rim.rotation_degrees = Vector3(-20, 160, 0)
	rim.light_energy = 0.6
	rim.light_color = Color("9fb8ff")
	add_child(rim)
	var cam := Camera3D.new()
	cam.fov = 22
	add_child(cam)
	cam.current = true
	var ids: Array = []
	for a in OS.get_cmdline_user_args():
		ids.append(a)
	if ids.is_empty():
		ids = ALL
	var full := ids.has("full")
	ids.erase("full")
	ids.erase("front")
	var episode_of := {"mert": "episode_02", "haldun": "episode_02", "nevzat": "episode_03", "idris": "episode_03"}
	for id in ids:
		Scenario.load_case(episode_of.get(id, "episode_01"))
		var rig := RIG.instantiate()
		add_child(rig)
		rig.setup(id)
		rig.pose("breathe")
		for i in 12:
			await get_tree().process_frame
		var base := Vector3(0, 1.6, 0)
		if rig.skeleton:
			var bone_pos: Vector3 = rig.skeleton.get_bone_global_pose(rig.skeleton.find_bone("Head")).origin
			base = rig.skeleton.global_transform * bone_pos
		if rig.has_meta("head_root"):
			base = (rig.get_meta("head_root") as Node3D).global_position
		if full:
			cam.fov = 34
			cam.position = Vector3(0, 1.0, 5.2)
			cam.look_at(Vector3(0, 0.95, 0))
		else:
			cam.fov = 20
			var hb := Basis.IDENTITY
			if rig.has_meta("head_root"):
				hb = (rig.get_meta("head_root") as Node3D).global_transform.basis
			var side := 0.0 if ids.size() > 0 and OS.get_cmdline_user_args().has("front") else 0.28
			cam.position = base + hb * Vector3(side, 0.02, 1.5)
			cam.look_at(base + hb * Vector3(0, -0.01, 0), hb.y)
		for i in 6:
			await get_tree().process_frame
		get_viewport().get_texture().get_image().save_png("/tmp/portrait_%s%s.png" % [id, "_full" if full else ""])
		rig.queue_free()
		await get_tree().process_frame
	get_tree().quit()
