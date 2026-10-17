shader_type canvas_item;

uniform vec2 center_uv = vec2(0.5, 0.55);
uniform float radius : hint_range(0.0, 1.0) = 0.16;
uniform float softness : hint_range(0.001, 1.0) = 0.13;

void fragment() {
    float dist = distance(SCREEN_UV, center_uv);
    float darkness = smoothstep(radius, radius + max(softness, 0.001), dist);
    COLOR = vec4(0.0, 0.0, 0.0, darkness);
}
