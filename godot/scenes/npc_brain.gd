extends Node

## NPC davranış durumu: IDLE, WORKING, WALKING, TALKING, OBSERVING, INVESTIGATING, FOLLOWING_PLAYER, REACTING.
## Yürüme NavigationAgent3D (avoidance açık). Slotlar `hub.claims` ile tekil: iki NPC aynı noktaya gitmez.
## Oyuncuyu (komiser, kamera, bakılan nokta) fark eder: işini bırakıp döner, çok yaklaşınca irkilir.

enum State { IDLE, WORKING, WALKING, TALKING, OBSERVING, INVESTIGATING, FOLLOWING_PLAYER, REACTING }

const SPEED := 1.3
const Profiles := preload("res://characters/base/character_profiles.gd")
const FORGET_RANGE := 4.0
const STARTLE_RANGE := 1.5

var rig: Node3D
var who := ""
var display_name := ""
var hub: Dictionary = {}
var home := Vector3.ZERO
var home_yaw := 0.0
var slot := Vector3.ZERO
var seated := false
var work: Array = []
var tasks: Array = []
var state := State.IDLE
var agent: NavigationAgent3D

var _start := 1.2
var _timer := 0.0
var _phase := "work"
var _task: Dictionary = {}
var _goal := Vector3.ZERO
var _claims: Array[String] = []
var _scan := 0.0
var _lost := 0.0
var _startled := false
var _speaking := false
var _heard := false
var _partner: Node = null
var _chat_flip := 0.0
var _stuck := 0.0
var _last := Vector3.ZERO
var _rng := RandomNumberGenerator.new()
var notice_range := 3.0
var sociability := 0.5


func setup(node: Node3D, id: String, shared: Dictionary, cfg: Dictionary) -> void:
	rig = node
	who = id
	hub = shared
	home = rig.position
	home_yaw = rig.rotation_degrees.y
	display_name = str(Scenario.character(id).get("name", id))
	seated = bool(cfg.get("seated", false))
	slot = cfg.get("slot", home)
	work = cfg.get("work", [])
	tasks = cfg.get("tasks", [])
	_start = float(cfg.get("delay", 1.2))
	_rng.randomize()
	var mind := Profiles.personality(id)
	notice_range = 2.0 + 2.0 * float(mind["curiosity"])
	sociability = float(mind["sociability"])
	rig.seated = seated
	agent = NavigationAgent3D.new()
	agent.radius = 0.32
	agent.path_desired_distance = 0.25
	agent.target_desired_distance = 0.22
	agent.max_speed = SPEED
	agent.avoidance_enabled = true
	agent.neighbor_distance = 3.0
	agent.max_neighbors = 5
	agent.time_horizon_agents = 1.2
	agent.velocity_computed.connect(_on_safe_velocity)
	rig.add_child(agent)
	hub["brains"][id] = self
	hub["names"][display_name] = self


func state_name() -> String:
	return State.keys()[state]


func is_home() -> bool:
	return state != State.WALKING and _phase in ["work", "talk_wait"]


func eye() -> Vector3:
	return rig.global_position + Vector3(0, 1.2 if seated else 1.5, 0)


func _process(delta: float) -> void:
	if rig == null:
		return
	if _start > 0.0:
		_start -= delta
		if _start <= 0.0:
			_do_work()
		return
	_scan -= delta
	if _scan <= 0.0:
		_scan = 0.25
		_notice()
	if _speaking or state == State.WALKING:
		return
	_timer -= delta
	if state == State.TALKING and _partner != null:
		_chat_flip -= delta
		if _chat_flip <= 0.0:
			_chat_flip = _rng.randf_range(2.2, 4.0)
			var mine: bool = rig.state_flag == "chat_talk"
			rig.state_flag = "chat_listen" if mine else "chat_talk"
			rig.act("Listen" if mine else "Talking")
	if _timer > 0.0:
		return
	match state:
		State.WORKING, State.IDLE:
			_next()
		State.INVESTIGATING:
			_go_home()
		State.TALKING:
			if _phase == "talk_wait":
				_do_work()
			else:
				_finish_chat()
		State.REACTING:
			_resume()
		State.OBSERVING:
			pass


