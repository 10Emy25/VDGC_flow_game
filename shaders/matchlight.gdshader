shader_type canvas_item;
render_mode unshaded;
uniform vec2 center_uv = vec2(0.5, 0.55);
uniform float radius : hint_range(0.05, 0.6) = 0.19;
uniform float softness : hint_range(0.01, 0.4) = 0.16;
void fragment() {
    vec2 uv = SCREEN_UV;
    float dist = length((uv - center_uv) * vec2(1.0, 1.65));
    float darkness = smoothstep(radius, radius + softness, dist);
    COLOR = vec4(0.012, 0.012, 0.026, darkness * 0.97);
}
