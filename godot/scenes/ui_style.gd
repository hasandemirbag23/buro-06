extends RefCounted

const THEME: Theme = preload("res://theme/buro_theme.tres")
const TYPEWRITER := preload("res://scenes/ui/typewriter.gd")

const NIGHT := Color("0c1016")
const RAISED := Color("14171D")
const INK := Color("efe6d6")
const MUTED := Color("9a9184")
const LAMP := Color("F59E0B")
const PAPER := Color("e7d7b1")
const PAPER_INK := Color("efe6d6")
const CRT := Color("b6f5a8")
const DANGER := Color("DC2626")
const CORK := Color("F59E0B")
const BLOOD := Color("DC2626")

static var _fonts_ready := false
static var sans: Font
static var mono: Font


static func theme() -> Theme:
	_bind_fallbacks()
	return THEME


static func _bind_fallbacks() -> void:
	if _fonts_ready:
		return
	_fonts_ready = true
	sans = load("res://theme/fonts/IBMPlexSans-Regular.ttf")
	var medium: Font = load("res://theme/fonts/IBMPlexSans-Medium.ttf")
	mono = load("res://theme/fonts/SpaceMono-Regular.ttf")
	medium.fallbacks = [sans]
	mono.fallbacks = [sans]


static func label(text: String, size := 16, color: Color = INK, use_mono := false) -> Label:
	var node := Label.new()
	_paint(node, size, color, use_mono)
	node.text = text
	return node


static func typed(text: String, size := 16, color: Color = INK, use_mono := false) -> Label:
	var node = TYPEWRITER.new()
	_paint(node, size, color, use_mono)
	node.play(text)
	return node


static func button(text: String) -> Button:
	var node := Button.new()
	node.text = text
	node.custom_minimum_size = Vector2(0, 42)
	return node


static func _paint(node: Label, size: int, color: Color, use_mono: bool) -> void:
	node.add_theme_font_size_override("font_size", size)
	node.add_theme_color_override("font_color", color)
	_bind_fallbacks()
	node.add_theme_font_override("font", mono if use_mono else sans)
	node.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
