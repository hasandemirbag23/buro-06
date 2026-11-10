extends Node3D

## BÜRO karakter rigi: Quaternius CC0 taban modeli + Universal Animation Library (humanoid retarget)
## + data/characters.json tasarım sistemi (renk, duruş, isimli aksiyonlar) + prosedürel poz katmanı.
## Sahneler: setup(), play(GameState durumu), pose(döngü), act(isimli aksiyon), set_expression().

const MeshFactory := preload("res://scenes/mesh_factory.gd")
const PoseOverlay := preload("res://scenes/pose_overlay.gd")
const AnimCatalog := preload("res://scenes/anim_catalog.gd")
const Styler := preload("res://scenes/character_styler.gd")
const FaceRig := preload("res://scenes/face_rig.gd")
const ANIM_LIB := preload("res://assets/anim/AnimationLibrary_Godot_Standard.gltf")
const DESIGN_PATH := "res://data/characters.json"

const FALLBACK := {
	"POLICE": "res://assets/characters/man_Suit.glb",
	"FORENSIC": "res://assets/characters/man_Worker.glb",
	"SITE_CHIEF": "res://assets/characters/man_Worker.glb",
	"CRIMINAL_BOSS": "res://assets/characters/man_Suit.glb",
}

## Döngülü poz -> kütüphane klibi
const CLIPS := {
	"breathe": "Idle", "talk": "Idle_Talking", "sit": "Sitting_Idle", "sit_talk": "Sitting_Talking",
	"inspect": "Crouch_Idle", "stand": "Idle", "walk": "Walk", "walk_formal": "Walk_Formal",
	"kneel": "Fixing_Kneeling", "interact": "Interact", "pickup": "PickUp_Table", "hit": "Hit_Chest", "push": "Push",
	"run": "Sprint",
}
const LOOPING := ["Idle", "Idle_Talking", "Sitting_Idle", "Sitting_Talking", "Crouch_Idle", "Fixing_Kneeling", "Walk", "Walk_Formal", "Idle_Torch", "Jog_Fwd", "Crouch_Fwd", "Sprint"]


## Kol ofsetleri (derece): kemik ekseni Y kol boyunca; X eğme, Z öne kaldırma.
const ARM_CHIN_R := {"RightUpperArm": Vector3(35, 0, 0), "RightLowerArm": Vector3(125, 0, 0), "RightHand": Vector3(20, 0, 0)}
const ARM_TEA_L := {"LeftUpperArm": Vector3(30, 0, 0), "LeftLowerArm": Vector3(130, 0, 0), "LeftHand": Vector3(15, 0, 0)}
const ARMS_HOLD := {"LeftUpperArm": Vector3(20, 0, 0), "LeftLowerArm": Vector3(95, 0, 0), "RightUpperArm": Vector3(20, 0, 0), "RightLowerArm": Vector3(95, 0, 0)}
const ARMS_CUFF := {"LeftUpperArm": Vector3(20, 75, -105), "LeftLowerArm": Vector3(40, 0, 0), "RightUpperArm": Vector3(20, -75, 105), "RightLowerArm": Vector3(40, 0, 0), "LeftHand": Vector3.ZERO, "RightHand": Vector3.ZERO}
const ARMS_CUFF_SIT := {"LeftUpperArm": Vector3(50, 20, -120), "LeftLowerArm": Vector3(50, 0, 0), "RightUpperArm": Vector3(50, -20, 120), "RightLowerArm": Vector3(50, 0, 0), "LeftHand": Vector3.ZERO, "RightHand": Vector3.ZERO}
const CUFF_LOCK := ["LeftUpperArm", "LeftLowerArm", "LeftHand", "RightUpperArm", "RightLowerArm", "RightHand"]
const ARMS_CAMERA := {"LeftUpperArm": Vector3(60, 0, 0), "LeftLowerArm": Vector3(115, 0, 0), "RightUpperArm": Vector3(60, 0, 0), "RightLowerArm": Vector3(115, 0, 0)}
const ARMS_CROSSED := {"LeftUpperArm": Vector3(38, -60, -12), "LeftLowerArm": Vector3(118, 0, 0), "RightUpperArm": Vector3(38, 60, 12), "RightLowerArm": Vector3(118, 0, 0)}
const ARMS_TABLE := {"LeftUpperArm": Vector3(28, 0, 0), "LeftLowerArm": Vector3(70, 0, 0), "RightUpperArm": Vector3(28, 0, 0), "RightLowerArm": Vector3(70, 0, 0)}
const PRESETS := {
	"chin": ARM_CHIN_R,
	"tea": ARM_TEA_L,
	"hold": ARMS_HOLD,
	"camera": ARMS_CAMERA,
	"crossed": ARMS_CROSSED,
	"table": ARMS_TABLE,
	"radio": {"RightUpperArm": Vector3(55, -20, 0), "RightLowerArm": Vector3(120, 0, 0), "RightHand": Vector3(10, 0, 0)},
	"point": {"RightUpperArm": Vector3(72, 10, 0), "RightLowerArm": Vector3(18, 0, 0)},
	"upright": {"Spine": Vector3(-6, 0, 0), "Chest": Vector3(-3, 0, 0)},
}

