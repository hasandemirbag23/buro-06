extends Node3D

## Sinematik ana menü sahnesi: yağmurlu Ankara gecesi, yaşanmış Cinayet Büro.
## Ayrı bir 3D sahne; oyun dünyasından bağımsız (main.gd menü açıkken gösterir).
## Mevcut GLB varlıkları: masa, sandalye, lamba, telsiz, ekran, klavye, telefon, kitap, askılık, raf, pencere.
## Prosedürel (düşük detay, ileride GLB ile değiştirilmeli): saat, küllük, çay bardağı, fotoğraflar, harita, dosyalar.

const MeshFactory := preload("res://scenes/mesh_factory.gd")

const DESK := preload("res://assets/furniture/desk.glb")
const CHAIR := preload("res://assets/furniture/chairDesk.glb")
const SCREEN := preload("res://assets/furniture/computerScreen.glb")
const KEYS := preload("res://assets/furniture/computerKeyboard.glb")
const LAMP := preload("res://assets/furniture/lampSquareTable.glb")
const RADIO := preload("res://assets/furniture/radio.glb")
const PHONE := preload("res://assets/props/Phone.glb")
const BOOKS := preload("res://assets/furniture/books.glb")
const RACK := preload("res://assets/furniture/coatRackStanding.glb")
const SHELF := preload("res://assets/interior/Bookshelf.glb")
const WINDOW_MODEL := preload("res://assets/interior/Window_Large1.glb")
const CURTAIN := preload("res://assets/interior/Curtains_Double.glb")
const CEIL := preload("res://assets/interior/Light_Ceiling1.glb")
const CARPET := preload("res://assets/interior/Carpet_1.glb")
const BOX := preload("res://assets/furniture/cardboardBoxClosed.glb")
const BIN := preload("res://assets/furniture/trashcan.glb")
const STREET := preload("res://assets/props/Streetlight_Single.glb")
const SetBase := preload("res://scenes/sets/set_base.gd")

const FEET := 0.17
## Pencereden görünen Ankara maketi: 1:10 ölçek, zorlanmış perspektif (kamera far = 80).
const CITY_SCALE := 0.1
const WALL_Z := -3.2
const WOOD := Color("4a3224")
const AMBER := Color("ffb24d")
const COLD := Color("6f90c8")

const GLASS_SHADER := """
shader_type spatial;
render_mode unshaded, depth_draw_never, blend_mix;
uniform float speed = 0.45;
uniform float amount = 1.0;

float hash(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

// BigWings tarzı damla katmanı: x = damla maskesi, y = iz
vec2 drops(vec2 uv, float t, float scale) {
	vec2 UVo = uv;
	uv *= scale;
	uv.y += t * 0.75;
	vec2 grid = vec2(6.0, 1.0) * 2.0;
	vec2 id = floor(uv * grid);
	float shift = hash(vec2(id.x, 3.1));
	uv.y += shift;
	id = floor(uv * grid);
	float n = hash(id + 7.7);
	vec2 st = fract(uv * grid) - vec2(0.5, 0.0);
	float x = n - 0.5;
	float yy = UVo.y * 20.0;
	float wiggle = sin(yy + sin(yy));
	x += wiggle * (0.5 - abs(x)) * (n - 0.5);
	x *= 0.7;
	float ti = fract(t * 0.5 + n);
	float y = (smoothstep(0.0, 0.85, ti) * smoothstep(1.0, 0.85, ti) - 0.5) * 0.9 + 0.5;
	vec2 p = vec2(x, y);
	float d = length((st - p) * vec2(1.0, 6.0) * 0.5);
	float main_drop = smoothstep(0.4, 0.0, d);
	float r = sqrt(smoothstep(1.0, y, st.y));
	float cd = abs(st.x - x);
	float trail = smoothstep(0.23 * r, 0.15 * r * r, cd);
	float front = smoothstep(-0.02, 0.02, st.y - y);
	trail *= front * r * r;
	float yb = fract(UVo.y * 10.0 * scale * 0.1) + (st.y - 0.5);
	float dd = length(st - vec2(x, yb));
	float small = smoothstep(0.3, 0.0, dd) * r * front;
	return vec2(main_drop + small, trail);
}

void fragment() {
	vec2 uv = UV;
	float t = TIME * speed;
	vec2 a = drops(uv, t, 1.0);
	vec2 b = drops(uv * 1.35 + 7.0, t * 1.1, 1.0);
	float m = clamp(a.x + b.x, 0.0, 1.0);
	float trails = clamp(a.y + b.y, 0.0, 1.0);
	float wet = clamp(m * 1.1 + trails * 0.7, 0.0, 1.0);
	ALBEDO = vec3(0.55, 0.68, 0.85);
	ALPHA = (0.08 + wet * 0.22) * amount;
}
"""

const GRAIN_SHADER := """
shader_type canvas_item;
uniform float strength = 0.05;
float hash(vec2 p) { return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453); }
void fragment() {
	vec2 uv = UV;
	float v = smoothstep(0.35, 1.05, distance(uv, vec2(0.5)) * 1.25);
	float g = hash(floor(uv * vec2(900.0, 520.0)) + floor(TIME * 24.0));
	COLOR = vec4(0.0, 0.0, 0.0, clamp(v * 0.5 + max(g - 0.5, 0.0) * strength * 1.4, 0.0, 1.0));
}
"""

var camera: Camera3D
var env: Environment
var tubes: Array[OmniLight3D] = []
var desk_lamp: SpotLight3D
var lamp_glow: OmniLight3D
var flash: DirectionalLight3D
var second_hand: Node3D
var minute_hand: Node3D
var hour_hand: Node3D
var radio_led: MeshInstance3D
var rain: GPUParticles3D
var _t := 0.0
var _flash_in := 14.0
var _flash_t := -1.0
var _intro := 0.0
var _sec_last := -1
var _rng := RandomNumberGenerator.new()
var drift := true

const CAM_WIDE := Vector3(-0.35, 1.85, 5.1)
const CAM_BASE := Vector3(0.35, 1.42, 3.15)
const CAM_LOOK := Vector3(0.85, 1.05, -1.85)
const FOV_WIDE := 44.0
const FOV_SETTLE := 34.0


func _ready() -> void:
	_rng.seed = 606
	_environment()
	_room()
	_window()
	_wall_clock()
	_map()
	_board()
	_furniture()
	_desk_still_life()
	_computer_corner()
	_lights()
	_dust()
	_overlay()
	camera = Camera3D.new()
	camera.fov = FOV_WIDE
	camera.near = 0.05
	camera.far = 80.0
	camera.attributes = null
	add_child(camera)
	camera.position = CAM_WIDE
	camera.look_at(CAM_LOOK)
	camera.make_current()


