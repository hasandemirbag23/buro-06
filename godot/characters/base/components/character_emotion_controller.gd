extends Node

## Duygusal durum + stres. stress_resistance stres kazanımını azaltır ve düşüşü hızlandırır;
## aggression yüksekse gerginlik öfkeye, düşükse korkuya/tedirginliğe döner.

const CS := preload("res://characters/base/character_state.gd")

const EMOTIONS := ["neutral", "calm", "nervous", "angry", "afraid", "sad", "surprised", "confident"]
## duygu -> CharacterRig.EXPRESSIONS anahtarı
const EXPRESSION := {
	"neutral": "neutral", "calm": "focused", "nervous": "nervous", "angry": "angry",
	"afraid": "nervous", "sad": "broken", "surprised": "nervous", "confident": "smug",
}

var base: CharacterBody3D
var emotion := "neutral"
var intensity := 0.0
var stress := 0.0
var _forced := 0.0


func bind(owner_base: CharacterBody3D) -> void:
	base = owner_base
	_evaluate()


func add_stress(amount: float) -> void:
	var resist: float = base.trait_value("stress_resistance")
	stress = clampf(stress + amount * (1.15 - resist), 0.0, 100.0)
	_evaluate()


func set_emotion(next: String, power := 0.6, duration := 0.0) -> void:
	if not EMOTIONS.has(next):
		return
	_forced = duration
	_apply(next, clampf(power, 0.0, 1.0))


func _process(delta: float) -> void:
	if base == null:
		return
	if _forced > 0.0:
		_forced -= delta
		if _forced <= 0.0:
			_evaluate()
		return
	if stress > 0.0:
		var calm: float = 0.6 + 2.2 * base.trait_value("stress_resistance") + 1.2 * base.trait_value("patience")
		var before := stress
		stress = maxf(0.0, stress - calm * delta)
		if int(before / 5.0) != int(stress / 5.0):
			_evaluate()


func _evaluate() -> void:
	var aggression: float = base.trait_value("aggression")
	var confidence: float = base.trait_value("confidence")
	var next := "neutral"
	if stress < 20.0:
		next = "confident" if confidence >= 0.8 and stress < 8.0 else "neutral"
	elif stress < 70.0:
		next = "angry" if aggression >= 0.5 else "nervous"
	else:
		next = "angry" if aggression >= 0.6 else "afraid"
	_apply(next, clampf(stress / 100.0, 0.0, 1.0))


func _apply(next: String, power: float) -> void:
	var changed := next != emotion
	emotion = next
	intensity = power
	base.rig.set_expression(EXPRESSION.get(next, "neutral"))
	if changed:
		base.emotion_changed.emit(next)
