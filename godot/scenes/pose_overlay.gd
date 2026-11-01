extends SkeletonModifier3D

## Animasyon üstüne prosedürel kemik ofsetleri (duruş, el-çene, baş sallama, titreme).
## offsets: kemik adı -> Euler derece; sway: kemik adı -> [genlik derece Vector3, hız].

var offsets: Dictionary = {}
var sway: Dictionary = {}
var locked: Dictionary = {}
var weight := 1.0
var _time := 0.0
var _cache: Dictionary = {}


func set_offsets(next: Dictionary, next_sway: Dictionary = {}, next_locked: Array = []) -> void:
	offsets = next
	sway = next_sway
	locked.clear()
	for bone_name in next_locked:
		locked[str(bone_name)] = true
	_cache.clear()


func _process_modification() -> void:
	var skeleton := get_skeleton()
	if skeleton == null:
		return
	_time += get_process_delta_time()
	for bone_name in offsets.keys():
		var euler: Vector3 = offsets[bone_name]
		_apply(skeleton, bone_name, euler)
	for bone_name in sway.keys():
		if locked.has(bone_name):
			continue
		var spec: Array = sway[bone_name]
		var amp: Vector3 = spec[0]
		var speed: float = spec[1]
		var phase: float = sin(_time * speed)
		_apply(skeleton, bone_name, amp * phase)


const BONE_ALIAS := {
	"Spine": "Abdomen", "Chest": "Torso", "UpperChest": "Chest",
	"LeftShoulder": "Shoulder.L", "LeftUpperArm": "UpperArm.L", "LeftLowerArm": "LowerArm.L", "LeftHand": "Hand.L",
	"RightShoulder": "Shoulder.R", "RightUpperArm": "UpperArm.R", "RightLowerArm": "LowerArm.R", "RightHand": "Hand.R",
}


func _apply(skeleton: Skeleton3D, bone_name: String, euler_deg: Vector3) -> void:
	var idx: int = _cache.get(bone_name, -2)
	if idx == -2:
		idx = skeleton.find_bone(bone_name)
		if idx < 0 and BONE_ALIAS.has(bone_name):
			idx = skeleton.find_bone(str(BONE_ALIAS[bone_name]))
		_cache[bone_name] = idx
	if idx < 0:
		return
	var offset := Quaternion.from_euler(euler_deg * (PI / 180.0) * weight)
	if locked.has(bone_name):
		skeleton.set_bone_pose_rotation(idx, offset)
	else:
		skeleton.set_bone_pose_rotation(idx, skeleton.get_bone_pose_rotation(idx) * offset)