func _lens() -> CameraAttributesPractical:
	var lens := CameraAttributesPractical.new()
	lens.dof_blur_far_enabled = true
	lens.dof_blur_far_distance = 6.5
	lens.dof_blur_far_transition = 5.0
	lens.dof_blur_near_enabled = true
	lens.dof_blur_near_distance = 1.4
	lens.dof_blur_near_transition = 1.2
	lens.dof_blur_amount = 0.06
	return lens


# ------------------------------------------------------------------ ortam
func _environment() -> void:
	env = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("07090d")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("2c3444")
	env.ambient_light_energy = 1.05
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.tonemap_exposure = 1.05
	env.ssao_enabled = false
	env.glow_enabled = true
	env.glow_intensity = 0.22
	env.glow_bloom = 0.04
	env.glow_hdr_threshold = 1.15
	env.fog_enabled = true
	env.fog_light_color = Color("0b0f16")
	env.fog_density = 0.006
	env.volumetric_fog_enabled = false
	env.adjustment_enabled = true
	env.adjustment_contrast = 1.1
	env.adjustment_saturation = 0.92
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)


func _room() -> void:
	var floor_node := MeshFactory.textured_box(self, Vector3(9.4, 0.16, 8.4), Vector3(0, 0.08, 0.2), MeshFactory.pbr("wood_floor_worn", Color("a8845f"), Vector2(5, 4), 0.95))
	floor_node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_drop(CARPET, Vector3(0.9, FEET, -0.6), 0.0, 2.0)
	var plaster := MeshFactory.pbr("plastered_wall_02", Color("8f8576"), Vector2(3, 1.5), 1.0)
	var paint_low := MeshFactory.pbr("concrete_wall_006", Color("3d4a3c"), Vector2(3, 0.6), 1.0)
	# arka duvar: pencere boşluğu bırakılmış
	MeshFactory.textured_box(self, Vector3(1.9, 3.0, 0.2), Vector3(-4.35, 1.5, WALL_Z), plaster)
	MeshFactory.textured_box(self, Vector3(6.0, 3.0, 0.2), Vector3(2.0, 1.5, WALL_Z), plaster)
	MeshFactory.textured_box(self, Vector3(2.0, 1.0, 0.2), Vector3(-1.55, 0.5, WALL_Z), plaster)
	MeshFactory.textured_box(self, Vector3(2.0, 0.55, 0.2), Vector3(-1.55, 2.72, WALL_Z), plaster)
	MeshFactory.textured_box(self, Vector3(0.2, 3.0, 8.4), Vector3(-4.7, 1.5, 0.2), plaster)
	MeshFactory.textured_box(self, Vector3(0.2, 3.0, 8.4), Vector3(4.9, 1.5, 0.2), plaster)
	MeshFactory.textured_box(self, Vector3(9.8, 0.2, 8.4), Vector3(0, 3.0, 0.2), MeshFactory.pbr("concrete_wall_006", Color("403a33"), Vector2(3, 3), 1.0))
	# lambri: koyu yeşil boyalı alt duvar + ahşap çıta
	MeshFactory.textured_box(self, Vector3(9.4, 1.1, 0.04), Vector3(0, 0.62, WALL_Z + 0.12), paint_low)
	MeshFactory.box(self, Vector3(9.4, 0.06, 0.07), Vector3(0, 1.18, WALL_Z + 0.12), WOOD, 0.6)
	MeshFactory.box(self, Vector3(9.4, 0.14, 0.07), Vector3(0, 0.24, WALL_Z + 0.12), WOOD, 0.6)
	MeshFactory.textured_box(self, Vector3(0.04, 1.1, 8.0), Vector3(-4.58, 0.62, 0.2), paint_low)
	MeshFactory.box(self, Vector3(0.07, 0.06, 8.0), Vector3(-4.58, 1.18, 0.2), WOOD, 0.6)
	# su lekesi ve kirli tavan
	MeshFactory.box(self, Vector3(1.4, 0.01, 0.9), Vector3(2.8, 2.89, -2.2), Color("1b1814"), 1.0)


func _window() -> void:
	var cx := -1.55
	var cy := 1.95
	# pencerenin dışı: iki katman şehir + sokak lambası
	var backdrop := MeshFactory.box(self, Vector3(90, 34, 0.2), Vector3(cx, 9.0, WALL_Z - 67.0), Color("070b12"), 1.0)
	backdrop.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_city(cx)
	# sokak lambası: amber hale
	_cast_off(_drop(STREET, Vector3(cx + 1.15, -0.8, WALL_Z - 3.6), 12.0, 2.4))
	var street := OmniLight3D.new()
	street.position = Vector3(cx + 1.3, 1.6, WALL_Z - 3.0)
	street.light_color = Color("ffb257")
	street.light_energy = 2.4
	street.omni_range = 9.0
	street.shadow_enabled = false
	add_child(street)
	MeshFactory.sphere(self, 0.1, street.position + Vector3(0, 0.4, 0), Color("ffc27a"), 4.0)
	# pencere modeli, perde, camdaki yağmur
	var win_node := _drop(WINDOW_MODEL, Vector3(cx, 0.92, WALL_Z + 0.06), 0.0, 1.45)
	var clear := StandardMaterial3D.new()
	clear.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	clear.albedo_color = Color(0.5, 0.65, 0.85, 0.06)
	clear.roughness = 0.05
	_retint(win_node, {"White": MeshFactory.material(Color("2c2118"), 0.7), "Glass": clear})
	var curtain := _drop(CURTAIN, Vector3(cx, 0.9, WALL_Z + 0.34), 0.0, 0.66, Vector3(0.04, 0.0, -0.12))
	curtain.scale = Vector3(0.62, 0.66, 0.66)
	var glass := MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = Vector2(1.95, 1.7)
	glass.mesh = quad
	glass.position = Vector3(cx, cy, WALL_Z + 0.02)
	var shader := Shader.new()
	shader.code = GLASS_SHADER
	var mat := ShaderMaterial.new()
	mat.shader = shader
	glass.material_override = mat
	glass.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(glass)
	# dış yağmur çizgileri
	rain = GPUParticles3D.new()
	rain.position = Vector3(cx, 7.0, WALL_Z - 3.0)
	rain.amount = 160
	rain.lifetime = 1.0
	rain.visibility_aabb = AABB(Vector3(-8, -9, -6), Vector3(16, 12, 12))
	var pm := ParticleProcessMaterial.new()
	pm.direction = Vector3(0.2, -1, 0)
	pm.spread = 3.0
	pm.initial_velocity_min = 11.0
	pm.initial_velocity_max = 14.0
	pm.gravity = Vector3(0, -8, 0)
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.emission_box_extents = Vector3(6.0, 0.2, 2.5)
	rain.process_material = pm
	var drop := QuadMesh.new()
	drop.size = Vector2(0.012, 0.34)
	var drop_mat := StandardMaterial3D.new()
	drop_mat.albedo_color = Color(0.7, 0.8, 1.0, 0.35)
	drop_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	drop_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	drop_mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	drop.material = drop_mat
	rain.draw_pass_1 = drop
	add_child(rain)
	# soğuk dış ışık: pencereden içeri giren hacimsel huzme
	var beam := SpotLight3D.new()
	beam.position = Vector3(cx + 0.4, 2.6, WALL_Z - 4.0)
	beam.light_color = COLD
	beam.light_energy = 4.0
	beam.spot_range = 12.0
	beam.spot_angle = 24.0
	beam.shadow_enabled = false
	add_child(beam)
	beam.look_at(Vector3(cx + 0.8, 0.4, 0.0))
	# şimşek: nadir, kısa
	flash = DirectionalLight3D.new()
	flash.light_color = Color("cfe0ff")
	flash.light_energy = 0.0
	flash.rotation_degrees = Vector3(-35, 160, 0)
	flash.shadow_enabled = false
	add_child(flash)


