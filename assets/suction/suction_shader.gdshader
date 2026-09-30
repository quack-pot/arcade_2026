shader_type spatial;
render_mode unshaded, cull_back, depth_draw_never, depth_test_disabled;

uniform sampler2D screen_tex : hint_screen_texture, repeat_disable, filter_linear;

uniform vec3 funnel_axis = vec3(0.0, 1.0, 0.0);
uniform vec3 axis_origin = vec3(0.0);
uniform float source_pos = -1.0;
uniform float sink_pos = 1.0;
uniform float source_radius = 0.5;
uniform float sink_radius = 0.1;

uniform float squeeze : hint_range(0.0, 0.98) = 0.1;
uniform float pull_power : hint_range(0.0, 5.0) = -0.5;
uniform float twist : hint_range(0.0, 20.0) = 5.0;
uniform float spin_speed : hint_range(-5.0, 5.0) = 8.0;
uniform float flow_speed : hint_range(0.0, 5.0) = 0.8;
uniform float flow_freq : hint_range(0.0, 30.0) = 50.0;
uniform float flow_amount : hint_range(0.0, 1.0) = 0.1;
uniform float smear : hint_range(0.0, 3.0) = 3.0;
uniform float edge_softness : hint_range(0.0, 4.0) = 4.0;

uniform float wave_amp : hint_range(0.0, 1.0) = 0.15;
uniform float wave_freq : hint_range(0.0, 10.0) = 3.0;
uniform float wave_speed : hint_range(-5.0, 5.0) = 1.0; 

varying vec3 local_pos;

const int SAMPLES = 8;

void vertex() {
	local_pos = VERTEX;
	
	vec3 axis = normalize(funnel_axis);
	vec3 rel = VERTEX - axis_origin;
	float a = dot(rel, axis);
	vec3 r = rel - axis * a;
	float t = clamp((a - source_pos) / (sink_pos - source_pos), 0.0, 1.0);
	
	float wave = sin(t * wave_freq * 6.2831 - TIME * wave_speed * 6.2831);
	VERTEX = axis_origin + axis * a + r * (1.0 + wave_amp * wave);
}

float radius_at(float a) {
	float k = clamp((a - source_pos) / (sink_pos - source_pos), 0.0, 1.0);
	return mix(source_radius, sink_radius, k);
}

vec2 project(mat4 vp, vec3 p) {
	vec4 c = vp * vec4(p, 1.0);
	return c.xy / c.w * 0.5 + 0.5;
}

void fragment() {
	mat4 vp = PROJECTION_MATRIX * VIEW_MATRIX * MODEL_MATRIX;
	vec3 axis = normalize(funnel_axis);
	
	vec3 rel_p = local_pos - axis_origin;
	float a = dot(rel_p, axis);
	vec3 r = rel_p - axis * a;
	float t = clamp((a - source_pos) / (sink_pos - source_pos), 0.0, 1.0);
	
	float w = mix(0.25, 1.0, pow(t, pull_power));
	float flow = 0.5 + 0.5 * sin(t * flow_freq - TIME * flow_speed * 6.2831);
	w *= mix(1.0 - flow_amount, 1.0, flow);
	
	float twist_angle = w * twist;
	float spin_angle = TIME * spin_speed;
	
	vec3 col = vec3(0.0);
	for (int i = 0; i < SAMPLES; i++) {
		float f = float(i) / float(SAMPLES - 1);
		
		float sq = clamp(squeeze * w * (1.0 + 0.5 * smear * f), 0.0, 0.98);
		float a2 = a - sq * (a - source_pos);
		float r_scale = radius_at(a2) / max(radius_at(a), 0.0001);
		
		float ang = twist_angle * (1.0 + smear * f) + spin_angle;
		vec3 r2 = (r * cos(ang) + cross(axis, r) * sin(ang)) * r_scale;
		
		vec3 p2 = axis_origin + axis * a2 + r2;
		col += textureLod(screen_tex, clamp(project(vp, p2), vec2(0.001), vec2(0.999)), 0.0).rgb;
	}
	col /= float(SAMPLES);
	col *= w;
	
	if (edge_softness > 0.0) {
		float edge = pow(clamp(abs(dot(normalize(NORMAL), normalize(VIEW))), 0.0, 1.0), edge_softness);
		col = mix(textureLod(screen_tex, SCREEN_UV, 0.0).rgb, col, edge);
	}
	
	ALBEDO = col * vec3(2.0, 2.0, 2.0);
	ALPHA = t;
}