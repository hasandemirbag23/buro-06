extends SceneTree

## Karakter modellerini denetler: iskelet, kemikler, blend shape, animasyon kütüphanesi.
## Çalıştır: godot --headless --path . -s tools/inspect_rigs.gd

func _init() -> void:
	var dir := DirAccess.open("res://assets/characters")
	var shown := false
	for f in dir.get_files():
		if not f.ends_with(".glb"):
			continue
		var scene: Node = load("res://assets/characters/" + f).instantiate()
		var skel := scene.find_child("GeneralSkeleton", true, false) as Skeleton3D
		var morphs := 0
		var meshes: Array[String] = []
		for m in scene.find_children("*", "MeshInstance3D", true, false):
			var mi := m as MeshInstance3D
			morphs += mi.mesh.get_blend_shape_count() if mi.mesh else 0
			meshes.append("%s(%d surf)" % [mi.name, mi.mesh.get_surface_count() if mi.mesh else 0])
		print("%s skeleton=%s bones=%d blendshapes=%d anim_players=%d meshes=%s" % [f, skel != null, skel.get_bone_count() if skel else 0, morphs, scene.find_children("*", "AnimationPlayer", true, false).size(), meshes])
		if skel and not shown:
			shown = true
			var names: Array[String] = []
			for i in skel.get_bone_count():
				names.append(skel.get_bone_name(i))
			print("  BONES: ", names)
		scene.free()
	var lib: Node = load("res://assets/anim/AnimationLibrary_Godot_Standard.gltf").instantiate()
	var ap := lib.find_child("AnimationPlayer", true, false) as AnimationPlayer
	print("ANIMS(%d): %s" % [ap.get_animation_list().size(), ap.get_animation_list()])
	var a := ap.get_animation("Idle_Loop")
	for i in mini(6, a.get_track_count()):
		print("  track ", a.track_get_path(i))
	quit()