func _wall_clock() -> void:
	var at := Vector3(0.45, 2.55, WALL_Z + 0.12)
	var face := MeshFactory.cylinder(self, 0.24, 0.04, at, Color("d9ceb4"))
	face.rotation_degrees.x = 90
	var rim := MeshFactory.cylinder(self, 0.265, 0.03, at + Vector3(0, 0, -0.012), Color("1b1a18"))
	rim.rotation_degrees.x = 90
	for h in 12:
		var a := deg_to_rad(h * 30.0)
		var tick := MeshFactory.box(self, Vector3(0.012, 0.045 if h % 3 == 0 else 0.025, 0.01), at + Vector3(sin(a) * 0.2, cos(a) * 0.2, 0.026), Color("1b1a18"))
		tick.rotation.z = -a
	hour_hand = _hand(at, 0.12, 0.014, Color("15130f"))
	minute_hand = _hand(at, 0.18, 0.01, Color("15130f"))
	second_hand = _hand(at, 0.2, 0.004, Color("8a1f1a"))
	var dial := MeshFactory.sphere(self, 0.014, at + Vector3(0, 0, 0.04), Color("15130f"))
	dial.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	hour_hand.rotation.z = -deg_to_rad(3 * 30.0 + 17 * 0.5)
	minute_hand.rotation.z = -deg_to_rad(17 * 6.0)


func _hand(at: Vector3, length: float, width: float, color: Color) -> Node3D:
	var pivot := Node3D.new()
	pivot.position = at + Vector3(0, 0, 0.032)
	add_child(pivot)
	MeshFactory.box(pivot, Vector3(width, length, 0.006), Vector3(0, length * 0.5 - 0.02, 0), color, 0.5)
	return pivot


func _map() -> void:
	var at := Vector3(-3.55, 1.85, WALL_Z + 0.12)
	MeshFactory.box(self, Vector3(1.25, 1.55, 0.04), at + Vector3(0, 0, -0.01), Color("1c1510"), 0.8)
	var quad := MeshInstance3D.new()
	var mesh := QuadMesh.new()
	mesh.size = Vector2(1.15, 1.45)
	quad.mesh = mesh
	quad.position = at + Vector3(0, 0, 0.015)
	quad.material_override = _tex_material(_map_texture(), 0.85)
	add_child(quad)
	MeshFactory.label(self, "ANKARA", at + Vector3(0, 0.62, 0.05), Color("2a2118"), 0.55)
	for p in [Vector3(-0.12, 0.05, 0.03), Vector3(0.2, -0.18, 0.03), Vector3(-0.28, -0.3, 0.03)]:
		MeshFactory.sphere(self, 0.018, at + p, Color("b42323"))


func _board() -> void:
	var at := Vector3(2.55, 1.75, WALL_Z + 0.13)
	MeshFactory.box(self, Vector3(2.5, 1.65, 0.05), at, WOOD, 0.6)
	var cork := MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = Vector2(2.34, 1.5)
	cork.mesh = quad
	cork.position = at + Vector3(0, 0, 0.03)
	cork.material_override = _tex_material(_cork_texture(), 0.95)
	add_child(cork)
	var pins: Array[Vector3] = []
	var spots := [Vector2(-0.8, 0.4), Vector2(-0.25, 0.5), Vector2(0.35, 0.38), Vector2(0.85, 0.5), Vector2(-0.55, -0.2), Vector2(0.1, -0.15), Vector2(0.7, -0.3), Vector2(-0.95, -0.5)]
	for i in spots.size():
		var s: Vector2 = spots[i]
		var photo := _photo(i)
		photo.position = at + Vector3(s.x, s.y, 0.045)
		photo.rotation.z = deg_to_rad(_rng.randf_range(-9, 9))
		pins.append(photo.position + Vector3(0, 0.07, 0.012))
		MeshFactory.sphere(self, 0.014, photo.position + Vector3(0, 0.07, 0.014), Color("b42323"))
	# kırmızı iplikler
	for pair in [[0, 1], [1, 2], [2, 3], [0, 4], [4, 5], [5, 2], [5, 6], [3, 6], [4, 7]]:
		_cord(pins[pair[0]], pins[pair[1]])
	# notlar
	for n in 3:
		var note := MeshFactory.box(self, Vector3(0.16, 0.12, 0.004), at + Vector3(-0.2 + n * 0.55, -0.55, 0.045), Color("e8d98a"), 0.9)
		note.rotation.z = deg_to_rad(_rng.randf_range(-12, 12))
	MeshFactory.label(self, "DOSYA NO 06", at + Vector3(0, 0.95, 0.06), Color("e7dfcf"), 0.4)


func _photo(seed_value: int) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = Vector2(0.24, 0.18)
	node.mesh = quad
	node.material_override = _tex_material(_photo_texture(seed_value), 0.55)
	add_child(node)
	var border := MeshFactory.box(node, Vector3(0.26, 0.2, 0.002), Vector3(0, 0, -0.002), Color("e9e4d8"), 0.8)
	border.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return node


func _cord(a: Vector3, b: Vector3) -> void:
	var rope := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.006, 0.006, a.distance_to(b))
	rope.mesh = mesh
	rope.position = (a + b) * 0.5 + Vector3(0, -0.01, 0.012)
	add_child(rope)
	rope.look_at(b + Vector3(0, -0.01, 0.012), Vector3.UP)
	MeshFactory.paint(rope, Color("a31f1f"), 0.5)


