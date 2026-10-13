shader_type canvas_item;
uniform sampler2D screen_texture : hint_screen_texture, filter_linear;
uniform float progress = 0.0;
uniform vec2 focus = vec2(0.5, 0.47);
uniform vec4 pastel : source_color;
void fragment() {
	vec2 uv = focus + (SCREEN_UV - focus) * (1.0 - progress * 0.45);
	vec4 c = texture(screen_texture, uv);
	float grey = dot(c.rgb, vec3(0.299, 0.587, 0.114));
	c.rgb = mix(c.rgb, vec3(grey), smoothstep(0.0, 0.65, progress));
	c.rgb = mix(c.rgb, pastel.rgb, smoothstep(0.65, 1.0, progress));
	COLOR = c;
}
