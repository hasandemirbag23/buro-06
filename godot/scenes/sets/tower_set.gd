extends "res://scenes/sets/set_base.gd"
## Vadi Kule şantiyesi: kule iskeleti, vinç, iş makineleri, konteyner, kolon, ceset ve lastik izi.


func build() -> void:
	_tower()
	_crane()
	_machines()
	_container()
	_column()
	_body()
	_tracks()
	_more()


func _tower() -> void:
	var origin := Vector3(-7, 0, -13)
	_block(origin, Vector2(13, 10), 0.0, 24.0)
	_block(Vector3(-0.1, 0, -6.5), Vector2(4.0, 1.1), 0.0, 0.8)
	_block(Vector3(3.05, 0, -7.5), Vector2(2.2, 0.9), 0.0, 2.0)
	for floor_i in 7:
		var y := 0.2 + floor_i * 3.4
		MeshFactory.box(self, Vector3(13, 0.35, 10), origin + Vector3(0, y, 0), CONCRETE_DARK, 0.9)
		for gx in 4:
			for gz in 3:
				var cx := -5.5 + gx * 3.6
				var cz := -4.2 + gz * 4.2
				var h := 3.2 if floor_i < 6 else 1.6
				MeshFactory.box(self, Vector3(0.55, h, 0.55), origin + Vector3(cx, y + h * 0.5 + 0.18, cz), CONCRETE, 0.85)
				if floor_i == 6:
					for r in 4:
						MeshFactory.cylinder(self, 0.018, 1.2, origin + Vector3(cx - 0.16 + (r % 2) * 0.32, y + 2.4, cz - 0.16 + int(r / 2) * 0.32), RUST)
		for k in 6:
			MeshFactory.box(self, Vector3(0.06, 1.1, 0.06), origin + Vector3(-6.4 + k * 2.6, y + 0.75, 5.0), RUST)
		MeshFactory.box(self, Vector3(13, 0.05, 0.05), origin + Vector3(0, y + 1.1, 5.0), AMBER, 0.6, 0.4)
	for floor_i in [1, 3, 4]:
		var y: float = 0.2 + floor_i * 3.4
		MeshFactory.box(self, Vector3(2.2, 2.4, 0.08), origin + Vector3(1.4, y + 1.5, 4.9), Color("c9c2b4"), 0.9)
		MeshFactory.box(self, Vector3(1.6, 1.0, 0.06), origin + Vector3(-3.0, y + 1.2, 4.9), Color("2a7a9a"), 0.7)
	MeshFactory.box(self, Vector3(2.4, 0.8, 0.04), origin + Vector3(4.0, 4.2, 5.04), Color("f2d23a"), 0.6)
	MeshFactory.label(self, "VADİ KULE REZİDANS", origin + Vector3(4.0, 4.2, 5.1), Color("1a1408"), 0.5)
	for i in 5:
		var rebar := MeshFactory.cylinder(self, 0.02, 3.0, Vector3(-13.5 + i * 0.1, 0.3, -5.5 + i * 0.12), RUST)
		rebar.rotation_degrees = Vector3(0, 0, 88 + i * 1.5)
	for i in 3:
		MeshFactory.box(self, Vector3(1.2, 0.2 + i * 0.2, 1.0), Vector3(-1.5 + i * 1.4, 0.1 + i * 0.1, -6.5), CONCRETE_DARK, 0.9)
	MeshFactory.box(self, Vector3(1.0, 1.0, 0.8), Vector3(2.5, 0.5, -7.5), Color("8a7a66"), 0.9)
	MeshFactory.box(self, Vector3(1.0, 1.0, 0.8), Vector3(3.6, 0.5, -7.5), Color("8a7a66"), 0.9)
	MeshFactory.box(self, Vector3(1.0, 1.0, 0.8), Vector3(3.05, 1.5, -7.5), Color("8a7a66"), 0.9)


