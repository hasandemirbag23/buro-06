extends Control

## BüroChat: kişi listesi, balonlar, sesli mesaj, fotoğraf, yazıyor animasyonu, cevaplar.

const Kit := preload("res://scenes/ui/tablet/tablet_kit.gd")
const UiStyle := preload("res://scenes/ui_style.gd")

var contact := "Behzat"
var typing := false
var sent: Array = []
var thread: VBoxContainer
var stamp := ""
var stamp_case := ""


func render() -> void:
	if stamp_case != Scenario.case_id:
		stamp_case = Scenario.case_id
		contact = "Behzat"
		typing = false
		sent = []
		stamp = ""
	var next := "%s|%s|%d|%s" % [contact, typing, sent.size(), "|".join(GameState.clues)]
	if next == stamp and get_child_count() > 0:
		return
	stamp = next
	for child in get_children():
		child.queue_free()
	var narrow := get_viewport_rect().size.x < 860
	var root: BoxContainer = VBoxContainer.new() if narrow else HBoxContainer.new()
	root.add_theme_constant_override("separation", 10)
	Kit.cover(root)
	add_child(root)
	root.add_child(_contacts(narrow))
	var talk := VBoxContainer.new()
	Kit.fill(talk)
	talk.add_theme_constant_override("separation", 8)
	root.add_child(talk)
	talk.add_child(Kit.line(contact, 20, UiStyle.INK))
	thread = VBoxContainer.new()
	thread.add_theme_constant_override("separation", 6)
	thread.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	talk.add_child(Kit.scroll(thread))
	if typing:
		thread.add_child(Kit.line(contact + " yazıyor…", 14, UiStyle.LAMP, true))
	else:
		_messages()
	var replies := HBoxContainer.new()
	replies.add_theme_constant_override("separation", 6)
	talk.add_child(replies)
	var table: Dictionary = Scenario.data.get("replies", {})
	for option in table.get(contact, []):
		var button := UiStyle.button(option["text"])
		button.add_theme_font_size_override("font_size", 13)
		button.custom_minimum_size = Vector2(0, 34)
		button.pressed.connect(_reply.bind(option))
		replies.add_child(button)


func _contacts(narrow: bool) -> Control:
	var box: BoxContainer = HBoxContainer.new() if narrow else VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	if not narrow:
		box.custom_minimum_size = Vector2(168, 0)
	for who in ["Behzat", "Akbaba", "Hayalet"]:
		var button := UiStyle.button("%s   %d" % [who, _count(who)])
		button.custom_minimum_size = Vector2(0, 36)
		button.add_theme_font_size_override("font_size", 14)
		if who == contact:
			button.add_theme_color_override("font_color", UiStyle.LAMP)
		button.pressed.connect(_switch.bind(who))
		box.add_child(button)
	return box


func _count(who: String) -> int:
	var total := 0
	for message in Scenario.data.get("chat", []):
		if message["sender"] == who and _visible(message):
			total += 1
	return total


func _visible(message: Dictionary) -> bool:
	return not message.has("requiresClueId") or GameState.clues.has(message["requiresClueId"])


func _switch(who: String) -> void:
	if who == contact:
		return
	contact = who
	typing = true
	stamp = ""
	render()
	get_tree().create_timer(0.9).timeout.connect(func() -> void:
		if contact == who:
			typing = false
			stamp = ""
			render()
	)


func _messages() -> void:
	for message in Scenario.data.get("chat", []):
		if message["sender"] != contact or not _visible(message):
			continue
		thread.add_child(_bubble(str(message["text"]), str(message["at"]), false, str(message.get("type", "text"))))
	for item in sent:
		if item["contact"] == contact:
			thread.add_child(_bubble(item["text"], "şimdi", item["mine"], "text"))


func _bubble(text: String, at: String, mine: bool, kind: String) -> Control:
	var row := HBoxContainer.new()
	var card := Kit.panel(Color("243044") if mine else Kit.CARD, UiStyle.LAMP if mine else Kit.LINE, 12)
	card.custom_minimum_size = Vector2(260, 0)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 4)
	card.add_child(column)
	if kind == "photo":
		column.add_child(_photo())
	elif kind == "voice":
		column.add_child(_voice())
	var label := UiStyle.label(text, 15, UiStyle.INK)
	label.custom_minimum_size = Vector2(240, 0)
	column.add_child(label)
	column.add_child(Kit.line(at, 12, UiStyle.MUTED, true))
	if mine:
		var spacer := Control.new()
		spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(spacer)
	row.add_child(card)
	if not mine:
		var spacer := Control.new()
		spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(spacer)
	return row


func _photo() -> Control:
	var frame := ColorRect.new()
	frame.custom_minimum_size = Vector2(240, 104)
	frame.color = Color("6d6254")
	var crack := ColorRect.new()
	crack.color = Color("2a241c")
	crack.custom_minimum_size = Vector2(6, 84)
	crack.position = Vector2(118, 10)
	frame.add_child(crack)
	var marker := Kit.line("3", 22, UiStyle.LAMP, true)
	marker.position = Vector2(146, 34)
	frame.add_child(marker)
	return frame


func _voice() -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	var play := UiStyle.button("▶")
	play.custom_minimum_size = Vector2(40, 34)
	var bar := ProgressBar.new()
	bar.max_value = 100
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(140, 8)
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	play.pressed.connect(func() -> void:
		bar.value = 0
		var tween := create_tween()
		tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		tween.tween_property(bar, "value", 100.0, 2.0)
		Cinematic.play("radio")
	)
	row.add_child(play)
	row.add_child(bar)
	return row


func _reply(option: Dictionary) -> void:
	sent.append({"contact": contact, "text": option["text"], "mine": true})
	typing = true
	stamp = ""
	render()
	var who := contact
	get_tree().create_timer(1.1).timeout.connect(func() -> void:
		sent.append({"contact": who, "text": option["reply"], "mine": false})
		if contact == who:
			typing = false
		stamp = ""
		render()
	)
