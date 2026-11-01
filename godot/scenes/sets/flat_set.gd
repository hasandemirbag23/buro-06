extends "res://scenes/sets/set_base.gd"
## Öveç Sokak 14: ev, mutfak, yatak odası ve sokak tarafı.


func build() -> void:
	house()
	_more()


func house() -> void:
	var block := Vector3(-6.5, 0, -12)
	_block(block, Vector2(12, 6), 0.0, 8.0)
	_block(Vector3(-4.8, 0, 1.5), Vector2(0.3, 10), 0.0, 2.4)
	_block(Vector3(0.2, 0, -3.6), Vector2(10, 0.3), 0.0, 2.4)
	MeshFactory.box(self, Vector3(12, 8, 6), block + Vector3(0, 4, 0), Color("2a2622"), 0.8)
	for floor_i in 3:
		for k in 4:
			var lit: bool = (int(floor_i) + int(k)) % 2 == 0
			var glow := 0.8 if lit else 0.0
			var glass := Color("e6c27a") if lit else Color("14120f")
			MeshFactory.box(self, Vector3(1.2, 0.9, 0.08), block + Vector3(-4.2 + k * 2.6, 1.6 + floor_i * 2.2, 3.06), glass, 0.4, glow)
	MeshFactory.label(self, "ÖVEÇ SOKAK 14", block + Vector3(0, 7.2, 3.2), Color("f4efe4"), 0.45)
	var floor := MeshFactory.box(self, Vector3(16, 0.06, 14), Vector3(2.2, 0.04, 2.4), Color("6e6256"), 0.85)
	floor.set_meta("action", "walk")
	MeshFactory.box(self, Vector3(0.12, 2.4, 10), Vector3(-4.8, 1.2, 1.5), Color("cbb89a"), 0.75)
	MeshFactory.box(self, Vector3(10, 2.4, 0.12), Vector3(0.2, 1.2, -3.6), Color("cbb89a"), 0.75)
	var gas := OmniLight3D.new()
	gas.position = Vector3(-3.2, 1.6, -0.6)
	gas.light_color = Color("9dbe7a")
	gas.light_energy = 0.6
	gas.omni_range = 6.0
	gas.shadow_enabled = false
	add_child(gas)
	var b := Vector3(0.2, 0, 3.2)
	MeshFactory.box(self, Vector3(2.2, 0.35, 1.3), b + Vector3(0, 0.2, 0), Color("d7d0c4"), 0.7)
	_block(b, Vector2(2.2, 1.3), 0.0, 0.8)
	MeshFactory.box(self, Vector3(0.7, 0.16, 0.45), b + Vector3(-0.6, 0.42, 0.15), Color("efe6d6"), 0.6)
	MeshFactory.box(self, Vector3(1.5, 0.06, 0.9), b + Vector3(0.15, 0.4, -0.05), Color("6a2430"), 0.6)
	var phone := MeshFactory.box(self, Vector3(0.16, 0.02, 0.32), b + Vector3(0.7, 0.46, 0.15), Color("111111"), 0.3)
	phone.rotation_degrees.y = -20
	MeshFactory.box(self, Vector3(1.1, 0.9, 0.08), b + Vector3(-1.5, 1.5, -0.4), Color("1a1408"), 0.5)
	MeshFactory.label(self, "24 HAZİRAN", b + Vector3(-1.5, 1.7, -0.32), Color("f4efe4"), 0.28)
	MeshFactory.label(self, "MEZUNİYET", b + Vector3(-1.5, 1.35, -0.32), Color("F59E0B"), 0.22)
	_spot("hotspot_phone", MeshFactory.zone(self, Vector3(2.6, 0.6, 3.0), b + Vector3(0.2, 0.3, 0.4), Color(0, 0, 0, 0), "hotspot:hotspot_phone"),
		b + Vector3(0.4, 0.2, 0.5), b + Vector3(1.7, 0, 1.8), b + Vector3(-1.8, 2.3, 3.4), b + Vector3(0.5, 0.1, 0.5), b + Vector3(0.5, 1.4, 0.5), [Vector3(1.3, 0, 0.3), Vector3(-0.6, 0, 1.5)], "1")
	var p := Vector3(-3.5, 0, -1.0)
	MeshFactory.box(self, Vector3(2.2, 0.9, 0.7), p + Vector3(0, 0.5, 0), Color("d8d2c6"), 0.6)
	_block(p, Vector2(2.3, 0.8), 0.0, 1.0)
	MeshFactory.box(self, Vector3(0.5, 0.12, 0.5), p + Vector3(0.3, 0.98, 0), Color("2a2a2a"), 0.4)
	var hose := MeshFactory.cylinder(self, 0.025, 0.7, p + Vector3(-0.2, 0.7, 0.15), Color("c9a24a"))
	hose.rotation_degrees.z = 80
	var cut := MeshFactory.cylinder(self, 0.03, 0.18, p + Vector3(0.25, 0.55, 0.2), Color("c9a24a"))
	cut.rotation_degrees.z = 70
	MeshFactory.box(self, Vector3(0.28, 0.02, 0.06), p + Vector3(0.55, 0.98, 0.15), Color("c0c4c8"), 0.3)
	_spot("hotspot_column", MeshFactory.zone(self, Vector3(2.4, 1.4, 1.6), p + Vector3(0, 0.7, 0), Color(0, 0, 0, 0), "hotspot:hotspot_column"),
		p + Vector3(0, 0.8, 0), p + Vector3(1.4, 0, 1.6), p + Vector3(-0.4, 2.2, 3.2), p + Vector3(0.1, 0.9, 0.2), p + Vector3(0, 1.6, 0), [Vector3(0.9, 0, 0.5)], "3")
	var c := Vector3(9.5, 0, 1.0)
	MeshFactory.box(self, Vector3(1.6, 0.75, 0.7), c + Vector3(0, 0.4, 0), Color("5a4030"), 0.7)
	_block(c, Vector2(1.8, 0.9), 0.0, 0.9)
	MeshFactory.box(self, Vector3(1.5, 0.04, 0.6), c + Vector3(0, 0.8, 0), Color("6b4a32"), 0.6)
	for i in 4:
		var scrap := MeshFactory.box(self, Vector3(0.18, 0.012, 0.12), c + Vector3(-0.3 + (i % 2) * 0.28, 0.84, -0.08 + int(i / 2) * 0.16), Color("f4efe4"))
		scrap.rotation_degrees.y = -20 + i * 15
	MeshFactory.box(self, Vector3(0.9, 0.7, 0.04), c + Vector3(0, 1.7, -0.45), Color("f7f1e4"))
	MeshFactory.label(self, "24 HAZİRAN", c + Vector3(0, 1.85, -0.4), Color("9b1d1d"), 0.26)
	MeshFactory.label(self, "HUKUK 2026", c + Vector3(0, 1.55, -0.4), Color("1a1408"), 0.2)
	_spot("hotspot_desk", MeshFactory.zone(self, Vector3(2.2, 1.2, 1.2), c + Vector3(0, 0.9, 0), Color(0, 0, 0, 0), "hotspot:hotspot_desk"),
		c + Vector3(0, 0.9, 0), c + Vector3(1.4, 0, 2.1), c + Vector3(-1.0, 1.8, 1.7), c + Vector3(0, 0.85, 0.1), c + Vector3(0, 1.8, 0), [Vector3(0.8, 0, 0.2)], "2")
	var t := Vector3(5.2, 0, 8.5)
	MeshFactory.cylinder(self, 0.28, 0.55, t + Vector3(0, 0.28, 0), Color("2a2e28"))
	_block(t, Vector2(0.7, 0.7), 0.0, 0.6)
	MeshFactory.box(self, Vector3(0.22, 0.012, 0.12), t + Vector3(0.05, 0.58, 0.05), Color("f4efe4"))
	MeshFactory.label(self, "23:30", t + Vector3(0.05, 0.62, 0.12), Color("1a1408"), 0.16)
	MeshFactory.box(self, Vector3(0.16, 0.28, 0.16), t + Vector3(0.35, 0.2, -0.2), Color("6a3a22"), 0.4)
	MeshFactory.box(self, Vector3(0.16, 0.28, 0.16), t + Vector3(-0.28, 0.2, 0.15), Color("6a3a22"), 0.4)
	MeshFactory.label(self, "06 HL 880", t + Vector3(1.2, 1.4, 0), Color("f4efe4"), 0.32)
	_spot("hotspot_suv", MeshFactory.zone(self, Vector3(2.4, 1.0, 2.2), t + Vector3(0, 0.4, 0), Color(0, 0, 0, 0), "hotspot:hotspot_suv"),
		t + Vector3(0, 0.3, 0), t + Vector3(-2.0, 0, 1.2), t + Vector3(2.4, 2.4, 2.6), t + Vector3(0.1, 0.4, 0), t + Vector3(0, 1.2, 0), [Vector3(0.7, 0, -0.4)], "4")