## İsimli aksiyon -> {clip, offsets, sway, sweat, oneshot}
const ACTIONS := {
	"Idle": {"clip": "breathe"},
	"Talking": {"clip": "talk"},
	"Walking": {"clip": "walk"},
	"Inspecting": {"clip": "inspect"},
	"Thinking": {"clip": "breathe", "offsets": ARM_CHIN_R, "extra": {"Head": Vector3(8, -12, 6)}},
	"DrinkingTea": {"clip": "breathe", "offsets": ARM_TEA_L, "extra": {"Head": Vector3(-6, 0, 0)}},
	"Angry": {"clip": "talk", "extra": {"Spine": Vector3(12, 0, 0), "Head": Vector3(-8, 0, 0), "LeftShoulder": Vector3(0, 0, 8), "RightShoulder": Vector3(0, 0, -8)}},
	"Photographing": {"clip": "inspect", "offsets": ARMS_CAMERA, "extra": {"Head": Vector3(6, 0, 0)}},
	"WritingReport": {"clip": "breathe", "offsets": ARMS_HOLD, "extra": {"Head": Vector3(22, 0, 0), "Spine": Vector3(6, 0, 0)}},
	"ReviewingDocuments": {"clip": "breathe", "offsets": ARMS_HOLD, "extra": {"Head": Vector3(18, 0, 0)}},
	"LookingAround": {"clip": "breathe", "sway": {"Head": [Vector3(0, 38, 0), 0.9], "Chest": [Vector3(0, 10, 0), 0.9]}},
	"Confident": {"clip": "breathe", "offsets": ARMS_CROSSED, "extra": {"Spine": Vector3(-6, 0, 0), "Head": Vector3(-5, 0, 0)}},
	"Arrogant": {"clip": "talk", "extra": {"Spine": Vector3(-8, 0, 0), "Head": Vector3(-12, 0, -6), "LeftShoulder": Vector3(0, 0, -6), "RightShoulder": Vector3(0, 0, 6)}},
	"Nervous": {"clip": "talk", "extra": {"Head": Vector3(10, 0, 0), "Spine": Vector3(5, 0, 0)}, "sway": {"Head": [Vector3(0, 6, 3), 7.0], "Chest": [Vector3(0, 0, 1.5), 9.0]}},
	"Sweat": {"clip": "talk", "sweat": true, "extra": {"Head": Vector3(12, 0, 0), "Spine": Vector3(6, 0, 0)}, "sway": {"Head": [Vector3(0, 6, 3), 7.0], "Chest": [Vector3(0, 0, 1.5), 9.0]}},
	"Confession": {"clip": "breathe", "sweat": true, "extra": {"Spine": Vector3(16, 0, 0), "Chest": Vector3(8, 0, 0), "Head": Vector3(30, 0, 0), "LeftShoulder": Vector3(0, 0, 12), "RightShoulder": Vector3(0, 0, -12)}},
	"Breakdown": {"clip": "breathe", "sweat": true, "extra": {"Spine": Vector3(18, 0, 0), "Chest": Vector3(8, 0, 0), "Head": Vector3(34, 0, 0), "LeftShoulder": Vector3(0, 0, 12), "RightShoulder": Vector3(0, 0, -12)}, "sway": {"Chest": [Vector3(1.5, 0, 0), 2.2]}},
	"Defensive": {"clip": "breathe", "offsets": ARMS_CROSSED, "extra": {"Spine": Vector3(-10, 0, 0), "Head": Vector3(-4, 18, 0)}},
	"NervousHands": {"clip": "breathe", "offsets": ARMS_TABLE, "extra": {"Head": Vector3(6, 24, 0), "Spine": Vector3(4, 0, 0)}, "sway": {"LeftHand": [Vector3(16, 0, 12), 6.3], "RightHand": [Vector3(14, 0, -10), 7.1], "Head": [Vector3(0, 10, 0), 1.1]}},
	"SweatHands": {"clip": "breathe", "sweat": true, "offsets": ARMS_TABLE, "extra": {"Head": Vector3(10, 20, 0), "Spine": Vector3(6, 0, 0)}, "sway": {"LeftHand": [Vector3(16, 0, 12), 6.3], "RightHand": [Vector3(14, 0, -10), 7.1], "Head": [Vector3(0, 8, 2), 5.0]}},
	"Listen": {"clip": "breathe", "extra": {"Head": Vector3(2, 0, 7), "Spine": Vector3(2, 0, 0)}, "sway": {"Head": [Vector3(4, 0, 0), 1.3]}, "expression": "focused"},
	"Surprise": {"clip": "breathe", "extra": {"Spine": Vector3(-10, 0, 0), "Head": Vector3(-12, 0, 0), "LeftShoulder": Vector3(0, 0, 10), "RightShoulder": Vector3(0, 0, -10), "LeftUpperArm": Vector3(18, 0, -14), "RightUpperArm": Vector3(18, 0, 14)}, "expression": "nervous"},
	"Running": {"clip": "run", "expression": "focused"},
	"Crouch": {"clip": "inspect"},
	"Cuffed": {"clip": "walk", "offsets": ARMS_CUFF, "lock": CUFF_LOCK, "extra": {"Head": Vector3(14, 0, 0), "Spine": Vector3(6, 0, 0)}},
	"GrabArm": {"clip": "breathe", "offsets": {"RightUpperArm": Vector3(58, 20, 8), "RightLowerArm": Vector3(48, 0, 0), "RightHand": Vector3(8, 0, 0)}, "extra": {"Head": Vector3(8, -18, 0), "Spine": Vector3(4, 0, 0)}},
	"TableSlam": {"clip": "talk", "offsets": ARMS_TABLE, "extra": {"Spine": Vector3(14, 0, 0), "Head": Vector3(-6, 0, 0)}},
}

