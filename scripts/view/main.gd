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
	show_warning()

func _process(_delta: float) -> void:
	mic_warning.visible = VoiceInput.missing_microphone and not GameState.settings.keyboard_mode and not settings_panel.visible and not current_view is EndingView
	if current_view is RunView and current_view.state.status != "running":
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
	UIFactory.button(screen, "begin", Rect2(760, 765, 400, 80), show_clinic)

func show_clinic() -> void:
	var clinic := ClinicView.new()
	clinic.entered_dream.connect(show_run)
	replace_view(clinic)

func show_run() -> void:
	var run := RunView.new()
	run.run_finished.connect(show_ending)
	replace_view(run)

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
	UIFactory.button(screen, "restart", Rect2(640, 641, 640, 80), show_clinic)

func toggle_settings() -> void:
	if settings_panel.visible:
		settings_panel.close()
	else:
		settings_panel.open()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_K:
		GameState.set_setting("keyboard_mode", not GameState.settings.keyboard_mode)
		get_viewport().set_input_as_handled()