func _crane() -> void:
	var base := Vector3(9.5, 0, -16)
	_block(base, Vector2(3, 3), 0.0, 30.0)
	MeshFactory.box(self, Vector3(3.0, 0.8, 3.0), base + Vector3(0, 0.4, 0), CONCRETE_DARK, 0.9)
	for corner in [Vector3(-0.5, 0, -0.5), Vector3(0.5, 0, -0.5), Vector3(-0.5, 0, 0.5), Vector3(0.5, 0, 0.5)]:
		MeshFactory.box(self, Vector3(0.12, 30, 0.12), base + corner + Vector3(0, 15.8, 0), Color("c9a22a"), 0.6)
	for i in 15:
		var y := 1.8 + i * 2.0
		MeshFactory.box(self, Vector3(1.0, 0.06, 0.06), base + Vector3(0, y, -0.5), Color("c9a22a"))
		MeshFactory.box(self, Vector3(1.0, 0.06, 0.06), base + Vector3(0, y, 0.5), Color("c9a22a"))
		MeshFactory.box(self, Vector3(0.06, 0.06, 1.0), base + Vector3(-0.5, y, 0), Color("c9a22a"))
		MeshFactory.box(self, Vector3(0.06, 0.06, 1.0), base + Vector3(0.5, y, 0), Color("c9a22a"))
		var brace := MeshFactory.box(self, Vector3(0.05, 2.2, 0.05), base + Vector3(-0.5, y + 1.0, 0), Color("c9a22a"))
		brace.rotation_degrees.x = 28 if i % 2 == 0 else -28
	MeshFactory.box(self, Vector3(1.6, 1.4, 1.6), base + Vector3(0, 31.4, 0), Color("c9a22a"), 0.6)
	MeshFactory.box(self, Vector3(1.4, 1.2, 1.1), base + Vector3(0, 31.2, 1.3), Color("2c3138"), 0.5)
	MeshFactory.box(self, Vector3(1.2, 0.6, 0.04), base + Vector3(0, 31.3, 1.86), Color("5a7a98"), 0.3, 0.5)
	MeshFactory.box(self, Vector3(26, 0.5, 0.5), base + Vector3(-11, 32.3, 0), Color("c9a22a"), 0.6)
	for i in 12:
		var tie := MeshFactory.box(self, Vector3(0.05, 1.2, 0.05), base + Vector3(-22 + i * 2.0, 32.9, 0), Color("c9a22a"))
		tie.rotation_degrees.z = 35 if i % 2 == 0 else -35
	MeshFactory.box(self, Vector3(26, 0.08, 0.08), base + Vector3(-11, 33.5, 0), Color("c9a22a"))
	MeshFactory.box(self, Vector3(8, 0.5, 0.5), base + Vector3(5.5, 32.3, 0), Color("c9a22a"), 0.6)
	MeshFactory.box(self, Vector3(1.6, 1.2, 1.4), base + Vector3(8.6, 32.9, 0), CONCRETE_DARK, 0.9)
	MeshFactory.box(self, Vector3(0.03, 18, 0.03), base + Vector3(-14, 23.2, 0), Color("b8bcc0"), 0.3)
	MeshFactory.box(self, Vector3(0.4, 0.5, 0.2), base + Vector3(-14, 14.0, 0), STEEL, 0.4)
	MeshFactory.box(self, Vector3(0.05, 34.5, 0.05), base + Vector3(0, 17.2, 0), Color("c9a22a"))
	host.beacon = MeshFactory.sphere(self, 0.18, base + Vector3(0, 34.7, 0), Color("DC2626"), 3.0)


