extends RefCounted

## Karakter görünüm katmanı: prosedürel kafa (tools/headgen), göz, saç/sakal, gözlük, aksesuar, deri ve kumaş materyalleri.
## Şablon: data/character_templates.json. Kafa varlıkları: assets/heads/<id>_skin.glb, _hair.glb, _head.json.

const HEAD_DIR := "res://assets/heads/"
const TEMPLATES := "res://data/character_templates.json"
const HEAD_OFFSET := Vector3(0.0, 0.098, 0.012)

static var _templates: Dictionary = {}
static var _hair_normal: NoiseTexture2D
static var _cloth_normal: NoiseTexture2D
static var _eye_shader: Shader


static func templates() -> Dictionary:
	if _templates.is_empty():
		var parsed = JSON.parse_string(FileAccess.get_file_as_string(TEMPLATES))
		if parsed is Dictionary:
			_templates = parsed
	return _templates


static func template(id: String) -> Dictionary:
	var out: Dictionary = (templates().get("default", {}) as Dictionary).duplicate(true)
	var over: Dictionary = templates().get("characters", {}).get(id, {})
	for key in over.keys():
		if out.get(key) is Dictionary and over[key] is Dictionary:
			out[key].merge(over[key], true)
		else:
			out[key] = over[key]
	return out


static func has_head(id: String) -> bool:
	return ResourceLoader.exists(HEAD_DIR + id + "_skin.glb")


## Kafa düğümü (deri + saç + göz + gözlük + yüz aksesuarları). Rig'den bağımsız.
static func build_head(id: String) -> Node3D:
	var tpl := template(id)
	var meta: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(HEAD_DIR + id + "_head.json"))
	var root := Node3D.new()
	root.name = "HeadRoot"
	var mats: Array[ShaderMaterial] = []
	var skin_mat := _skin_material(tpl)
	mats.append(skin_mat)
	_add_glb(root, HEAD_DIR + id + "_skin.glb", skin_mat)
	if ResourceLoader.exists(HEAD_DIR + id + "_hair.glb"):
		var hair: Dictionary = tpl.get("hair", {})
		var hair_mat := _hair_material(float(hair.get("dress", 0.0)))
		mats.append(hair_mat)
		_add_glb(root, HEAD_DIR + id + "_hair.glb", hair_mat)
	_eyes(root, meta, tpl)
	_glasses(root, meta, str(tpl.get("glasses", "none")))
	_face_props(root, meta, tpl)
	_face_uniforms(mats, meta, tpl)
	root.set_meta("head_meta", meta)
	root.set_meta("face_mats", mats)
	return root


## Yüz deformasyonunun anatomi sabitleri: göz küreleri, ağız. Heykelle aynı
## kaynaktan (head.json) geldiği için kapak tam kürenin üstünde çalışır.
static func _face_uniforms(mats: Array[ShaderMaterial], meta: Dictionary, tpl: Dictionary) -> void:
	var el: Array = meta["eye_l"]
	var er: Array = meta["eye_r"]
	var mc: Array = meta.get("mouth", [0.0, -0.061, 0.072])
	for m in mats:
		m.set_shader_parameter("eye_a", Vector3(el[0], el[1], el[2]))
		m.set_shader_parameter("eye_b", Vector3(er[0], er[1], er[2]))
		m.set_shader_parameter("eye_rad", float(meta.get("eye_radius", 0.0118)))
		m.set_shader_parameter("mouth_c", Vector3(mc[0], mc[1], mc[2]))
		m.set_shader_parameter("mouth_half", 0.016 * float(tpl.get("mouth_w", 1.0)))


## rig: character_rig.gd düğümü (skeleton, head_mesh dolu olmalı).
static func apply(rig: Node3D, id: String) -> void:
	if rig.skeleton == null or not has_head(id):
		return
	var tpl := template(id)
	var attach := BoneAttachment3D.new()
	attach.name = "StyledHead"
	attach.bone_name = "Head"
	rig.skeleton.add_child(attach)
	var root := build_head(id)
	root.position = HEAD_OFFSET
	attach.add_child(root)
	if rig.head_mesh:
		rig.head_mesh.visible = false
	_body_props(rig, tpl)
	_body(rig, tpl)
	rig.set_meta("head_root", root)
	rig.set_meta("head_meta", root.get_meta("head_meta"))


static func _add_glb(parent: Node3D, path: String, mat: Material) -> void:
	var packed: PackedScene = load(path)
	if packed == null:
		return
	var inst := packed.instantiate()
	parent.add_child(inst)
	for node in inst.find_children("*", "MeshInstance3D", true, false):
		var mi := node as MeshInstance3D
		mi.material_override = mat
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON


