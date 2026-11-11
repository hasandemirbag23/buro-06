extends "res://scenes/sets/set_base.gd"
## Ulus zabıta otoparkı. Çekici sırası, nöbet kulübesi, mühür masası.


func build() -> void:
	_yard()
	_van()
	_seal()
	_file()
	_log()
	_gate()


func _yard() -> void:
	solid_box(Vector3(-1.0, 0, 0.2), Vector3(16.0, 2.4, 0.2), Color("3a4044"))
	solid_box(Vector3(-8.6, 0, 4.6), Vector3(0.2, 2.4, 9.0), Color("3a4044"))
	solid_box(Vector3(7.2, 0, 4.6), Vector3(0.2, 2.4, 9.0), Color("3a4044"))
	solid_box(Vector3(-5.2, 0, 8.7), Vector3(6.6, 1.3, 0.16), Color("c9a24a"))
	solid_box(Vector3(5.6, 0, 8.7), Vector3(3.0, 1.3, 0.16), Color("c9a24a"))
	MeshFactory.box(self, Vector3(14.0, 0.05, 8.0), Vector3(-0.6, 0.03, 4.4), Color("4a463c"), 0.95)
	MeshFactory.label(self, "ZABITA OTOPARKI", Vector3(-2.0, 2.3, 8.9), Color("1a1408"), 0.4)
	var lamp := OmniLight3D.new()
	lamp.position = Vector3(0.5, 3.2, 5.0)
	lamp.light_color = Color("ffe3b0")
	lamp.light_energy = 1.6
	lamp.omni_range = 12.0
	lamp.shadow_enabled = false
	add_child(lamp)
	for i in 3:
		MeshFactory.box(self, Vector3(1.8, 0.7, 0.9), Vector3(-6.2 + i * 2.2, 0.4, 1.4), Color("2a3138"), 0.6)
		MeshFactory.box(self, Vector3(0.5, 0.35, 0.5), Vector3(-6.2 + i * 2.2, 0.9, 1.4), Color("6a5428"), 0.7)


func _van() -> void:
	var v := Vector3(3.6, 0, 3.6)
	solid_box(v, Vector3(2.1, 1.5, 4.2), Color("e7e4dc"))
	# Kemal Sönmez vanın yanında, branda altında.
	body_tarp(Vector3(1.55, 0, 2.7), 90.0)
	MeshFactory.box(self, Vector3(1.5, 0.7, 0.06), v + Vector3(0, 1.15, 1.9), Color("8aa4c8"), 0.2)
	MeshFactory.box(self, Vector3(0.7, 0.35, 0.08), v + Vector3(0, 0.7, 2.12), Color("1a3a6a"), 0.4)
	MeshFactory.label(self, "06 ZBT 09", v + Vector3(0, 1.7, 2.2), Color("1a1408"), 0.22)
	var phone := MeshFactory.box(self, Vector3(0.16, 0.03, 0.28), v + Vector3(0.45, 1.15, 1.55), Color("111111"), 0.3)
	phone.rotation_degrees.y = 20
	_spot("hotspot_van", MeshFactory.zone(self, Vector3(2.4, 1.4, 2.0), v + Vector3(0.4, 0.8, 1.6), Color(0, 0, 0, 0), "hotspot:hotspot_van"),
		v + Vector3(0.4, 1.0, 1.5), Vector3(1.0, 0, 6.6), Vector3(0.2, 1.8, 7.6), v + Vector3(0.45, 1.2, 1.5), v + Vector3(0.2, 1.8, 1.2), [Vector3(-0.8, 0, 1.6)], "1")


func _seal() -> void:
	var s := Vector3(0.4, 0, 5.0)
	MeshFactory.cylinder(self, 0.08, 0.05, s + Vector3(0, 0.04, 0), Color("c9a24a"))
	MeshFactory.cylinder(self, 0.035, 0.12, s + Vector3(0, 0.12, 0), Color("6a5430"))
	MeshFactory.label(self, "0671", s + Vector3(0.25, 0.2, 0), Color("1a1408"), 0.16)
	_spot("hotspot_seal", MeshFactory.zone(self, Vector3(1.1, 0.6, 1.1), s + Vector3(0, 0.2, 0), Color(0, 0, 0, 0), "hotspot:hotspot_seal"),
		s, Vector3(0.6, 0, 6.5), Vector3(-1.4, 1.5, 7.4), s + Vector3(0, 0.05, 0), s + Vector3(0, 0.8, 0), [Vector3(0.45, 0, 0.25)], "2")


