extends Node

## Durum + duygu -> rig aksiyonu. Klip/poz tanımları CharacterRig ve data/animations.json'dadır.

const CS := preload("res://characters/base/character_state.gd")

const STATE_ACTION := {
	CS.State.IDLE: "Idle",
	CS.State.WALKING: "Walking",
	CS.State.RUNNING: "Running",
	CS.State.TALKING: "Talking",
	CS.State.LISTENING: "Listen",
	CS.State.INVESTIGATING: "Inspecting",
	CS.State.SITTING: "Sitting",
	CS.State.STANDING: "Standing",
	CS.State.REACTING: "Surprise",
}
## Beden dili duygu varyantı yalnızca bu durumlarda uygulanır (yürürken/konuşurken klip bozulmaz).
const EMOTION_BODY := ["IDLE", "STANDING", "SITTING", "LISTENING"]
const EMOTION_ACTION := {
	"nervous": "Nervous", "afraid": "Nervous", "angry": "Angry", "confident": "Confident",
	"sad": "Confession", "surprised": "Surprise",
}

var base: CharacterBody3D
var current := ""


func bind(owner_base: CharacterBody3D) -> void:
	base = owner_base
	base.state_changed.connect(func(_o: int, _n: int) -> void: _apply())
	base.emotion_changed.connect(func(_e: String) -> void: _apply())
	_apply()


func play_action(action: String) -> void:
	current = action
	base.rig.act(action)


func _apply() -> void:
	if base.state == CS.State.REACTING:
		return
	var action: String = STATE_ACTION[base.state]
	if CS.name_of(base.state) in EMOTION_BODY and EMOTION_ACTION.has(base.emotion_name()):
		action = EMOTION_ACTION[base.emotion_name()]
	base.rig.seated = base.sitting
	play_action(action)