# ------------------------------------------------------------------ materyaller
static func _noise(freq: float, seed_value: int, size: int, strength: float, fractal := 3) -> NoiseTexture2D:
	var noise := FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.frequency = freq
	noise.seed = seed_value
	noise.fractal_octaves = fractal
	var tex := NoiseTexture2D.new()
	tex.noise = noise
	tex.width = size
	tex.height = size
	tex.seamless = true
	tex.as_normal_map = true
	tex.bump_strength = strength
	return tex


## Yüz deformasyonu: deri ve saç gölgelendiricisine birlikte enjekte edilir.
## Kaş/bıyık/sakal saç mesh'inde olduğu için ikisi aynı fonksiyonu kullanmazsa
## kaş yerinde durup alın oynar. Ölçüler kafa yerel koordinatında, metre.
const FACE_GLSL := """
uniform vec3 eye_a = vec3(0.032, 0.010, 0.056);
uniform vec3 eye_b = vec3(-0.032, 0.010, 0.056);
uniform float eye_rad = 0.0118;
uniform vec3 mouth_c = vec3(0.0, -0.061, 0.072);
uniform float mouth_half = 0.016;
uniform float f_blink = 0.0;
uniform float f_jaw = 0.0;
uniform float f_brow = 0.0;
uniform float f_brow_in = 0.0;
uniform float f_squint = 0.0;
uniform float f_smile = 0.0;
uniform float f_sneer = 0.0;
// Boyun: kafa mesh'i Head kemiğine bağlı ama boynun tabanı yakada durmalı.
// neck_xf, bir köşeyi "göğse bağlıymış gibi" taşır; çene altından tabana doğru
// ağırlık 0'dan 1'e çıkar (iki kemikli doğrusal harmanlama).
uniform mat4 neck_xf = mat4(1.0);
uniform float neck_top = -0.112;
uniform float neck_base = -0.245;

vec3 rot_x(vec3 q, float a) {
	float c = cos(a);
	float s = sin(a);
	return vec3(q.x, q.y * c - q.z * s, q.y * s + q.z * c);
}

// Göz kapağı küreyi saran kabuktur; kırpma onu kürenin yanal ekseni etrafında
// döndürür — gerçek kapak da böyle hareket eder.
vec3 lid_offset(vec3 p, vec3 c) {
	vec3 q = p - c;
	float d = length(q);
	float shell = 1.0 - smoothstep(eye_rad + 0.0015, eye_rad + 0.0115, d);
	float front = smoothstep(-0.0070, 0.0020, q.z);
	vec3 off = vec3(0.0);
	float upper = smoothstep(-0.0012, 0.0062, q.y);
	float w = shell * front * upper;
	if (w > 0.001) {
		off += (rot_x(q, f_blink * 0.80) - q) * w;
	}
	float lower = smoothstep(-0.0012, -0.0062, q.y);
	off.y += f_squint * 0.0038 * shell * front * lower;
	return off;
}

vec3 brow_offset(vec3 p) {
	float ey = (eye_a.y + eye_b.y) * 0.5;
	float h = p.y - ey;
	float band = smoothstep(0.007, 0.019, h) * (1.0 - smoothstep(0.029, 0.052, h));
	float front = smoothstep(-0.012, 0.018, p.z);
	float inner = 1.0 - smoothstep(0.004, 0.032, abs(p.x));
	float w = band * front;
	return vec3(0.0, (f_brow * 0.0062 + f_brow_in * 0.0058 * inner) * w, 0.0);
}

// Çene, kulak hizasındaki bir eksen etrafında döner: ağız açılırken çene aşağı
// ve hafif geriye gider.
vec3 jaw_offset(vec3 p) {
	// Geçiş dudak hizasında keskin olmalı: yumuşak bir geçişte alt ve üst dudak
	// birlikte iniyor, ağız açılmak yerine bütün alt yüz kayıyor.
	float w = smoothstep(mouth_c.y + 0.005, mouth_c.y - 0.009, p.y);
	if (w < 0.001) {
		return vec3(0.0);
	}
	vec3 pivot = vec3(0.0, mouth_c.y + 0.054, mouth_c.z - 0.092);
	vec3 q = p - pivot;
	vec3 d = (rot_x(q, f_jaw * 0.17) - q) * w;
	// alt dudak ortada biraz daha açılsın, ağız bademleşsin
	float lip = (1.0 - smoothstep(0.004, mouth_half * 1.6, abs(p.x - mouth_c.x)))
		* (1.0 - smoothstep(0.002, 0.014, abs(p.y - mouth_c.y)))
		* smoothstep(mouth_c.z - 0.030, mouth_c.z - 0.004, p.z);
	d.y -= f_jaw * 0.0040 * lip * w;
	return d;
}

vec3 mouth_offset(vec3 p) {
	vec3 q = p - mouth_c;
	float near = 1.0 - smoothstep(0.010, 0.036, length(vec3(q.x * 0.8, q.y, q.z * 0.6)));
	float corner = smoothstep(0.004, mouth_half, abs(q.x));
	float upper = smoothstep(-0.0012, 0.0060, q.y);
	vec3 d = vec3(0.0);
	d.y += f_smile * 0.0058 * near * corner;
	d.x += sign(q.x) * f_smile * 0.0032 * near * corner;
	d.y += f_sneer * 0.0036 * near * upper;
	return d;
}

vec3 face_offset(vec3 p) {
	return lid_offset(p, eye_a) + lid_offset(p, eye_b) + brow_offset(p) + jaw_offset(p) + mouth_offset(p);
}

void neck_apply(inout vec3 vert, inout vec3 nrm, float rest_y) {
	float w = 1.0 - smoothstep(neck_base, neck_top, rest_y);
	if (w <= 0.0) {
		return;
	}
	// Heykelin boynu tabanda omuza doğru genişliyor; gövde modelinin kendi omzu
	// olduğu için bu genişleme sırttan dışarı taşıyordu. Yakanın altında kalan
	// kısım eksenine doğru daraltılır (gövdenin içinde, görünmez).
	float taper = 1.0 - smoothstep(-0.295, -0.205, rest_y);
	vert.xz = mix(vert.xz, vec2(0.0, -0.034), taper * 0.74);
	vec3 moved = (neck_xf * vec4(vert, 1.0)).xyz;
	vec3 n2 = mat3(neck_xf) * nrm;
	vert = mix(vert, moved, w);
	nrm = normalize(mix(nrm, n2, w));
}

// Deformasyon normali de çevirir; komşu iki noktadan sonlu farkla yeniden kur.
void face_apply(inout vec3 vert, inout vec3 nrm, vec3 tang, vec3 bitang) {
	vec3 d0 = face_offset(vert);
	vec3 pt = vert + tang * 0.0015;
	vec3 pb = vert + bitang * 0.0015;
	vec3 et = (pt + face_offset(pt)) - (vert + d0);
	vec3 eb = (pb + face_offset(pb)) - (vert + d0);
	vec3 n2 = cross(et, eb);
	if (length(n2) > 1e-9) {
		n2 = normalize(n2);
		nrm = dot(n2, nrm) < 0.0 ? -n2 : n2;
	}
	vert += d0;
}
"""

