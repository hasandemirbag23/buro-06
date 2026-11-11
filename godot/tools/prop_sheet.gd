extends Node3D
## Tripo nesne kontrol sayfası: tümünü hedef boyutta, önü +Z'ye bakar halde dizer.
## godot --path . --resolution 1600x900 res://tools/prop_sheet.tscn -> /tmp/props_sheet.png

const Props := preload("res://scenes/props_lib.gd")


func _ready() -> void:
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color("6d7480")
	env.environment.ambient_light_color = Color("c8ccd4")
	env.environment.ambient_light_energy = 0.7
	add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-40, 30, 0)
	sun.shadow_enabled = true
	add_child(sun)
	var floor := MeshInstance3D.new()
	floor.mesh = PlaneMesh.new()
	floor.mesh.size = Vector2(80, 40)
	add_child(floor)
	var small := ["B3", "B6", "N1", "N3", "Q2", "Q1", "B1", "B2", "C1"]
	var big := ["M1", "M2", "S3", "M4", "M3", "S4", "S1", "S5", "S6"]
	var x := -9.0
	for id in small:
		_put(id, Vector3(x, 0, 2.0), 0.9)
		x += 2.2
	x = -16.0
	for id in big:
		_put(id, Vector3(x, 0, -6.0), 2.0)
		x += 4.6 if id in ["S4", "S5", "S6", "M3"] else 3.4
	var cam := Camera3D.new()
	cam.fov = 50
	add_child(cam)
	cam.position = Vector3(1.5, 7.0, 15.0)
	cam.look_at(Vector3(1.5, 1.0, -2.0))
	for i in 8:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("/tmp/props_sheet.png")
	get_tree().quit()


func _put(id: String, at: Vector3, label_h: float) -> void:
	var node := Props.make(id)
	node.position = at
	add_child(node)
	var tag := Label3D.new()
	tag.text = id
	tag.font_size = 96
	tag.pixel_size = 0.004
	tag.position = at + Vector3(0, -0.0, 1.2)
	tag.rotation_degrees.x = -60
	tag.modulate = Color.YELLOW
	add_child(tag)
