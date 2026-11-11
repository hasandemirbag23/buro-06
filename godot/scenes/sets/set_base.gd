extends Node3D
## Olay yeri setlerinin ortak tabanı. Çarpışma, hotspot ve prop yerleştirme
## ana sahneye (host) devredilir; böylece tek navmesh ve tek engel listesi kalır.

const MeshFactory := preload("res://scenes/mesh_factory.gd")
const Props := preload("res://scenes/props_lib.gd")
const CITY := "res://assets/city/"
const CONCRETE := Color("8b8f93")
const CONCRETE_DARK := Color("5e6266")
const RUST := Color("7a3b1e")
const STEEL := Color("3a3f46")
const AMBER := Color("F59E0B")
## Ankara apartman ızgarası (BUILDING_DESIGN.md)
const FLOOR_H := 2.9
const SHOP_H := 3.6
const BAY := 1.5
## Cephe tipleri: [sıva rengi, bant rengi, çatı rengi, balkon, zemin]
const FACADES := {
	"A": [Color("cdbb98"), Color("9c9588"), Color("7d4433"), true, "entry"],
	"B": [Color("c08a6c"), Color("a39a8e"), Color("6e3a2c"), true, "shop"],
	"C": [Color("8f9a96"), Color("5f6664"), Color("4a4d50"), false, "shop"],
	"D": [Color("b8ab92"), Color("8e8573"), Color("5c5a55"), false, "entry"],
}

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
	if kit != "roads" and model.begins_with("building"):
		return _kenney_to_apartment(kit, model, feet, yaw, scale)
	if model == "dumpster":
		return _swap("S3", kit, model, feet, yaw, scale, solid, Vector3(0, 1.3, 0))
	return _kenney(kit, model, feet, yaw, scale, solid)


func _kenney(kit: String, model: String, feet: Vector3, yaw: float, scale: float, solid: bool) -> Node3D:
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
	var node := _prop(_cache[path], feet, yaw, scale, Vector3.ZERO, solid)
	if path.ends_with("vehicles/sedan.glb") and host.has_method("_reskin"):
		host._reskin(node, "S5")
	return node


## Yol şeridi: Kenney yol karolarıyla düz yol döşer (görsel).
func road(from_x: float, to_x: float, z: float, tile := 8.0) -> void:
	var x := from_x
	while x <= to_x:
		city("roads", "road-straight", Vector3(x, 0.0, z), 90.0, tile, false)
		x += tile
	# Kaldırım tarafı şeride park etmiş araçlar (yürüme alanı dışında, görsel)
	var span := to_x - from_x
	var lane := z - tile * 0.25
	_vehicle("S6", Vector3(from_x + span * 0.42, 0.0, lane), 180.0)
	_vehicle("S5", Vector3(from_x + span * 0.18, 0.0, lane), 0.0)
	_vehicle("S5", Vector3(from_x + span * 0.7, 0.0, lane), 180.0)


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
	_swap("S1", "roads", "light-square", at, yaw, 10.0, solid)
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


## Arka plan binası dizisi: bitişik nizam Ankara apartmanları (models yalnız tip seçer).
func skyline(models: Array, x0: float, x1: float, z: float, step: float, scale := 10.0, yaw := 0.0, jitter_z := 5.0) -> void:
	var i := 0
	var x := x0
	while x <= x1:
		var m: Array = models[i % models.size()]
		var seed := absi(hash(str(m[1]) + str(i)))
		var kind: String = "C" if str(m[1]).contains("skyscraper") else ["A", "B", "A", "D"][seed % 4]
		var floors := (7 + seed % 3) if kind == "C" else (4 + seed % 4)
		apartment(Vector3(x, 0.0, z - float(i % 3) * jitter_z), step - 0.2, 11.0 * scale / 10.0, floors, kind, yaw, seed)
		x += step
		i += 1