func _file() -> void:
	var f := Vector3(4.5, 0, 2.2)
	MeshFactory.box(self, Vector3(0.32, 0.06, 0.24), f + Vector3(0, 0.2, 0), Color("8c2f2f"), 0.6)
	MeshFactory.label(self, "DOSYA", f + Vector3(0, 0.32, 0.05), Color("f4efe4"), 0.16)
	_spot("hotspot_file", MeshFactory.zone(self, Vector3(1.2, 0.8, 1.2), f + Vector3(0, 0.3, 0.3), Color(0, 0, 0, 0), "hotspot:hotspot_file"),
		f, Vector3(1.6, 0, 4.4), Vector3(0.2, 1.6, 5.8), f + Vector3(0, 0.15, 0), f + Vector3(0, 0.7, 0), [Vector3(-1.2, 0, 0.8)], "3")


func _log() -> void:
	var k := Vector3(-6.4, 0, 5.4)
	solid_box(k, Vector3(1.6, 1.1, 1.2), Color("5a4030"))
	MeshFactory.box(self, Vector3(0.34, 0.04, 0.24), k + Vector3(0.2, 1.14, 0.35), Color("e7d7b1"), 0.8)
	MeshFactory.label(self, "NÖBET", k + Vector3(0, 1.55, 0.5), Color("1a1408"), 0.2)
	_spot("hotspot_log", MeshFactory.zone(self, Vector3(1.8, 1.3, 1.4), k + Vector3(0.4, 0.7, 0.6), Color(0, 0, 0, 0), "hotspot:hotspot_log"),
		k + Vector3(0.3, 1.0, 0.4), Vector3(-4.6, 0, 5.6), Vector3(-3.2, 1.6, 7.0), k + Vector3(0.2, 1.15, 0.35), k + Vector3(0.1, 1.6, 0.2), [Vector3(0.7, 0, 0.3)], "4")


func _gate() -> void:
	var g := Vector3(1.6, 0, 8.2)
	MeshFactory.box(self, Vector3(0.08, 0.9, 0.5), g + Vector3(0, 0.5, 0), Color("f4efe4"), 0.5)
	MeshFactory.label(self, "Y. BEKLİYOR", g + Vector3(0.15, 0.7, 0.08), Color("1a1408"), 0.14)
	_spot("hotspot_ticket", MeshFactory.zone(self, Vector3(1.0, 1.2, 0.8), g + Vector3(0.1, 0.5, 0.2), Color(0, 0, 0, 0), "hotspot:hotspot_ticket"),
		g, Vector3(1.6, 0, 6.8), Vector3(3.4, 1.5, 7.6), g + Vector3(0, 0.4, 0.1), g + Vector3(0, 1.1, 0), [Vector3(0.4, 0, -0.3)], "5")


func details() -> void:
	skyline([["commercial", "building-c"], ["commercial", "building-b"], ["suburban", "building-type-c"]], -20.0, 24.0, -18.0, 16.0)
	road(-22.0, 24.0, 13.0)
	sidewalk(-16.0, 18.0, 10.2, 2.2)
	street_lamp(Vector3(-7.5, 0, 10.6), 0.0)
	street_lamp(Vector3(8.5, 0, 10.6), 0.0)
	MeshFactory.label(self, "ULUS", Vector3(6.2, 2.4, 10.4), Color("e7e1d6"), 0.4)
	for row in 6:
		for col in 6:
			var on := (row * 2 + col) % 4 != 0
			var tint := Color("e7c98a") if on else Color("242a32")
			MeshFactory.box(host, Vector3(1.3, 1.5, 0.08), Vector3(-10.0 + col * 3.4, 2.0 + row * 2.0, -7.2), tint, 0.5, 0.6 if on else 0.0)
