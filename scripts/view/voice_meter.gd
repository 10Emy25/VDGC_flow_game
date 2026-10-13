class_name VoiceMeter
extends Control

var pulse_tier := 0
var age := 0.0
var tier_labels: Array[Label] = []
var current: Label

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	UIFactory.texture(self, "ui_voice_meter", Rect2(Vector2.ZERO, size))
	for key in ["hum", "talk_tier", "shout_tier"]:
		tier_labels.append(UIFactory.label(self, key, Rect2(0, 72, 90, 35), GameState.balance.ui.small_size))
	current = UIFactory.label(self, "quiet", Rect2(0, -45, 120, 38), GameState.balance.ui.small_size)
	current.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT

func _process(delta: float) -> void:
	age += delta
	visible = GameState.settings.show_voice_meter
	var thresholds := VoiceInput.model.thresholds()
	var centers: Array[float] = []
	for index in range(3):
		var normalized := clampf((thresholds[index] - VoiceInput.model.floor_db) / (VoiceInput.model.cal_shout_db - VoiceInput.model.floor_db), 0.0, 1.0)
		var center := maxf(tier_labels[index].size.x * 0.5, 24 + normalized * (size.x - 48))
		if index > 0:
			center = maxf(center, centers[index - 1] + (tier_labels[index - 1].size.x + tier_labels[index].size.x) * 0.5 + 6.0)
		centers.append(center)
		tier_labels[index].add_theme_color_override("font_color", Color(GameState.balance.palette.ink))
	var overflow := maxf(0.0, centers.back() + tier_labels.back().size.x * 0.5 - size.x)
	for index in range(3):
		tier_labels[index].position.x = centers[index] - overflow - tier_labels[index].size.x * 0.5
	current.text = GameState.text({"QUIET":"quiet", "HUM":"hum", "TALK":"talk_tier", "SHOUT":"shout_tier"}[VoiceInput.tier])
	queue_redraw()

func _draw() -> void:
	if current != null:
		draw_style_box(make_bar(Color(GameState.balance.palette.cream, 0.96)), Rect2(current.position, current.size))
	for index in range(tier_labels.size()):
		var label := tier_labels[index]
		var color := Color(GameState.balance.palette.gold if VoiceInput.tier == ["HUM", "TALK", "SHOUT"][index] else GameState.balance.palette.cream)
		draw_style_box(make_bar(color), Rect2(label.position, label.size))
	var inner := Rect2(24, 22, size.x - 48, 25)
	draw_style_box(make_bar(Color(GameState.balance.palette.ink, 0.12)), inner)
	var fill := inner
	fill.size.x *= VoiceInput.level01
	if fill.size.x > 0.0:
		draw_style_box(make_bar(Color(GameState.balance.palette.gold)), fill)
	var thresholds := VoiceInput.model.thresholds()
	for index in range(3):
		var value := clampf((thresholds[index] - VoiceInput.model.floor_db) / (VoiceInput.model.cal_shout_db - VoiceInput.model.floor_db), 0.0, 1.0)
		var x := inner.position.x + value * inner.size.x
		var alpha := 1.0 if pulse_tier != index + 1 else 0.5 + 0.5 * absf(sin(age * TAU * GameState.balance.layout.pulse_hz))
		draw_line(Vector2(x, 12), Vector2(x, 57), Color(GameState.balance.palette.ink, alpha), 3.0, true)
		var label_center := tier_labels[index].position.x + tier_labels[index].size.x * 0.5
		if absf(label_center - x) > 1.0:
			draw_line(Vector2(x, 57), Vector2(label_center, 68), Color(GameState.balance.palette.ink, alpha), 1.0, true)

func make_bar(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(10)
	return style
