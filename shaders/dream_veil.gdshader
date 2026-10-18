shader_type canvas_item;
// Falling asleep and waking into the dream: blurs what is behind it, closes like eyelids,
// fades to black and washes the picture with a soft pastel haze.
uniform sampler2D screen_texture : hint_screen_texture, filter_linear;
uniform float blur_px = 0.0;
uniform float lids = 1.0;      // 1 = eyes open, 0 = closed
uniform float darkness = 0.0;  // 0..1 fade to black
uniform float haze = 0.0;      // 0..1 dreamy wash
uniform vec4 haze_color : source_color = vec4(1.0, 0.95, 0.86, 1.0);
uniform float vignette = 0.0;

void fragment() {
	vec3 c = vec3(0.0);
	if (blur_px > 0.5) {
		// Golden-angle disc of taps: a soft, round blur in one pass.
		for (int i = 0; i < 32; i++) {
			float fi = float(i);
			float r = sqrt((fi + 0.5) / 32.0) * blur_px;
			float a = fi * 2.39996;
			c += texture(screen_texture, SCREEN_UV + vec2(cos(a), sin(a)) * r * SCREEN_PIXEL_SIZE).rgb;
		}
		c /= 32.0;
	} else {
		c = texture(screen_texture, SCREEN_UV).rgb;
	}
	c = mix(c, mix(c, haze_color.rgb, 0.55) + 0.1, haze);
	vec2 d = SCREEN_UV - 0.5;
	c *= 1.0 - smoothstep(0.3, 0.8, length(d * vec2(1.0, 0.85))) * vignette;
	// Almond-shaped opening that closes towards the middle.
	float open = clamp(lids, 0.0, 1.0);
	float x = d.x / 0.75;
	float edge = open * 0.62 * (1.0 - x * x);
	float soft = 0.02 + 0.05 * open;
	float inside = 1.0 - smoothstep(edge - soft, edge, abs(d.y));
	inside = mix(inside, 1.0, smoothstep(0.92, 1.0, open));
	c *= inside;
	c = mix(c, vec3(0.0), clamp(darkness, 0.0, 1.0));
	COLOR = vec4(c, 1.0);
}
