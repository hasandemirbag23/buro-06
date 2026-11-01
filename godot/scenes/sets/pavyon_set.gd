extends "res://scenes/sets/set_base.gd"
## Geceler Gazinosu arka otoparkı.


func build() -> void:
	club()
	_more()


func club() -> void:
	var club := Vector3(-8.0, 0, -8.0)
	_block(club, Vector2(14, 8), 0.0, 6.0)
	MeshFactory.box(self, Vector3(14, 6, 8), club + Vector3(0, 3, 0), Color("1a1218"), 0.7)
	MeshFactory.box(self, Vector3(8, 1.2, 0.12), club + Vector3(0, 4.6, 4.06), Color("14080c"))
	MeshFactory.label(self, "GECELER", club + Vector3(0, 4.6, 4.2), Color("ff4d6d"), 0.7)
	var neon := OmniLight3D.new()
	neon.position = club + Vector3(0, 3.2, 5.2)
	neon.light_color = Color("ff3355")
	neon.light_energy = 2.4
	neon.omni_range = 14.0
	neon.shadow_enabled = false
	add_child(neon)
	var gold := OmniLight3D.new()
	gold.position = Vector3(2.0, 3.0, 1.0)
	gold.light_color = Color("e6b450")
	gold.light_energy = 1.2
	gold.omni_range = 8.0
	gold.shadow_enabled = false
	add_child(gold)
	for i in 5:
		var pane := Color("ff4d6d") if i % 2 == 0 else Color("f5d76e")
		MeshFactory.box(self, Vector3(1.4, 1.6, 0.08), club + Vector3(-4.0 + i * 2.0, 2.2, 4.08), pane, 0.3, 1.1)
	var car := Vector3(0.4, 0, 3.4)
	_block(car, Vector2(2.4, 4.6), 0.0, 1.5)
	MeshFactory.box(self, Vector3(2.4, 0.7, 4.6), car + Vector3(0, 0.45, 0), Color("1c1e24"), 0.35)
	MeshFactory.box(self, Vector3(2.1, 0.45, 1.6), car + Vector3(0, 1.05, -0.3), Color("141820"), 0.2)
	MeshFactory.box(self, Vector3(0.08, 0.7, 1.1), car + Vector3(-1.35, 0.55, 0.9), Color("2a2e36"), 0.4)
	MeshFactory.box(self, Vector3(0.55, 0.12, 0.9), car + Vector3(0.15, 0.72, 0.35), Color("6a2430"), 0.6)
	var phone := MeshFactory.box(self, Vector3(0.16, 0.03, 0.32), car + Vector3(0.55, 0.835, 0.55), Color("111111"), 0.3)
	phone.rotation_degrees.y = 18
	var screen_glow := MeshFactory.box(self, Vector3(0.13, 0.004, 0.27), car + Vector3(0.55, 0.853, 0.55), Color("4a74c8"), 0.1, 1.4)
	screen_glow.rotation_degrees.y = 18
	MeshFactory.box(self, Vector3(0.5, 0.02, 0.6), car + Vector3(0.45, 0.805, 0.5), Color("2a2e36"), 0.5)
	MeshFactory.label(self, "06 HL", car + Vector3(0, 1.35, 2.2), Color("f4efe4"), 0.28)
	_spot("hotspot_phone", MeshFactory.zone(self, Vector3(2.2, 1.2, 2.0), car + Vector3(0.4, 0.7, 0.4), Color(0, 0, 0, 0), "hotspot:hotspot_phone"),
		car + Vector3(0.5, 0.8, 0.5), car + Vector3(2.2, 0, 1.6), car + Vector3(-1.6, 2.4, 3.4), car + Vector3(0.55, 0.85, 0.55), car + Vector3(0.4, 1.6, 0.2), [Vector3(1.4, 0, 0.2)], "1")
	var nail := car + Vector3(1.5, 0, 1.3)
	MeshFactory.cylinder(self, 0.04, 0.02, nail + Vector3(0, 0.02, 0), Color("c9a24a"))
	MeshFactory.box(self, Vector3(0.08, 0.012, 0.22), nail + Vector3(0.2, 0.02, 0.1), Color("6a3a8a"))
	_spot("hotspot_column", MeshFactory.zone(self, Vector3(1.4, 0.6, 1.4), nail + Vector3(0, 0.3, 0), Color(0, 0, 0, 0), "hotspot:hotspot_column"),
		nail, nail + Vector3(1.2, 0, 1.2), nail + Vector3(-1.6, 1.8, 2.4), nail + Vector3(0, 0.05, 0), nail + Vector3(0, 0.6, 0), [Vector3(0.45, 0, 0.2)], "2")
	var bag_at := car + Vector3(-1.6, 0.16, -0.8)
	MeshFactory.box(self, Vector3(0.5, 0.3, 0.38), bag_at, Color("5a1828"), 0.45)
	var flap := MeshFactory.box(self, Vector3(0.5, 0.02, 0.3), bag_at + Vector3(0, 0.2, -0.26), Color("6a2034"), 0.45)
	flap.rotation_degrees.x = -50
	MeshFactory.box(self, Vector3(0.3, 0.012, 0.2), bag_at + Vector3(0.38, -0.14, 0.2), Color("d8c07a"))
	MeshFactory.box(self, Vector3(0.1, 0.012, 0.16), bag_at + Vector3(-0.3, -0.14, 0.35), Color("f4efe4"))
	MeshFactory.label(self, "VIP", bag_at + Vector3(0, 0.45, 0.1), Color("f5d76e"), 0.22)
	_spot("hotspot_desk", MeshFactory.zone(self, Vector3(1.4, 0.8, 1.2), bag_at + Vector3(0.1, 0.1, 0.1), Color(0, 0, 0, 0), "hotspot:hotspot_desk"),
		bag_at, car + Vector3(-2.3, 0, -0.2), car + Vector3(-3.5, 1.9, -2.6), bag_at + Vector3(0, 0.1, 0), bag_at + Vector3(0, 0.65, 0), [Vector3(-0.6, 0, -0.3)], "3")


