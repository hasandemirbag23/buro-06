extends Node

## Prosedürel ses: adım sesi ve konuşma mırıltısı. Harici ses dosyası kullanmaz;
## gerçek ses varlıkları gelince `step_stream` ve `voice_stream` değiştirilir.

const CS := preload("res://characters/base/character_state.gd")
const RATE := 22050

static var _step_cache: AudioStreamWAV
static var _voice_cache: Dictionary = {}

var base: CharacterBody3D
var player: AudioStreamPlayer3D
var voice_player: AudioStreamPlayer3D
var enabled := true
var step_stream: AudioStream
var step_streams: Array[AudioStream] = []
var voice_stream: AudioStream
var _step_t := 0.0
var _voice_t := 0.0
var _rng := RandomNumberGenerator.new()


func bind(owner_base: CharacterBody3D) -> void:
	base = owner_base
	_rng.randomize()
	player = AudioStreamPlayer3D.new()
	player.unit_size = 4.0
	player.max_distance = 18.0
	player.volume_db = -14.0
	player.bus = "SFX"
	base.add_child(player)
	voice_player = AudioStreamPlayer3D.new()
	voice_player.unit_size = 5.0
	voice_player.max_distance = 20.0
	voice_player.volume_db = -26.0
	voice_player.bus = "Voice"
	base.add_child(voice_player)
	for i in 4:
		var path := "res://assets/audio/sfx/footstep_concrete_%03d.ogg" % i
		if ResourceLoader.exists(path):
			step_streams.append(load(path))
	step_stream = _steps()
	voice_stream = _voice(base.voice_pitch)


func _process(delta: float) -> void:
	if base == null or not enabled:
		return
	if base.state in [CS.State.WALKING, CS.State.RUNNING] and base.velocity.length() > 0.3:
		_step_t -= delta
		if _step_t <= 0.0:
			_step_t = 0.52 if base.state == CS.State.WALKING else 0.33
			player.stream = step_streams[_rng.randi() % step_streams.size()] if not step_streams.is_empty() else step_stream
			player.pitch_scale = _rng.randf_range(0.85, 1.15)
			player.play()
	else:
		_step_t = 0.0
	if base.state == CS.State.TALKING:
		_voice_t -= delta
		if _voice_t <= 0.0:
			_voice_t = _rng.randf_range(0.14, 0.3)
			voice_player.stream = voice_stream
			voice_player.pitch_scale = _rng.randf_range(0.85, 1.2)
			voice_player.play()


static func _wav(samples: PackedFloat32Array) -> AudioStreamWAV:
	var bytes := PackedByteArray()
	bytes.resize(samples.size() * 2)
	for i in samples.size():
		bytes.encode_s16(i * 2, int(clampf(samples[i], -1.0, 1.0) * 32000.0))
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = RATE
	wav.data = bytes
	return wav


static func _steps() -> AudioStreamWAV:
	if _step_cache == null:
		var n := int(RATE * 0.09)
		var s := PackedFloat32Array()
		s.resize(n)
		var rng := RandomNumberGenerator.new()
		rng.seed = 7
		for i in n:
			var env := exp(-float(i) / (n * 0.18))
			s[i] = (rng.randf() * 2.0 - 1.0) * 0.5 * env + sin(float(i) * 0.05) * 0.4 * env
		_step_cache = _wav(s)
	return _step_cache


static func _voice(pitch: float) -> AudioStreamWAV:
	var key := snappedf(pitch, 0.05)
	if not _voice_cache.has(key):
		var n := int(RATE * 0.12)
		var s := PackedFloat32Array()
		s.resize(n)
		var hz := 130.0 * pitch
		for i in n:
			var t := float(i) / RATE
			var env := sin(PI * float(i) / n)
			s[i] = (sin(TAU * hz * t) * 0.5 + sin(TAU * hz * 2.0 * t) * 0.2) * env * 0.6
		_voice_cache[key] = _wav(s)
	return _voice_cache[key]
