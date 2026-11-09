extends Node

## Yüz canlandırma. Geometrik deformasyon deri ve saç gölgelendiricisinde
## (character_styler.gd · FACE_GLSL); burası yalnız üniformları sürer:
## göz kırpma, bakış, konuşurken çene, ifade geçişleri.
##
## Kafa heykelinde blend shape yok ve olmayacak — marching cubes her ifade için
## farklı topoloji üretirdi, morph target bağlanamazdı. Bu yüzden deformasyon
## köşe kaydırmasıyla yapılıyor.

const KEYS := ["f_blink", "f_jaw", "f_brow", "f_brow_in", "f_squint", "f_smile", "f_sneer"]

## İfade -> üniform hedefleri. character_rig.EXPRESSIONS anahtarlarıyla aynı.
const EXPRESSIONS := {
	"neutral": {},
	"tired": {"f_brow": -0.12, "f_squint": 0.34},
	"angry": {"f_brow": -0.85, "f_squint": 0.42, "f_sneer": 0.28, "f_smile": -0.32},
	"nervous": {"f_brow": 0.26, "f_brow_in": 0.75, "f_squint": -0.16, "f_smile": -0.18},
	"smug": {"f_smile": 0.50, "f_brow": 0.18, "f_squint": 0.22},
	"broken": {"f_brow_in": 0.95, "f_smile": -0.62, "f_squint": 0.45},
	"focused": {"f_brow": -0.32, "f_squint": 0.38},
}

const BLINK_TIME := 0.15
const EYE_YAW_MAX := 30.0
const EYE_PITCH_MAX := 16.0

var mats: Array = []
var eyes: Array[MeshInstance3D] = []
var who := ""
var speaker_name := ""

var _val: Dictionary = {}
var _goal: Dictionary = {}
var _blinking := false
var _blink_t := 0.0
var _next_blink := 2.0
var _talk_until := 0.0
var _talk_phase := 0.0
var _last_line := ""
var _last_aside := ""
var _gaze := Vector2.ZERO
var _gaze_goal := Vector2.ZERO
var _sacc_t := 0.0
var _sacc := Vector2.ZERO
var _rng := RandomNumberGenerator.new()


func bind(head_root: Node3D, who_id: String, display_name: String) -> void:
	who = who_id
	speaker_name = display_name
	mats = head_root.get_meta("face_mats", [])
	eyes.clear()
	for key in ["eye_l", "eye_r"]:
		var node := head_root.get_node_or_null(NodePath(key)) as MeshInstance3D
		if node:
			eyes.append(node)
	for k in KEYS:
		_val[k] = 0.0
		_goal[k] = 0.0
	_rng.randomize()
	_next_blink = _rng.randf_range(0.8, 3.4)
	if GameState and not GameState.updated.is_connected(_on_state):
		GameState.updated.connect(_on_state)
	set_process(true)


func set_expression(name: String) -> void:
	var spec: Dictionary = EXPRESSIONS.get(name, EXPRESSIONS["neutral"])
	for k in KEYS:
		if k == "f_blink" or k == "f_jaw":
			continue
		_goal[k] = float(spec.get(k, 0.0))


## Gözün başın üstüne eklediği bakış payı (derece). character_rig verir.
func set_gaze(pitch: float, yaw: float) -> void:
	_gaze_goal = Vector2(clampf(pitch, -EYE_PITCH_MAX, EYE_PITCH_MAX), clampf(yaw, -EYE_YAW_MAX, EYE_YAW_MAX))


## Dışarıdan konuşturmak için (seslendirme ya da sinematik).
func talk_for(seconds: float) -> void:
	_talk_until = maxf(_talk_until, _now() + seconds)


func _now() -> float:
	return float(Time.get_ticks_msec()) / 1000.0


