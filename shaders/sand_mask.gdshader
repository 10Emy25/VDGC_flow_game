shader_type canvas_item;
uniform sampler2D brush_mask;
void fragment() {
	vec4 sand = texture(TEXTURE, UV);
	sand.a *= 1.0 - texture(brush_mask, UV).r;
	COLOR = sand * COLOR;
}
