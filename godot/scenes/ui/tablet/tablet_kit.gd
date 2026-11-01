extends RefCounted

const UiStyle := preload("res://scenes/ui_style.gd")

const BG := Color("0c0d10")
const CARD := Color("1b1e24")
const LINE := Color("2c313a")


static func box(bg: Color, border: Color, radius := 10, width := 1, margin := 12) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(width)
	style.set_corner_radius_all(radius)
	style.corner_detail = 8
	style.set_content_margin_all(margin)
	style.anti_aliasing = true
	return style


static func panel(bg: Color, border: Color, radius := 10) -> PanelContainer:
	var node := PanelContainer.new()
	node.add_theme_stylebox_override("panel", box(bg, border, radius))
	return node


static func fill(node: Control) -> void:
	node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	node.size_flags_vertical = Control.SIZE_EXPAND_FILL


static func cover(node: Control) -> void:
	node.set_anchors_preset(Control.PRESET_FULL_RECT)
	node.offset_left = 0
	node.offset_top = 0
	node.offset_right = 0
	node.offset_bottom = 0


static func scroll(content: Control) -> ScrollContainer:
	var node := ScrollContainer.new()
	node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	node.size_flags_vertical = Control.SIZE_EXPAND_FILL
	node.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	node.add_child(content)
	return node


static func line(text: String, size := 15, color: Color = UiStyle.INK, mono := false) -> Label:
	var label := UiStyle.label(text, size, color, mono)
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	return label