# ------------------------------------------------------------------ mobilya
func _furniture() -> void:
	for i in 2:
		_drop(SHELF, Vector3(-4.42, FEET, -1.9 + i * 1.7), 90.0, 0.52)
	_drop(RACK, Vector3(4.3, FEET, -2.6), 20.0, 2.15)
	_drop(BOX, Vector3(4.35, FEET, 0.4), 8.0, 2.1, Vector3(0.1, 0.0, -0.1))
	_drop(BOX, Vector3(4.4, FEET + 0.58, 0.45), -6.0, 1.7, Vector3(0.1, 0.0, -0.1))
	_drop(BIN, Vector3(3.5, FEET, -2.7), 10.0, 2.0)
	# ana masa (kahraman masa): sağ-merkez
	_retint(_drop(DESK, Vector3(1.15, FEET, -1.75), 0.0, 2.35, Vector3(0.355, 0.0, -0.185)), {"*": _desk_wood()})
	_drop(CHAIR, Vector3(2.35, FEET, -1.2), 128.0, 1.9, Vector3(0.165, 0.0, -0.155))
	# soldaki ikinci masa (bilgisayar köşesi)
	_retint(_drop(DESK, Vector3(-1.5, FEET, -1.9), 0.0, 2.1, Vector3(0.355, 0.0, -0.185)), {"*": _desk_wood()})
	_drop(CHAIR, Vector3(-2.65, FEET, -1.3), 70.0, 1.9, Vector3(0.165, 0.0, -0.155))
	# ön plan: bulanık sandalye sırtlığı
	_drop(CHAIR, Vector3(2.9, FEET, 1.7), 215.0, 1.9, Vector3(0.165, 0.0, -0.155))


## Ana menü silüeti (ANKARA_WORLD_DESIGN.md): ön planda Cebeci apartman sırası,
## arkada Kızılay iş merkezi kütleleri, en arkada özgün bir seyir kulesi.
## Apartmanlar set_base.apartment() ile (FACADES + Tripo M1–M4 modülleri, yeni kredi yok).
## Maket 1:10; yerel ölçüler gerçek metre. Tabanlar pencere pervazının altında kalır.
func _city(cx: float) -> void:
	var city := SetBase.new()
	city.name = "AnkaraSiluet"
	city.position = Vector3(cx, -0.15, WALL_Z - 2.0)
	city.scale = Vector3.ONE * CITY_SCALE
	add_child(city)
	# 1) Cebeci: 4–6 katlı A tipi apartmanlar, bitişik nizam, hafif kırık sıra
	var x := -170.0
	var i := 0
	while x < 170.0:
		var w := 10.0 + float((i * 7) % 4)
		var floors := 4 + (i * 5) % 3
		var kind := "B" if i % 4 == 2 else "A"
		city.apartment(Vector3(x + w * 0.5, 0, -77.0 - float(i % 3) * 2.5), w - 0.3, 12.0, floors, kind, float((i % 3) - 1) * 1.5, 31 + i * 17)
		x += w
		i += 1
	# 2) Kızılay: iş merkezi kütleleri (C tipi bant pencereli bloklar + cam/beton levha bloklar)
	var blocks := [
		[-150.0, -205.0, 24.0, 12, 0], [-105.0, -215.0, 18.0, 15, 1], [-62.0, -200.0, 28.0, 11, 0],
		[-20.0, -225.0, 20.0, 18, 1], [24.0, -205.0, 26.0, 13, 0], [70.0, -218.0, 18.0, 16, 1],
		[112.0, -200.0, 30.0, 10, 0], [158.0, -212.0, 22.0, 14, 1],
	]
	for k in blocks.size():
		var bl: Array = blocks[k]
		if int(bl[4]) == 0:
			city.apartment(Vector3(bl[0], 0, bl[1]), bl[2], 16.0, int(bl[3]), "C", 0.0, 7 + k * 11)
		else:
			_office_slab(city, Vector3(bl[0], 0, bl[1]), Vector3(bl[2], int(bl[3]) * 3.4 + 4.0, 15.0), k)
	# 3) özgün seyir kulesi (Atakule'nin birebir kopyası değil)
	_tower(city, Vector3(60.0, 0, -600.0))
	_cast_off(city)


## Kızılay tipi iş merkezi levhası: koyu cam cephe, kat kat ışık bantları, çatıda makine katı.
func _office_slab(parent: Node3D, feet: Vector3, size: Vector3, seed: int) -> void:
	var glass := Color("1c2633") if seed % 2 == 0 else Color("2a2f36")
	MeshFactory.box(parent, size, feet + Vector3(0, size.y * 0.5, 0), glass, 0.25)
	var floors := int((size.y - 4.0) / 3.4)
	for f in floors:
		var lit := (f * 3 + seed) % 4 != 0
		var tint := Color("f2d39a") if (f + seed) % 3 != 0 else Color("cfe3ff")
		var y := 4.0 + f * 3.4 + 1.5
		MeshFactory.box(parent, Vector3(size.x * 0.92, 0.9, 0.05), feet + Vector3(0, y, size.z * 0.5 + 0.03), tint if lit else Color("10161e"), 0.4, 0.7 if lit else 0.0)
		MeshFactory.box(parent, Vector3(size.x + 0.2, 0.35, size.z + 0.2), feet + Vector3(0, y - 1.5, 0), Color("6d7278"), 0.8)
	MeshFactory.box(parent, Vector3(size.x * 0.5, 3.0, size.z * 0.6), feet + Vector3(0, size.y + 1.5, 0), Color("3a3f46"), 0.8)
	if seed % 2 == 1:
		var sign := MeshFactory.label(parent, "İŞ MERKEZİ", feet + Vector3(0, size.y - 1.4, size.z * 0.5 + 0.2), Color("ffb24d"), 12.0)
		sign.billboard = BaseMaterial3D.BILLBOARD_DISABLED


