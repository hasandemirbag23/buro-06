extends "res://scenes/sets/set_base.gd"
## Bahçelievler, Nermin Eczanesi. Gece nöbeti bitmiş, kepenk yarıda.


func build() -> void:
	_shell()
	_counter()
	_fridge()
	_desk()
	_bin()
	_door()
	_drawer()


func _shell() -> void:
	solid_box(Vector3(-1.5, 0, -0.4), Vector3(14.0, 3.2, 0.28), Color("1c2420"))
	solid_box(Vector3(-8.2, 0, 3.6), Vector3(0.28, 3.2, 8.2), Color("1c2420"))
	solid_box(Vector3(5.4, 0, 3.6), Vector3(0.28, 3.2, 8.2), Color("1c2420"))
	solid_box(Vector3(-4.2, 0, 7.55), Vector3(8.0, 2.8, 0.28), Color("1c2420"))
	solid_box(Vector3(4.6, 0, 7.55), Vector3(1.8, 2.8, 0.28), Color("1c2420"))
	MeshFactory.box(self, Vector3(12.6, 0.06, 7.2), Vector3(-1.4, 0.04, 3.7), Color("d9d3c6"), 0.8)
	MeshFactory.box(self, Vector3(3.2, 0.9, 0.08), Vector3(1.6, 2.5, 7.72), Color("12382a"), 0.4, 0.4)
	MeshFactory.label(self, "NERMİN ECZANESİ", Vector3(1.6, 3.15, 7.9), Color("e7f6ee"), 0.42)
	var cross := MeshFactory.box(self, Vector3(0.18, 0.9, 0.06), Vector3(-6.2, 2.6, 7.8), Color("1fa85a"), 0.3, 1.6)
	MeshFactory.box(cross, Vector3(0.7, 0.18, 0.06), Vector3(0, 0, 0.01), Color("1fa85a"), 0.3, 1.6)
	var neon := OmniLight3D.new()
	neon.position = Vector3(1.6, 2.4, 8.4)
	neon.light_color = Color("8dffe0")
	neon.light_energy = 1.4
	neon.omni_range = 8.0
	neon.shadow_enabled = false
	add_child(neon)
	for i in 4:
		MeshFactory.box(self, Vector3(1.4, 1.8, 0.35), Vector3(-6.4 + i * 1.5, 0.95, 0.4), Color("f4efe6"), 0.7)
		MeshFactory.box(self, Vector3(1.1, 0.08, 0.28), Vector3(-6.4 + i * 1.5, 0.55 + (i % 3) * 0.35, 0.58), Color("c45b4a") if i % 2 == 0 else Color("2a6b8f"), 0.5)


func _counter() -> void:
	var c := Vector3(-2.3, 0, 2.6)
	solid_box(c, Vector3(2.6, 1.05, 0.7), Color("f7f4ee"))
	MeshFactory.box(self, Vector3(0.16, 0.02, 0.32), c + Vector3(0.7, 1.08, 0.2), Color("111111"), 0.3)
	MeshFactory.label(self, "17 NİSAN", c + Vector3(-0.8, 1.7, -0.5), Color("1a1408"), 0.22)
	MeshFactory.label(self, "RUHSAT 2004", c + Vector3(-0.8, 1.45, -0.5), Color("8a1d1d"), 0.16)
	_spot("hotspot_counter", MeshFactory.zone(self, Vector3(2.2, 1.2, 1.4), c + Vector3(0.4, 0.6, 0.5), Color(0, 0, 0, 0), "hotspot:hotspot_counter"),
		c + Vector3(0.5, 0.9, 0.4), Vector3(-0.6, 0, 4.3), Vector3(1.2, 1.7, 5.4), c + Vector3(0.6, 1.1, 0.2), c + Vector3(0.2, 1.6, 0.2), [Vector3(0.8, 0, 0.6)], "1")


func _fridge() -> void:
	var f := Vector3(-6.3, 0, 1.6)
	solid_box(f, Vector3(0.9, 1.8, 0.7), Color("d5dde4"))
	MeshFactory.box(self, Vector3(0.7, 1.1, 0.04), f + Vector3(0, 1.0, 0.36), Color("9ec9e8"), 0.15, 0.3)
	MeshFactory.label(self, "02:12", f + Vector3(0, 1.55, 0.42), Color("1a1408"), 0.16)
	_spot("hotspot_fridge", MeshFactory.zone(self, Vector3(1.3, 1.6, 1.2), f + Vector3(0.6, 0.8, 0.4), Color(0, 0, 0, 0), "hotspot:hotspot_fridge"),
		f + Vector3(0.4, 0.8, 0.3), Vector3(-4.4, 0, 2.6), Vector3(-2.6, 1.6, 4.2), f + Vector3(0.2, 1.2, 0.4), f + Vector3(0, 1.5, 0.2), [Vector3(0.7, 0, 0.4)], "2")