const SKIN_SHADER := """
shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;
uniform float pores : hint_range(0.0, 1.0) = 0.6;
uniform float wrinkle : hint_range(0.0, 1.0) = 0.5;
uniform vec3 stubble_color : source_color = vec3(0.12, 0.1, 0.09);
	uniform float sheen : hint_range(0.0, 1.0) = 0.35;
	uniform float nose_z = 0.108;
uniform float matte : hint_range(0.0, 1.0) = 0.0;
varying vec3 lp;
float h3(vec3 p) {
	p = fract(p * 0.3183099 + vec3(0.71, 0.113, 0.419));
	p *= 17.0;
	return fract(p.x * p.y * p.z * (p.x + p.y + p.z));
}
float vn(vec3 x) {
	vec3 i = floor(x);
	vec3 f = fract(x);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(mix(h3(i), h3(i + vec3(1, 0, 0)), f.x), mix(h3(i + vec3(0, 1, 0)), h3(i + vec3(1, 1, 0)), f.x), f.y),
		mix(mix(h3(i + vec3(0, 0, 1)), h3(i + vec3(1, 0, 1)), f.x), mix(h3(i + vec3(0, 1, 1)), h3(i + vec3(1, 1, 1)), f.x), f.y), f.z);
}
float bump(vec3 p) {
	return vn(p * 900.0) * 0.55 + vn(p * 380.0) * 0.45;
}
//FACE//
void vertex() {
	lp = VERTEX;
	face_apply(VERTEX, NORMAL, TANGENT, BINORMAL);
	neck_apply(VERTEX, NORMAL, lp.y);
}
void fragment() {
	float e = 0.0006;
	float b0 = bump(lp);
	vec3 g = vec3(bump(lp + vec3(e, 0, 0)) - b0, bump(lp + vec3(0, e, 0)) - b0, bump(lp + vec3(0, 0, e)) - b0) / e;
	vec3 gv = (VIEW_MATRIX * MODEL_MATRIX * vec4(g, 0.0)).xyz;
	gv = gv - dot(gv, NORMAL) * NORMAL;
	NORMAL = normalize(NORMAL - gv * 0.000035 * (0.4 + pores));
	vec3 col = COLOR.rgb;
	float pit = smoothstep(0.66, 0.9, vn(lp * 1100.0));
	col *= 1.0 - pit * 0.22 * pores;
	col *= 1.0 + (vn(lp * 160.0) - 0.5) * 0.12;
	float hn = vn(lp * 2200.0) * 0.6 + vn(lp * 900.0) * 0.4;
	float hairs = smoothstep(0.46, 0.6, hn) * smoothstep(0.1, 0.6, COLOR.a);
	col = mix(col, stubble_color, hairs * 0.7);
	float cheek = smoothstep(0.028, 0.008, distance(vec2(abs(lp.x), lp.y), vec2(0.042, -0.018)));
	col = mix(col, col * vec3(1.22, 0.62, 0.52), cheek * 0.42);
	float lip = smoothstep(0.018, 0.004, distance(lp, vec3(0.0, -0.067, 0.09)));
	col = mix(col, col * vec3(1.35, 0.45, 0.4), lip * 0.55);
	float ear = smoothstep(0.02, 0.006, abs(abs(lp.x) - 0.074)) * smoothstep(0.02, 0.0, abs(lp.y + 0.012));
	col = mix(col, col * vec3(1.18, 0.55, 0.48), ear * 0.35);
	ALBEDO = col;
	float tz = smoothstep(0.035, 0.075, lp.y) * smoothstep(0.03, 0.08, lp.z) * (1.0 - smoothstep(0.0, 0.045, abs(lp.x)));
	float nose = 1.0 - smoothstep(0.0, 0.02, distance(lp, vec3(0.0, -0.034, nose_z)));
	float oily = clamp(tz * 0.8 + nose, 0.0, 1.0) * sheen;
	float cheekMatte = smoothstep(0.055, 0.012, distance(vec2(abs(lp.x), lp.y), vec2(0.046, -0.02)));
	ROUGHNESS = mix(0.78, 0.6, oily);
	ROUGHNESS = mix(ROUGHNESS, 0.9, matte * (0.25 + cheekMatte * 0.45));
	SPECULAR = mix(0.2, 0.12, matte) + oily * 0.08;
	RIM = 0.18;
	RIM_TINT = 0.6;
}
"""
static var _skin_shader: Shader


