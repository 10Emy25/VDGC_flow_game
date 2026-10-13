class_name CalibrationFlow
extends Control

signal finished(result: Dictionary)
signal stage_changed(stage: int)
var model: Calibration
var stage := 0
var elapsed := 0.0
var retries := 0
var samples: Array = [[], [], []]
var result: Dictionary
var subtitle: Label
var hint: Label
var skip_button: Button
var done := false
var keys := ["silence", "talk", "shout"]
var keyboard_previous := false

func _ready() -> void:
	model = Calibration.new(GameState.balance)
	result = model.defaults()
	keyboard_previous = GameState.settings.keyboard_mode
	subtitle = UIFactory.subtitle(self, keys[stage], UIFactory.rect(GameState.balance.layout.subtitle_rect))
	hint = UIFactory.label(self, "keyboard_continue", Rect2(410, 825, 1100, 52), GameState.balance.ui.small_size)
	skip_button = UIFactory.button(self, "calibration_skip", Rect2(70, 810, 310, 66), use_defaults)
	update_text()

func update_text() -> void:
	subtitle.text = GameState.text("retry" if stage == 2 and retries > 0 else keys[stage])
	hint.visible = GameState.settings.keyboard_mode
	skip_button.visible = not GameState.settings.keyboard_mode

func _process(delta: float) -> void:
	if done:
		return
	if keyboard_previous != GameState.settings.keyboard_mode:
		keyboard_previous = GameState.settings.keyboard_mode
		elapsed = 0.0
		samples[stage].clear()
	update_text()
	if not GameState.settings.keyboard_mode:
		elapsed += delta
		samples[stage].append(VoiceInput.mic_db)
		if elapsed >= GameState.balance.calibration.window_s:
			advance()
	queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	if not done and GameState.settings.keyboard_mode and event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_SPACE:
		advance()
		get_viewport().set_input_as_handled()

func advance() -> void:
	if done:
		return
	if stage < 2:
		stage += 1
		elapsed = 0.0
		stage_changed.emit(stage)
		update_text()
		return
	if GameState.settings.keyboard_mode:
		result = model.defaults()
	else:
		var silence: Array[float] = []
		var talk: Array[float] = []
		var shout: Array[float] = []
		silence.assign(samples[0])
		talk.assign(samples[1])
		shout.assign(samples[2])
		result = model.evaluate(silence, talk, shout)
		if result.retry and retries < GameState.balance.calibration.max_retries:
			retries += 1
			elapsed = 0.0
			samples[2].clear()
			update_text()
			return
	finish()

func use_defaults() -> void:
	result = model.defaults()
	finish()

func finish() -> void:
	done = true
	VoiceInput.set_calibration(result.floor_db, result.talk_db, result.cal_shout_db)
	finished.emit(result)

func _draw() -> void:
	if done:
		return
	var center := Vector2(960, 610)
	var radius: float = GameState.balance.ui.sand_ring_radius
	var progress: float = elapsed / GameState.balance.calibration.window_s
	draw_arc(center, radius, 0.0, TAU, 64, Color(GameState.balance.palette.ink, 0.15), 4.0, true)
	if progress > 0.0:
		draw_arc(center, radius, -PI * 0.5, -PI * 0.5 + TAU * progress, 64, Color(GameState.balance.palette.gold), 5.0, true)