func _machines() -> void:
	var m := Vector3(15, 0, -4)
	_block(m + Vector3(0.2, 0, 0), Vector2(7.2, 2.8), 0.0, 3.5)
	_block(Vector3(14, 0, 4.5), Vector2(3.0, 0.9), 0.0, 1.0)
	for w in [Vector3(-1.9, 0.55, -1.1), Vector3(-1.9, 0.55, 1.1), Vector3(1.4, 0.55, -1.1), Vector3(1.4, 0.55, 1.1), Vector3(2.6, 0.55, -1.1), Vector3(2.6, 0.55, 1.1)]:
		var wheel := MeshFactory.cylinder(self, 0.55, 0.4, m + w, Color("111111"))
		wheel.rotation_degrees.x = 90
	MeshFactory.box(self, Vector3(6.4, 0.5, 2.2), m + Vector3(0.4, 0.9, 0), STEEL, 0.5)
	MeshFactory.box(self, Vector3(1.9, 1.9, 2.2), m + Vector3(-2.4, 1.95, 0), Color("c8541f"), 0.5)
	MeshFactory.box(self, Vector3(0.06, 0.8, 1.9), m + Vector3(-3.37, 2.2, 0), Color("4a6a86"), 0.3, 0.5)
	var drum := MeshFactory.cylinder(self, 1.1, 3.8, m + Vector3(1.2, 2.4, 0), Color("d8d2c8"), 0.0)
	drum.rotation_degrees.z = 72
	var band := MeshFactory.cylinder(self, 1.13, 0.5, m + Vector3(1.0, 2.35, 0), Color("c8541f"), 0.0)
	band.rotation_degrees.z = 72
	var band_b := MeshFactory.cylinder(self, 1.13, 0.5, m + Vector3(2.3, 2.75, 0), Color("c8541f"), 0.0)
	band_b.rotation_degrees.z = 72
	MeshFactory.label(self, "KUZEY HAFRİYAT", m + Vector3(1.4, 1.35, 1.16), Color("1a1a1a"), 0.42)
	var lamp := SpotLight3D.new()
	lamp.position = m + Vector3(-3.45, 1.4, 0.6)
	lamp.rotation_degrees = Vector3(-8, -90, 0)
	lamp.light_color = Color("ffe9b8")
	lamp.light_energy = 2.5
	lamp.spot_range = 10.0
	lamp.spot_angle = 30.0
	lamp.shadow_enabled = false
	add_child(lamp)
	for i in 3:
		for j in 2:
			MeshFactory.box(self, Vector3(0.9, 0.5, 0.9), Vector3(13 + i * 1.0, 0.25 + j * 0.5, 4.5), Color("9a9490"), 0.95)
	var bundle := Vector3(-11, 0.08, 1.5)
	for i in 7:
		var bar := MeshFactory.cylinder(self, 0.02, 6.0, bundle + Vector3(0, (i % 2) * 0.04, (i - 3) * 0.05), RUST)
		bar.rotation_degrees.z = 90
	var barrow := MeshFactory.box(self, Vector3(0.7, 0.35, 1.0), Vector3(11.5, 0.5, 8.0), Color("1f3a2a"), 0.6)
	barrow.rotation_degrees.y = 30