func _more() -> void:
	var p := Vector3(-3.5, 0, -1.0)
	MeshFactory.cylinder(self, 0.04, 0.02, p + Vector3(1.15, 0.9, 0.15), Color("b7b3aa"), 0.3)
	MeshFactory.box(self, Vector3(0.08, 0.05, 0.12), p + Vector3(1.28, 0.9, 0.2), Color("2a2a2a"), 0.4)
	MeshFactory.label(self, "VANA", p + Vector3(1.2, 1.25, 0.15), Color("f4efe4"), 0.14)
	_spot("hotspot_stove", MeshFactory.zone(self, Vector3(0.9, 0.7, 0.8), p + Vector3(1.2, 0.7, 0.15), Color(0, 0, 0, 0), "hotspot:hotspot_stove"),
		p + Vector3(1.2, 0.5, 0.15), p + Vector3(1.4, 0, 1.6), p + Vector3(2.2, 1.7, 2.0), p + Vector3(1.2, 0.9, 0.15), p + Vector3(1.2, 1.3, 0.15), [Vector3(0.45, 0, 0.35)], "5")
	var door := Vector3(2.4, 0, 6.2)
	MeshFactory.box(self, Vector3(0.9, 2.0, 0.08), door + Vector3(0, 1.0, 0), Color("5a4030"), 0.7)
	MeshFactory.box(self, Vector3(0.16, 0.012, 0.12), door + Vector3(0.15, 0.35, 0.06), Color("f4efe4"))
	MeshFactory.label(self, "NOT", door + Vector3(0.15, 0.7, 0.1), Color("1a1408"), 0.14)
	_spot("hotspot_note", MeshFactory.zone(self, Vector3(1.2, 1.6, 0.6), door + Vector3(0, 0.8, 0.2), Color(0, 0, 0, 0), "hotspot:hotspot_note"),
		door + Vector3(0, 0.6, 0.3), Vector3(1.7, 0, 4.6), door + Vector3(1.4, 1.6, 1.6), door + Vector3(0.1, 0.5, 0.1), door + Vector3(0, 1.2, 0.2), [Vector3(0.5, 0, 0.4)], "6")


