extends Label

var _full := ""
var _count := 0.0
var speed := 46.0


func play(next: String) -> void:
	if next == _full:
		return
	_full = next
	_count = 0.0
	speed = 120.0 if next.length() > 220 else 64.0
	text = next
	visible_characters = 0 if next != "" else -1
	set_process(next != "")


func is_typing() -> bool:
	return is_processing()


func finish() -> void:
	visible_characters = -1
	set_process(false)


func _process(delta: float) -> void:
	_count += speed * delta
	var shown := mini(_full.length(), int(_count))
	visible_characters = shown
	if shown >= _full.length():
		visible_characters = -1
		set_process(false)