func _physics_process(delta: float) -> void:
	if rig == null or _start > 0.0:
		return
	if state != State.WALKING or _speaking:
		agent.velocity = Vector3.ZERO
		return
	if agent.is_navigation_finished():
		_arrived()
		return
	var next := agent.get_next_path_position()
	var to := next - rig.global_position
	to.y = 0.0
	agent.velocity = to.normalized() * SPEED if to.length() > 0.01 else Vector3.ZERO
	_stuck += delta
	if _stuck >= 1.5:
		if rig.global_position.distance_to(_last) < 0.25:
			_snap_arrive()
			return
		_stuck = 0.0
		_last = rig.global_position


func _on_safe_velocity(safe: Vector3) -> void:
	if state != State.WALKING or _speaking:
		return
	var step := Vector3(safe.x, 0.0, safe.z)
	rig.global_position += step * get_physics_process_delta_time()
	if step.length() > 0.1:
		rig.rotation.y = lerp_angle(rig.rotation.y, atan2(step.x, step.z), 0.18)


func _snap_arrive() -> void:
	rig.global_position = Vector3(_goal.x, home.y, _goal.z)
	_arrived()


## --- görev seçimi ---------------------------------------------------------

func _do_work() -> void:
	_phase = "work"
	_task = {}
	state = State.WORKING
	_release()
	var pick: Dictionary = _pick(work)
	var action: String = str(pick.get("action", "Idle"))
	rig.state_flag = "work"
	rig.look_at_target(null)
	rig.act(action)
	_timer = _rng.randf_range(float(pick.get("min", 6.0)), float(pick.get("max", 12.0)))
	if _heard:
		_listen_to(hub.get("speaker_eye", eye()))


func _next() -> void:
	if tasks.is_empty() or seated:
		_do_work()
		return
	var open: Array = []
	for t in tasks:
		if _can_do(t):
			open.append(t)
	if open.is_empty() or _rng.randf() < 0.6 - 0.5 * sociability:
		_do_work()
		return
	var task: Dictionary = _pick(open)
	_task = task
	if str(task["kind"]) == "visit":
		var partner: Node = hub["brains"][str(task["partner"])]
		_claim("slot:" + str(task["partner"]))
		_goal = partner.slot
		_phase = "go_visit"
	else:
		var spot: Vector3 = task["spot"]
		_claim("spot:%d,%d" % [roundi(spot.x), roundi(spot.z)])
		_goal = spot
		_phase = "go_spot"
	_walk()


func _can_do(t: Dictionary) -> bool:
	if str(t["kind"]) == "visit":
		var partner: Node = hub["brains"].get(str(t["partner"]))
		if partner == null or partner == self or not partner.is_home():
			return false
		if partner._partner != null or partner._speaking:
			return false
		return not hub["claims"].has("slot:" + str(t["partner"]))
	var spot: Vector3 = t["spot"]
	return not hub["claims"].has("spot:%d,%d" % [roundi(spot.x), roundi(spot.z)])


func _pick(list: Array) -> Dictionary:
	if list.is_empty():
		return {}
	var total := 0.0
	for e in list:
		total += float(e.get("w", 1.0))
	var roll := _rng.randf() * total
	for e in list:
		roll -= float(e.get("w", 1.0))
		if roll <= 0.0:
			return e
	return list[0]


func _claim(key: String) -> void:
	hub["claims"][key] = who
	_claims.append(key)


func _release() -> void:
	for key in _claims:
		if hub["claims"].get(key, "") == who:
			hub["claims"].erase(key)
	_claims.clear()


## --- yürüme ---------------------------------------------------------------

func _walk() -> void:
	state = State.WALKING
	rig.state_flag = "walk"
	rig.look_at_target(null)
	rig.seated = false
	rig.pose("walk")
	agent.target_position = _goal
	_stuck = 0.0
	_last = rig.global_position


func _go_home() -> void:
	if _partner != null:
		_finish_chat()
		return
	_phase = "back"
	_goal = home
	_walk()


func _arrived() -> void:
	match _phase:
		"go_spot":
			state = State.INVESTIGATING
			_phase = "do_spot"
			_face(_task.get("yaw", rig.rotation_degrees.y))
			rig.act(str(_task.get("action", "Inspecting")))
			_timer = _rng.randf_range(float(_task.get("min", 5.0)), float(_task.get("max", 9.0)))
		"go_visit":
			var partner: Node = hub["brains"].get(str(_task.get("partner", "")))
			if partner == null or not partner.is_home() or partner._speaking:
				_go_home()
				return
			_partner = partner
			state = State.TALKING
			_phase = "do_visit"
			rig.look_at_target(partner.eye())
			rig.turn_to(partner.rig.global_position, 0.4)
			rig.state_flag = "chat_talk"
			rig.act("Talking")
			_chat_flip = _rng.randf_range(2.2, 4.0)
			_timer = _rng.randf_range(float(_task.get("min", 7.0)), float(_task.get("max", 11.0)))
			partner.receive(self)
		"back":
			rig.global_position = Vector3(home.x, home.y, home.z)
			rig.seated = seated
			_face(home_yaw)
			_do_work()
		_:
			_do_work()


