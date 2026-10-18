class_name DreamStars
extends Control
# Small twinkling stars over the dark between the bedroom and the dream. The field is seeded and timed
# from the music, so the bedroom and the flower path draw the same stars in the same place.

var stars: Array[Dictionary] = []
var music_time := 0.0
var strength := 0.0:
	set(value):
		strength = value
		visible = strength > 0.001
		queue_redraw()

func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	size = Vector2(GameState.balance.layout.screen[0], GameState.balance.layout.screen[1])
	var config: Dictionary = GameState.balance.intro.stars
	var rng := RandomNumberGenerator.new()
	rng.seed = int(config.seed)
	for index in range(int(config.count)):
		stars.append({
			"point": Vector2(rng.randf_range(80, size.x - 80), rng.randf_range(60, size.y - 160)),
			"size": rng.randf_range(4.0, 11.0),
			"speed": rng.randf_range(1.2, 3.4),
			"phase": rng.randf_range(0.0, TAU),
			"warm": rng.randf() < 0.35,
		})
	visible = false

func _draw() -> void:
	for star in stars:
		var twinkle := 0.45 + 0.55 * (0.5 + 0.5 * sin(music_time * star.speed + star.phase))
		var alpha: float = strength * twinkle
		var color := Color("#ffe9b8") if star.warm else Color("#e4eeff")
		var p: Vector2 = star.point
		var s: float = star.size * (0.8 + 0.3 * twinkle)
		draw_circle(p, s * 1.6, Color(color, alpha * 0.12))
		draw_colored_polygon(PackedVector2Array([p + Vector2(0, -s * 1.8), p + Vector2(s * 0.28, 0), p + Vector2(0, s * 1.8), p + Vector2(-s * 0.28, 0)]), Color(color, alpha))
		draw_colored_polygon(PackedVector2Array([p + Vector2(-s * 1.8, 0), p + Vector2(0, s * 0.28), p + Vector2(s * 1.8, 0), p + Vector2(0, -s * 0.28)]), Color(color, alpha))
