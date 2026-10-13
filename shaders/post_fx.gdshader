shader_type canvas_item;
uniform sampler2D screen_texture : hint_screen_texture, filter_linear;
uniform sampler2D grain_texture : repeat_enable;
uniform sampler2D paper_texture : repeat_enable;
uniform float world_real = 0.0;
uniform float stress = 0.0;
uniform float heartbeat = 0.0;
uniform bool reduce_distortion = false;
void fragment() {
	vec2 uv = SCREEN_UV;
	vec2 center = uv - 0.5;
	if (!reduce_distortion) {
		uv += center * sin(TIME * 1.7) * stress * world_real * 0.004;
	}
	vec4 c = texture(screen_texture, uv);
	if (!reduce_distortion) {
		float chroma = max(stress - 0.5, 0.0) * world_real * 0.007;
		c.r = texture(screen_texture, uv + vec2(chroma, 0.0)).r;
		c.b = texture(screen_texture, uv - vec2(chroma, 0.0)).b;
		float grey = dot(c.rgb, vec3(0.299, 0.587, 0.114));
		if (!(c.r > c.g * 1.4 && c.r > c.b * 1.4)) c.rgb = mix(c.rgb, vec3(grey), stress * world_real * 0.7);
	}
	float grain = texture(grain_texture, uv * vec2(4.0, 2.25) + fract(TIME * 8.0)).r - 0.5;
	float paper = texture(paper_texture, uv * vec2(4.0, 2.25)).r - 0.5;
	c.rgb += (grain * (0.05 + stress * 0.07) + paper * 0.07) * world_real;
	float vignette = smoothstep(0.25, 0.7, length(center));
	c.rgb *= 1.0 - vignette * world_real * (0.18 + stress * 0.48 + heartbeat * 0.06);
	COLOR = c;
}
