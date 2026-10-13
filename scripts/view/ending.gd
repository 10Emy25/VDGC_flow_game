class_name EndingView
extends Control

signal finished
var age := 0.0
var line: Label
var speaker: Label
var done := false

func _ready() -> void:
	theme = GameState.ui_theme
	GameState.world_real = 0.0
	PostFX.stress = 0.0
	Sfx.stop_all()
	Sfx.loop("amb_clock", true, GameState.balance.audio.clock_db)
	UIFactory.texture(self, "clinic_bg", Rect2(0, 0, 1920, 1080))
	UIFactory.texture(self, "sandtray", UIFactory.rect(GameState.balance.layout.tray_rect))
	UIFactory.texture(self, "sand_layer", UIFactory.rect(GameState.balance.layout.sand_rect))
	UIFactory.texture(self, "buried_runner_doll", UIFactory.rect(GameState.balance.layout.doll_rect))
	UIFactory.label(self, "ending_caption", Rect2(60, 44, 600, 54), GameState.balance.ui.small_size).horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	line = UIFactory.subtitle(self, "ending_therapist", UIFactory.rect(GameState.balance.layout.subtitle_rect))
	speaker = UIFactory.label(self, "me", UIFactory.rect(GameState.balance.ending.speaker_rect), GameState.balance.ui.therapist_size, Color(GameState.balance.palette.cool))
	var backing := StyleBoxFlat.new()
	backing.bg_color = Color(GameState.balance.palette.ink)
	backing.set_corner_radius_all(10)
	speaker.add_theme_stylebox_override("normal", backing)
	speaker.hide()

func _process(delta: float) -> void:
	if done:
		return
	age += delta
	if age >= GameState.balance.ending.therapist_s:
		line.text = GameState.text("ending_me")
		line.add_theme_color_override("font_color", Color(GameState.balance.palette.cool))
		speaker.show()
	if age >= GameState.balance.ending.therapist_s + GameState.balance.ending.me_s:
		done = true
		finished.emit()
