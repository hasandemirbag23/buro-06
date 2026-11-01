shader_type canvas_item;
render_mode unshaded, blend_mix;

uniform float scan_strength : hint_range(0.0, 0.5) = 0.16;
uniform float vignette_strength : hint_range(0.0, 1.0) = 0.72;
uniform float grain_strength : hint_range(0.0, 0.2) = 0.035;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void fragment() {
	vec2 uv = UV - vec2(0.5);
	float vig = smoothstep(0.28, 0.86, length(uv * vec2(1.12, 0.92)));
	float scan = 0.5 + 0.5 * sin(FRAGCOORD.y * 1.45);
	float grain = hash(FRAGCOORD.xy + vec2(TIME * 37.0, TIME * 11.0));
	float flicker = 0.96 + 0.04 * sin(TIME * 22.0);
	float alpha = vig * vignette_strength + scan * scan_strength + grain * grain_strength;
	alpha = clamp(alpha, 0.0, 0.78) * flicker;
	COLOR = vec4(0.015, 0.012, 0.018, alpha);
}