static func _skin_material(tpl: Dictionary) -> ShaderMaterial:
	if _skin_shader == null:
		_skin_shader = Shader.new()
		_skin_shader.code = SKIN_SHADER.replace("//FACE//", FACE_GLSL)
	var m := ShaderMaterial.new()
	m.shader = _skin_shader
	m.set_shader_parameter("pores", float(tpl.get("pores", 0.5)))
	m.set_shader_parameter("wrinkle", float(tpl.get("wrinkle", 0.5)))
	m.set_shader_parameter("stubble_color", Color(str(tpl.get("stubble_color", "#2a2420"))))
	m.set_shader_parameter("sheen", float(tpl.get("sheen", 0.18)))
	m.set_shader_parameter("nose_z", float(tpl.get("nose_z", 0.108)))
	m.set_shader_parameter("matte", float(tpl.get("matte", 0.0)))
	return m


const HAIR_SHADER := """
shader_type spatial;
uniform float dress : hint_range(0.0, 1.0) = 0.0;
varying vec3 lp;
float h3(vec3 p) {
	p = fract(p * 0.3183099 + vec3(0.71, 0.113, 0.419));
	p *= 17.0;
	return fract(p.x * p.y * p.z * (p.x + p.y + p.z));
}
float vn(vec3 x) {
	vec3 i = floor(x);
	vec3 f = fract(x);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(mix(h3(i), h3(i + vec3(1, 0, 0)), f.x), mix(h3(i + vec3(0, 1, 0)), h3(i + vec3(1, 1, 0)), f.x), f.y),
		mix(mix(h3(i + vec3(0, 0, 1)), h3(i + vec3(1, 0, 1)), f.x), mix(h3(i + vec3(0, 1, 1)), h3(i + vec3(1, 1, 1)), f.x), f.y), f.z);
}
float strands(vec3 p) {
	return vn(vec3(p.x * 650.0, p.y * 55.0, p.z * 650.0)) * 0.6 + vn(vec3(p.x * 1500.0, p.y * 120.0, p.z * 1500.0)) * 0.4;
}
//FACE//
void vertex() {
	lp = VERTEX;
	face_apply(VERTEX, NORMAL, TANGENT, BINORMAL);
}
void fragment() {
	float e = 0.0008;
	float s0 = strands(lp);
	vec3 g = vec3(strands(lp + vec3(e, 0, 0)) - s0, 0.0, strands(lp + vec3(0, 0, e)) - s0) / e;
	vec3 gv = (VIEW_MATRIX * MODEL_MATRIX * vec4(g, 0.0)).xyz;
	gv = gv - dot(gv, NORMAL) * NORMAL;
	NORMAL = normalize(NORMAL - gv * 0.00007);
	float root = smoothstep(-0.03, 0.09, lp.y);
	vec3 col = COLOR.rgb * (0.62 + 0.75 * s0) * (0.78 + 0.22 * root);
	ALBEDO = col;
	ROUGHNESS = mix(0.62 + (1.0 - s0) * 0.2, 0.42, dress);
	SPECULAR = mix(0.12 + s0 * 0.1, 0.26, dress);
	RIM = 0.08;
	RIM_TINT = 0.5;
}
"""
static var _hair_shader: Shader