## Yüz ifadesi -> blend shape adayları (model destekliyorsa) ve baş ofseti yedeği.
const EXPRESSIONS := {
	"neutral": {"shapes": {}, "head": Vector3.ZERO},
	"tired": {"shapes": {"browDownLeft": 0.5, "browDownRight": 0.5, "eyeSquintLeft": 0.4, "eyeSquintRight": 0.4}, "head": Vector3(6, 0, 0)},
	"angry": {"shapes": {"browDownLeft": 1.0, "browDownRight": 1.0, "jawForward": 0.3, "mouthFrownLeft": 0.6, "mouthFrownRight": 0.6}, "head": Vector3(-6, 0, 0)},
	"nervous": {"shapes": {"browInnerUp": 0.8, "eyeWideLeft": 0.5, "eyeWideRight": 0.5, "mouthPressLeft": 0.5, "mouthPressRight": 0.5}, "head": Vector3(8, 0, 4)},
	"smug": {"shapes": {"mouthSmileRight": 0.6, "browDownLeft": 0.3, "eyeSquintRight": 0.3}, "head": Vector3(-8, 0, -4)},
	"broken": {"shapes": {"browInnerUp": 1.0, "mouthFrownLeft": 0.8, "mouthFrownRight": 0.8, "eyeSquintLeft": 0.6, "eyeSquintRight": 0.6}, "head": Vector3(22, 0, 0)},
	"focused": {"shapes": {"browDownLeft": 0.4, "browDownRight": 0.4, "eyeSquintLeft": 0.5, "eyeSquintRight": 0.5}, "head": Vector3(6, 0, 0)},
}

static var _library: AnimationLibrary
static var _designs: Dictionary = {}

