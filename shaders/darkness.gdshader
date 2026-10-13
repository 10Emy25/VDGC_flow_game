shader_type canvas_item;
// Darkness with a soft pool of light around Mina. Used in the real (nightmare) world only.
uniform vec2 screen_size = vec2(1920.0, 1080.0);
uniform vec2 center = vec2(760.0, 680.0);
uniform float radius = 430.0;
uniform float soft = 520.0;
uniform float strength = 0.6;
uniform float flicker = 0.0;

void fragment() {
	vec2 p = UV * screen_size;
	float d = distance(p, center);
	float a = smoothstep(radius, radius + soft, d) * strength;
	a += flicker * 0.08 * sin(TIME * 23.0 + p.y * 0.01);
	COLOR = vec4(0.0, 0.0, 0.0, clamp(a, 0.0, 0.92));
}