func _desk() -> void:
	var d := Vector3(3.5, 0, 2.0)
	solid_box(d, Vector3(1.4, 0.78, 0.7), Color("6b4a32"))
	for i in 3:
		var scrap := MeshFactory.box(self, Vector3(0.16, 0.01, 0.11), d + Vector3(-0.3 + i * 0.22, 0.8, 0.05), Color("f4efe4"))
		scrap.rotation_degrees.y = -12 + i * 14
	MeshFactory.label(self, "İEGM", d + Vector3(0, 1.15, 0.2), Color("8a1d1d"), 0.2)
	_spot("hotspot_script", MeshFactory.zone(self, Vector3(1.6, 1.2, 1.2), d + Vector3(0, 0.7, 0.4), Color(0, 0, 0, 0), "hotspot:hotspot_script"),
		d + Vector3(0, 0.8, 0.2), Vector3(2.0, 0, 3.5), Vector3(0.4, 1.7, 4.6), d + Vector3(0, 0.9, 0.15), d + Vector3(0, 1.4, 0), [Vector3(0.5, 0, 0.55)], "3")


func _bin() -> void:
	var b := Vector3(-1.2, 0, 5.5)
	solid_box(b, Vector3(0.45, 0.55, 0.45), Color("2e3430"))
	MeshFactory.box(self, Vector3(0.18, 0.04, 0.12), b + Vector3(0.15, 0.62, 0.1), Color("f4efe4"))
	MeshFactory.label(self, "ONKO-B", b + Vector3(0.2, 0.78, 0.15), Color("1a1408"), 0.14)
	_spot("hotspot_bin", MeshFactory.zone(self, Vector3(1.2, 0.9, 1.2), b + Vector3(0.2, 0.4, 0.2), Color(0, 0, 0, 0), "hotspot:hotspot_bin"),
		b + Vector3(0.1, 0.4, 0.1), Vector3(0.4, 0, 5.6), Vector3(1.8, 1.5, 6.6), b + Vector3(0.1, 0.5, 0.1), b + Vector3(0, 1.1, 0), [Vector3(0.55, 0, 0.2)], "4")


func _door() -> void:
	var door := Vector3(-7.4, 0, 5.2)
	MeshFactory.box(self, Vector3(0.08, 2.1, 0.9), door + Vector3(0, 1.05, 0), Color("3a2a1c"), 0.7)
	MeshFactory.box(self, Vector3(0.12, 0.08, 0.2), door + Vector3(0.1, 0.15, 0.35), Color("c9a24a"), 0.4)
	MeshFactory.label(self, "ARKA", door + Vector3(0.2, 1.8, 0), Color("e7e1d6"), 0.2)
	_spot("hotspot_backdoor", MeshFactory.zone(self, Vector3(1.1, 2.0, 1.2), door + Vector3(0.8, 1.0, 0.2), Color(0, 0, 0, 0), "hotspot:hotspot_backdoor"),
		door + Vector3(0.5, 1.0, 0.2), Vector3(-5.4, 0, 5.3), Vector3(-3.6, 1.6, 6.2), door + Vector3(0.4, 0.4, 0.2), door + Vector3(0.3, 1.5, 0.1), [Vector3(0.7, 0, 0.15)], "5")


func _drawer() -> void:
	var g := Vector3(-2.3, 0, 2.6)
	MeshFactory.box(self, Vector3(0.42, 0.08, 0.34), g + Vector3(-0.55, 0.95, 0.55), Color("cfc6b4"), 0.6)
	MeshFactory.box(self, Vector3(0.28, 0.02, 0.16), g + Vector3(-0.55, 1.02, 0.55), Color("1f6b3a"), 0.5)
	_spot("hotspot_drawer", MeshFactory.zone(self, Vector3(1.0, 0.6, 0.8), g + Vector3(-0.4, 0.8, 0.7), Color(0, 0, 0, 0), "hotspot:hotspot_drawer"),
		g + Vector3(-0.4, 0.9, 0.6), Vector3(-2.2, 0, 4.5), Vector3(-0.4, 1.6, 5.2), g + Vector3(-0.5, 1.0, 0.55), g + Vector3(-0.4, 1.5, 0.4), [Vector3(-0.2, 0, 0.9)], "6")


func details() -> void:
	skyline([["commercial", "building-a"], ["suburban", "building-type-a"], ["commercial", "building-b"]], -18.0, 22.0, -16.0, 14.0)
	road(-20.0, 22.0, 12.6)
	sidewalk(-16.0, 18.0, 9.6, 2.4)
	street_lamp(Vector3(-6.0, 0, 10.2), 180.0)
	street_lamp(Vector3(8.0, 0, 10.4), 180.0)
	MeshFactory.label(self, "4. CADDE", Vector3(6.5, 2.2, 9.8), Color("e7e1d6"), 0.35)
	for row in 7:
		for col in 5:
			var on := (row + col) % 3 != 0
			var tint := Color("f0cf86") if on else Color("1c2430")
			MeshFactory.box(host, Vector3(1.1, 1.3, 0.08), Vector3(-8.0 + col * 3.2, 1.6 + row * 1.8, -6.4), tint, 0.5, 0.7 if on else 0.0)