## Seyir kulesi: sekizgen gövde, ters koni seyir başlığı, ışıklı lokanta bandı, anten.
func _tower(parent: Node3D, base: Vector3) -> void:
	# Gövde aşağıdan projektörle aydınlatılmış gibi hafif ışır; gece göğünde silüet okunur.
	var concrete := Color("c9c2b6")
	_cyl(parent, 18.0, 22.0, 10.0, base + Vector3(0, 5.0, 0), Color("8f8a82"), 0.15, 8)
	_cyl(parent, 4.0, 6.2, 122.0, base + Vector3(0, 71.0, 0), concrete, 0.22, 8)
	for f in 4:
		var ang := f * PI * 0.5 + PI * 0.25
		var fin := MeshFactory.box(parent, Vector3(1.2, 100.0, 3.2), base + Vector3(cos(ang) * 5.4, 60.0, sin(ang) * 5.4), Color("b3ad a2".replace(" ", "")), 0.8, 0.12)
		fin.rotation.y = -ang
	_cyl(parent, 13.5, 5.0, 9.0, base + Vector3(0, 136.5, 0), concrete, 0.3, 16)
	_cyl(parent, 13.8, 13.8, 3.6, base + Vector3(0, 142.8, 0), Color("ffcf8a"), 2.2, 24)
	_cyl(parent, 9.5, 13.8, 4.4, base + Vector3(0, 146.8, 0), Color("5a6270"), 0.15, 24)
	_cyl(parent, 0.5, 0.9, 24.0, base + Vector3(0, 161.0, 0), Color("c8ccd2"), 0.3, 8)
	MeshFactory.sphere(parent, 1.6, base + Vector3(0, 174.0, 0), Color("ff2a1a"), 3.2)
	for k in 8:
		MeshFactory.sphere(parent, 0.8, base + Vector3(0, 18.0 + k * 14.0, 6.3), Color("ff3b2a"), 1.6)


func _cyl(parent: Node3D, top_r: float, bottom_r: float, height: float, pos: Vector3, color: Color, emission := 0.0, sides := 16) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = top_r
	mesh.bottom_radius = bottom_r
	mesh.height = height
	mesh.radial_segments = sides
	mi.mesh = mesh
	mi.position = pos
	mi.material_override = MeshFactory.material(color, 0.8, emission)
	parent.add_child(mi)
	return mi


func _cast_off(node: Node) -> void:
	if node is GeometryInstance3D:
		node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for child in node.get_children():
		_cast_off(child)


func _telephone(at: Vector3) -> void:
	_drop(PHONE, at, 160.0, 0.38)


func _desk_still_life() -> void:
	var top := 1.08
	var base := Vector3(1.15, top, -1.75)
	# lamba
	_drop(LAMP, base + Vector3(0.62, 0.0, -0.18), 35.0, 1.5, Vector3(0.06, 0.0, -0.06))
	# telsiz (retro radyo) ve el telsizi
	var radio := _drop(RADIO, base + Vector3(-0.6, 0.0, -0.2), -8.0, 1.5, Vector3(0.1, 0.0, -0.05))
	radio_led = MeshFactory.sphere(self, 0.008, radio.global_position + Vector3(0.1, 0.18, 0.12), Color("ff2a1a"), 3.0)
	var walkie := MeshFactory.box(self, Vector3(0.06, 0.16, 0.035), base + Vector3(-0.3, 0.02, 0.05), Color("15171a"), 0.5)
	walkie.rotation_degrees = Vector3(90, 0, -25)
	var antenna := MeshFactory.cylinder(walkie, 0.004, 0.09, Vector3(0.015, 0.12, 0), Color("0c0d0e"))
	antenna.rotation_degrees.x = 0
	MeshFactory.box(walkie, Vector3(0.04, 0.04, 0.004), Vector3(0, 0.02, 0.02), Color("3a4a3a"), 0.6, 0.4)
	_telephone(base + Vector3(0.2, 0.0, -0.3))
	# açık soruşturma dosyası
	var folder_base := base + Vector3(-0.05, 0.0, 0.08)
	var cover := MeshFactory.box(self, Vector3(0.44, 0.012, 0.31), folder_base + Vector3(-0.1, 0.006, 0.0), Color("b6945a"), 0.85)
	cover.rotation_degrees.y = -8
	var cover2 := MeshFactory.box(self, Vector3(0.44, 0.012, 0.31), folder_base + Vector3(0.25, 0.006, 0.02), Color("a8854e"), 0.85)
	cover2.rotation_degrees.y = -3
	for i in 4:
		var sheet := _sheet(i)
		sheet.position = folder_base + Vector3(-0.05 + i * 0.07, 0.014 + i * 0.002, 0.02 * i - 0.03)
		sheet.rotation_degrees.y = _rng.randf_range(-15, 15)
	MeshFactory.label(self, "DOSYA NO 06", folder_base + Vector3(-0.1, 0.05, 0.19), Color("5a2a22"), 0.2).rotation_degrees.x = -75
	# fotoğraflar masada
	for i in 4:
		var photo := _photo(20 + i)
		photo.rotation_degrees = Vector3(-90, 0, _rng.randf_range(-30, 30))
		photo.position = base + Vector3(0.2 + i * 0.13, 0.016 + i * 0.001, 0.1 + _rng.randf_range(-0.06, 0.06))
		photo.scale = Vector3.ONE * 0.8
	# dağınık evraklar
	for i in 8:
		var sheet := _sheet(30 + i)
		sheet.position = base + Vector3(_rng.randf_range(-0.7, 0.8), 0.003 * i + 0.003, _rng.randf_range(-0.2, 0.28))
		sheet.rotation_degrees.y = _rng.randf_range(-40, 40)
	# çay bardağı (ince belli) + tabak + kaşık
	_tea_glass(base + Vector3(0.45, 0.0, 0.18))
	# küllük, izmarit, yanık sigara
	_ashtray(base + Vector3(-0.42, 0.0, 0.2))
	# kitap yığını
	_drop(BOOKS, base + Vector3(0.9, 0.0, 0.05), 18.0, 1.9, Vector3(0.07, 0.0, -0.04))


func _computer_corner() -> void:
	var base := Vector3(-1.5, 1.08, -1.9)
	var crt := _drop(SCREEN, base + Vector3(-0.1, 0.0, -0.1), 180.0, 1.9, Vector3(0.19, 0.0, -0.05))
	for mi in crt.find_children("*", "MeshInstance3D", true, false):
		(mi as MeshInstance3D).material_override = MeshFactory.material(Color("a39b86"), 0.7)
	_drop(KEYS, base + Vector3(-0.1, 0.0, 0.3), 180.0, 1.9, Vector3(0.14, 0.0, -0.06))
	# ekranda yeşil terminal yazısı
	var term := MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = Vector2(0.4, 0.3)
	term.mesh = quad
	term.position = base + Vector3(-0.1, 0.3, 0.075)
	var mat := _tex_material(_terminal_texture(), 0.4)
	mat.emission_enabled = true
	mat.emission_texture = mat.albedo_texture
	mat.emission_energy_multiplier = 1.4
	term.material_override = mat
	term.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(term)
	var glow := OmniLight3D.new()
	glow.position = base + Vector3(-0.1, 0.3, 0.45)
	glow.light_color = Color("9bf5a0")
	glow.light_energy = 0.45
	glow.omni_range = 1.8
	add_child(glow)
	for i in 5:
		var sheet := _sheet(60 + i)
		sheet.position = base + Vector3(0.45 + i * 0.03, 0.003 * i + 0.003, 0.15 - i * 0.04)
		sheet.rotation_degrees.y = _rng.randf_range(-25, 25)