## Her kafa kendi materyalini alır: yüz üniformları (kırpma, çene, kaş) materyal
## üstünde tutuluyor, paylaşılan tek materyalde bütün karakterler aynı anda kırpardı.
static func _hair_material(dress: float = 0.0) -> ShaderMaterial:
	if _hair_shader == null:
		_hair_shader = Shader.new()
		_hair_shader.code = HAIR_SHADER.replace("//FACE//", FACE_GLSL)
	var m := ShaderMaterial.new()
	m.shader = _hair_shader
	if dress > 0.0:
		m.set_shader_parameter("dress", dress)
	return m


const FABRICS := {
	"leather": {"rough": 0.42, "freq": 0.05, "bump": 3.2, "scale": 5.0, "normal": 0.9, "metal": 0.0},
	"wool": {"rough": 0.95, "freq": 0.22, "bump": 2.0, "scale": 14.0, "normal": 0.55, "metal": 0.0},
	"cotton": {"rough": 0.88, "freq": 0.12, "bump": 2.4, "scale": 9.0, "normal": 0.6, "metal": 0.0},
	"denim": {"rough": 0.9, "freq": 0.3, "bump": 2.2, "scale": 16.0, "normal": 0.6, "metal": 0.0},
	"canvas": {"rough": 0.92, "freq": 0.18, "bump": 2.6, "scale": 12.0, "normal": 0.65, "metal": 0.0},
	"suit": {"rough": 0.8, "freq": 0.09, "bump": 2.0, "scale": 8.0, "normal": 0.5, "metal": 0.0},
}
static var _fabric_tex: Dictionary = {}
static var _cloth_cache: Dictionary = {}


static func cloth_material(base: StandardMaterial3D, color: Color, fabric := "cotton", worn := 0.3) -> StandardMaterial3D:
	var key := "%s|%s|%s|%.2f" % [fabric, color.to_html(), base.resource_name, worn]
	if _cloth_cache.has(key):
		return _cloth_cache[key]
	var spec: Dictionary = FABRICS.get(fabric, FABRICS["cotton"])
	if not _fabric_tex.has(fabric):
		_fabric_tex[fabric] = _noise(float(spec["freq"]), fabric.hash() % 1000, 512, float(spec["bump"]), 5)
	var m := base.duplicate() as StandardMaterial3D
	m.albedo_color = color.darkened(worn * 0.14)
	m.roughness = clampf(float(spec["rough"]) + worn * 0.08, 0.05, 1.0)
	m.metallic_specular = 0.35 if fabric != "leather" else 0.6
	m.normal_enabled = true
	m.normal_texture = _fabric_tex[fabric]
	m.normal_scale = float(spec["normal"]) * (0.8 + worn * 0.6)
	m.uv1_triplanar = true
	var sc: float = float(spec["scale"])
	m.uv1_scale = Vector3(sc, sc, sc)
	m.rim_enabled = true
	m.rim = 0.12
	m.rim_tint = 0.4
	_cloth_cache[key] = m
	return m


# ------------------------------------------------------------------ gözler
static func _eye_material(color: Color, tired: float) -> ShaderMaterial:
	if _eye_shader == null:
		_eye_shader = Shader.new()
		_eye_shader.code = """
shader_type spatial;
uniform vec3 iris_color : source_color = vec3(0.25, 0.15, 0.08);
uniform float tired = 0.3;
varying vec3 lp;
void vertex() { lp = VERTEX; }
void fragment() {
	vec3 d = normalize(lp);
	float a = acos(clamp(d.z, -1.0, 1.0));
	float ang = atan(d.y, d.x);
	float streak = 0.5 + 0.5 * sin(ang * 46.0) * sin(ang * 13.0 + a * 8.0);
	vec3 sclera = mix(vec3(0.80, 0.77, 0.72), vec3(0.72, 0.42, 0.38), tired * 0.5 * (0.5 + 0.5 * sin(ang * 31.0 + a * 12.0)) * smoothstep(0.5, 1.3, a));
	vec3 iris = mix(iris_color * 0.55, iris_color * 1.35, streak);
	iris = mix(iris, iris * 0.35, smoothstep(0.42, 0.52, a));
	iris = mix(iris, iris_color * 1.6, smoothstep(0.32, 0.12, a) * 0.5);
	float in_iris = 1.0 - smoothstep(0.50, 0.53, a);
	float pupil = 1.0 - smoothstep(0.17, 0.2, a);
	vec3 col = mix(sclera, iris, in_iris);
	col = mix(col, vec3(0.01), pupil);
	ALBEDO = col;
	ROUGHNESS = 0.07;
	SPECULAR = 0.9;
}
"""
	var m := ShaderMaterial.new()
	m.shader = _eye_shader
	m.set_shader_parameter("iris_color", color)
	m.set_shader_parameter("tired", tired)
	return m