func _more() -> void:
	var car := Vector3(0.4, 0, 3.4)
	var mirror := car + Vector3(-0.2, 0, -2.4)
	MeshFactory.box(self, Vector3(0.7, 0.9, 0.06), mirror + Vector3(0, 1.15, 0), Color("d8d2c8"), 0.25)
	MeshFactory.box(self, Vector3(0.62, 0.8, 0.02), mirror + Vector3(0, 1.15, 0.04), Color("8aa4c8"), 0.05)
	MeshFactory.label(self, "06-71", mirror + Vector3(0.05, 1.15, 0.08), Color("c43b55"), 0.18)
	_spot("hotspot_mirror", MeshFactory.zone(self, Vector3(1.0, 1.4, 0.6), mirror + Vector3(0, 0.8, 0.2), Color(0, 0, 0, 0), "hotspot:hotspot_mirror"),
		mirror + Vector3(0, 0.6, 0.3), car + Vector3(-2.3, 0, -0.2), mirror + Vector3(1.2, 1.6, 1.4), mirror, mirror + Vector3(0, 1.2, 0.1), [Vector3(0.45, 0, 0.3)], "4")
	var rack := Vector3(3.6, 0, 1.2)
	MeshFactory.box(self, Vector3(0.08, 1.5, 0.08), rack + Vector3(0, 0.75, 0), Color("2a2420"), 0.6)
	MeshFactory.box(self, Vector3(0.7, 0.06, 0.08), rack + Vector3(0.3, 1.45, 0), Color("2a2420"), 0.6)
	MeshFactory.box(self, Vector3(0.35, 0.7, 0.08), rack + Vector3(0.25, 1.05, 0.02), Color("1a120c"), 0.8)
	MeshFactory.box(self, Vector3(0.1, 0.06, 0.04), rack + Vector3(0.45, 0.7, 0.06), Color("f4efe4"))
	_spot("hotspot_ticket", MeshFactory.zone(self, Vector3(1.0, 1.6, 0.7), rack + Vector3(0.2, 0.7, 0.2), Color(0, 0, 0, 0), "hotspot:hotspot_ticket"),
		rack + Vector3(0.2, 0.5, 0.3), car + Vector3(2.2, 0, 1.6), rack + Vector3(1.3, 1.5, 1.5), rack + Vector3(0.3, 1.0, 0), rack + Vector3(0.2, 1.3, 0.1), [Vector3(0.4, 0, 0.35)], "5")


