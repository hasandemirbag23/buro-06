extends RefCounted

static func material(color: Color, rough := 0.78, emission := 0.0) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = rough
	if emission > 0.0:
		mat.emission_enabled = true
		mat.emission = color
		mat.emission_energy_multiplier = emission
	return mat


static func paint(mesh_instance: MeshInstance3D, color: Color, rough := 0.78, emission := 0.0) -> void:
	mesh_instance.material_override = material(color, rough, emission)


static func box(parent: Node3D, size: Vector3, pos: Vector3, color: Color, rough := 0.78, emission := 0.0) -> MeshInstance3D:
	var mesh_instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh_instance.mesh = mesh
	mesh_instance.position = pos
	paint(mesh_instance, color, rough, emission)
	parent.add_child(mesh_instance)
	return mesh_instance


static func cylinder(parent: Node3D, radius: float, height: float, pos: Vector3, color: Color, emission := 0.0) -> MeshInstance3D:
	var mesh_instance := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh_instance.mesh = mesh
	mesh_instance.position = pos
	paint(mesh_instance, color, 0.6, emission)
	parent.add_child(mesh_instance)
	return mesh_instance


static func sphere(parent: Node3D, radius: float, pos: Vector3, color: Color, emission := 0.0) -> MeshInstance3D:
	var mesh_instance := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh_instance.mesh = mesh
	mesh_instance.position = pos
	paint(mesh_instance, color, 0.45, emission)
	parent.add_child(mesh_instance)
	return mesh_instance


static func block(parent: Node3D, size: Vector3, pos: Vector3, color: Color, rough := 0.86) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.position = pos
	var shape := CollisionShape3D.new()
	var box_shape := BoxShape3D.new()
	box_shape.size = size
	shape.shape = box_shape
	body.add_child(shape)
	var mesh_instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh_instance.mesh = mesh
	paint(mesh_instance, color, rough)
	body.add_child(mesh_instance)
	parent.add_child(body)
	return body


static func zone(parent: Node3D, size: Vector3, pos: Vector3, color: Color, action: String, rough := 0.8) -> Area3D:
	var area := Area3D.new()
	area.position = pos
	area.set_meta("action", action)
	area.collision_layer = 2
	area.collision_mask = 0
	area.monitoring = false
	area.monitorable = true
	area.input_ray_pickable = true
	var shape := CollisionShape3D.new()
	var box_shape := BoxShape3D.new()
	box_shape.size = size
	shape.shape = box_shape
	area.add_child(shape)
	var mesh_instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh_instance.mesh = mesh
	paint(mesh_instance, color, rough)
	area.add_child(mesh_instance)
	parent.add_child(area)
	return area


static func solid(parent: Node3D, size: Vector3, pos: Vector3, color: Color, action: String) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.position = pos
	body.set_meta("action", action)
	var shape := CollisionShape3D.new()
	var box_shape := BoxShape3D.new()
	box_shape.size = size
	shape.shape = box_shape
	body.add_child(shape)
	var mesh_instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh_instance.mesh = mesh
	paint(mesh_instance, color)
	body.add_child(mesh_instance)
	parent.add_child(body)
	return body


static func label(parent: Node3D, text: String, pos: Vector3, color: Color, size := 0.12) -> Label3D:
	var tag := Label3D.new()
	tag.text = text
	tag.position = pos
	tag.pixel_size = 0.004
	tag.font_size = 48
	tag.modulate = color
	tag.outline_modulate = Color(0, 0, 0, 0.85)
	tag.outline_size = 8
	tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	tag.scale = Vector3.ONE * size
	parent.add_child(tag)
	return tag


## Poly Haven PBR seti: res://assets/textures/<id>_{Diffuse,nor_gl,Rough}.jpg
static func pbr(texture_id: String, tint := Color.WHITE, tiling := Vector2.ONE, rough_scale := 1.0) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	var base := "res://assets/textures/%s_" % texture_id
	mat.albedo_color = tint
	mat.albedo_texture = load(base + "Diffuse.jpg")
	if ResourceLoader.exists(base + "nor_gl.jpg"):
		mat.normal_enabled = true
		mat.normal_texture = load(base + "nor_gl.jpg")
		mat.normal_scale = 0.8
	if ResourceLoader.exists(base + "Rough.jpg"):
		mat.roughness_texture = load(base + "Rough.jpg")
	mat.roughness = rough_scale
	mat.uv1_scale = Vector3(tiling.x, tiling.y, 1.0)
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	return mat


static func textured_box(parent: Node3D, size: Vector3, pos: Vector3, mat: Material) -> MeshInstance3D:
	var mesh_instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh_instance.mesh = mesh
	mesh_instance.position = pos
	mesh_instance.material_override = mat
	parent.add_child(mesh_instance)
	return mesh_instance


## GLB sahnesini yerleştir (ölçek, dönüş); gölge açık.
static func place(parent: Node3D, scene: PackedScene, pos: Vector3, yaw_deg := 0.0, scale := 1.0) -> Node3D:
	var node := scene.instantiate() as Node3D
	node.position = pos
	node.rotation_degrees.y = yaw_deg
	node.scale = Vector3.ONE * scale
	parent.add_child(node)
	return node


static func environment(bg: Color, ambient: Color, fog_density: float, ambient_energy := 0.55, glow := false) -> WorldEnvironment:
	var world := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = bg
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = ambient
	env.ambient_light_energy = ambient_energy
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.fog_enabled = true
	env.fog_light_color = bg
	env.fog_density = fog_density
	if glow:
		env.glow_enabled = true
		env.glow_intensity = 0.28
		env.glow_bloom = 0.04
		env.glow_hdr_threshold = 1.15
	world.environment = env
	return world