static func _eyes(root: Node3D, meta: Dictionary, tpl: Dictionary) -> void:
	var radius := float(meta.get("eye_radius", 0.0118))
	var mat := _eye_material(Color(str(meta.get("eye_color", "#3a2616"))), float(meta.get("tired", 0.3)))
	for key in ["eye_l", "eye_r"]:
		var arr: Array = meta[key]
		var mi := MeshInstance3D.new()
		mi.name = key
		var sphere := SphereMesh.new()
		sphere.radius = radius
		sphere.height = radius * 2.0
		sphere.radial_segments = 24
		sphere.rings = 12
		mi.mesh = sphere
		mi.material_override = mat
		mi.position = Vector3(arr[0], arr[1], arr[2])
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		root.add_child(mi)


# ------------------------------------------------------------------ gözlük
static func _glasses(root: Node3D, meta: Dictionary, kind: String) -> void:
	if kind == "none":
		return
	var frame := StandardMaterial3D.new()
	frame.albedo_color = {"thin": Color("2b2a28"), "half": Color("2b2a28"), "round": Color("b08d4a"), "thick": Color("101010")}.get(kind, Color("202020"))
	frame.metallic = 0.7 if kind != "thick" else 0.0
	frame.roughness = 0.3
	var lens := StandardMaterial3D.new()
	lens.albedo_color = Color(0.75, 0.85, 0.95, 0.12)
	lens.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	lens.roughness = 0.05
	lens.metallic_specular = 1.0
	var fitted := meta.has("glass_z")
	var tube: float = {"thin": 0.0016, "half": 0.0011, "round": 0.0015, "thick": 0.0042}[kind]
	var rad: float = {"thin": 0.0175, "half": 0.016, "round": 0.0195, "thick": 0.0205}[kind]
	if fitted and kind == "thin":
		tube = 0.0011
		rad = 0.017
	elif fitted and kind == "round":
		tube = 0.0022
		rad = 0.018
	elif fitted and kind == "thick":
		tube = 0.0036
		rad = 0.0165
	elif kind == "half":
		rad = 0.0155
	var wide := 1.08 if kind == "thin" and fitted else (1.12 if kind == "thin" else 1.0)
	var glass := Node3D.new()
	glass.name = "Glasses"
	root.add_child(glass)
	var eye_l: Array = meta["eye_l"]
	var gz := float(meta.get("glass_z", 0.1))
	for side in [1.0, -1.0]:
		var cx: float = float(side) * float(eye_l[0])
		var cy: float = float(eye_l[1]) - 0.002
		if kind == "half":
			var bar := MeshInstance3D.new()
			var seg := BoxMesh.new()
			seg.size = Vector3(rad * wide * 2.05, tube * 2.4, tube * 1.8)
			bar.mesh = seg
			bar.material_override = frame
			bar.position = Vector3(cx, cy + rad * 1.05, gz)
			glass.add_child(bar)
		else:
			var ring := MeshInstance3D.new()
			var torus := TorusMesh.new()
			torus.inner_radius = rad - tube
			torus.outer_radius = rad + tube
			torus.rings = 28
			torus.ring_segments = 8
			ring.mesh = torus
			ring.material_override = frame
			ring.rotation_degrees = Vector3(90, 0, 0)
			ring.scale = Vector3(wide, 1.0, 1.0 if kind != "thin" else 0.88)
			ring.position = Vector3(cx, cy, gz)
			glass.add_child(ring)
		var disc := MeshInstance3D.new()
		var cyl := CylinderMesh.new()
		cyl.top_radius = rad
		cyl.bottom_radius = rad
		cyl.height = 0.0006
		cyl.radial_segments = 24
		disc.mesh = cyl
		disc.material_override = lens
		disc.rotation_degrees = Vector3(90, 0, 0)
		disc.scale = Vector3(wide, 1.0, 1.0 if kind != "thin" else 0.88)
		disc.position = Vector3(cx, cy, gz)
		glass.add_child(disc)
		var arm := MeshInstance3D.new()
		var box := BoxMesh.new()
		var x_out: float = side * (float(eye_l[0]) + rad * wide + 0.001)
		var ear: Array = meta["ear_l"] if side > 0.0 else meta["ear_r"]
		var x_ear: float = float(ear[0]) if meta.has("glass_z") else side * (float(eye_l[0]) + 0.0485)
		var z_ear: float = float(ear[2]) + 0.006 if meta.has("glass_z") else -0.012
		var span := Vector3(x_ear, float(eye_l[1]) + 0.004, z_ear) - Vector3(x_out, float(eye_l[1]) - 0.002, gz)
		box.size = Vector3(tube * 1.4 + 0.0008, tube * 1.4 + 0.0008, span.length())
		arm.mesh = box
		arm.material_override = frame
		arm.position = Vector3(x_out, float(eye_l[1]) - 0.002, gz) + span * 0.5
		glass.add_child(arm)
		arm.look_at_from_position(arm.position, arm.position + span, Vector3.UP)
	var bridge := MeshInstance3D.new()
	var bbox := BoxMesh.new()
	bbox.size = Vector3(2.0 * (float(eye_l[0]) - rad * wide) + 0.002, tube * 1.6, tube * 1.6)
	bridge.mesh = bbox
	bridge.material_override = frame
	bridge.position = Vector3(0, float(eye_l[1]) + (rad * 1.02 if kind == "half" else 0.004), gz + 0.001)
	glass.add_child(bridge)
	if meta.has("glass_z") and kind != "half":
		var pad_mat := frame
		for side in [1.0, -1.0]:
			var pad := MeshInstance3D.new()
			var ball := SphereMesh.new()
			ball.radius = 0.0022
			ball.height = 0.0044
			pad.mesh = ball
			pad.material_override = pad_mat
			pad.position = Vector3(side * 0.007, float(eye_l[1]) - (0.022 if kind == "half" else 0.014), float(meta.get("glass_pad_z", gz - 0.006)))
			glass.add_child(pad)
			var hinge := MeshInstance3D.new()
			var hb := SphereMesh.new()
			hb.radius = tube * 1.6
			hb.height = tube * 3.2
			hinge.mesh = hb
			hinge.material_override = frame
			hinge.position = Vector3(side * (float(eye_l[0]) + rad * wide), float(eye_l[1]) - 0.002, gz)
			glass.add_child(hinge)


