extends Node
## Menü sahnesi ekran görüntüsü: godot --path . res://tools/menu_shot.tscn [-- window|desk|board|computer|skyline] -> /tmp/menu_<n>.png
const Stage := preload("res://scenes/menu_stage.gd")
const VIEWS := {
	"window": [Vector3(-1.2, 1.7, 0.8), Vector3(-1.55, 1.8, -3.2)],
	"desk": [Vector3(1.3, 1.5, 0.4), Vector3(1.1, 1.0, -1.8)],
	"board": [Vector3(2.4, 1.8, 0.2), Vector3(2.5, 1.7, -3.2)],
	"computer": [Vector3(-1.3, 1.5, 0.2), Vector3(-1.5, 1.1, -1.9)],
	"skyline": [Vector3(-1.55, 1.85, -3.5), Vector3(-1.55, 2.6, -40.0)],
}

func _ready() -> void:
	var stage := Stage.new()
	add_child(stage)
	stage.set("_intro", 0.35)
	stage.set("drift", false)
	if OS.get_cmdline_user_args().is_empty():
		var menu = load("res://scenes/main_menu.gd").new()
		add_child(menu)
		menu.visible = true
		menu._show("home")
	var args := OS.get_cmdline_user_args()
	if args.size() > 0 and VIEWS.has(args[0]):
		for i in 8:
			await get_tree().process_frame
		var cam: Camera3D = stage.get("camera")
		cam.position = VIEWS[args[0]][0]
		cam.look_at(VIEWS[args[0]][1])
		cam.fov = 42.0
		cam.attributes = null
	for n in 2:
		for i in 40:
			await get_tree().process_frame
		get_viewport().get_texture().get_image().save_png("/tmp/menu_%d.png" % n)
	get_tree().quit()
