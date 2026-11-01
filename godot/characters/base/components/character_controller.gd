extends Node

## Hareket: NavigationAgent3D yol + CharacterBody3D move_and_slide + kaçınma.
## Kişilik: confidence yürüme hızını etkiler.

const CS := preload("res://characters/base/character_state.gd")

signal arrived
signal blocked

var base: CharacterBody3D
var agent: NavigationAgent3D
var moving := false
var walk_speed := 1.3
var run_speed := 3.1
var _run := false
var _goal := Vector3.ZERO
var _ground := 0.0
var _stuck := 0.0
var _last := Vector3.ZERO


func bind(owner_base: CharacterBody3D) -> void:
	base = owner_base
	agent = base.get_node("NavigationAgent3D")
	agent.velocity_computed.connect(_on_safe_velocity)
	walk_speed = 1.15 + 0.35 * base.trait_value("confidence")
	run_speed = 2.8 + 0.6 * base.trait_value("confidence")
	agent.max_speed = run_speed
	_ground = base.position.y


func move_to(target: Vector3, run := false) -> bool:
	var wanted: int = CS.State.RUNNING if run else CS.State.WALKING
	if not base.request_state(wanted):
		return false
	_run = run
	_goal = target
	_ground = base.global_position.y
	agent.target_position = target
	moving = true
	_stuck = 0.0
	_last = base.global_position
	return true


func stop() -> void:
	moving = false
	base.velocity = Vector3.ZERO
	if base.state in [CS.State.WALKING, CS.State.RUNNING]:
		base.request_state(CS.State.STANDING)


func sit() -> bool:
	moving = false
	return base.request_state(CS.State.SITTING)


func stand() -> bool:
	return base.request_state(CS.State.STANDING)


func face(world: Vector3, duration := 0.45) -> void:
	base.rig.turn_to(world, duration)


func _physics_process(delta: float) -> void:
	if not moving:
		agent.velocity = Vector3.ZERO
		return
	if not base.state in [CS.State.WALKING, CS.State.RUNNING]:
		agent.velocity = Vector3.ZERO
		return
	if agent.is_navigation_finished():
		stop()
		arrived.emit()
		return
	var next := agent.get_next_path_position()
	var to := next - base.global_position
	to.y = 0.0
	var speed := run_speed if _run else walk_speed
	if to.length() < 0.01:
		agent.velocity = Vector3.ZERO
	else:
		agent.velocity = to.normalized() * speed
	_stuck += delta
	if _stuck >= 1.6:
		if base.global_position.distance_to(_last) < 0.2:
			stop()
			blocked.emit()
			return
		_stuck = 0.0
		_last = base.global_position


func _on_safe_velocity(safe: Vector3) -> void:
	if not moving or not base.state in [CS.State.WALKING, CS.State.RUNNING]:
		return
	base.velocity = Vector3(safe.x, 0.0, safe.z)
	base.move_and_slide()
	base.global_position.y = _ground
	var flat := Vector3(base.velocity.x, 0.0, base.velocity.z)
	if flat.length() > 0.2:
		base.rig.rotation.y = lerp_angle(base.rig.rotation.y, atan2(flat.x, flat.z), 0.2)
