extends Control
var finale: Control
func _process(_delta: float) -> void:
	queue_redraw()
func _draw() -> void:
	if finale.phase not in ["voice", "reply", "white"]: return
	for i in range(finale.taunt_cloud.size()):
		var incoming: ScreamTaunt = finale.taunt_cloud[i]
		var broken: bool = incoming.shattered
		if broken and finale.pulse <= 0: continue
		var alpha: float = finale.pulse if broken else 0.75
		var origin: Vector2 = finale.WORD_ORIGINS[i]
		var target: Vector2 = incoming.position + Vector2(0, 20)
		var direction: Vector2 = (finale.CENTER - origin).normalized()
		var perpendicular := Vector2(-direction.y, direction.x)
		var points := PackedVector2Array()
		for j in range(25):
			var t: float = j / 24.0
			var point: Vector2 = origin.lerp(target, t)
			point += perpendicular * sin(t * TAU * 1.4 + finale.age * 2 + i) * 30 * sin(t * PI)
			if broken: point -= direction * (1 - finale.pulse) * 200 * t
			points.append(point)
		for j in range(24):
			if broken and j % 4 == 0: continue
			var width: float = lerpf(25, 3, j / 24.0)
			draw_line(points[j], points[j + 1], Color(0.08, 0.05, 0.13, alpha), width + 5, true)
			draw_line(points[j] + perpendicular * 3, points[j + 1] + perpendicular * 3, Color(0.37, 0.2, 0.4, alpha), width * 0.3, true)
	if finale.pulse > 0: draw_arc(finale.CENTER, (1 - finale.pulse) * 1400 + 80, 0, TAU, 100, Color(1, 0.93, 0.72, finale.pulse), 14, true)