## Çevre detayları (görsel + çarpışma). Yürüme alanı dışındakiler yalnızca arka plandır.
func details() -> void:

	skyline([["commercial", "building-skyscraper-b"], ["commercial", "building-e"], ["commercial", "building-skyscraper-c"], ["commercial", "building-g"]], -52.0, 52.0, -26.0, 12.0)
	# Yan binalar
	city("commercial", "building-g", Vector3(10.5, 0.0, -9.0), 0.0, 10.0, false)
	city("commercial", "building-f", Vector3(21.0, 0.0, -9.0), 0.0, 10.0, false)
	city("commercial", "building-d", Vector3(-25.0, 0.0, -9.0), 0.0, 10.0, false)
	# Sokak, kaldırım, lambalar
	road(-48.0, 48.0, 25.0)
	sidewalk(-48.0, 48.0, 19.0, 3.4)
	for i in 9:
		street_lamp(Vector3(-44.0 + i * 11.0, 0.0, 17.8), 180.0, i % 2 == 0)
	for x in [-16.0, 16.0]:
		city("suburban", "tree-small", Vector3(x, 0.0, 17.6), 0.0, 9.0, false)
	# Otopark çizgileri
	for i in 7:
		MeshFactory.box(self, Vector3(0.1, 0.012, 3.0), Vector3(4.5 + i * 2.6, 0.012, 9.6), Color("d8d2c8"), 0.8)
	# Park halindeki araçlar (çarpışmalı)
	city("suburban", "tree-small", Vector3(13.2, 0.0, 12.5), 0.0, 6.0, false)
	local("res://assets/vehicles/sedan.glb", Vector3(8.4, 0, 3.6), 90.0, 1.55)
	local("res://assets/vehicles/sedan.glb", Vector3(11.2, 0, 8.0), 80.0, 1.55)
	local("res://assets/vehicles/sedan.glb", Vector3(-9.8, 0, 8.2), 100.0, 1.55)
	city("roads", "dumpster", Vector3(-11.6, 0.0, 0.8), 90.0, 5.0, true)
	# Giriş: kırmızı halı, kordon direkleri, ışıklı tabela
	MeshFactory.box(self, Vector3(2.2, 0.02, 3.0), Vector3(-8.0, 0.012, -2.2), Color("5a0f1e"), 0.9)
	for x in [-9.4, -6.6]:
		solid_box(Vector3(x, 0, -0.9), Vector3(0.3, 1.0, 0.3), Color("c9a24a"), 0.0, 0.4)
		MeshFactory.sphere(self, 0.08, Vector3(x, 1.06, -0.9), Color("c9a24a"), 0.2)
	MeshFactory.box(self, Vector3(2.8, 0.05, 0.05), Vector3(-8.0, 0.85, -0.9), Color("8a1c24"), 0.4)
	MeshFactory.box(self, Vector3(1.4, 2.4, 0.08), Vector3(-8.0, 1.2, -3.94), Color("14080c"), 0.6)
	var blue := OmniLight3D.new()
	blue.position = Vector3(-4.0, 3.2, -2.0)
	blue.light_color = Color("5a7aff")
	blue.light_energy = 1.4
	blue.omni_range = 9.0
	blue.shadow_enabled = false
	add_child(blue)
	solid_box(Vector3(-5.0, 0, -2.4), Vector3(0.5, 0.7, 0.5), Color("2a2e36"), 0.0)
	MeshFactory.sphere(self, 0.1, Vector3(-5.0, 0.76, -2.4), Color("ff8a3a"), 1.6)
	street_lamp(Vector3(11.5, 0.0, 1.5), -90.0, true, true)
	street_lamp(Vector3(-11.8, 0.0, 12.0), 90.0, true, true)
