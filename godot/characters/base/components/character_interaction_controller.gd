extends Node

## Etkileşim: algı alanı (Area3D), diğer karakterleri fark etme ve karşılıklı konuşma.
## Kişilik: curiosity algı yarıçapını, sociability sohbet başlatma isteğini, patience dinleme sabrını belirler.

const CS := preload("res://characters/base/character_state.gd")

signal noticed(other: CharacterBody3D)
signal conversation_started(other: CharacterBody3D)
signal conversation_ended(other: CharacterBody3D)

var base: CharacterBody3D
var area: Area3D
var kind := "none"   ## none | noticing | conversing
var partner: CharacterBody3D = null
var nearby: Array[CharacterBody3D] = []
var auto_social := false
var _timer := 0.0
var _flip := 0.0
var _impatient_done := false
var _elapsed := 0.0
var _cooldown := 0.0
var _rng := RandomNumberGenerator.new()


func bind(owner_base: CharacterBody3D) -> void:
	base = owner_base
	_rng.randomize()
	area = base.get_node("InteractionArea")
	var shape := (area.get_node("Sense") as CollisionShape3D).shape as SphereShape3D
	shape.radius = 1.8 + 2.4 * base.trait_value("curiosity")
	area.area_entered.connect(_on_enter)
	area.area_exited.connect(_on_exit)


func can_converse() -> bool:
	return kind != "conversing" and base.state in [CS.State.IDLE, CS.State.STANDING, CS.State.SITTING, CS.State.INVESTIGATING, CS.State.LISTENING]


## `other` ile konuşma başlatır: bu karakter TALKING, diğeri LISTENING; roller periyodik değişir.
func interact_with(other: CharacterBody3D, duration := 8.0) -> bool:
	if other == base or other == null or not can_converse() or not other.interaction.can_converse():
		return false
	if not base.request_state(CS.State.TALKING):
		return false
	if not other.request_state(CS.State.LISTENING):
		base.request_state(CS.State.IDLE)
		return false
	_begin(other, duration, true)
	other.interaction._begin(base, duration, false)
	return true


func end_conversation() -> void:
	if kind != "conversing":
		return
	var other := partner
	_finish()
	if other != null and is_instance_valid(other):
		other.interaction._finish()


func _begin(other: CharacterBody3D, duration: float, lead: bool) -> void:
	partner = other
	_set_kind("conversing")
	_timer = duration
	_elapsed = 0.0
	_impatient_done = false
	_flip = _rng.randf_range(2.5, 4.0)
	if not base.sitting:
		base.controller.face(other.global_position, 0.4)
	base.look.look_at(other)
	if lead:
		conversation_started.emit(other)


func _finish() -> void:
	var other := partner
	partner = null
	_set_kind("none")
	base.look.clear()
	_cooldown = _rng.randf_range(6.0, 12.0)
	if base.state in [CS.State.TALKING, CS.State.LISTENING]:
		base.request_state(CS.State.SITTING if base.sitting else CS.State.STANDING)
	if other != null:
		conversation_ended.emit(other)


func _set_kind(next: String) -> void:
	if kind == next:
		return
	kind = next
	base.interaction_changed.emit(next)


func _process(delta: float) -> void:
	if base == null:
		return
	_cooldown = maxf(0.0, _cooldown - delta)
	if kind == "conversing":
		_tick_conversation(delta)
	elif auto_social and _cooldown <= 0.0 and base.trait_value("sociability") > 0.5 and can_converse():
		for other in nearby:
			if is_instance_valid(other) and other.interaction.can_converse() and _rng.randf() < 0.02 * base.trait_value("sociability"):
				interact_with(other, _rng.randf_range(6.0, 10.0))
				break


func _tick_conversation(delta: float) -> void:
	if partner == null or not is_instance_valid(partner):
		_finish()
		return
	_elapsed += delta
	_flip -= delta
	if _flip <= 0.0 and base.state in [CS.State.TALKING, CS.State.LISTENING]:
		_flip = _rng.randf_range(2.5, 4.0)
		base.request_state(CS.State.LISTENING if base.state == CS.State.TALKING else CS.State.TALKING)
	## sabırsız dinleyici: bir kez homurdanır
	if base.state == CS.State.LISTENING and not _impatient_done and _elapsed > 3.0 + 7.0 * base.trait_value("patience"):
		_impatient_done = true
		base.emotion.add_stress(6.0 + 10.0 * base.trait_value("aggression"))
	_timer -= delta
	if _timer <= 0.0 and base.state in [CS.State.TALKING, CS.State.LISTENING]:
		end_conversation()


func _on_enter(other_area: Area3D) -> void:
	var other := other_area.get_parent() as CharacterBody3D
	if other == null or other == base or not other.has_method("full_name") or nearby.has(other):
		return
	nearby.append(other)
	if kind == "none":
		_set_kind("noticing")
	noticed.emit(other)
	if kind == "noticing" and base.look.target == null:
		base.look.look_at(other)
		if base.trait_value("curiosity") < 0.5 and base.trait_value("confidence") < 0.45:
			base.react("Surprise", 0.9)


func _on_exit(other_area: Area3D) -> void:
	var other := other_area.get_parent() as CharacterBody3D
	if other == null:
		return
	nearby.erase(other)
	if nearby.is_empty() and kind == "noticing":
		_set_kind("none")
		if base.look.target == other:
			base.look.clear()
