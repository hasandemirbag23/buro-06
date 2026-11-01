extends Node

## Bakış hedefi (Node3D veya dünya noktası). Hedef yokken meraka göre kısa çevre bakışları.

const CS := preload("res://characters/base/character_state.gd")

var base: CharacterBody3D
var target: Variant = null
var idle_glances := true
var _glance_in := 2.0
var _glance_for := 0.0
var _rng := RandomNumberGenerator.new()


func bind(owner_base: CharacterBody3D) -> void:
	base = owner_base
	_rng.randomize()
	_glance_in = _next_gap()


func look_at(who: Variant, speed := 5.0) -> void:
	target = who
	_glance_for = 0.0
	base.rig.look_at_target(_point(who), speed)


func clear() -> void:
	target = null
	_glance_for = 0.0
	base.rig.clear_gaze()


func _point(who: Variant) -> Variant:
	if who == null:
		return null
	if who is CharacterBody3D and who.has_method("eye_position"):
		return who.eye_position()
	return who


func _process(delta: float) -> void:
	if base == null:
		return
	if target is Object and is_instance_valid(target) and target is CharacterBody3D:
		base.rig.look_at_target(_point(target), 5.0)
	if target != null or not idle_glances:
		return
	if base.state in [CS.State.WALKING, CS.State.RUNNING, CS.State.REACTING]:
		return
	if _glance_for > 0.0:
		_glance_for -= delta
		if _glance_for <= 0.0:
			base.rig.clear_gaze()
			_glance_in = _next_gap()
		return
	_glance_in -= delta
	if _glance_in <= 0.0:
		var yaw: float = base.rig.global_rotation.y + deg_to_rad(_rng.randf_range(-55.0, 55.0))
		var spot: Vector3 = base.eye_position() + Vector3(sin(yaw), _rng.randf_range(-0.1, 0.1), cos(yaw)) * 3.0
		base.rig.look_at_target(spot, 3.5)
		_glance_for = _rng.randf_range(0.9, 1.8)


func _next_gap() -> float:
	var curiosity: float = base.trait_value("curiosity")
	return _rng.randf_range(2.0, 4.0) + (1.0 - curiosity) * 7.0