func _container() -> void:
	var c := Vector3(9.5, 0, 1.0)
	_block(c + Vector3(0, 0, -0.35), Vector2(6.0, 1.9), 0.0, 3.0)
	_block(c + Vector3(-2.95, 0, 0), Vector2(0.3, 2.6), 0.0, 3.0)
	_block(c + Vector3(2.95, 0, 0), Vector2(0.3, 2.6), 0.0, 3.0)
	MeshFactory.box(self, Vector3(6.0, 0.25, 2.6), c + Vector3(0, 0.3, 0), Color("1f4a63"), 0.7)
	MeshFactory.block(self, Vector3(6.0, 2.5, 0.1), c + Vector3(0, 1.65, -1.25), Color("2a6180"), 0.7)
	MeshFactory.block(self, Vector3(0.1, 2.5, 2.6), c + Vector3(-2.95, 1.65, 0), Color("255a77"), 0.7)
	MeshFactory.block(self, Vector3(0.1, 2.5, 2.6), c + Vector3(2.95, 1.65, 0), Color("255a77"), 0.7)
	MeshFactory.box(self, Vector3(6.2, 0.12, 2.8), c + Vector3(0, 2.95, 0), Color("1a3f55"), 0.7)
	for i in 9:
		MeshFactory.box(self, Vector3(0.08, 2.4, 0.04), c + Vector3(-2.7 + i * 0.68, 1.65, -1.31), Color("1c4a63"), 0.7)
	MeshFactory.box(self, Vector3(0.9, 0.5, 0.4), c + Vector3(-2.0, 2.3, -1.5), Color("c9c2b4"), 0.5)
	MeshFactory.box(self, Vector3(1.4, 0.3, 0.9), c + Vector3(0, 0.15, 1.75), STEEL, 0.5)
	MeshFactory.box(self, Vector3(0.5, 0.9, 0.04), c + Vector3(3.0, 1.8, 1.15), Color("f4efe4"))
	MeshFactory.label(self, "ŞANTİYE ŞEFLİĞİ", c + Vector3(0.0, 3.35, 1.1), Color("e7e1d6"), 0.55)
	var glow := OmniLight3D.new()
	glow.position = c + Vector3(0, 2.6, 0.2)
	glow.light_color = Color("ffd98a")
	glow.light_energy = 2.4
	glow.omni_range = 5.5
	glow.shadow_enabled = false
	add_child(glow)
	MeshFactory.box(self, Vector3(1.2, 0.08, 0.3), c + Vector3(0, 2.86, 0.2), Color("fff1c8"), 0.3, 1.2)
	MeshFactory.box(self, Vector3(2.0, 0.08, 0.9), c + Vector3(0, 0.95, -0.4), Color("6b4a32"), 0.7)
	for leg in [Vector3(-0.9, 0.65, -0.8), Vector3(0.9, 0.65, -0.8), Vector3(-0.9, 0.65, 0.0), Vector3(0.9, 0.65, 0.0)]:
		MeshFactory.box(self, Vector3(0.06, 0.6, 0.06), c + leg, STEEL, 0.4)
	MeshFactory.box(self, Vector3(0.46, 0.46, 0.46), c + Vector3(-1.1, 0.65, -0.3), Color("2a2a2a"), 0.5)
	MeshFactory.box(self, Vector3(0.9, 0.2, 0.5), c + Vector3(-0.5, 1.05, -0.45), Color("d8d2c8"))
	MeshFactory.cylinder(self, 0.07, 0.14, c + Vector3(0.55, 1.07, -0.3), Color("111111"))
	MeshFactory.box(self, Vector3(0.09, 0.09, 0.012), c + Vector3(0.55, 1.08, -0.225), Color("f4efe4"))
	MeshFactory.box(self, Vector3(0.09, 0.012, 0.09), c + Vector3(0.55, 1.14, -0.3), Color("f4efe4"))
	MeshFactory.box(self, Vector3(0.68, 0.5, 0.03), c + Vector3(-0.4, 1.85, -1.18), Color("f4efe4"))
	MeshFactory.box(self, Vector3(0.68, 0.14, 0.032), c + Vector3(-0.4, 2.03, -1.18), Color("2a2a2a"))
	MeshFactory.label(self, "MART", c + Vector3(-0.4, 2.03, -1.15), Color("f4efe4"), 0.32)
	MeshFactory.box(self, Vector3(0.1, 0.1, 0.034), c + Vector3(-0.28, 1.72, -1.18), Color("9b1d1d"), 0.4)
	MeshFactory.label(self, "19", c + Vector3(-0.28, 1.72, -1.15), Color("f4efe4"), 0.28)
	MeshFactory.box(self, Vector3(0.34, 0.24, 0.012), c + Vector3(0.1, 0.995, -0.1), Color("fff3a8"))
	var note := MeshFactory.label(self, "19.03", c + Vector3(0.1, 1.01, -0.1), Color("9b1d1d"), 0.42)
	note.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	note.rotation_degrees.x = -90
	var hat := MeshFactory.box(self, Vector3(0.36, 0.1, 0.32), c + Vector3(0.75, 1.04, -0.6), Color("f0c419"), 0.4)
	hat.rotation_degrees.y = 20
	_spot("hotspot_desk", MeshFactory.zone(self, Vector3(2.2, 0.5, 1.2), c + Vector3(0, 1.1, -0.4), Color(0, 0, 0, 0), "hotspot:hotspot_desk"),
		c + Vector3(0, 1.0, -0.4), c + Vector3(1.4, 0, 2.1), c + Vector3(-1.0, 1.8, 1.7), c + Vector3(0, 1.05, -0.5), c + Vector3(0, 2.3, -0.4), [Vector3(0.9, 1.0, 0.0)], "2")