func _face(yaw_deg: float) -> void:
	var dir := Vector3(sin(deg_to_rad(yaw_deg)), 0, cos(deg_to_rad(yaw_deg)))
	rig.turn_to(rig.global_position + dir, 0.4)


## --- sohbet ---------------------------------------------------------------

func receive(visitor: Node) -> void:
	_partner = visitor
	state = State.TALKING
	_phase = "talk_wait"
	rig.state_flag = "chat_listen"
	_timer = 60.0
	_chat_flip = _rng.randf_range(1.5, 3.0)
	rig.look_at_target(visitor.eye())
	if not seated:
		rig.turn_to(visitor.rig.global_position, 0.4)
	rig.act("Listen")


func end_talk() -> void:
	_partner = null
	rig.look_at_target(null)
	if not seated:
		_face(home_yaw)
	_do_work()


func _finish_chat() -> void:
	var partner := _partner
	_partner = null
	if partner != null:
		partner.end_talk()
	rig.look_at_target(null)
	_phase = "back"
	_goal = home
	_walk()


## --- oyuncu farkındalığı --------------------------------------------------

func _notice() -> void:
	if _speaking or _start > 0.0:
		return
	var points: Array = hub["player"].call()
	var best := 1.0e9
	var at := Vector3.ZERO
	for p in points:
		var d := Vector2(p.x - rig.global_position.x, p.z - rig.global_position.z).length()
		if d < best:
			best = d
			at = p
	if state == State.WORKING or state == State.IDLE:
		if best < notice_range:
			_lost = 0.0
			_startled = false
			_observe(at, best)
	elif state == State.OBSERVING:
		if best > FORGET_RANGE:
			_lost += 0.25
			if _lost > 1.2:
				_startled = false
				rig.look_at_target(null)
				_do_work()
		else:
			_lost = 0.0
			rig.look_at_target(at + Vector3(0, 1.3, 0))
			if best < STARTLE_RANGE and not _startled and not seated:
				_startled = true
				react("Surprise", 1.1)


func _observe(at: Vector3, dist: float) -> void:
	state = State.OBSERVING
	_phase = "work"
	rig.state_flag = "observe"
	rig.look_at_target(at + Vector3(0, 1.3, 0))
	if not seated:
		rig.turn_to(at, 0.5)
	rig.act("Listen")
	if dist < STARTLE_RANGE and not seated:
		_startled = true
		react("Surprise", 1.1)


## Kısa tepki (REACTING): irkilme, el kaldırma vb. Bitince önceki duruma döner.
func react(action: String, duration: float) -> void:
	if state == State.WALKING:
		return
	state = State.REACTING
	rig.act(action)
	_timer = duration


func _resume() -> void:
	if _speaking:
		return
	if _near_player():
		state = State.OBSERVING
		rig.act("Listen")
	else:
		rig.look_at_target(null)
		_do_work()


func _near_player() -> bool:
	for p in hub["player"].call():
		if Vector2(p.x - rig.global_position.x, p.z - rig.global_position.z).length() < FORGET_RANGE:
			return true
	return false


## --- konuşma (GameState.speaker) -------------------------------------------

func on_speaker(name: String) -> void:
	var mine := name != "" and name == display_name
	if mine and not _speaking:
		_speaking = true
		if state == State.WALKING:
			rig.pose("breathe")
		rig.state_flag = "speak"
		var pts: Array = hub["player"].call()
		if pts.size() > 0:
			rig.look_at_target(pts[0] + Vector3(0, 1.3, 0))
		rig.act("Talking")
		state = State.TALKING if state != State.WALKING else State.WALKING
	elif not mine and _speaking:
		_speaking = false
		rig.look_at_target(null)
		if state == State.WALKING:
			rig.pose("walk")
		else:
			_do_work()
	_heard = name != "" and not mine
	if _heard and not _speaking and (state == State.WORKING or state == State.OBSERVING):
		_listen_to(hub.get("speaker_eye", eye()))
	elif not _heard and not _speaking and state == State.OBSERVING and name == "":
		pass


func _listen_to(target: Vector3) -> void:
	rig.look_at_target(target)