## Çevre detayları (görsel + çarpışma). Yürüme alanı dışındakiler yalnızca arka plandır.
func details() -> void:

	skyline([["commercial", "building-a"], ["commercial", "building-skyscraper-a"], ["commercial", "building-d"], ["commercial", "building-b"]], -50.0, 50.0, -30.0, 13.0)
	# Bitişik apartmanlar
	city("commercial", "building-b", Vector3(6.5, 0.0, -12.5), 0.0, 10.0, false)
	city("commercial", "building-d", Vector3(17.5, 0.0, -12.5), 0.0, 10.0, false)
	city("commercial", "building-f", Vector3(-19.0, 0.0, -12.5), 0.0, 10.0, false)
	city("commercial", "building-h", Vector3(-30.0, 0.0, -12.5), 0.0, 10.0, false)
	# Sokak, kaldırım, lambalar, ağaçlar
	road(-48.0, 48.0, 25.0)
	sidewalk(-48.0, 48.0, 19.0, 3.4)
	for i in 9:
		street_lamp(Vector3(-44.0 + i * 11.0, 0.0, 17.8), 180.0, i % 2 == 1)
	for x in [-14.0, -2.0, 9.0, 19.0]:
		city("suburban", "tree-large", Vector3(x, 0.0, 17.6), 0.0, 7.0, false)
	city("roads", "dumpster", Vector3(15.5, 0.0, 15.2), 180.0, 4.5, true)
	for x in [-9.0, 14.0]:
		city("roads", "road-sign-street", Vector3(x, 0.0, 17.0), 180.0, 10.0, false)
	# Bina girişi ve balkonlar
	solid_box(Vector3(-6.5, 0, -8.6), Vector3(2.6, 0.2, 1.2), Color("77706a"), 0.0, 0.9)
	MeshFactory.box(self, Vector3(1.2, 2.1, 0.08), Vector3(-6.5, 1.05, -8.93), Color("3a2a1f"), 0.6)
	MeshFactory.box(self, Vector3(0.1, 0.1, 0.1), Vector3(-6.0, 1.0, -8.85), Color("c9a24a"), 0.3, 0.2)
	var porch := OmniLight3D.new()
	porch.position = Vector3(-6.5, 2.6, -8.2)
	porch.light_color = Color("ffd49a")
	porch.light_energy = 1.2
	porch.omni_range = 5.0
	porch.shadow_enabled = false
	add_child(porch)
	for k in 3:
		MeshFactory.box(self, Vector3(2.2, 0.12, 0.9), Vector3(-10.6 + k * 4.2, 3.2, -8.45), Color("6a6560"), 0.9)
		MeshFactory.box(self, Vector3(2.2, 0.7, 0.05), Vector3(-10.6 + k * 4.2, 3.6, -8.02), Color("3a3f46"), 0.5)
	# İç mekan eşyaları (çarpışmalı). Kenney mobilya, ölçek ~2.2
	local("res://assets/furniture/bookcaseClosed.glb", Vector3(6.8, 0, -3.0), 0.0, 2.2)
	local("res://assets/furniture/cabinetTelevision.glb", Vector3(8.0, 0, -2.8), 0.0, 2.2)
	local("res://assets/furniture/sideTableDrawers.glb", Vector3(-1.9, 0, 7.4), 0.0, 2.0)
	local("res://assets/furniture/chair.glb", Vector3(8.5, 0, 5.2), 200.0, 2.4)
	local("res://assets/furniture/table.glb", Vector3(6.2, 0, 6.9), 10.0, 2.0)
	local("res://assets/furniture/cardboardBoxClosed.glb", Vector3(9.0, 0, 7.4), 15.0, 2.6)
	local("res://assets/furniture/cardboardBoxClosed.glb", Vector3(9.6, 0, 7.9), -10.0, 2.2)
	local("res://assets/furniture/rugRectangle.glb", Vector3(5.6, 0.012, 2.0), 0.0, 2.0, false)
