extends Node

## Atlanabilir sinematik katman. Oyun durumunu bekletmez; sahne aynı karede değişir.

signal started(id: String)
signal finished(id: String)
signal skipped(id: String)

const PATH := "res://data/cinematics.json"
const GRADES := {
	"case": Color(0, 0, 0, 0),
	"evidence": Color(0.45, 0.05, 0.04, 0.22),
	"lie": Color(0.55, 0.28, 0.02, 0.2),
	"call": Color(0.55, 0.32, 0.02, 0.28),
	"authority": Color(0.04, 0.07, 0.16, 0.5),
	"radio": Color(0.05, 0.2, 0.1, 0.22),
	"confession": Color(0.35, 0.02, 0.02, 0.34),
}

var beat_id := ""
var playing := false
var mood := "case"
var liar := ""
var shake := 0.0
var data: Dictionary = {}

var _token := 0
var _hold := ""
var _bed: AudioStreamPlayer
var _sting: AudioStreamPlayer
var _shook := false
var _clips: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	if parsed is Dictionary:
		data = parsed
	_bed = AudioStreamPlayer.new()
	_bed.bus = "Music"
	_bed.volume_db = -32.0
	_bed.finished.connect(func() -> void:
		if _bed.stream:
			_bed.play()
	)
	add_child(_bed)
	_sting = AudioStreamPlayer.new()
	_sting.bus = "SFX"
	_sting.volume_db = -8.0
	add_child(_sting)
	_clips = {
		"case": _loop(54.0, 0.18, false),
		"evidence": _loop(82.0, 0.28, true),
		"lie": _loop(104.0, 0.22, true),
		"call": _loop(220.0, 0.12, false),
		"authority": _loop(67.0, 0.2, false),
		"radio": _noise(1.4),
		"confession": _loop(46.0, 0.3, true),
	}
	_play_bed()


func _process(delta: float) -> void:
	var cam := get_viewport().get_camera_3d()
	if shake <= 0.0008:
		if _shook:
			_shook = false
			if cam:
				cam.h_offset = 0.0
				cam.v_offset = 0.0
		return
	_shook = true
	shake = lerpf(shake, 0.0, 1.0 - exp(-8.0 * delta))
	if cam == null:
		return
	var t := Time.get_ticks_msec() / 1000.0
	cam.h_offset = sin(t * 46.0) * shake
	cam.v_offset = cos(t * 35.0) * shake * 0.6


func reset() -> void:
	_token += 1
	playing = false
	beat_id = ""
	liar = ""
	_hold = ""
	mood = "case"
	shake = 0.0
	if _bed:
		_play_bed()
	finished.emit("")


func spec(id: String) -> Dictionary:
	var beats: Dictionary = data.get("beats", {})
	var found: Variant = beats.get(id, {})
	return found if found is Dictionary else {}


func grade() -> Color:
	return GRADES.get(mood, GRADES["case"])


func play(id: String) -> void:
	var beat := spec(id)
	if beat.is_empty():
		return
	_token += 1
	var token := _token
	beat_id = id
	playing = true
	var next := str(beat.get("mood", "keep"))
	if next == "lie" or next == "radio":
		if _hold == "":
			_hold = mood
		_set_mood(next)
	elif next != "keep":
		_hold = ""
		_set_mood(next)
	shake = maxf(shake, float(beat.get("shake", 0.0)))
	if next == "evidence" or next == "confession" or id == "lie":
		_hit(320.0 if next == "evidence" else 180.0)
	started.emit(id)
	var seconds := float(beat.get("duration", 0.6))
	if seconds <= 0.0:
		return
	get_tree().create_timer(seconds, true).timeout.connect(func() -> void:
		if token == _token and playing:
			_end(false)
	)


func skip() -> void:
	if playing:
		_end(true)


func punch(amount: float) -> void:
	shake = maxf(shake, amount)


func on_clue(clue_id: String) -> void:
	var rows: Array = Scenario.data.get("importantClues", [])
	play("evidence_major" if rows.has(clue_id) else "evidence")


func mark_lie(suspect_id: String) -> void:
	liar = suspect_id
	play("lie")


func clear_lie() -> void:
	liar = ""


func _end(was_skip: bool) -> void:
	var id := beat_id
	playing = false
	beat_id = ""
	if _hold != "":
		_set_mood(_hold)
		_hold = ""
	if was_skip:
		skipped.emit(id)
	finished.emit(id)


func _set_mood(next: String) -> void:
	mood = next
	_play_bed()


func _play_bed() -> void:
	if _bed == null:
		return
	var clip := _clips.get(mood, _clips["case"]) as AudioStream
	if _bed.stream == clip and _bed.playing:
		return
	_bed.stream = clip
	_bed.play()


func _hit(freq: float) -> void:
	if _sting == null:
		return
	_sting.stream = _blip(freq)
	_sting.play()


func _loop(freq: float, gain: float, pulse: bool) -> AudioStreamWAV:
	var rate := 22050
	var count := rate * 2
	var bytes := PackedByteArray()
	bytes.resize(count * 2)
	for i in count:
		var t := float(i) / float(rate)
		var env := 0.65 + 0.35 * sin(TAU * t / 2.0)
		if pulse:
			env *= 0.45 + 0.55 * maxf(0.0, sin(TAU * t * 2.0))
		var sample := sin(TAU * freq * t) * gain + sin(TAU * freq * 2.01 * t) * gain * 0.35
		_write(bytes, i, sample * env)
	return _wav(bytes, rate)


func _noise(seconds: float) -> AudioStreamWAV:
	var rate := 22050
	var count := int(rate * seconds)
	var bytes := PackedByteArray()
	bytes.resize(count * 2)
	var rng := RandomNumberGenerator.new()
	rng.seed = 6
	for i in count:
		var burst := 0.35 if fmod(float(i) / rate, 0.45) < 0.06 else 0.08
		_write(bytes, i, rng.randf_range(-1.0, 1.0) * burst)
	return _wav(bytes, rate)


func _blip(freq: float) -> AudioStreamWAV:
	var rate := 22050
	var count := int(rate * 0.18)
	var bytes := PackedByteArray()
	bytes.resize(count * 2)
	for i in count:
		var t := float(i) / float(rate)
		var env := 1.0 - t / 0.18
		_write(bytes, i, sin(TAU * freq * t) * 0.45 * env)
	return _wav(bytes, rate)


func _write(bytes: PackedByteArray, i: int, sample: float) -> void:
	var v := int(clampf(sample, -1.0, 1.0) * 32767.0)
	bytes[i * 2] = v & 255
	bytes[i * 2 + 1] = (v >> 8) & 255


func _wav(bytes: PackedByteArray, rate: int) -> AudioStreamWAV:
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = rate
	wav.stereo = false
	wav.data = bytes
	return wav
