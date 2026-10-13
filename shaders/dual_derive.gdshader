shader_type canvas_item;
uniform bool derive_real = false;
uniform bool derive_cute = false;
uniform float real_amount = 0.0;
uniform bool reduce_distortion = false;
uniform vec2 source_size = vec2(300.0, 360.0);
uniform sampler2D hatch_texture : repeat_enable;
void fragment() {
	vec2 uv = UV;
	if (!reduce_distortion) {
		float frame = floor(TIME * 8.0);
		uv += normalize(vec2(sin(frame * 2.17), cos(frame * 1.31))) * 1.5 / source_size * real_amount;
	}
	vec4 c = texture(TEXTURE, uv);
	float grey = dot(c.rgb, vec3(0.299, 0.587, 0.114));
	bool red = c.r > c.g * 1.4 && c.r > c.b * 1.4;
	if (derive_real) {
		vec3 ink = red ? c.rgb : vec3(grey);
		ink = clamp((ink - 0.5) * 1.6 + 0.5, 0.0, 1.0);
		ink *= mix(0.68, 1.0, texture(hatch_texture, UV * 3.0).r);
		c.rgb = ink;
	}
	if (derive_cute) {
		c.rgb = mix(c.rgb, vec3(0.95, 0.88, 0.79), 0.45);
	}
	COLOR = c * COLOR;
}