func _sheet(seed_value: int) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = Vector2(0.21, 0.297)
	node.mesh = quad
	node.rotation_degrees.x = -90
	node.material_override = _tex_material(_paper_texture(seed_value), 0.9)
	add_child(node)
	return node


func _tea_glass(at: Vector3) -> void:
	var saucer := MeshFactory.cylinder(self, 0.06, 0.006, at + Vector3(0, 0.003, 0), Color("c9bfa8"))
	saucer.material_override = MeshFactory.material(Color("c9bfa8"), 0.35)
	var glass := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.03
	mesh.bottom_radius = 0.018
	mesh.height = 0.09
	glass.mesh = mesh
	glass.position = at + Vector3(0, 0.051, 0)
	var gm := StandardMaterial3D.new()
	gm.albedo_color = Color(0.85, 0.9, 0.95, 0.18)
	gm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	gm.roughness = 0.05
	gm.metallic_specular = 1.0
	glass.material_override = gm
	glass.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(glass)
	var tea := MeshInstance3D.new()
	var tm := CylinderMesh.new()
	tm.top_radius = 0.026
	tm.bottom_radius = 0.0175
	tm.height = 0.07
	tea.mesh = tm
	tea.position = at + Vector3(0, 0.043, 0)
	var tmat := StandardMaterial3D.new()
	tmat.albedo_color = Color("7a2a0e")
	tmat.roughness = 0.1
	tmat.emission_enabled = true
	tmat.emission = Color("a8400f")
	tmat.emission_energy_multiplier = 0.5
	tea.material_override = tmat
	add_child(tea)
	var spoon := MeshFactory.box(self, Vector3(0.006, 0.002, 0.11), at + Vector3(0.05, 0.009, 0.02), Color("b8b8b4"), 0.25)
	spoon.rotation_degrees.y = 35
	_steam(at + Vector3(0, 0.09, 0), 0.4)


func _ashtray(at: Vector3) -> void:
	var tray := MeshFactory.cylinder(self, 0.075, 0.022, at + Vector3(0, 0.011, 0), Color("22262b"))
	tray.material_override = MeshFactory.material(Color("2a2f35"), 0.2)
	var ash := MeshFactory.cylinder(self, 0.06, 0.004, at + Vector3(0, 0.022, 0), Color("55524d"))
	ash.material_override = MeshFactory.material(Color("6a665f"), 1.0)
	for i in 5:
		var butt := MeshFactory.cylinder(self, 0.0045, 0.03, at + Vector3(_rng.randf_range(-0.035, 0.035), 0.027, _rng.randf_range(-0.035, 0.035)), Color("d9d2c0"))
		butt.rotation_degrees = Vector3(90, _rng.randf_range(0, 180), 0)
		butt.material_override = MeshFactory.material(Color("c9c1ac") if i % 2 == 0 else Color("8a6a3a"), 0.9)
	# yanan sigara kenarda duruyor
	var cig := MeshFactory.cylinder(self, 0.0045, 0.085, at + Vector3(0.02, 0.04, 0.06), Color("e6e0d0"))
	cig.rotation_degrees = Vector3(78, 20, 0)
	var ember := MeshFactory.sphere(self, 0.0055, at + Vector3(0.005, 0.044, 0.1), Color("ff5a1a"), 3.0)
	ember.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_steam(at + Vector3(0.005, 0.05, 0.1), 1.0, true)


func _steam(at: Vector3, strength: float, smoke := false) -> void:
	var p := GPUParticles3D.new()
	p.position = at
	p.amount = 28 if smoke else 14
	p.lifetime = 5.0 if smoke else 2.4
	p.visibility_aabb = AABB(Vector3(-1, -0.2, -1), Vector3(2, 2.5, 2))
	var pm := ParticleProcessMaterial.new()
	pm.direction = Vector3(0.1, 1, 0)
	pm.spread = 12.0
	pm.initial_velocity_min = 0.05
	pm.initial_velocity_max = 0.12 if smoke else 0.08
	pm.gravity = Vector3(0.015, 0.02, 0.0)
	pm.scale_min = 0.5
	pm.scale_max = 1.2
	pm.turbulence_enabled = true
	pm.turbulence_noise_strength = 0.35
	pm.turbulence_noise_scale = 3.0
	var curve := Curve.new()
	curve.add_point(Vector2(0, 0.3))
	curve.add_point(Vector2(1, 1.8))
	var ct := CurveTexture.new()
	ct.curve = curve
	pm.scale_curve = ct
	var fade := Gradient.new()
	fade.set_color(0, Color(1, 1, 1, 0.0))
	fade.add_point(0.25, Color(1, 1, 1, 0.5 * strength))
	fade.set_color(1, Color(1, 1, 1, 0.0))
	var gt := GradientTexture1D.new()
	gt.gradient = fade
	pm.color_ramp = gt
	p.process_material = pm
	var quad := QuadMesh.new()
	quad.size = Vector2(0.09, 0.09)
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = _soft_texture()
	mat.albedo_color = Color(0.85, 0.88, 0.95, 1.0) if smoke else Color(1, 1, 1, 1)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	mat.vertex_color_use_as_albedo = true
	quad.material = mat
	p.draw_pass_1 = quad
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(p)


func _dust() -> void:
	var p := GPUParticles3D.new()
	p.position = Vector3(1.0, 1.6, -1.2)
	p.amount = 28
	p.lifetime = 12.0
	p.preprocess = 12.0
	p.visibility_aabb = AABB(Vector3(-4, -3, -4), Vector3(8, 6, 8))
	var pm := ParticleProcessMaterial.new()
	pm.direction = Vector3(0, 0.2, 0)
	pm.spread = 180.0
	pm.initial_velocity_min = 0.01
	pm.initial_velocity_max = 0.05
	pm.gravity = Vector3.ZERO
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.emission_box_extents = Vector3(2.8, 1.4, 2.0)
	pm.turbulence_enabled = true
	pm.turbulence_noise_strength = 0.12
	pm.turbulence_noise_scale = 2.0
	p.process_material = pm
	var quad := QuadMesh.new()
	quad.size = Vector2(0.006, 0.006)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.85, 0.6, 0.8)
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.8, 0.5)
	quad.material = mat
	p.draw_pass_1 = quad
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(p)