func _column() -> void:
	var p := Vector3(-3.5, 0, -1.0)
	_block(p, Vector2(1.1, 1.1), 0.0, 4.0)
	_block(p + Vector3(-1.2, 0, 0.2), Vector2(1.1, 0.2), 0.0, 1.6)
	_block(p + Vector3(-1.75, 0, -0.35), Vector2(0.2, 1.1), 0.0, 1.6)
	MeshFactory.box(self, Vector3(1.0, 0.1, 1.0), p + Vector3(0, 0.05, 0), Color("6a5428"), 0.9)
	MeshFactory.box(self, Vector3(0.9, 4.0, 0.9), p + Vector3(0, 2.1, 0), CONCRETE, 0.85)
	MeshFactory.box(self, Vector3(0.5, 0.7, 0.3), p + Vector3(0.22, 1.5, 0.35), Color("4a4d50"), 0.95)
	for r in 3:
		MeshFactory.cylinder(self, 0.018, 0.9, p + Vector3(0.05 + r * 0.14, 1.5, 0.42), RUST)
	for seg in [[Vector3(-0.1, 2.3, 0.46), 28.0, 0.6], [Vector3(0.12, 1.9, 0.46), -35.0, 0.5], [Vector3(-0.05, 1.1, 0.46), 20.0, 0.7], [Vector3(0.25, 0.7, 0.46), -15.0, 0.4]]:
		var crack := MeshFactory.box(self, Vector3(0.025, seg[2], 0.02), p + seg[0], Color("151618"), 0.95)
		crack.rotation_degrees.z = seg[1]
	MeshFactory.box(self, Vector3(0.9, 0.1, 0.9), p + Vector3(0, 4.15, 0), CONCRETE_DARK, 0.9)
	MeshFactory.box(self, Vector3(1.1, 1.6, 0.06), p + Vector3(-1.2, 1.4, 0.2), Color("b89a5a"), 0.95)
	MeshFactory.box(self, Vector3(0.06, 1.6, 1.1), p + Vector3(-1.75, 1.4, -0.35), Color("b89a5a"), 0.95)
	for i in 4:
		MeshFactory.box(self, Vector3(0.1, 0.3, 0.1), p + Vector3(0.6 + (i % 2) * 0.25, 0.15, 0.7 + int(i / 2) * 0.25), CONCRETE_DARK, 0.95)
	_spot("hotspot_column", MeshFactory.zone(self, Vector3(1.0, 4.0, 1.0), p + Vector3(0, 2.1, 0), Color(0, 0, 0, 0), "hotspot:hotspot_column"),
		p + Vector3(0, 1.5, 0), p + Vector3(1.4, 0, 1.6), p + Vector3(-0.4, 2.6, 4.6), p + Vector3(0.1, 1.5, 0.3), p + Vector3(0, 4.6, 0), [Vector3(0.75, 0, 0.8)], "3")


