class_name FlowerSticker
extends Node2D
# Vector sticker: the same face gradually stretches into the nightmare.
var morph := 0.0
var age := 0.0
func _process(delta: float) -> void:
	age += delta
	queue_redraw()
func ellipse(center: Vector2, radius: Vector2, color: Color) -> void:
	var points := PackedVector2Array()
	for i in range(48):
		var angle: float = i * TAU / 48
		points.append(center + Vector2(cos(angle), sin(angle)) * radius)
	draw_colored_polygon(points, color)
func _draw() -> void:
	var ink := Color("28312c")
	var pink := Color("efbac5").lerp(Color("807888"), morph)
	draw_polyline(PackedVector2Array([Vector2(0, 35), Vector2(-9, 85), Vector2(0, 130)]), ink, 9, true)
	draw_polyline(PackedVector2Array([Vector2(0, 35), Vector2(-9, 85), Vector2(0, 130)]), Color("78a883"), 5, true)
	ellipse(Vector2(-22, 87), Vector2(28, 12), Color("7fa88b"))
	ellipse(Vector2(20, 105), Vector2(28, 12), Color("7fa88b"))
	for i in range(8):
		draw_set_transform(Vector2.ZERO, i * TAU / 8, Vector2.ONE)
		ellipse(Vector2(0, -54), Vector2(25, 38), ink)
		ellipse(Vector2(0, -54), Vector2(22, 35), pink)
	draw_set_transform(Vector2.ZERO)
	# A round golden face lengthens into a pale, hollow mask.
	var face := PackedVector2Array()
	for i in range(64):
		var a: float = i * TAU / 64
		var round_face := Vector2(cos(a) * 39, sin(a) * 39)
		var ghost_face := Vector2(cos(a) * (35 + sin(a) * 4), sin(a) * 54 + 9)
		face.append(round_face.lerp(ghost_face, morph))
	draw_colored_polygon(face, Color("f8df8e").lerp(Color("e5e9e4"), morph))
	var outline := face.duplicate()
	outline.append(face[0])
	draw_polyline(outline, ink, 3, true)
	for side in [-1, 1]:
		ellipse(Vector2(side * 13, -7 + morph * 3), Vector2(3.2 + morph * 8, 4 + morph * 11), Color("20212a"))
		if morph < 0.8:
			draw_circle(Vector2(side * 20, 9), 5, Color(0.93, 0.53, 0.6, (1 - morph) * 0.65))
	if morph < 1:
		draw_arc(Vector2(0, 6), 12, 0.15, PI - 0.15, 24, Color(0.12, 0.13, 0.15, 1 - morph), 2, true)
	if morph > 0:
		ellipse(Vector2(0, 24), Vector2(2 + morph * 10, 3 + morph * 20), Color(0.06, 0.05, 0.09, morph))
		for side in [-1, 1]:
			draw_line(Vector2(side * 17, 10), Vector2(side * 20, 28 + 7 * sin(age)), Color(0.1, 0.08, 0.13, morph * 0.7), 2, true)