# ------------------------------------------------------------------ ışıklar
func _lights() -> void:
	for at in [Vector3(-2.2, 2.9, -0.5), Vector3(2.4, 2.9, -0.5)]:
		_drop(CEIL, at, 0.0, 0.62)
		var tube := OmniLight3D.new()
		tube.position = at + Vector3(0, -0.25, 0)
		tube.light_color = Color("c9d6bf")
		tube.light_energy = 1.15
		tube.omni_range = 6.5
		tube.shadow_enabled = false
		add_child(tube)
		tubes.append(tube)
	# masa lambası: amber, gölgeli, hacimli
	var lamp_pos := Vector3(1.15 + 0.62 + 0.03, 1.55, -1.75 - 0.12)
	desk_lamp = SpotLight3D.new()
	desk_lamp.position = lamp_pos
	desk_lamp.light_color = AMBER
	desk_lamp.light_energy = 9.0
	desk_lamp.spot_range = 5.0
	desk_lamp.spot_angle = 52.0
	desk_lamp.spot_attenuation = 0.7
	desk_lamp.shadow_enabled = true
	desk_lamp.shadow_bias = 0.05
	desk_lamp.shadow_blur = 0.0
	add_child(desk_lamp)
	desk_lamp.look_at(Vector3(1.05, 1.05, -1.55))
	lamp_glow = OmniLight3D.new()
	lamp_glow.position = lamp_pos + Vector3(0, -0.05, 0.1)
	lamp_glow.light_color = AMBER
	lamp_glow.light_energy = 1.2
	lamp_glow.omni_range = 3.2
	lamp_glow.shadow_enabled = false
	add_child(lamp_glow)
	# ön planda hafif sıcak dolgu (kameradan, çok zayıf)
	var fill := OmniLight3D.new()
	fill.position = Vector3(0.0, 1.8, 2.4)
	fill.light_color = Color("3a465c")
	fill.light_energy = 0.35
	fill.omni_range = 9.0
	add_child(fill)


func _overlay() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 2
	add_child(layer)
	var rect := ColorRect.new()
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var shader := Shader.new()
	shader.code = GRAIN_SHADER
	var mat := ShaderMaterial.new()
	mat.shader = shader
	rect.material = mat
	layer.add_child(rect)


# ------------------------------------------------------------------ hareket
func _process(delta: float) -> void:
	_t += delta
	_intro = minf(_intro + delta / 14.0, 1.0)
	var ease := 1.0 - pow(1.0 - _intro, 3.0)
	if camera and drift:
		var sway := Vector3(sin(_t * 0.035) * 0.18, sin(_t * 0.028) * 0.022, cos(_t * 0.022) * 0.08)
		var mouse := Vector2.ZERO
		var vp := get_viewport()
		if vp:
			var size := vp.get_visible_rect().size
			if size.x > 0.0:
				mouse = (vp.get_mouse_position() / size - Vector2(0.5, 0.5)).clampf(-0.5, 0.5)
		camera.position = CAM_WIDE.lerp(CAM_BASE, ease) + sway + Vector3(mouse.x * 0.08, -mouse.y * 0.03, 0.0)
		camera.fov = lerpf(FOV_WIDE, FOV_SETTLE, ease)
		var look := CAM_LOOK + Vector3(sin(_t * 0.03) * 0.1 + mouse.x * 0.08, cos(_t * 0.036) * 0.03 - mouse.y * 0.04, 0.0)
		camera.look_at(look)
		camera.rotation.z = sin(_t * 0.045) * 0.003
	# neon/lamba titremesi
	for i in tubes.size():
		var flick := 1.0
		if i == 1 and fmod(_t * 3.1 + i, 9.0) < 0.14:
			flick = 0.35
		tubes[i].light_energy = (1.15 + 0.04 * sin(_t * 5.0 + i)) * flick
	if desk_lamp:
		var buzz := 1.0 + 0.025 * sin(_t * 31.0) + (0.12 if fmod(_t, 17.0) < 0.07 else 0.0)
		desk_lamp.light_energy = 9.0 * buzz
	if radio_led:
		(radio_led.material_override as StandardMaterial3D).emission_energy_multiplier = 3.0 if fmod(_t, 2.0) < 1.1 else 0.4
	# saat: saniye ibresi tık tık
	var sec := int(_t)
	if sec != _sec_last and second_hand:
		_sec_last = sec
		second_hand.rotation.z = -deg_to_rad((sec % 60) * 6.0)
		minute_hand.rotation.z = -deg_to_rad(17 * 6.0 + sec / 10.0)
	# şimşek
	_flash_in -= delta
	if _flash_in <= 0.0 and _flash_t < 0.0:
		_flash_t = 0.0
		_flash_in = _rng.randf_range(18.0, 40.0)
	if _flash_t >= 0.0:
		_flash_t += delta
		var k := 0.0
		if _flash_t < 0.08:
			k = 1.0
		elif _flash_t > 0.16 and _flash_t < 0.3:
			k = 0.6 * (1.0 - (_flash_t - 0.16) / 0.14)
		flash.light_energy = k * 2.2
		env.ambient_light_energy = 1.05 + k * 1.2
		if _flash_t > 0.45:
			_flash_t = -1.0
			flash.light_energy = 0.0
			env.ambient_light_energy = 1.05


# ------------------------------------------------------------------ yardımcılar
func _drop(scene: PackedScene, feet: Vector3, yaw: float, scale: float, local_feet: Vector3 = Vector3.ZERO) -> Node3D:
	var offset := Basis(Vector3.UP, deg_to_rad(yaw)) * (local_feet * scale)
	var node := MeshFactory.place(self, scene, feet - offset, yaw, scale)
	_cast(node)
	return node


## Yüzey adına göre materyal değiştir (GLB'nin düz renklerini yaşlandır).
func _retint(node: Node, map: Dictionary) -> void:
	for mi in node.find_children("*", "MeshInstance3D", true, false):
		var m := mi as MeshInstance3D
		for i in m.mesh.get_surface_count():
			var mat := m.mesh.surface_get_material(i)
			var key: String = mat.resource_name if mat else ""
			if map.has(key):
				m.set_surface_override_material(i, map[key])
			elif map.has("*"):
				m.set_surface_override_material(i, map["*"])


func _desk_wood() -> StandardMaterial3D:
	var mat := MeshFactory.pbr("wood_table_001", Color("b0834f"), Vector2(1, 1), 0.85)
	mat.uv1_triplanar = true
	mat.uv1_scale = Vector3(0.8, 0.8, 0.8)
	mat.uv1_world_triplanar = false
	return mat


func _cast(node: Node) -> void:
	if node is MeshInstance3D:
		node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	for child in node.get_children():
		_cast(child)


func _tex_material(tex: Texture2D, rough: float) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = tex
	mat.roughness = rough
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	return mat