var who := ""
var state_flag := ""
var state := ""
var seated := false
var design: Dictionary = {}
var sweat: Array[MeshInstance3D] = []
var body: Node3D
var model: Node3D
var skeleton: Skeleton3D
var player: AnimationPlayer
var tree: AnimationTree
var overlay: SkeletonModifier3D
var _machine: AnimationNodeStateMachine
var _started := false
var _travel_tries := 0
var _oneshot_token := 0
var head_mesh: MeshInstance3D
var face: Node
var _neck_head: BoneAttachment3D
var _neck_base: BoneAttachment3D
var _neck_rest := Transform3D.IDENTITY
var _breath: Tween
var _xfade := 0.25
var _xfades: Dictionary = {}
var _clip := ""
var _oneshot := ""
var _expression := Vector3.ZERO
var _action_offsets: Dictionary = {}
var _locked: Array = []
var _gaze_target: Variant = null
var _gaze := Vector3.ZERO
var _gaze_goal := Vector3.ZERO
var _gaze_speed := 5.0
var _turn: Tween


static func designs() -> Dictionary:
	if _designs.is_empty():
		var text := FileAccess.get_file_as_string(DESIGN_PATH)
		var parsed = JSON.parse_string(text)
		if parsed is Dictionary:
			_designs = parsed
	return _designs


func setup(who_id: String) -> void:
	who = who_id
	design = designs().get(who, {})
	_build()
	play("IDLE")


## GameState anim durumları (sorgu odası ve eski çağrılar).
func play(next_state: String) -> void:
	if next_state == state:
		return
	state = next_state
	_kill_breath()
	_reset_body()
	match next_state:
		"IDLE":
			act("Idle")
		"TALKING":
			act("Talking")
		"ARROGANT":
			act("Sit_Arrogant" if seated else "Arrogant")
		"LOOK_AWAY":
			act("LookAway")
		"ANGRY":
			act("Angry")
		"CONFIDENT", "DEFENSIVE":
			act("Defensive" if next_state == "DEFENSIVE" else "Confident")
		"BROKEN_CONFESS":
			act("Breakdown")
		"ANGRY_SLAM":
			act("Slam_Table")
		"NERVOUS":
			act("NervousHands" if seated else "Nervous")
		"NERVOUS_SWEAT":
			act("SweatHands" if seated else "Sweat")
		"KNEEL":
			pose("kneel")
		"PHOTO":
			act("PhotographEvidence")
		_:
			act("Idle")


## Tasarım sistemindeki isimli aksiyon (Idle, Talking, Angry, DrinkingTea, Thinking, Photographing, ...).
func act(action: String) -> void:
	var spec := _spec(action)
	var clip: String = spec.get("clip", "breathe")
	if seated and clip in ["breathe", "talk"]:
		clip = "sit_talk" if clip == "talk" else "sit"
	_xfade = float(spec.get("xfade", 0.25))
	_action_offsets = {}
	_action_offsets.merge(spec.get("offsets", {}))
	_action_offsets.merge(spec.get("extra", {}))
	_locked = spec.get("lock", [])
	if skeleton != null and skeleton.has_node("CuffL"):
		var arms: Dictionary = ARMS_CUFF_SIT if seated else ARMS_CUFF
		for bone in CUFF_LOCK:
			_action_offsets[bone] = arms[bone]
		_locked = CUFF_LOCK
		if seated and clip in ["breathe", "talk", "walk", "walk_formal"]:
			clip = "sit"
	_push_overlay(spec.get("sway", {}))
	for drop in sweat:
		drop.visible = bool(spec.get("sweat", false))
	pose(clip)
	var face := str(spec.get("expression", ""))
	if face != "":
		set_expression(face)
	var shot := str(spec.get("oneshot", ""))
	if shot != "":
		oneshot(shot, clip)


## Masaya vurma: kollar kalkar, iner; gövde öne atılır.
func _spec(action: String) -> Dictionary:
	var raw := AnimCatalog.get_state(action)
	if raw.is_empty():
		return ACTIONS.get(action, ACTIONS["Idle"])
	var clip := str(raw.get("clip", "breathe"))
	if seated and str(raw.get("seated_clip", "")) != "":
		clip = str(raw["seated_clip"])
	var offsets: Dictionary = {}
	var pose_name := str(raw.get("pose", ""))
	if pose_name != "" and PRESETS.has(pose_name):
		offsets = PRESETS[pose_name]
	return {
		"clip": clip,
		"offsets": offsets,
		"extra": _vec_map(raw.get("extra", {})),
		"sway": _sway_map(raw.get("sway", {})),
		"sweat": bool(raw.get("sweat", false)),
		"expression": str(raw.get("expression", "")),
		"oneshot": str(raw.get("oneshot", "")),
		"xfade": float(raw.get("xfade", AnimCatalog.xfade_default())),
	}