## Sahnedeki konuşan kişi bu karakterse, satır uzunluğu kadar ağzı oynat.
## Seslendirme dosyası olmadığı için süre metinden tahmin ediliyor; yazı
## makinesinin hızıyla (scenes/ui/typewriter.gd) aynı mertebede.
func _on_state() -> void:
	if speaker_name == "":
		return
	if GameState.speaker == speaker_name and GameState.line != _last_line:
		_last_line = GameState.line
		if GameState.line != "":
			talk_for(clampf(float(GameState.line.length()) / 46.0, 0.7, 9.0))
	# Behzat'ın araya girdiği replik ayrı alanda tutuluyor (GameState.behzat_line).
	if speaker_name.contains("Behzat") and GameState.behzat_line != _last_aside:
		_last_aside = GameState.behzat_line
		if GameState.behzat_line != "":
			talk_for(clampf(float(GameState.behzat_line.length()) / 46.0, 0.6, 5.0))


func _stress() -> float:
	if who == "" or not GameState:
		return 0.0
	return clampf(float(GameState.stress.get(who, 0)) / 100.0, 0.0, 1.0)


func _process(delta: float) -> void:
	if mats.is_empty():
		return
	var stress := _stress()
	_tick_blink(delta, stress)
	_tick_talk(delta)
	_tick_gaze(delta)
	# ifade değerleri yumuşak geçsin; anında atlayınca yüz takırdıyor
	for k in KEYS:
		if k == "f_blink" or k == "f_jaw":
			continue
		_val[k] = lerpf(_val[k], _goal[k], 1.0 - exp(-7.0 * delta))
	var squint: float = _val["f_squint"] + 0.18 * stress
	for m in mats:
		m.set_shader_parameter("f_blink", _val["f_blink"])
		m.set_shader_parameter("f_jaw", _val["f_jaw"])
		m.set_shader_parameter("f_brow", _val["f_brow"])
		m.set_shader_parameter("f_brow_in", _val["f_brow_in"])
		m.set_shader_parameter("f_squint", squint)
		m.set_shader_parameter("f_smile", _val["f_smile"])
		m.set_shader_parameter("f_sneer", _val["f_sneer"])


## Stres arttıkça kırpma sıklaşır — tedirgin insan daha sık kırpar.
func _tick_blink(delta: float, stress: float) -> void:
	if _blinking:
		_blink_t += delta
		var t := clampf(_blink_t / BLINK_TIME, 0.0, 1.0)
		# kapanış açılıştan hızlı
		_val["f_blink"] = sin(pow(t, 0.72) * PI)
		if t >= 1.0:
			_blinking = false
			_val["f_blink"] = 0.0
		return
	_next_blink -= delta
	if _next_blink <= 0.0:
		_blinking = true
		_blink_t = 0.0
		_next_blink = _rng.randf_range(2.2, 6.0) * (1.0 - 0.5 * stress)


func _tick_talk(delta: float) -> void:
	var target := 0.0
	if _now() < _talk_until:
		_talk_phase += delta * 9.5
		# iki farklı hızda salınım: tek sinüs makine gibi duruyor
		var a := 0.5 + 0.5 * sin(_talk_phase)
		var b := 0.55 + 0.45 * sin(_talk_phase * 2.37 + 1.1)
		target = clampf(a * b, 0.0, 1.0) * 0.9
	_val["f_jaw"] = lerpf(_val["f_jaw"], target, 1.0 - exp(-18.0 * delta))


## Mikro sakkad: göz hiç kıpırdamayınca bakış cansız duruyor.
func _tick_gaze(delta: float) -> void:
	_sacc_t -= delta
	if _sacc_t <= 0.0:
		_sacc_t = _rng.randf_range(0.7, 2.6)
		_sacc = Vector2(_rng.randf_range(-1.6, 1.6), _rng.randf_range(-3.6, 3.6))
	var goal := _gaze_goal + _sacc
	_gaze = _gaze.lerp(goal, 1.0 - exp(-14.0 * delta))
	for e in eyes:
		if is_instance_valid(e):
			e.rotation_degrees = Vector3(_gaze.x, _gaze.y, 0.0)
