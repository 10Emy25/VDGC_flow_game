extends Control

var current_view: Control
var view_host: Control
var hud_layer: CanvasLayer
var settings_panel: SettingsPanel
var settings_button: Button
var mic_warning: Label

func _ready() -> void:
	theme = GameState.ui_theme
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	view_host = Control.new()
	view_host.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(view_host)
	hud_layer = CanvasLayer.new()
	hud_layer.layer = 10
	add_child(hud_layer)
	settings_button = UIFactory.button(hud_layer, "settings", UIFactory.rect(GameState.balance.layout.settings_rect), toggle_settings)
	settings_button.process_mode = Node.PROCESS_MODE_ALWAYS
	settings_button.z_index = 10
	settings_panel = SettingsPanel.new()
	hud_layer.add_child(settings_panel)
	settings_panel.closed.connect(func() -> void: settings_button.show())
	mic_warning = UIFactory.label(hud_layer, "mic_missing", Rect2(590, 870, 1270, 45), GameState.balance.ui.small_size)
	mic_warning.process_mode = Node.PROCESS_MODE_ALWAYS
	process_mode = Node.PROCESS_MODE_ALWAYS
	# Tester mode (debug builds only). Delete scripts/dev/ to remove it; this line then does nothing.
	if OS.is_debug_build() and ResourceLoader.exists("res://scripts/dev/tester_mode.gd"):
		var tester: Node = load("res://scripts/dev/tester_mode.gd").new()
		tester.set("main", self)
		add_child(tester)
	show_warning()

func _process(_delta: float) -> void:
	mic_warning.visible = VoiceInput.missing_microphone and not GameState.settings.keyboard_mode and not settings_panel.visible and not current_view is EndingView and not current_view is BedroomIntro
	if current_view is RunView and (current_view.state.status != "running" or current_view.dream_left > 0.0):
		mic_warning.hide()

	if current_view is LastScream and current_view.phase in ["shock", "reveal", "white", "wake", "phone"]: mic_warning.hide()
	if current_view is RunView and current_view.night_continuation != null:
		if current_view.night_continuation.phase in ["blackout", "look", "listen"] or current_view.night_continuation.elapsed >= 73: mic_warning.hide()

	var cinematic: bool = current_view is LastScream and current_view.phase in ["shock", "reveal"]
	if current_view is RunView and current_view.night_continuation != null:
		cinematic = current_view.night_continuation.phase in ["blackout", "look", "listen"] or current_view.night_continuation.elapsed >= 73
	settings_button.visible = not cinematic and not settings_panel.visible

	if current_view is RunView and current_view.final_confrontation != null:
		var final_phase: String = current_view.final_confrontation.phase
		mic_warning.visible = VoiceInput.missing_microphone and not GameState.settings.keyboard_mode and not settings_panel.visible and final_phase in ["player_light", "voice"]
		settings_button.visible = final_phase not in ["roar", "auto_scream"] and not settings_panel.visible

	if current_view is RunView and current_view.locker_pass != null and current_view.locker_pass.active:
		settings_button.hide()
		mic_warning.hide()

func replace_view(view: Control) -> void:
	if current_view != null:
		view_host.remove_child(current_view)
		current_view.queue_free()
	current_view = view
	view.process_mode = Node.PROCESS_MODE_PAUSABLE
	view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	view_host.add_child(view)

func show_warning() -> void:
	var screen := Control.new()
	replace_view(screen)
	var bg := ColorRect.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(GameState.balance.palette.quiet)
	screen.add_child(bg)
	UIFactory.label(screen, "game_title", Rect2(260, 180, 1400, 120), GameState.balance.ui.title_size, Color(GameState.balance.palette.warm))
	UIFactory.label(screen, "chapter_title", Rect2(300, 305, 1320, 66), GameState.balance.ui.therapist_size, Color(GameState.balance.palette.gold))
	var warning := UIFactory.label(screen, "content_warning", Rect2(410, 455, 1100, 235), GameState.balance.ui.body_size, Color(GameState.balance.palette.warm))
	warning.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UIFactory.button(screen, "begin", Rect2(760, 765, 400, 80), show_calibration)

func show_calibration() -> void:
	var calibration := CalibrationView.new()
	calibration.finished.connect(show_bedroom)
	replace_view(calibration)

func show_bedroom() -> void:
	var intro := BedroomIntro.new()
	intro.fell_asleep.connect(func(music_elapsed: float) -> void: show_run(true, music_elapsed))
	replace_view(intro)

# from_dream: Mina has just fallen asleep in the bedroom and the music-box intro is still playing.
func show_run(from_dream: bool = false, music_elapsed: float = 0.0) -> void:
	var run := RunView.new()
	if from_dream:
		run.dream_left = maxf(0.01, GameState.balance.intro.music_bars * GameState.balance.bar_s - music_elapsed)
	run.run_finished.connect(show_ending)
	run.flower_triggered.connect(show_last_scream)
	replace_view(run)

func show_flower_night() -> void:
	if not current_view is RunView: show_run()
	if current_view.night_continuation == null: current_view.start_night_continuation()

func show_last_scream() -> void:
	if not current_view is RunView: show_run()
	var finale: LastScream = current_view.start_last_scream()
	if not finale.finished.is_connected(show_calibration): finale.finished.connect(show_calibration)

func show_ending() -> void:
	var ending := EndingView.new()
	ending.finished.connect(show_end_screen)
	replace_view(ending)

func show_end_screen() -> void:
	Sfx.stop_all()
	var screen := Control.new()
	replace_view(screen)
	UIFactory.texture(screen, "run_bg_far_cute", Rect2(0, 0, 1920, 1080))
	UIFactory.texture(screen, "ui_panel_wide", Rect2(360, 290, 1200, 570))
	UIFactory.label(screen, "end_title", Rect2(420, 335, 1080, 200), GameState.balance.ui.title_size)
	UIFactory.button(screen, "restart", Rect2(640, 641, 640, 80), show_calibration)

func toggle_settings() -> void:
	if settings_panel.visible:
		settings_panel.close()
	else:
		settings_panel.open()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_K:
		GameState.set_setting("keyboard_mode", not GameState.settings.keyboard_mode)
		get_viewport().set_input_as_handled()