func _vec_map(raw: Variant) -> Dictionary:
	var out: Dictionary = {}
	if raw is Dictionary:
		for key in raw.keys():
			var arr: Array = raw[key]
			out[key] = Vector3(float(arr[0]), float(arr[1]), float(arr[2]))
	return out


func _sway_map(raw: Variant) -> Dictionary:
	var out: Dictionary = {}
	if raw is Dictionary:
		for key in raw.keys():
			var pair: Array = raw[key]
			var amp: Array = pair[0]
			out[key] = [Vector3(float(amp[0]), float(amp[1]), float(amp[2])), float(pair[1])]
	return out


func slam_table() -> void:
	act("Slam_Table")
	var tween := create_tween()
	tween.tween_method(_slam_phase, 0.0, 1.0, 0.22).set_ease(Tween.EASE_OUT)
	tween.tween_method(_slam_phase, 1.0, 2.0, 0.09).set_ease(Tween.EASE_IN)
	tween.tween_method(_slam_phase, 2.0, 3.0, 0.45).set_ease(Tween.EASE_OUT)


func _slam_phase(p: float) -> void:
	var raise := Vector3(70, 0, 0)
	var raise_low := Vector3(40, 0, 0)
	var hit := Vector3(22, 0, 0)
	var hit_low := Vector3(60, 0, 0)
	var rest := ARMS_TABLE["LeftUpperArm"]
	var rest_low := ARMS_TABLE["LeftLowerArm"]
	var up: Vector3
	var low: Vector3
	var lean := 14.0
	if p < 1.0:
		up = rest.lerp(raise, p)
		low = rest_low.lerp(raise_low, p)
		lean = lerpf(14.0, 4.0, p)
	elif p < 2.0:
		up = raise.lerp(hit, p - 1.0)
		low = raise_low.lerp(hit_low, p - 1.0)
		lean = lerpf(4.0, 24.0, p - 1.0)
	else:
		up = hit.lerp(rest, p - 2.0)
		low = hit_low.lerp(rest_low, p - 2.0)
		lean = lerpf(24.0, 14.0, p - 2.0)
	_action_offsets = {"LeftUpperArm": up, "RightUpperArm": up, "LeftLowerArm": low, "RightLowerArm": low, "Spine": Vector3(lean, 0, 0), "Head": Vector3(-6, 0, 0)}
	_push_overlay({})


## Bakış: Node3D, Vector3 (dünya) ya da null. Baş ve gövde yumuşakça döner.
func look_at_target(target: Variant, speed := 5.0) -> void:
	_gaze_target = target
	_gaze_speed = speed
	set_process(true)


func clear_gaze() -> void:
	look_at_target(null, 3.0)


func _process(delta: float) -> void:
	if not is_inside_tree():
		return
	_gaze_goal = Vector3.ZERO
	var at: Variant = _gaze_target
	if at is Object and not is_instance_valid(at):
		_gaze_target = null
		at = null
	if at != null:
		var world: Vector3 = at.global_position if at is Node3D else at
		var local := global_transform.affine_inverse() * world
		var flat := Vector2(local.x, local.z).length()
		var yaw := rad_to_deg(atan2(local.x, local.z))
		var pitch := rad_to_deg(atan2(local.y - 1.55, maxf(flat, 0.2)))
		if absf(yaw) < 100.0:
			_gaze_goal = Vector3(clampf(-pitch, -22.0, 22.0), clampf(yaw, -70.0, 70.0), 0.0)
	var next := _gaze.lerp(_gaze_goal, 1.0 - exp(-_gaze_speed * delta))
	# Göz, başın götürmediği payı alır: baş 0.65, göz ~0.5 — gerçekte göz önce
	# gider, baş arkasından döner.
	if face:
		face.set_gaze(_gaze.x * 0.5, _gaze.y * 0.55)
	if next.distance_to(_gaze) > 0.02:
		_gaze = next
		_push_overlay(overlay.sway if overlay else {})
	elif _gaze_target == null and _gaze_goal == Vector3.ZERO and _gaze.length() > 0.0:
		_gaze = Vector3.ZERO
		_push_overlay(overlay.sway if overlay else {})