# ------------------------------------------------------------------ aksesuar
static func _gold() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color("c6a15b")
	m.metallic = 0.9
	m.roughness = 0.25
	return m


static func _face_props(root: Node3D, meta: Dictionary, tpl: Dictionary) -> void:
	if bool(tpl.get("earring", false)):
		var ear: Array = meta["ear_l"]
		var ring := MeshInstance3D.new()
		var torus := TorusMesh.new()
		torus.inner_radius = 0.0045
		torus.outer_radius = 0.0062
		ring.mesh = torus
		ring.material_override = _gold()
		ring.rotation_degrees = Vector3(0, 0, 90)
		ring.position = Vector3(float(ear[0]) - 0.001, float(ear[1]) - 0.014, float(ear[2]))
		root.add_child(ring)
	var props: Array = tpl.get("props", [])
	if props.has("cigarette"):
		var c: Array = meta["mouth_corner"]
		var holder := Node3D.new()
		holder.name = "Cigarette"
		holder.position = Vector3(-float(c[0]) + 0.002, float(c[1]) - 0.001, float(c[2]) + 0.004)
		holder.rotation_degrees = Vector3(-6, -14, 0)
		root.add_child(holder)
		var paper := StandardMaterial3D.new()
		paper.albedo_color = Color("e8e3d6")
		paper.roughness = 0.9
		var stick := MeshInstance3D.new()
		var cyl := CylinderMesh.new()
		cyl.top_radius = 0.0033
		cyl.bottom_radius = 0.0033
		cyl.height = 0.075
		stick.mesh = cyl
		stick.material_override = paper
		stick.rotation_degrees = Vector3(90, 0, 0)
		stick.position = Vector3(0, 0, 0.034)
		holder.add_child(stick)
		var ember := MeshInstance3D.new()
		var sph := SphereMesh.new()
		sph.radius = 0.0034
		sph.height = 0.0068
		ember.mesh = sph
		var em := StandardMaterial3D.new()
		em.albedo_color = Color("ff5a1a")
		em.emission_enabled = true
		em.emission = Color("ff4a10")
		em.emission_energy_multiplier = 2.2
		ember.material_override = em
		ember.position = Vector3(0, 0, 0.072)
		holder.add_child(ember)