## Tripo nesnesi (props_lib) — set düğümüne, görsel. Taban feet'e oturur.
func tripo(id: String, feet: Vector3, yaw := 0.0, size := Vector3.ZERO) -> Node3D:
	var node := Props.make(id, size)
	node.position = feet
	node.rotation_degrees.y = yaw
	add_child(node)
	for mi in node.find_children("*", "MeshInstance3D", true, false):
		(mi as MeshInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	return node


## Kenney modelini Tripo karşılığıyla değiştirir. solid ise Kenney modeli görünmez olarak
## yerinde kalır: çarpışma kutusu ve navmesh engeli birebir aynı kalsın diye.
func _swap(id: String, kit: String, model: String, feet: Vector3, yaw: float, scale: float, solid: bool, size := Vector3.ZERO) -> Node3D:
	if solid:
		var old := _kenney(kit, model, feet, yaw, scale, true)
		if old:
			old.visible = false
	return tripo(id, feet, yaw, size)


func _vehicle(id: String, at: Vector3, yaw: float) -> void:
	var car := tripo(id, at, yaw)
	if id == "S6":
		for side in [-1.0, 1.0]:
			var tag := MeshFactory.label(car, "POLİS", Vector3(0.2, 0.85, side * 1.07), Color("f4f6fa"), 0.5)
			tag.billboard = BaseMaterial3D.BILLBOARD_DISABLED
			tag.fixed_size = false
			tag.rotation_degrees.y = 0.0 if side > 0 else 180.0


## Kenney bina çağrısını aynı ayak izinde bir Ankara apartmanına çevirir.
func _kenney_to_apartment(kit: String, model: String, feet: Vector3, yaw: float, scale: float) -> Node3D:
	var seed := absi(hash(model + str(snappedf(feet.x, 0.1)) + str(snappedf(feet.z, 0.1))))
	var k := scale / 10.0
	var width := (9.0 + float(seed % 4) * 1.5) * k
	var depth := 10.0 * k
	var floors := 4 + seed % 3
	var kind := "A"
	if model.begins_with("building-skyscraper"):
		floors = 8 + seed % 3
		width = 13.5 * k
		kind = "C"
	elif kit == "commercial":
		kind = ["B", "A", "C", "D", "B"][seed % 5]
		floors = 5 + seed % 3
	return apartment(feet, width, depth, floors, kind, yaw, seed)


## Ankara apartmanı: kodla gövde + Tripo modülleri (M1 balkon, M2 pencere, M3 kepenk, M4 giriş).
## Önü yerel +Z. Görsel, çarpışmasız (arka plan).
func apartment(feet: Vector3, width: float, depth: float, floors: int, kind := "A", yaw := 0.0, seed := 0) -> Node3D:
	var f: Array = FACADES[kind]
	var root := Node3D.new()
	root.name = "Apartman_%s" % kind
	root.position = feet
	root.rotation_degrees.y = yaw
	add_child(root)
	var ground := SHOP_H if f[4] == "shop" else FLOOR_H
	var height := ground + floors * FLOOR_H
	var plaster := MeshFactory.pbr("plastered_wall_02", f[0], Vector2(0.35, 0.35))
	plaster.uv1_triplanar = true
	plaster.uv1_world_triplanar = true
	MeshFactory.textured_box(root, Vector3(width, height, depth), Vector3(0, height * 0.5, 0), plaster)
	var front := depth * 0.5
	# kat bantları ve çatı
	for i in floors + 1:
		MeshFactory.box(root, Vector3(width + 0.12, 0.18, depth + 0.12), Vector3(0, ground + i * FLOOR_H - 0.09, 0), f[1], 0.9)
	var roof := MeshInstance3D.new()
	var prism := PrismMesh.new()
	prism.size = Vector3(width + 0.6, 1.6 + width * 0.06, depth + 0.6)
	roof.mesh = prism
	roof.position = Vector3(0, height + prism.size.y * 0.5, 0)
	roof.rotation_degrees.y = 90.0 if width < depth else 0.0
	roof.material_override = MeshFactory.material(f[2], 0.85)
	root.add_child(roof)
	# cephe ızgarası
	var bays := maxi(int(width / BAY), 2)
	var pitch := width / bays
	var windows: Array[Transform3D] = []
	var rails: Array[Transform3D] = []
	for fl in floors:
		var y := ground + fl * FLOOR_H + 0.75
		for b in bays:
			var x := -width * 0.5 + pitch * (b + 0.5)
			windows.append(Transform3D(Basis(), Vector3(x, y, front)))
			var lit := (seed + fl * 7 + b * 3) % 5
			if lit < 2:
				MeshFactory.box(root, Vector3(1.0, 1.25, 0.02), Vector3(x, y + 0.75, front + 0.005), Color("f0cf86"), 0.4, 0.8)
			if f[3] and b % 3 == 1:
				MeshFactory.box(root, Vector3(pitch * 2.0, 0.14, 1.1), Vector3(x + pitch * 0.5, y - 0.82, front + 0.55), f[1], 0.9)
				rails.append(Transform3D(Basis(), Vector3(x, y - 0.75, front + 1.06)))
				rails.append(Transform3D(Basis(), Vector3(x + pitch, y - 0.75, front + 1.06)))
	_modules(root, "M2", windows)
	_modules(root, "M1", rails)
	# zemin kat
	if f[4] == "shop":
		var shops := maxi(int(width / 3.8), 1)
		var shop_w := width / shops
		var fronts: Array[Transform3D] = []
		for i in shops:
			fronts.append(Transform3D(Basis().scaled(Vector3.ONE * (shop_w / 3.8)), Vector3(-width * 0.5 + shop_w * (i + 0.5), 0, front + 0.05)))
		_modules(root, "M3", fronts)
	else:
		_modules(root, "M4", [Transform3D(Basis(), Vector3(0, 0, front + 0.2))])
		for side in [-1.0, 1.0]:
			MeshFactory.box(root, Vector3(1.0, 0.4, 0.04), Vector3(side * width * 0.3, 0.45, front + 0.01), Color("2a2d31"), 0.6)
	return root


## Tekrar eden modül: tek MultiMesh (bir çizim çağrısı).
func _modules(parent: Node3D, id: String, places: Array) -> void:
	if places.is_empty():
		return
	var info := Props.mesh_of(id)
	if info[0] == null:
		return
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = info[0]
	mm.instance_count = places.size()
	for i in places.size():
		mm.set_instance_transform(i, (places[i] as Transform3D) * (info[1] as Transform3D))
	var node := MultiMeshInstance3D.new()
	node.multimesh = mm
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	parent.add_child(node)
