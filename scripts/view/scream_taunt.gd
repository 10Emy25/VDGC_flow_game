class_name ScreamTaunt
extends Control
var phrase := ""
var damage := 0.0
var shattered := false
var shatter_age := 0.0
var drift := 0.0
func _process(delta: float) -> void:
	drift += delta
	if shattered: shatter_age += delta
	queue_redraw()
func _draw() -> void:
	var font: Font = GameState.ui_theme.default_font
	if font == null: font = ThemeDB.fallback_font
	var pen := -font.get_string_size(phrase, HORIZONTAL_ALIGNMENT_LEFT, -1, 38).x * 0.5
	for i in range(phrase.length()):
		var c := phrase.substr(i, 1)
		var scatter: float = shatter_age * 420 if shattered else damage * 9
		var offset := Vector2(sin(i * 8.31), cos(i * 5.17)) * scatter
		var point := Vector2(pen, sin(drift * 2.2 + i * 0.3) * 7) + offset
		var alpha: float = maxf(0, 1 - shatter_age / 1.4) if shattered else 1.0
		draw_string_outline(font, point, c, HORIZONTAL_ALIGNMENT_LEFT, -1, 38, 8, Color(0.03, 0.02, 0.05, alpha))
		draw_string(font, point, c, HORIZONTAL_ALIGNMENT_LEFT, -1, 38, Color(lerpf(0.78, 1, damage), lerpf(0.64, 0.97, damage), lerpf(0.7, 0.83, damage), alpha))
		if damage > 0.3 and not shattered: draw_line(point + Vector2(0, -30), point + Vector2(13, -15), Color(0.05, 0.02, 0.07, alpha), 2)
		pen += font.get_string_size(c, HORIZONTAL_ALIGNMENT_LEFT, -1, 38).x
func reset(text: String) -> void:
	phrase = text
	damage = 0
	shattered = false
	shatter_age = 0