static func _body_props(rig: Node3D, tpl: Dictionary) -> void:
	var props: Array = tpl.get("props", [])
	if props.has("gold_chain") and rig.skeleton:
		var chest := BoneAttachment3D.new()
		chest.bone_name = "UpperChest"
		rig.skeleton.add_child(chest)
		var chain := MeshInstance3D.new()
		var t2 := TorusMesh.new()
		t2.inner_radius = 0.085
		t2.outer_radius = 0.092
		chain.mesh = t2
		chain.material_override = _gold()
		chain.position = Vector3(0, 0.1, 0.03)
		chain.scale = Vector3(1.0, 1.0, 1.0)
		chest.add_child(chain)
	if props.has("radio") and rig.skeleton:
		var sh := BoneAttachment3D.new()
		sh.bone_name = "UpperChest"
		rig.skeleton.add_child(sh)
		var dark := StandardMaterial3D.new()
		dark.albedo_color = Color("121416")
		dark.roughness = 0.5
		dark.metallic = 0.3
		var body := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(0.055, 0.1, 0.03)
		body.mesh = bm
		body.material_override = dark
		body.position = Vector3(0.115, 0.07, 0.12)
		sh.add_child(body)
		var ant := MeshInstance3D.new()
		var am := CylinderMesh.new()
		am.top_radius = 0.003
		am.bottom_radius = 0.004
		am.height = 0.1
		ant.mesh = am
		ant.material_override = dark
		ant.position = Vector3(0.13, 0.17, 0.12)
		sh.add_child(ant)


# ------------------------------------------------------------------ gövde (deri tonu + kumaş)
static var _smooth_cache: Dictionary = {}


## Aynı konumdaki tepelerin normallerini ortalar (düşük poligonlu gövdede kumaş gibi yumuşak gölge).
static func smooth_mesh(src: ArrayMesh) -> ArrayMesh:
	if _smooth_cache.has(src):
		return _smooth_cache[src]
	var out := ArrayMesh.new()
	for surface in src.get_surface_count():
		var arrays := src.surface_get_arrays(surface)
		var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var idx: PackedInt32Array = arrays[Mesh.ARRAY_INDEX] if arrays[Mesh.ARRAY_INDEX] != null else PackedInt32Array()
		if idx.is_empty():
			idx = PackedInt32Array(range(verts.size()))
		var sums := {}
		for t in range(0, idx.size(), 3):
			var a := verts[idx[t]]
			var b := verts[idx[t + 1]]
			var c := verts[idx[t + 2]]
			var fn := (b - a).cross(c - a)
			for k in 3:
				var key := Vector3i((verts[idx[t + k]] * 2000.0).round())
				sums[key] = sums.get(key, Vector3.ZERO) + fn
		var normals := PackedVector3Array()
		normals.resize(verts.size())
		for i in verts.size():
			var key := Vector3i((verts[i] * 2000.0).round())
			normals[i] = (sums[key] as Vector3).normalized()
		arrays[Mesh.ARRAY_NORMAL] = normals
		arrays[Mesh.ARRAY_TANGENT] = null
		var flags := src.surface_get_format(surface) & Mesh.ARRAY_FLAG_USE_8_BONE_WEIGHTS
		out.add_surface_from_arrays(src.surface_get_primitive_type(surface), arrays, [], {}, flags)
		out.surface_set_material(surface, src.surface_get_material(surface))
		out.surface_set_name(surface, src.surface_get_name(surface))
	_smooth_cache[src] = out
	return out


static func _body(rig: Node3D, tpl: Dictionary) -> void:
	var skin_col := Color(str(tpl.get("skin", "#c39a7a")))
	var cloth: Dictionary = tpl.get("cloth", {})
	var fabric := str(cloth.get("fabric", "cotton"))
	var worn := float(cloth.get("worn", 0.3))
	for mesh_instance in rig.find_children("*", "MeshInstance3D", true, false):
		var mi := mesh_instance as MeshInstance3D
		if mi.mesh == null or mi.skin == null or mi == rig.head_mesh:
			continue
		var part: String = mi.name.get_slice("_", 1)
		if mi.mesh is ArrayMesh:
			mi.mesh = smooth_mesh(mi.mesh)
		for surface in mi.mesh.get_surface_count():
			var base := (mi.get_surface_override_material(surface) if mi.get_surface_override_material(surface) else mi.mesh.surface_get_material(surface)) as StandardMaterial3D
			if base == null:
				continue
			if base.resource_name.begins_with("Skin") and part != "Feet" and base.albedo_color.r >= base.albedo_color.b:
				var sm := base.duplicate() as StandardMaterial3D
				sm.albedo_color = skin_col.darkened(0.04)
				sm.roughness = 0.6
				sm.subsurf_scatter_enabled = true
				sm.subsurf_scatter_strength = 0.35
				mi.set_surface_override_material(surface, sm)
			elif part == "Body" or part == "Legs":
				var f := fabric
				if part == "Legs":
					f = str(cloth.get("legs", "wool" if fabric == "leather" else fabric))
				mi.set_surface_override_material(surface, cloth_material(base, base.albedo_color, f, worn))
			elif part == "Feet":
				mi.set_surface_override_material(surface, cloth_material(base, base.albedo_color, "leather", 0.7))