func _body() -> void:
	var b := Vector3(0.2, 0, 3.2)
	_block(b + Vector3(0, 0, 0.2), Vector2(1.5, 2.6), 0.0, 0.4)
	var pool := MeshFactory.cylinder(self, 0.9, 0.012, b + Vector3(0, 0.005, 0.1), Color("2a0b0d"))
	pool.scale = Vector3(1.0, 1.0, 1.4)
	var pool_mat: StandardMaterial3D = pool.material_override
	pool_mat.roughness = 0.1
	for seg in [[Vector3(0, 0, 1.1), Vector3(0.5, 0.012, 0.05), 0.0], [Vector3(-0.25, 0, 0.75), Vector3(0.05, 0.012, 0.7), 0.0], [Vector3(0.25, 0, 0.75), Vector3(0.05, 0.012, 0.7), 0.0], [Vector3(0, 0, 0.4), Vector3(0.5, 0.012, 0.05), 0.0], [Vector3(-0.25, 0, -0.15), Vector3(0.05, 0.012, 1.1), 0.0], [Vector3(0.25, 0, -0.15), Vector3(0.05, 0.012, 1.1), 0.0], [Vector3(-0.5, 0, 0.1), Vector3(0.05, 0.012, 0.7), 20.0], [Vector3(0.55, 0, 0.0), Vector3(0.05, 0.012, 0.8), -30.0], [Vector3(0, 0, -0.7), Vector3(0.5, 0.012, 0.05), 0.0]]:
		var line := MeshFactory.box(self, seg[1], b + seg[0] + Vector3(0, 0.02, 0), Color("f2f2f2"), 0.9)
		line.rotation_degrees.y = seg[2]
	var ring := MeshFactory.cylinder(self, 0.28, 0.012, b + Vector3(0, 0.02, 1.3), Color("f2f2f2"))
	ring.scale = Vector3(1, 1, 1)
	MeshFactory.cylinder(self, 0.22, 0.014, b + Vector3(0, 0.021, 1.3), Color("2a0b0d"))
	var phone := MeshFactory.box(self, Vector3(0.16, 0.02, 0.32), b + Vector3(0.95, 0.03, 0.6), Color("111111"), 0.3)
	phone.rotation_degrees.y = -35
	var screen := MeshFactory.box(self, Vector3(0.13, 0.006, 0.27), b + Vector3(0.95, 0.045, 0.6), Color("1e2f55"), 0.1, 0.9)
	screen.rotation_degrees.y = -35
	for i in 3:
		var crack := MeshFactory.box(self, Vector3(0.006, 0.004, 0.2), b + Vector3(0.93 + i * 0.025, 0.05, 0.58), Color("e7f3ff"), 0.2, 1.2)
		crack.rotation_degrees.y = -35 + i * 24
	MeshFactory.box(self, Vector3(0.25, 0.01, 0.35), b + Vector3(-0.9, 0.03, -0.4), Color("f4efe4"))
	MeshFactory.box(self, Vector3(0.22, 0.02, 0.03), b + Vector3(-0.9, 0.035, -0.55), Color("DC2626"))
	_spot("hotspot_phone", MeshFactory.zone(self, Vector3(2.6, 0.6, 3.0), b + Vector3(0.2, 0.3, 0.4), Color(0, 0, 0, 0), "hotspot:hotspot_phone"),
		b + Vector3(0.4, 0.2, 0.5), b + Vector3(1.7, 0, 1.8), b + Vector3(-1.8, 2.3, 3.4), b + Vector3(0.5, 0.1, 0.5), b + Vector3(0.5, 1.4, 0.5), [Vector3(1.3, 0, 0.3), Vector3(-0.6, 0, 1.5)], "1")


