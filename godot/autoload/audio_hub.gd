extends Node

## Ses merkezi: bus düzeni, müzik/ortam geçişi, SFX ve diyalog seslendirmesi.
## Buslar: Master -> Music, Ambient, SFX, Voice. Seviyeler Archive.settings içinde (0..100).
## Seslendirme sözleşmesi: res://assets/audio/voice/<dosya_id>/<şüpheli>_<düğüm>.ogg (yoksa sessiz).
## Tüm dosyalar CC0, bkz. assets/audio/LICENSES.md

const Archive := preload("res://scenes/case_archive.gd")
const BUSES := ["Music", "Ambient", "SFX", "Voice"]
const SETTING_KEYS := {"Master": "master", "Music": "music", "Ambient": "ambient", "SFX": "sfx", "Voice": "voice"}
const AUDIO := "res://assets/audio/"
const MUSIC_BY_SCENE := {
	"office": ["music/hallway", -6.0],
	"site": ["music/dark_place", -8.0],
	"interrogation": ["music/interrogation_drone", -6.0],
}

var _music: AudioStreamPlayer
var _ambient: AudioStreamPlayer
var _voice: AudioStreamPlayer
var _pool: Array[AudioStreamPlayer] = []
var _cache := {}
var _scene := ""
var _case := ""
var _music_key := ""
var _tween: Tween
var _last := {"scene": "", "clues": -1, "tablet": false, "notice": "", "node": ""}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	Archive.boot()
	_build_buses()
	_music = _player("Music")
	_ambient = _player("Ambient")
	_voice = _player("Voice")
	for i in 6:
		_pool.append(_player("SFX"))
	apply_settings()
	GameState.updated.connect(_on_updated)
	GameState.slammed.connect(_on_slammed)
	_on_updated()


func _build_buses() -> void:
	for bus_name in BUSES:
		if AudioServer.get_bus_index(bus_name) != -1:
			continue
		AudioServer.add_bus()
		var idx := AudioServer.bus_count - 1
		AudioServer.set_bus_name(idx, bus_name)
		AudioServer.set_bus_send(idx, "Master")


func _player(bus_name: String) -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	p.bus = bus_name
	add_child(p)
	return p


## Ayar sözlüğünden bus seviyelerini uygular (Archive.settings).
func apply_settings() -> void:
	for bus_name in SETTING_KEYS:
		var idx := AudioServer.get_bus_index(bus_name)
		if idx == -1:
			continue
		var pct := float(Archive.settings.get(SETTING_KEYS[bus_name], 80.0))
		AudioServer.set_bus_volume_db(idx, linear_to_db(maxf(pct / 100.0, 0.0001)))
		AudioServer.set_bus_mute(idx, pct <= 0.5)


func _load(rel: String) -> AudioStream:
	if _cache.has(rel):
		return _cache[rel]
	var stream: AudioStream = null
	for ext in [".ogg", ".wav", ".mp3"]:
		if ResourceLoader.exists(AUDIO + rel + ext):
			stream = load(AUDIO + rel + ext)
			break
	_cache[rel] = stream
	return stream


## Kısa efekt. name: "sfx/" altındaki dosya adı (uzantısız).
func sfx(sound: String, volume_db := 0.0, pitch := 1.0) -> void:
	var stream := _load("sfx/" + sound)
	if stream == null:
		return
	for p in _pool:
		if not p.playing:
			p.stream = stream
			p.volume_db = volume_db
			p.pitch_scale = pitch
			p.play()
			return


## Adım sesi: yüzey "grass" veya "concrete".
func step(surface: String) -> void:
	var n := 3 if surface == "grass" else 4
	sfx("footstep_%s_%03d" % [surface, randi() % n], -12.0, randf_range(0.9, 1.1))


## Diyalog sesi: voice/<case>/<key>.ogg varsa çalar ve süreyi döner, yoksa 0.
func voice(key: String) -> float:
	var stream := _load("voice/%s/%s" % [_case, key])
	if stream == null:
		return 0.0
	_voice.stream = stream
	_voice.play()
	return stream.get_length()


func stop_voice() -> void:
	_voice.stop()


func _set_music(rel: String, volume: float) -> void:
	if rel == _music_key:
		return
	_music_key = rel
	if _tween:
		_tween.kill()
	_tween = create_tween()
	if _music.playing:
		_tween.tween_property(_music, "volume_db", -60.0, 0.7)
	_tween.tween_callback(func() -> void:
		var stream := _load(rel)
		if stream is AudioStreamOggVorbis:
			(stream as AudioStreamOggVorbis).loop = true
		_music.stream = stream
		_music.volume_db = -60.0
		if stream:
			_music.play()
	)
	_tween.tween_property(_music, "volume_db", volume, 1.2)


func _set_ambient(on: bool, volume: float) -> void:
	if on:
		var stream := _load("ambient/rain_loop")
		if stream is AudioStreamOggVorbis:
			(stream as AudioStreamOggVorbis).loop = true
		if _ambient.stream != stream:
			_ambient.stream = stream
		_ambient.volume_db = volume
		if not _ambient.playing and stream:
			_ambient.play()
	else:
		_ambient.stop()


func _on_scene(scene_id: String) -> void:
	_scene = scene_id
	var m: Array = MUSIC_BY_SCENE.get(scene_id, MUSIC_BY_SCENE["office"])
	_set_music(str(m[0]), float(m[1]))
	var site_rain: bool = scene_id == "site" and str(Scenario.data.get("set", "tower")) != "flat"
	if scene_id == "office":
		_set_ambient(true, -22.0)
	elif site_rain:
		_set_ambient(true, -10.0)
	else:
		_set_ambient(false, 0.0)


func _on_updated() -> void:
	_case = Scenario.case_id
	if GameState.scene_id != _last["scene"]:
		_last["scene"] = GameState.scene_id
		_on_scene(GameState.scene_id)
	var count: int = GameState.clues.size()
	if _last["clues"] >= 0 and count > int(_last["clues"]):
		sfx("confirmation_002", -6.0)
	_last["clues"] = count
	if GameState.tablet_open != _last["tablet"]:
		_last["tablet"] = GameState.tablet_open
		sfx("open_001" if GameState.tablet_open else "close_001", -8.0)
	var notice := str(GameState.notice)
	if notice != _last["notice"]:
		_last["notice"] = notice
		if notice == "Hatalı şifre.":
			sfx("error_001", -6.0)
		elif notice == "Telefon kilidi açıldı.":
			sfx("confirmation_001", -6.0)
	var suspect := str(GameState.active_suspect)
	if suspect != "":
		var node := "%s_%s" % [suspect, str(GameState.dialogue_node.get(suspect, "start"))]
		if node != _last["node"]:
			_last["node"] = node
			voice(node)
	else:
		_last["node"] = ""


func _on_slammed(clue_id: String) -> void:
	var suspect := str(GameState.active_suspect)
	if suspect == "":
		return
	if bool(GameState.confessed.get(suspect, false)):
		sfx("impactBell_heavy_000", -4.0)
	elif GameState.used.get(suspect, []).has(clue_id):
		sfx("impactPunch_heavy_000", -2.0)
	else:
		sfx("impactWood_heavy_000", -4.0)


func _exit_tree() -> void:
	for p in get_children():
		if p is AudioStreamPlayer:
			(p as AudioStreamPlayer).stop()
			(p as AudioStreamPlayer).stream = null
	_cache.clear()
