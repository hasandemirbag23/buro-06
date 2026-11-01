extends Control

## BÜRO-OS ana ekranı: dosya numarası, kanıt sayısı, uygulama ikonları.

const Kit := preload("res://scenes/ui/tablet/tablet_kit.gd")
const UiStyle := preload("res://scenes/ui_style.gd")

var stamp := ""


func render() -> void:
	var next := "%s|%d|%d|%s|%s" % [Scenario.case_id, GameState.clues.size(), GameState.inspected.size(), GameState.arrest_unlocked(), GameState.phone_ready()]
	if next == stamp and get_child_count() > 0:
		return
	stamp = next
	for child in get_children():
		child.queue_free()
	var column := VBoxContainer.new()
	Kit.cover(column)
	column.add_theme_constant_override("separation", 14)
	add_child(column)
	column.add_child(Kit.line("AKTİF DOSYA", 12, UiStyle.MUTED, true))
	column.add_child(UiStyle.label(Scenario.file_label(), 26, UiStyle.LAMP))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	column.add_child(row)
	row.add_child(_stat("KANIT", str(GameState.clues.size()), UiStyle.CRT))
	row.add_child(_stat("İNCELEME", str(GameState.inspected.size()), UiStyle.INK))
	row.add_child(_stat("SORGU", "açık" if GameState.arrest_unlocked() else "kilitli", UiStyle.LAMP if GameState.arrest_unlocked() else UiStyle.DANGER))
	var grid := GridContainer.new()
	grid.columns = 2 if get_viewport_rect().size.x < 860 else 5
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	column.add_child(grid)
	_icon(grid, "BC", "BüroChat", "chat", UiStyle.CRT, false)
	_icon(grid, "ES", "E-Sorgu", "esorgu", UiStyle.CRT, false)
	_icon(grid, "TF", "Maktulün\nTelefonu", "phone", UiStyle.LAMP, not GameState.phone_ready())
	_icon(grid, "KP", "Kanıt Panosu", "board", UiStyle.LAMP, false)
	_icon(grid, "DS", "Dosyalar", "files", UiStyle.INK, false)


func _stat(title: String, value: String, color: Color) -> Control:
	var card := Kit.panel(Kit.CARD, Kit.LINE, 10)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var column := VBoxContainer.new()
	card.add_child(column)
	column.add_child(Kit.line(title, 11, UiStyle.MUTED, true))
	column.add_child(Kit.line(value, 22, color, true))
	return card


func _icon(grid: GridContainer, mark: String, title: String, app: String, color: Color, locked: bool) -> void:
	var button := Button.new()
	button.text = mark + "\n" + title + ("\nkilitli" if locked else "")
	button.custom_minimum_size = Vector2(120, 96)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.add_theme_font_size_override("font_size", 15)
	button.add_theme_color_override("font_color", UiStyle.MUTED if locked else color)
	var normal := Kit.box(Kit.CARD, color if not locked else Kit.LINE, 14, 1, 8)
	var hover := Kit.box(Color("242833"), color, 14, 1, 8)
	hover.shadow_color = Color(color, 0.45)
	hover.shadow_size = 10
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", Kit.box(Color("101216"), color, 14, 1, 8))
	button.pressed.connect(func() -> void:
		if app == "phone" and not GameState.phone_ready():
			GameState.notice = "Telefon olay yerinde. Cesedin yanındaki cihaz poşete girmeden açılmaz."
			GameState.updated.emit()
			return
		GameState.open_tablet(app)
	)
	grid.add_child(button)