func _tracks() -> void:
	var t := Vector3(5.2, 0, 8.5)
	for lane in [-0.95, 0.95]:
		for i in 16:
			var z := -3.0 + i * 0.4
			var tread := MeshFactory.box(self, Vector3(0.42, 0.03, 0.22), t + Vector3(lane + sin(z * 0.5) * 0.3, 0.0, z), Color("17120c"), 0.6)
			tread.rotation_degrees.y = 12 * cos(z * 0.5)
			MeshFactory.box(self, Vector3(0.44, 0.028, 0.06), t + Vector3(lane + sin(z * 0.5) * 0.3, 0.012, z + 0.14), Color("3a3024"), 0.6)
	var wet := MeshFactory.cylinder(self, 0.5, 0.006, t + Vector3(0.0, 0.004, 0.6), Color("16202c"))
	wet.scale = Vector3(1.4, 1, 3.2)
	var wet_mat: StandardMaterial3D = wet.material_override
	wet_mat.roughness = 0.05
	wet_mat.metallic = 0.3
	var pole := Vector3(8.0, 0, 6.2)
	_block(pole, Vector2(0.3, 0.3), 0.0, 4.6)
	MeshFactory.cylinder(self, 0.06, 4.6, pole + Vector3(0, 2.3, 0), STEEL)
	MeshFactory.box(self, Vector3(0.3, 0.18, 0.5), pole + Vector3(-0.2, 4.4, 0.2), Color("d8d2c8"), 0.4)
	MeshFactory.sphere(self, 0.03, pole + Vector3(-0.2, 4.4, 0.47), Color("DC2626"), 2.0)
	MeshFactory.box(self, Vector3(0.6, 0.4, 0.03), pole + Vector3(0, 2.4, 0.05), Color("f4efe4"))
	MeshFactory.label(self, "06 ANK 19" if false else "KAMERA 03", pole + Vector3(0, 2.4, 0.08), Color("1a1a1a"), 0.3)
	var cam := SpotLight3D.new()
	cam.position = pole + Vector3(-0.2, 4.3, 0.3)
	cam.rotation_degrees = Vector3(-50, -30, 0)
	cam.light_color = Color("b8d8ff")
	cam.light_energy = 1.4
	cam.spot_range = 9.0
	cam.spot_angle = 26.0
	cam.shadow_enabled = false
	add_child(cam)
	_spot("hotspot_suv", MeshFactory.zone(self, Vector3(3.2, 0.5, 6.4), t + Vector3(0, 0.25, 0), Color(0, 0, 0, 0), "hotspot:hotspot_suv"),
		t + Vector3(0, 0.1, 0), t + Vector3(-2.0, 0, 1.2), t + Vector3(3.4, 3.2, 3.4), t + Vector3(0.2, 0.05, -0.4), t + Vector3(0, 1.3, 0), [Vector3(-1.5, 0, -0.8)], "4")


func _more() -> void:
	var p := Vector3(-3.5, 0, -1.0)
	for i in 5:
		var bar := MeshFactory.cylinder(self, 0.012, 0.85, p + Vector3(1.7, 0.08, 0.15 + i * 0.06), Color("8a5a32"))
		bar.rotation_degrees.z = 80 + i * 4
	MeshFactory.box(self, Vector3(0.22, 0.04, 0.14), p + Vector3(1.85, 0.06, 0.35), Color("c9a24a"), 0.35)
	MeshFactory.label(self, "KESİK", p + Vector3(1.85, 0.35, 0.35), Color("f4efe4"), 0.16)
	_spot("hotspot_rebar", MeshFactory.zone(self, Vector3(1.1, 0.6, 1.0), p + Vector3(1.8, 0.3, 0.3), Color(0, 0, 0, 0), "hotspot:hotspot_rebar"),
		p + Vector3(1.8, 0.1, 0.3), p + Vector3(1.4, 0, 1.6), p + Vector3(2.6, 1.5, 1.8), p + Vector3(1.8, 0.1, 0.3), p + Vector3(1.8, 0.7, 0.3), [Vector3(0.4, 0, 0.5)], "5")
	var c := Vector3(9.5, 0, 1.0)
	MeshFactory.box(self, Vector3(0.28, 0.04, 0.38), c + Vector3(1.15, 0.55, 0.85), Color("6b4428"), 0.7)
	MeshFactory.box(self, Vector3(0.24, 0.012, 0.32), c + Vector3(1.15, 0.58, 0.85), Color("efe6d6"))
	MeshFactory.label(self, "NÖBET", c + Vector3(1.15, 0.85, 0.85), Color("f4efe4"), 0.16)
	_spot("hotspot_log", MeshFactory.zone(self, Vector3(0.8, 0.7, 0.8), c + Vector3(1.15, 0.5, 0.85), Color(0, 0, 0, 0), "hotspot:hotspot_log"),
		c + Vector3(1.15, 0.4, 0.85), c + Vector3(1.4, 0, 2.1), c + Vector3(2.2, 1.6, 2.0), c + Vector3(1.15, 0.55, 0.85), c + Vector3(1.15, 1.0, 0.85), [Vector3(0.5, 0, 0.4)], "6")