func _soft_texture() -> Texture2D:
	var grad := Gradient.new()
	grad.set_color(0, Color(1, 1, 1, 1))
	grad.set_color(1, Color(1, 1, 1, 0))
	var tex := GradientTexture2D.new()
	tex.gradient = grad
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.0, 0.5)
	tex.width = 64
	tex.height = 64
	return tex


func _rect(img: Image, x: int, y: int, w: int, h: int, c: Color) -> void:
	var r := Rect2i(x, y, w, h).intersection(Rect2i(0, 0, img.get_width(), img.get_height()))
	if r.size.x > 0 and r.size.y > 0:
		img.fill_rect(r, c)


func _paper_texture(seed_value: int) -> Texture2D:
	var r := RandomNumberGenerator.new()
	r.seed = seed_value * 17 + 3
	var img := Image.create(128, 180, false, Image.FORMAT_RGB8)
	img.fill(Color("d8cfb4").darkened(r.randf_range(0.0, 0.18)))
	var y := 14
	while y < 160:
		var w := r.randi_range(40, 108)
		_rect(img, 10, y, w, 2, Color(0.18, 0.17, 0.16))
		y += r.randi_range(6, 9)
		if r.randf() < 0.14:
			y += 8
	if r.randf() < 0.5:
		var sx := r.randi_range(60, 90)
		var sy := r.randi_range(120, 150)
		_rect(img, sx, sy, 34, 16, Color(0.62, 0.14, 0.12))
		_rect(img, sx + 3, sy + 3, 28, 10, Color("d8cfb4"))
	if r.randf() < 0.3:
		_rect(img, r.randi_range(10, 90), r.randi_range(20, 130), 14, 14, Color(0.4, 0.28, 0.16))
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)


func _photo_texture(seed_value: int) -> Texture2D:
	var r := RandomNumberGenerator.new()
	r.seed = seed_value * 31 + 5
	var w := 96
	var h := 72
	var img := Image.create(w, h, false, Image.FORMAT_RGB8)
	for y in h:
		for x in w:
			var v := 0.16 + 0.22 * (1.0 - float(y) / h) + r.randf() * 0.05
			var d := Vector2(x - w * 0.5, y - h * 0.5).length() / (w * 0.6)
			v *= clampf(1.15 - d * 0.6, 0.3, 1.0)
			img.set_pixel(x, y, Color(v, v * 0.97, v * 0.9))
	# sahne: yer çizgisi, nesne siluetleri, tebeşir ana hat
	_rect(img, 0, int(h * 0.62), w, h, Color(0.1, 0.1, 0.1))
	_rect(img, r.randi_range(6, 30), r.randi_range(14, 28), r.randi_range(14, 30), r.randi_range(22, 36), Color(0.07, 0.07, 0.08))
	var cx := r.randi_range(40, 70)
	var cy := r.randi_range(44, 56)
	var chalk := Color(0.82, 0.82, 0.78)
	_rect(img, cx - 10, cy, 20, 1, chalk)
	_rect(img, cx - 10, cy + 8, 20, 1, chalk)
	_rect(img, cx - 10, cy, 1, 9, chalk)
	_rect(img, cx + 9, cy, 1, 9, chalk)
	_rect(img, cx + 10, cy + 2, 8, 1, chalk)
	_rect(img, cx - 17, cy + 5, 7, 1, chalk)
	_rect(img, 70, 4, 18, 9, Color(0.8, 0.7, 0.2))
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)


func _cork_texture() -> Texture2D:
	var r := RandomNumberGenerator.new()
	r.seed = 99
	var img := Image.create(256, 160, false, Image.FORMAT_RGB8)
	for y in 160:
		for x in 256:
			var v := 0.36 + r.randf() * 0.14
			img.set_pixel(x, y, Color(v * 1.1, v * 0.72, v * 0.42))
	for i in 140:
		_rect(img, r.randi_range(0, 255), r.randi_range(0, 159), r.randi_range(1, 3), r.randi_range(1, 3), Color(0.2, 0.12, 0.07))
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)


func _map_texture() -> Texture2D:
	var r := RandomNumberGenerator.new()
	r.seed = 6
	var w := 460
	var h := 580
	var img := Image.create(w, h, false, Image.FORMAT_RGB8)
	for y in h:
		for x in w:
			var v := 0.78 + r.randf() * 0.06 - 0.22 * (Vector2(x - w * 0.5, y - h * 0.5).length() / (w * 0.7))
			img.set_pixel(x, y, Color(v * 0.95, v * 0.88, v * 0.7))
	var line := Color(0.35, 0.3, 0.24)
	for i in 14:
		_rect(img, 0, 30 + i * 40, w, 1, Color(0.6, 0.55, 0.45))
		_rect(img, 20 + i * 32, 0, 1, h, Color(0.6, 0.55, 0.45))
	# ana yollar
	var px := 40.0
	var py := 100.0
	for i in 60:
		px += r.randf_range(4.0, 9.0)
		py += r.randf_range(-3.0, 8.0)
		_rect(img, int(px), int(py), 8, 3, line)
	px = 380.0
	py = 40.0
	for i in 60:
		px -= r.randf_range(0.0, 6.0)
		py += r.randf_range(5.0, 9.0)
		_rect(img, int(px), int(py), 3, 8, line)
	# Çubuk Çayı benzeri dere (mavi gri)
	px = 20.0
	py = 330.0
	for i in 70:
		px += 6.0
		py += sin(i * 0.3) * 6.0
		_rect(img, int(px), int(py), 8, 4, Color(0.42, 0.5, 0.58))
	for i in 12:
		var cx := r.randi_range(60, 400)
		var cy := r.randi_range(80, 520)
		_rect(img, cx, cy, 14, 14, Color(0.5, 0.42, 0.34))
	for i in 3:
		var cx := r.randi_range(120, 340)
		var cy := r.randi_range(140, 460)
		for k in 8:
			_rect(img, cx - 8 + k, cy - 8, 1, 17, Color(0.7, 0.12, 0.1))
			_rect(img, cx - 8, cy - 8 + k, 17, 1, Color(0.7, 0.12, 0.1))
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)


func _terminal_texture() -> Texture2D:
	var r := RandomNumberGenerator.new()
	r.seed = 12
	var img := Image.create(128, 96, false, Image.FORMAT_RGB8)
	img.fill(Color(0.02, 0.07, 0.03))
	var y := 8
	while y < 80:
		_rect(img, 8, y, r.randi_range(30, 100), 3, Color(0.35, 0.95, 0.45))
		y += 7
	_rect(img, 8, 84, 6, 5, Color(0.5, 1.0, 0.6))
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)
