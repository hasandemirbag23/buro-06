extends Node3D
## Olay yeri setlerinin ortak tabanı. Çarpışma, hotspot ve prop yerleştirme
## ana sahneye (host) devredilir; böylece tek navmesh ve tek engel listesi kalır.

const MeshFactory := preload("res://scenes/mesh_factory.gd")
const CITY := "res://assets/city/"
const CONCRETE := Color("8b8f93")
const CONCRETE_DARK := Color("5e6266")
const RUST := Color("7a3b1e")
const STEEL := Color("3a3f46")
const AMBER := Color("F59E0B")

var host: Node3D
var _cache := {}


## Seti kurar (hotspot'lar, ana yapılar).
func build() -> void:
	pass


## Çevre detayları: bina cepheleri, sokak, aydınlatma. Ana sahne kurulumu bittikten sonra çağrılır.
func details() -> void:
	pass


func _block(center: Vector3, size: Vector2, yaw_deg := 0.0, height := 2.0) -> void:
	host._block(center, size, yaw_deg, height)


func _block_prop(node: Node3D, pad := 0.08) -> void:
	host._block_prop(node, pad)


func _prop(scene: PackedScene, feet: Vector3, yaw: float, scale: float, local_feet: Vector3 = Vector3.ZERO, solid := true) -> Node3D:
	return host._prop(scene, feet, yaw, scale, local_feet, solid)


func _spot(id: String, zone: Area3D, center: Vector3, stand: Vector3, cam: Vector3, look: Vector3, icon_at: Vector3, tent_offsets: Array, number: String) -> void:
	host._spot(id, zone, center, stand, cam, look, icon_at, tent_offsets, number)


## Kenney (CC0) şehir paketinden model yerleştirir. kit: commercial | suburban | roads.
## solid=true ise ayak izi kadar çarpışma ve navmesh engeli eklenir.
func city(kit: String, model: String, feet: Vector3, yaw := 0.0, scale := 8.0, solid := true) -> Node3D:
	var path := "%s%s/%s.glb" % [CITY, kit, model]
	if not _cache.has(path):
		_cache[path] = load(path)
	if _cache[path] == null:
		return null
	return _prop(_cache[path], feet, yaw, scale, Vector3.ZERO, solid)


## Yerel interior/furniture/props modeli (Quaternius, Kenney furniture vb.).
func local(path: String, feet: Vector3, yaw := 0.0, scale := 1.0, solid := true) -> Node3D:
	if not _cache.has(path):
		_cache[path] = load(path)
	if _cache[path] == null:
		return null
	return _prop(_cache[path], feet, yaw, scale, Vector3.ZERO, solid)


## Yol şeridi: Kenney yol karolarıyla düz yol döşer (görsel).
func road(from_x: float, to_x: float, z: float, tile := 8.0) -> void:
	var x := from_x
	while x <= to_x:
		city("roads", "road-straight", Vector3(x, 0.0, z), 90.0, tile, false)
		x += tile


## Işıklı pencere kutusu (arka plan binalarına canlılık).
func lit_windows(origin: Vector3, cols: int, rows: int, step: Vector2, facing_z := 1.0) -> void:
	for r in rows:
		for c in cols:
			if (r * 7 + c * 3) % 5 == 0:
				continue
			var on: bool = (r + c * 2) % 3 != 0
			var tint := Color("f0cf86") if on else Color("202630")
			MeshFactory.box(self, Vector3(0.9, 1.2, 0.06), origin + Vector3(c * step.x, r * step.y, 0.0), tint, 0.4, 0.9 if on else 0.0)


## Kutu + çarpışma tek seferde (kısa duvar, palet, kabin gibi basit nesneler).
func solid_box(center: Vector3, size: Vector3, color: Color, yaw := 0.0, rough := 0.8) -> MeshInstance3D:
	var mesh := MeshFactory.box(self, size, center + Vector3(0, size.y * 0.5, 0), color, rough)
	mesh.rotation_degrees.y = yaw
	_block(Vector3(center.x, 0, center.z), Vector2(size.x, size.z), yaw, size.y)
	return mesh


## Sokak lambası: Kenney direği + zayıf ışık (gölgesiz). arm_yaw direğin kolunun baktığı yöndür.
func street_lamp(at: Vector3, yaw: float, light := true, solid := false) -> void:
	city("roads", "light-square", at, yaw, 10.0, solid)
	if light:
		var spot := SpotLight3D.new()
		var arm := Basis(Vector3.UP, deg_to_rad(yaw)) * Vector3(0, 0, -1.6)
		spot.position = at + Vector3(arm.x, 5.8, arm.z)
		spot.rotation_degrees = Vector3(-90, 0, 0)
		spot.light_color = Color("ffe3b0")
		spot.light_energy = 3.5
		spot.spot_range = 9.0
		spot.spot_angle = 55.0
		spot.shadow_enabled = false
		add_child(spot)


## Kaldırım şeridi (görsel) ve bordür.
func sidewalk(x0: float, x1: float, z: float, width := 3.0) -> void:
	var w := x1 - x0
	MeshFactory.box(self, Vector3(w, 0.14, width), Vector3((x0 + x1) * 0.5, 0.07, z), Color("5b5f64"), 0.9)
	MeshFactory.box(self, Vector3(w, 0.16, 0.18), Vector3((x0 + x1) * 0.5, 0.08, z + width * 0.5), Color("7b8086"), 0.9)


## Arka plan binası dizisi: modeller sırayla seçilir.
func skyline(models: Array, x0: float, x1: float, z: float, step: float, scale := 10.0, yaw := 0.0, jitter_z := 5.0) -> void:
	var i := 0
	var x := x0
	while x <= x1:
		var m: Array = models[i % models.size()]
		city(str(m[0]), str(m[1]), Vector3(x, 0.0, z - float(i % 3) * jitter_z), yaw, scale, false)
		x += step
		i += 1
