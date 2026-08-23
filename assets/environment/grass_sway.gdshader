shader_type spatial;
render_mode cull_disabled;

uniform vec4 albedo : source_color = vec4(1.0);

uniform sampler2D wind_noise;
uniform float wind_strength : hint_range(0.0, 2.0) = 0.2;
uniform vec2 wind_direction = vec2(1.0, 0.5);
uniform float wind_speed = 0.5;

void vertex() {
    float height_factor = 1.0 - UV.y;
   
    vec2 world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xz;
    
    vec2 noise_uv = world_pos * 0.05 + wind_direction * TIME * wind_speed;
    float noise = texture(wind_noise, noise_uv).r;
    
    float displacement = (noise - 0.5) * wind_strength * height_factor;
    VERTEX.x += displacement * wind_direction.x;
    VERTEX.z += displacement * wind_direction.y;
}

void fragment() {
    ALBEDO = albedo.rgb;
}