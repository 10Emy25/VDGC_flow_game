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
		tier_labels.append(UIFactory.label(self, key, Rect2(0, 72, 100, 35), GameState.balance.ui.small_size))
	current = UIFactory.label(self, "quiet", Rect2(0, -45, 520, 38), GameState.balance.ui.small_size)
	current.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT

func _process(delta: float) -> void:
	age += delta
	visible = GameState.settings.show_voice_meter
	var thresholds := VoiceInput.model.thresholds()
	for index in range(3):
		var normalized := clampf((thresholds[index] - VoiceInput.model.floor_db) / (VoiceInput.model.cal_shout_db - VoiceInput.model.floor_db), 0.0, 1.0)
		tier_labels[index].position.x = 24 + normalized * (size.x - 48) - 50
		tier_labels[index].add_theme_color_override("font_color", Color(GameState.balance.palette.gold if VoiceInput.tier == ["HUM", "TALK", "SHOUT"][index] else GameState.balance.palette.ink))
	current.text = GameState.text({"QUIET":"quiet", "HUM":"hum", "TALK":"talk_tier", "SHOUT":"shout_tier"}[VoiceInput.tier])
	queue_redraw()

func _draw() -> void:
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

func make_bar(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(10)
	return style