## Çevre detayları (görsel + çarpışma). Yürüme alanı dışındakiler yalnızca arka plandır.
func details() -> void:

	var bld := [["commercial", "building-a"], ["commercial", "building-skyscraper-a"], ["commercial", "building-d"], ["commercial", "building-skyscraper-b"], ["commercial", "building-f"], ["commercial", "building-skyscraper-c"], ["commercial", "building-g"], ["commercial", "building-b"]]
	skyline(bld, -52.0, 52.0, -34.0, 12.0)
	for i in 6:
		city("commercial", ["building-h", "building-c", "building-e"][i % 3], Vector3(-36.0, 0.0, -8.0 + i * 8.0), 90.0, 10.0, false)
		city("commercial", ["building-b", "building-a", "building-g"][i % 3], Vector3(36.0, 0.0, -8.0 + i * 8.0), -90.0, 10.0, false)
	# Şantiye çiti: yürüme alanının hemen dışında, çarpışmalı
	for i in 12:
		city("roads", "construction-fence", Vector3(-14.0 + i * 3.04, 0.0, 16.8), 90.0, 8.0, true)
	for i in 8:
		city("roads", "construction-fence", Vector3(-15.1, 0.0, -6.5 + i * 3.04), 0.0, 8.0, true)
		city("roads", "construction-fence", Vector3(19.9, 0.0, -6.5 + i * 3.04), 0.0, 8.0, true)
	# Sokak: yol, kaldırım, lambalar
	road(-48.0, 48.0, 26.0)
	sidewalk(-48.0, 48.0, 20.2, 3.0)
	for i in 9:
		street_lamp(Vector3(-44.0 + i * 11.0, 0.0, 19.2), 180.0, i % 2 == 0)
	for x in [-20.0, 24.0]:
		city("suburban", "tree-large", Vector3(x, 0.0, 19.4), 0.0, 10.0, false)
	city("roads", "dumpster", Vector3(-17.5, 0.0, 19.4), 90.0, 5.0, false)
	# Şantiye eşyaları (çarpışmalı)
	solid_box(Vector3(17.2, 0, 12.0), Vector3(1.5, 2.4, 1.5), Color("2a5a8a"), 0.0)
	MeshFactory.box(self, Vector3(1.6, 0.12, 1.6), Vector3(17.2, 2.46, 12.0), Color("d8d2c8"), 0.6)
	solid_box(Vector3(-12.7, 0, -2.6), Vector3(1.2, 1.0, 1.2), Color("9a7a52"), 12.0)
	for i in 3:
		MeshFactory.box(self, Vector3(1.2, 0.08, 1.2), Vector3(-12.7, 0.12 + i * 0.3, -2.6), Color("7a6040"), 0.9).rotation_degrees.y = 12
	var drum := MeshFactory.cylinder(self, 0.7, 0.5, Vector3(-12.4, 0.25, 9.5), Color("a67c4a"))
	drum.rotation_degrees.x = 0
	_block(Vector3(-12.4, 0, 9.5), Vector2(1.4, 1.4), 0.0, 0.6)
	for i in 3:
		solid_box(Vector3(14.0 + i * 1.7, 0, 12.8), Vector3(1.5, 0.8, 0.5), Color("a8a49c"), 0.0, 0.95)
	for p in [Vector3(1.5, 0, 14.2), Vector3(2.6, 0, 14.7), Vector3(3.7, 0, 15.1), Vector3(-6.2, 0, 8.4)]:
		city("roads", "construction-cone", p, 0.0, 8.0, false)
	for p in [Vector3(-14.3, 0, 16.1), Vector3(18.8, 0, 16.1), Vector3(18.8, 0, -7.0)]:
		city("roads", "construction-light", p, 0.0, 9.0, false)
		var warn := OmniLight3D.new()
		warn.position = p + Vector3(0, 2.0, 0)
		warn.light_color = AMBER
		warn.light_energy = 0.8
		warn.omni_range = 4.0
		warn.shadow_enabled = false
		add_child(warn)