## Gövdeyi hedefe çevirir (Turn). Bitince callback.
func turn_to(world: Vector3, duration := 0.5) -> void:
	var delta := world - global_position
	if Vector2(delta.x, delta.z).length() < 0.05:
		return
	var goal := atan2(delta.x, delta.z)
	if _turn:
		_turn.kill()
	_turn = create_tween()
	_turn.tween_method(func(a: float) -> void: rotation.y = a, rotation.y, rotation.y + wrapf(goal - rotation.y, -PI, PI), duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


## Döngülü poz.
func pose(clip: String) -> void:
	if clip == _clip and _oneshot == "":
		return
	_clip = clip
	_oneshot = ""
	_play_clip(clip, _xfade)


## Tek seferlik klip; bitince `then` pozuna döner.
func oneshot(clip: String, then: String) -> void:
	_clip = then
	_oneshot = clip
	_play_clip(clip, 0.15)


## Yüz ifadesi: kafa heykelini deforme eden FaceRig'e geçer, baş duruşuyla destekler.
## (Eski kod 52 ARKit blend shape arıyordu; ne taban modelde ne de üretilen
## kafalarda hiç blend shape olmadı, ifade yalnız baş açısı olarak kalıyordu.)
func set_expression(name: String) -> void:
	var spec: Dictionary = EXPRESSIONS.get(name, EXPRESSIONS["neutral"])
	_expression = spec["head"]
	if face:
		face.set_expression(name)
	_push_overlay(overlay.sway if overlay else {})


func _bind_face(display_name: String) -> void:
	face = null
	var head_root := get_meta("head_root", null) as Node3D
	if head_root == null:
		return
	face = FaceRig.new()
	face.name = "FaceRig"
	add_child(face)
	face.bind(head_root, who, display_name)
	_bind_neck()


## Kafa mesh'i 33 cm'lik boynuyla birlikte Head kemiğine bağlı; baş dönünce boyun
## da rijit dönüp omuza giriyordu. Boynun tabanı göğüs kemiğine devredilir:
## deri gölgelendiricisi köşeleri baş ile göğüs arasında harmanlar (neck_xf).
func _bind_neck() -> void:
	_neck_head = null
	_neck_base = null
	if skeleton == null or face == null:
		return
	_neck_head = skeleton.get_node_or_null("StyledHead") as BoneAttachment3D
	var head_idx := skeleton.find_bone("Head")
	var base_idx := -1
	var base_name := ""
	for candidate in ["UpperChest", "Chest", "Neck"]:
		base_idx = skeleton.find_bone(candidate)
		if base_idx >= 0:
			base_name = candidate
			break
	if _neck_head == null or head_idx < 0 or base_idx < 0:
		return
	_neck_base = BoneAttachment3D.new()
	_neck_base.name = "NeckBase"
	_neck_base.bone_name = base_name
	skeleton.add_child(_neck_base)
	var offset := Transform3D(Basis(), Styler.HEAD_OFFSET)
	_neck_rest = skeleton.get_bone_global_rest(base_idx).affine_inverse() * skeleton.get_bone_global_rest(head_idx) * offset
	if not skeleton.skeleton_updated.is_connected(_update_neck):
		skeleton.skeleton_updated.connect(_update_neck)


## Kemik eklentileri de aynı sinyalle güncellenir ve bizden önce bağlandıkları
## için burada okunan dönüşümler PoseOverlay sonrası, yani ekrandaki pozdur.
func _update_neck() -> void:
	if face == null or not is_instance_valid(_neck_head) or not is_instance_valid(_neck_base):
		return
	var head := _neck_head.transform * Transform3D(Basis(), Styler.HEAD_OFFSET)
	var xf := head.affine_inverse() * _neck_base.transform * _neck_rest
	for m in face.mats:
		m.set_shader_parameter("neck_xf", xf)


## Konuşma süresi dışarıdan verilince ağız o kadar oynar (sinematik, seslendirme).
func talk_for(seconds: float) -> void:
	if face:
		face.talk_for(seconds)


func _push_overlay(sway: Dictionary) -> void:
	if overlay == null:
		return
	var merged: Dictionary = {}
	for key in design.get("overlay", {}).keys():
		var arr: Array = design["overlay"][key]
		merged[key] = Vector3(arr[0], arr[1], arr[2])
	for key in _action_offsets.keys():
		if _locked.has(key):
			merged[key] = _action_offsets[key]
		else:
			merged[key] = merged.get(key, Vector3.ZERO) + _action_offsets[key]
	if _expression != Vector3.ZERO:
		merged["Head"] = merged.get("Head", Vector3.ZERO) + _expression
	if _gaze.length() > 0.05:
		merged["Head"] = merged.get("Head", Vector3.ZERO) + _gaze * 0.65
		merged["Chest"] = merged.get("Chest", Vector3.ZERO) + _gaze * 0.25
		merged["Spine"] = merged.get("Spine", Vector3.ZERO) + _gaze * 0.1
	overlay.set_offsets(merged, sway, _locked)


func _play_clip(clip: String, _blend: float) -> void:
	if player == null:
		return
	var anim_name: String = CLIPS.get(clip, clip)
	if not player.has_animation(anim_name):
		anim_name = "Idle"
	_travel_tries = 0
	_travel(anim_name, _xfade)
	if _oneshot != "" and not anim_name in LOOPING:
		var length := player.get_animation(anim_name).length
		_oneshot_token += 1
		var token := _oneshot_token
		get_tree().create_timer(length).timeout.connect(func() -> void:
			if token == _oneshot_token and _oneshot != "":
				_oneshot = ""
				_play_clip(_clip, 0.3)
		)


## AnimationTree durum makinesinde klibe geç (ilk seferde start, sonra travel).
func _travel(anim_name: String, blend: float = 0.25) -> void:
	if tree == null:
		return
	tree.active = true
	var playback = tree.get("parameters/playback")
	if playback == null or not is_inside_tree():
		_travel_tries += 1
		if _travel_tries < 8:
			call_deferred("_travel", anim_name, blend)
		return
	if not _machine.has_node(anim_name):
		anim_name = "Idle"
	var current := str(playback.get_current_node())
	if not _started or current == "Start" or current == "":
		playback.start(anim_name)
		if not _started:
			_started = true
			call_deferred("_travel", anim_name, blend)
		return
	var link := "%s>%s" % [current, anim_name]
	if _xfades.has(link):
		(_xfades[link] as AnimationNodeStateMachineTransition).xfade_time = blend
	playback.travel(anim_name)


func _kill_breath() -> void:
	if _breath:
		_breath.kill()
		_breath = null


func _reset_body() -> void:
	if body == null:
		return
	body.position = Vector3.ZERO
	body.rotation = Vector3.ZERO
	body.scale = Vector3.ONE


func _build() -> void:
	for child in get_children():
		child.queue_free()
	sweat.clear()
	body = Node3D.new()
	body.name = "Body"
	add_child(body)
	var spec := Scenario.character(who)
	if spec.is_empty():
		return
	var path: String = design.get("model", FALLBACK.get(spec["model"], FALLBACK["POLICE"]))
	var packed: PackedScene = load(path)
	model = packed.instantiate()
	model.name = "Model"
	body.add_child(model)
	skeleton = model.find_child("GeneralSkeleton", true, false) as Skeleton3D
	_bind_animations()
	_tint(design.get("tint", {}))
	_shadows(model)
	overlay = PoseOverlay.new()
	overlay.name = "PoseOverlay"
	if skeleton:
		skeleton.add_child(overlay)
	_accessory(spec)
	Styler.apply(self, who)
	_bind_face(str(spec.get("name", "")))
	_push_overlay({})
	var title: String = design.get("title", spec["name"])
	var tag := MeshFactory.label(body, title, Vector3(0, 2.05, 0), Color("e7e1d6"), 0.55)
	tag.fixed_size = true
	tag.pixel_size = 0.0007


func _bind_animations() -> void:
	if _library == null:
		_library = AnimationLibrary.new()
		var src := ANIM_LIB.instantiate()
		var src_player := src.find_child("AnimationPlayer", true, false) as AnimationPlayer
		if src_player:
			for anim_name in src_player.get_animation_list():
				var anim := src_player.get_animation(anim_name)
				if anim_name in LOOPING:
					anim.loop_mode = Animation.LOOP_LINEAR
				_library.add_animation(anim_name, anim)
		src.free()
	player = AnimationPlayer.new()
	player.name = "AnimationPlayer"
	model.add_child(player)
	player.root_node = NodePath("..")
	player.add_animation_library("", _library)
	_machine = AnimationNodeStateMachine.new()
	var used_clips: Array = []
	for clip in CLIPS.values():
		if not used_clips.has(clip) and player.has_animation(clip):
			used_clips.append(clip)
	for clip in used_clips:
		var node := AnimationNodeAnimation.new()
		node.animation = clip
		_machine.add_node(clip, node)
	for clip in used_clips:
		for other in used_clips:
			if other == clip:
				continue
			var transition := AnimationNodeStateMachineTransition.new()
			transition.switch_mode = AnimationNodeStateMachineTransition.SWITCH_MODE_IMMEDIATE
			transition.xfade_time = 0.25
			_machine.add_transition(other, clip, transition)
			_xfades["%s>%s" % [other, clip]] = transition
	tree = AnimationTree.new()
	tree.name = "AnimationTree"
	tree.tree_root = _machine
	model.add_child(tree)
	tree.anim_player = tree.get_path_to(player)
	tree.active = true


## "Parça/Materyal" -> renk. Parça: Body, Head, Legs, Feet (mesh adının son eki).
func _tint(tints: Dictionary) -> void:
	for mesh_instance in _meshes(model):
		var part: String = mesh_instance.name.get_slice("_", 1)
		if part == "":
			part = mesh_instance.name
		if part == "Head":
			head_mesh = mesh_instance
		var mesh: Mesh = mesh_instance.mesh
		if mesh == null:
			continue
		for surface in mesh.get_surface_count():
			var base := mesh.surface_get_material(surface) as StandardMaterial3D
			if base == null:
				continue
			var key := "%s/%s" % [part, base.resource_name]
			if tints.has(key):
				var mat := base.duplicate() as StandardMaterial3D
				mat.albedo_color = Color(tints[key])
				mesh_instance.set_surface_override_material(surface, mat)


func _meshes(node: Node) -> Array[MeshInstance3D]:
	var out: Array[MeshInstance3D] = []
	if node is MeshInstance3D:
		out.append(node)
	for child in node.get_children():
		out.append_array(_meshes(child))
	return out


func _shadows(node: Node) -> void:
	if node is MeshInstance3D:
		node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	for child in node.get_children():
		_shadows(child)


func wear_cuffs() -> void:
	if skeleton == null or skeleton.has_node("CuffL"):
		return
	var steel := StandardMaterial3D.new()
	steel.albedo_color = Color("c5c8ce")
	steel.metallic = 0.85
	steel.roughness = 0.28
	for bone in ["LeftHand", "RightHand"]:
		var hand := _attach(bone)
		if hand == null:
			continue
		hand.name = "CuffL" if bone.begins_with("Left") else "CuffR"
		var ring := MeshInstance3D.new()
		var torus := TorusMesh.new()
		torus.inner_radius = 0.032
		torus.outer_radius = 0.044
		ring.mesh = torus
		ring.material_override = steel
		ring.position = Vector3(0, 0.015, 0)
		hand.add_child(ring)


func _attach(bone: String) -> BoneAttachment3D:
	if skeleton == null:
		return null
	var attachment := BoneAttachment3D.new()
	attachment.bone_name = bone
	skeleton.add_child(attachment)
	return attachment


func _accessory(spec: Dictionary) -> void:
	var head := _attach("Head")
	if head:
		var drop_a := MeshFactory.sphere(head, 0.022, Vector3(0.07, 0.06, 0.1), Color("9fd7ff"))
		var drop_b := MeshFactory.sphere(head, 0.018, Vector3(-0.08, 0.0, 0.1), Color("9fd7ff"))
		drop_a.visible = false
		drop_b.visible = false
		sweat = [drop_a, drop_b]
	match spec["accessory"]:
		"TEA_GLASS":
			var hand := _attach("LeftHand")
			if hand:
				MeshFactory.cylinder(hand, 0.03, 0.1, Vector3(0, -0.08, 0.04), Color("d8c7a1"))
				MeshFactory.cylinder(hand, 0.024, 0.06, Vector3(0, -0.1, 0.04), Color("6b3a2a"))
		"CAMERA":
			var chest := _attach("UpperChest")
			if chest:
				MeshFactory.box(chest, Vector3(0.14, 0.09, 0.08), Vector3(0, 0.0, 0.16), Color("111111"))
				MeshFactory.cylinder(chest, 0.03, 0.04, Vector3(0, 0.0, 0.22), Color("2a2a2a"))
		"GOLD_WATCH":
			var arm := _attach("RightLowerArm")
			if arm:
				MeshFactory.cylinder(arm, 0.045, 0.02, Vector3(0, 0.22, 0), Color("c6a15b"), 0.3)
		"BADGE":
			var chest := _attach("UpperChest")
			if chest:
				MeshFactory.box(chest, Vector3(0.06, 0.08, 0.015), Vector3(-0.1, 0.05, 0.14), Color("e6b450"), 0.35, 0.4)
		_:
			pass
