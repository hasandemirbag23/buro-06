extends Node3D
## Kafa önizleme (rig yok): /tmp/head_<id>_<front|q|side>.png
## godot --path . --resolution 700x700 res://tools/head_view.tscn -- behzat hayalet

const Styler := preload("res://scenes/character_styler.gd")
const MeshFactory := preload("res://scenes/mesh_factory.gd")


func _ready() -> void:
	add_child(MeshFactory.environment(Color("1a1d24"), Color("8c8274"), 0.0, 0.9))
	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-25, -30, 0)
	key.light_energy = 1.7
	key.light_color = Color("ffe2bd")
	key.shadow_enabled = true
	add_child(key)
	var rim := DirectionalLight3D.new()
	rim.rotation_degrees = Vector3(-20, 160, 0)
	rim.light_energy = 0.7
	rim.light_color = Color("9fb8ff")
	add_child(rim)
	var cam := Camera3D.new()
	cam.fov = 18
	add_child(cam)
	cam.current = true
	var args := Array(OS.get_cmdline_user_args())
	var hide_hair := args.has("nohair")
	var hide_skin := args.has("noskin")
	args = args.filter(func(a): return a != "nohair" and a != "noskin")
	for id in args:
		var head := Styler.build_head(id)
		add_child(head)
		if hide_skin:
			head.get_child(0).visible = false
		if hide_hair and head.get_child_count() > 1:
			head.get_child(1).visible = false
		for view in ["front", "q", "q2", "side", "side2"]:
			var yaw: float = {"front": 0.0, "q": 45.0, "q2": -45.0, "side": 90.0, "side2": -90.0}[view]
			var dir := Vector3(sin(deg_to_rad(yaw)), 0.03, cos(deg_to_rad(yaw)))
			cam.position = dir * 1.0
			cam.look_at(Vector3(0, -0.02, 0))
			for i in 3:
				await get_tree().process_frame
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png("/tmp/head_%s_%s.png" % [id, view])
		head.queue_free()
	get_tree().quit()
