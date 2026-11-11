extends RefCounted
## Tripo API ile üretilen nesneler (bkz. docs/redesign/PROP_SCALES.md).
## Tripo çıktısı 1 birime normalize ve orijinde ortalı gelir; make() modeli
## hedef boyuta ölçekler ve tabanını kökün orijinine oturtur.

const PATHS := {
	"B1": "res://assets/generated/props/B1/tripo-out/b1-7fad3128/model.glb",
	"B2": "res://assets/generated/props/B2/tripo-out/b2-e376cfca/model.glb",
	"B3": "res://assets/generated/props/B3/tripo-out/b3-f39b560b/model.glb",
	"B6": "res://assets/generated/props/B6/tripo-out/b6-60364d05/model.glb",
	"C1": "res://assets/generated/props/C1/tripo-out/c1-85f784ed/model.glb",
	"M1": "res://assets/generated/props/M1/tripo-out/m1-b62b506b/model.glb",
	"M2": "res://assets/generated/props/M2/tripo-out/m2-98bf59e1/model.glb",
	"M3": "res://assets/generated/props/M3/tripo-out/m3-bda773ee/model.glb",
	"M4": "res://assets/generated/props/M4/tripo-out/m4-8e963e88/model.glb",
	"N1": "res://assets/generated/props/N1/tripo-out/n1-8019984e/model.glb",
	"N3": "res://assets/generated/props/N3/tripo-out/n3-892407d8/model.glb",
	"Q1": "res://assets/generated/props/Q1/tripo-out/q1-5757e79d/model.glb",
	"Q2": "res://assets/generated/props/Q2/tripo-out/q2-deec4b08/model.glb",
	"S1": "res://assets/generated/props/S1/tripo-out/s1-e9956785/model.glb",
	"S3": "res://assets/generated/props/S3/tripo-out/s3-4d8bcaf2/model.glb",
	"S4": "res://assets/generated/props/S4/tripo-out/s4-773de129/model.glb",
	"S5": "res://assets/generated/props/S5/tripo-out/s5-6a93f170/model.glb",
	"S6": "res://assets/generated/props/S6/tripo-out/s6-28feccb3/model.glb",
}

## id: [hedef boyut (m, kök eksenlerinde; 0 = orantılı), yön düzeltmesi (derece)].
## Yön düzeltmesinden sonra modelin önü +Z'ye bakar. Masa (B1): çekmeceler -Z'de (oturan taraf).
## Yönler tools/prop_sheet.tscn render'ıyla doğrulandı (11.11.2026).
const SPEC := {
	"B1": [Vector3(0, 0.76, 0), Vector3(0, -90, 0)],
	"B2": [Vector3(0, 1.32, 0), Vector3(0, -90, 0)],
	"B3": [Vector3(0.75, 0, 0), Vector3.ZERO],
	"B6": [Vector3(0, 0.30, 0), Vector3.ZERO],
	"C1": [Vector3(0, 0, 1.8), Vector3.ZERO],  # kalite düşük: kullanılmıyor,
	"M1": [Vector3(1.2, 1.0, 0), Vector3(0, 90, 0)],
	"M2": [Vector3(1.2, 1.6, 0), Vector3(0, 90, 0)],
	"M3": [Vector3(3.6, 0, 0), Vector3(0, -90, 0)],
	"M4": [Vector3(0, 3.0, 0), Vector3.ZERO],
	"N1": [Vector3(0, 0, 0.30), Vector3(0, 0, 90)],
	"N3": [Vector3(0, 0, 0.16), Vector3.ZERO],
	"Q1": [Vector3(1.2, 0, 0), Vector3.ZERO],
	"Q2": [Vector3(0, 0.85, 0), Vector3(0, -45, 0)],
	"S1": [Vector3(0, 6.2, 0), Vector3.ZERO],
	"S3": [Vector3(0, 1.30, 0), Vector3.ZERO],
	"S4": [Vector3(4.0, 0, 0), Vector3(0, 90, 0)],
	"S5": [Vector3(4.3, 0, 0), Vector3.ZERO],
	"S6": [Vector3(4.6, 0, 0), Vector3.ZERO],
}

static var _scenes := {}
static var _meshes := {}


static func scene(id: String) -> PackedScene:
	if not _scenes.has(id):
		_scenes[id] = load(PATHS[id]) if ResourceLoader.exists(PATHS[id]) else null
	return _scenes[id]


## Hedef boyutlu, tabanı orijinde duran nesne kökü. size verilirse SPEC'i ezer.
static func make(id: String, size := Vector3.ZERO) -> Node3D:
	var root := Node3D.new()
	root.name = id
	var packed := scene(id)
	if packed == null:
		return root
	var inst := packed.instantiate() as Node3D
	inst.rotation_degrees = SPEC[id][1]
	var pivot := Node3D.new()
	root.add_child(pivot)
	pivot.add_child(inst)
	var box := _bounds(inst)
	var sc := _fit(box.size, size if size != Vector3.ZERO else SPEC[id][0])
	pivot.scale = sc
	var foot := Vector3(box.position.x + box.size.x * 0.5, box.position.y, box.position.z + box.size.z * 0.5)
	pivot.position = -foot * sc
	return root


## Tekrar eden modüller için: [mesh, mesh yerel → kök (taban orijinde) dönüşümü].
static func mesh_of(id: String, size := Vector3.ZERO) -> Array:
	var key := "%s|%s" % [id, size]
	if _meshes.has(key):
		return _meshes[key]
	var root := make(id, size)
	var out := [null, Transform3D.IDENTITY]
	for mi in root.find_children("*", "MeshInstance3D", true, false):
		var m := mi as MeshInstance3D
		if m.mesh == null:
			continue
		out = [m.mesh, _chain(m, root)]
		break
	root.free()
	_meshes[key] = out
	return out


static func _fit(have: Vector3, want: Vector3) -> Vector3:
	var axes := []
	for i in 3:
		if want[i] > 0.0 and have[i] > 0.0001:
			axes.append(want[i] / have[i])
	if axes.is_empty():
		return Vector3.ONE
	var mean := 0.0
	for a in axes:
		mean += a
	mean /= axes.size()
	var out := Vector3.ONE * mean
	for i in 3:
		if want[i] > 0.0 and have[i] > 0.0001:
			out[i] = want[i] / have[i]
	return out


## inst'in ebeveyni (pivot) uzayındaki birleşik AABB.
static func _bounds(inst: Node3D) -> AABB:
	var box := AABB()
	var first := true
	var parent := inst.get_parent() as Node3D
	for mi in inst.find_children("*", "MeshInstance3D", true, false):
		var m := mi as MeshInstance3D
		if m.mesh == null:
			continue
		var part: AABB = _chain(m, parent) * m.mesh.get_aabb()
		box = part if first else box.merge(part)
		first = false
	return AABB(Vector3(-0.5, -0.5, -0.5), Vector3.ONE) if first else box


## Ağaçta olmayan düğümler için node → ancestor dönüşümü.
static func _chain(node: Node3D, ancestor: Node) -> Transform3D:
	var xf := Transform3D.IDENTITY
	var n: Node = node
	while n != null and n != ancestor:
		if n is Node3D:
			xf = (n as Node3D).transform * xf
		n = n.get_parent()
	return xf
