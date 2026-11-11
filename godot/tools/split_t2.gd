extends SceneTree
## T2 (baret + yelek) tek mesh olarak geliyor; Z=0 düzleminde iki parçaya ayırır.
## Her parça kendi merkezine taşınır ve .res olarak kaydedilir.
## Çalıştır: godot --headless --path . --script res://tools/split_t2.gd

const SRC := "res://assets/generated/props/T2/tripo-out/t2-3c1b2eec/model.glb"
const OUT_HELMET := "res://assets/generated/props/T2/baret.res"
const OUT_VEST := "res://assets/generated/props/T2/yelek.res"


func _initialize() -> void:
	var packed := load(SRC) as PackedScene
	if packed == null:
		push_error("T2 modeli yüklenemedi: %s" % SRC)
		quit(1)
		return
	var root := packed.instantiate()
	var mi: MeshInstance3D = null
	for n in root.find_children("*", "MeshInstance3D", true, false):
		mi = n as MeshInstance3D
		break
	if mi == null or mi.mesh == null:
		push_error("MeshInstance3D bulunamadı")
		quit(1)
		return

	var arrays: Array = mi.mesh.surface_get_arrays(0)
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var norms: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL] if arrays[Mesh.ARRAY_NORMAL] != null else PackedVector3Array()
	var uvs: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV] if arrays[Mesh.ARRAY_TEX_UV] != null else PackedVector2Array()
	var idx: PackedInt32Array = arrays[Mesh.ARRAY_INDEX] if arrays[Mesh.ARRAY_INDEX] != null else PackedInt32Array()
	if idx.is_empty():
		idx = PackedInt32Array()
		for i in verts.size():
			idx.append(i)

	var mat := mi.mesh.surface_get_material(0)
	var parts := [_collect(verts, norms, uvs, idx, true), _collect(verts, norms, uvs, idx, false)]
	var names := ["Z+ parça", "Z- parça"]
	var meshes: Array[ArrayMesh] = []
	for p in parts.size():
		var d: Dictionary = parts[p]
		var m := _build(d, mat)
		meshes.append(m)
		var aabb := m.get_aabb()
		print("%s: %d üçgen, boyut %.3f x %.3f x %.3f" % [names[p], d["tris"], aabb.size.x, aabb.size.y, aabb.size.z])

	# Baret daha kompakt (küp benzeri), yelek daha geniş ve yassı: en/boy oranına bak.
	var a0 := meshes[0].get_aabb().size
	var a1 := meshes[1].get_aabb().size
	# Yelek baretten belirgin biçimde daha uzundur: baret = düşük Y olan parça.
	var helmet_first := a0.y < a1.y
	var helmet: ArrayMesh = meshes[0] if helmet_first else meshes[1]
	var vest: ArrayMesh = meshes[1] if helmet_first else meshes[0]
	print("baret = %s parça" % ("Z+" if helmet_first else "Z-"))

	ResourceSaver.save(helmet, OUT_HELMET)
	ResourceSaver.save(vest, OUT_VEST)
	print("kaydedildi: %s · %s" % [OUT_HELMET, OUT_VEST])
	quit(0)


## Üçgenleri ağırlık merkezinin Z işaretine göre ayırır, parçayı kendi merkezine taşır.
func _collect(verts: PackedVector3Array, norms: PackedVector3Array, uvs: PackedVector2Array,
		idx: PackedInt32Array, positive: bool) -> Dictionary:
	var ov := PackedVector3Array()
	var on := PackedVector3Array()
	var ou := PackedVector2Array()
	var tris := 0
	for t in range(0, idx.size(), 3):
		var i0 := idx[t]
		var i1 := idx[t + 1]
		var i2 := idx[t + 2]
		var cz := (verts[i0].z + verts[i1].z + verts[i2].z) / 3.0
		if (cz >= 0.0) != positive:
			continue
		tris += 1
		for i in [i0, i1, i2]:
			ov.append(verts[i])
			if norms.size() > i:
				on.append(norms[i])
			if uvs.size() > i:
				ou.append(uvs[i])
	# merkezle
	var c := Vector3.ZERO
	for v in ov:
		c += v
	if ov.size() > 0:
		c /= float(ov.size())
	var centered := PackedVector3Array()
	for v in ov:
		centered.append(v - c)
	return {"v": centered, "n": on, "u": ou, "tris": tris}


func _build(d: Dictionary, mat: Material) -> ArrayMesh:
	var arr := []
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = d["v"]
	if (d["n"] as PackedVector3Array).size() == (d["v"] as PackedVector3Array).size():
		arr[Mesh.ARRAY_NORMAL] = d["n"]
	if (d["u"] as PackedVector2Array).size() == (d["v"] as PackedVector3Array).size():
		arr[Mesh.ARRAY_TEX_UV] = d["u"]
	var m := ArrayMesh.new()
	m.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	if mat:
		m.surface_set_material(0, mat)
	return m
