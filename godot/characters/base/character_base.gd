extends CharacterBody3D

## Merkezi karakter kökü: kimlik + durum + kişilik. Davranış bileşenlere dağıtılmıştır:
## Controller (hareket), AnimationController, InteractionController, LookController,
## EmotionController, AudioController. Görsel/animasyon sistemi mevcut CharacterRig'tir.

const CS := preload("res://characters/base/character_state.gd")
const Profiles := preload("res://characters/base/character_profiles.gd")

const LAYER_CHARACTER := 8
const LAYER_OBSTACLE := 16
const LAYER_INTERACTION := 32

signal state_changed(old_state: int, new_state: int)
signal emotion_changed(emotion: String)
signal interaction_changed(kind: String)

@export var character_id := ""
@export var start_sitting := false

var first_name := ""
var last_name := ""
var role := ""
var traits: Array = []
var personality: Dictionary = {}
var voice_pitch := 1.0

var state: int = CS.State.IDLE
var sitting := false
var rig: Node3D
var controller: Node
var animation: Node
var interaction: Node
var look: Node
var emotion: Node
var audio: Node
var roster_ok := false

var _return_state: int = CS.State.IDLE
var _reaction_token := 0


func _ready() -> void:
	var data := Profiles.profile(character_id)
	first_name = data["first_name"]
	last_name = data["last_name"]
	role = data["role"]
	traits = data["traits"]
	personality = data["personality"]
	voice_pitch = float(data["voice"].get("pitch", 1.0))
	if not Profiles.has_profile(character_id):
		push_warning("CharacterBase: '%s' için character_profiles.json kaydı yok." % character_id)
	rig = $Rig
	roster_ok = not Scenario.character(character_id).is_empty()
	if roster_ok:
		rig.setup(character_id)
	else:
		push_warning("CharacterBase: '%s' aktif senaryo kadrosunda yok; model yüklenmedi." % character_id)
	controller = $Controller
	animation = $AnimationController
	interaction = $InteractionController
	look = $LookController
	emotion = $EmotionController
	audio = $AudioController
	for part in [controller, animation, interaction, look, emotion, audio]:
		part.bind(self)
	if start_sitting:
		_set_state(CS.State.SITTING)
	else:
		state_changed.emit(state, state)


## --- kimlik ---------------------------------------------------------------

func full_name() -> String:
	return ("%s %s" % [first_name, last_name]).strip_edges()


func trait_value(key: String) -> float:
	return float(personality.get(key, 0.5))


func state_name() -> String:
	return CS.name_of(state)


func movement_state() -> String:
	if state == CS.State.RUNNING:
		return "running"
	if state == CS.State.WALKING:
		return "walking"
	return "stopped"


func interaction_state() -> String:
	return interaction.kind if interaction else "none"


func is_speaking() -> bool:
	return state == CS.State.TALKING


func emotion_name() -> String:
	return emotion.emotion if emotion else "neutral"


func gaze_target() -> Variant:
	return look.target if look else null


func eye_position() -> Vector3:
	return global_position + Vector3(0, 1.2 if sitting else 1.55, 0)


func set_facing_degrees(yaw: float) -> void:
	rig.rotation_degrees.y = yaw


## --- durum yönetimi -------------------------------------------------------

## İzinli geçişlerde durumu değiştirir. Oturan karakter yürümeden önce otomatik ayağa kalkar.
func request_state(to: int) -> bool:
	if to == state:
		return true
	if state == CS.State.SITTING and CS.STAND_PREREQ.has(to):
		_set_state(CS.State.STANDING)
	if not CS.allowed(state, to):
		return false
	_set_state(to)
	return true


func _set_state(to: int) -> void:
	var old := state
	state = to
	if to == CS.State.SITTING:
		sitting = true
	elif to in [CS.State.STANDING, CS.State.IDLE, CS.State.WALKING, CS.State.RUNNING]:
		sitting = false
	state_changed.emit(old, to)


## Kısa tepki (irkilme, öfke vb.). Süre bitince önceki duruma döner.
func react(action: String, duration := 1.0) -> bool:
	if state == CS.State.REACTING:
		return false
	var before := state
	if not request_state(CS.State.REACTING):
		return false
	_return_state = before
	animation.play_action(action)
	_reaction_token += 1
	var token := _reaction_token
	get_tree().create_timer(duration).timeout.connect(func() -> void:
		if token == _reaction_token:
			_end_reaction()
	)
	return true


func _end_reaction() -> void:
	if state != CS.State.REACTING:
		return
	var back := _return_state
	if sitting:
		back = CS.State.SITTING
	elif back in [CS.State.WALKING, CS.State.RUNNING] and not controller.moving:
		back = CS.State.IDLE
	if not request_state(back):
		request_state(CS.State.IDLE)
