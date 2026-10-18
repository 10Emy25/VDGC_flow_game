class_name SettingsPanel
extends Control

signal closed
signal recalibrate_requested
var checks: Dictionary = {}
var sensitivity_label: Label
var recalibration: Control
var panel: Control

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	theme = GameState.ui_theme
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var shade := ColorRect.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.05, 0.12, 0.11, 0.75)
	add_child(shade)
	panel = Control.new()
	var rect_value := UIFactory.rect(GameState.balance.layout.settings_panel)
	panel.position = rect_value.position
	panel.size = rect_value.size
	add_child(panel)
	UIFactory.texture(panel, "ui_panel", Rect2(Vector2.ZERO, panel.size))
	UIFactory.label(panel, "settings", Rect2(65, 30, 840, 70), GameState.balance.ui.system_size)
	var ypos := 124.0
	for key in ["keyboard_mode", "show_voice_meter", "reduce_distortion", "reduce_scares"]:
		var label_key: String = {"keyboard_mode":"keyboard_mode", "show_voice_meter":"voice_meter", "reduce_distortion":"reduce_distortion", "reduce_scares":"reduce_scares"}[key]
		var checkbox := CheckButton.new()
		checkbox.text = GameState.text(label_key)
		checkbox.position = Vector2(90, ypos)
		checkbox.size = Vector2(790, 65)
		checkbox.button_pressed = GameState.settings[key]
		checkbox.toggled.connect(func(value: bool) -> void: GameState.set_setting(key, value))
		panel.add_child(checkbox)
		checks[key] = checkbox
		ypos += 78
	sensitivity_label = UIFactory.label(panel, "sensitivity", Rect2(90, 446, 790, 50), GameState.balance.ui.body_size)
	var slider := HSlider.new()
	slider.position = Vector2(105, 513)
	slider.size = Vector2(760, 40)
	slider.min_value = GameState.balance.sensitivity.min_db
	slider.max_value = GameState.balance.sensitivity.max_db
	slider.step = GameState.balance.sensitivity.step_db
	slider.value = GameState.settings.sensitivity_db
	slider.value_changed.connect(func(value: float) -> void: GameState.set_setting("sensitivity_db", value))
	panel.add_child(slider)
	UIFactory.button(panel, "recalibrate", Rect2(95, 589, 780, 66), start_recalibration)
	UIFactory.button(panel, "close", Rect2(320, 691, 330, 66), close)
	GameState.settings_changed.connect(refresh)
	refresh()
	hide()

func refresh() -> void:
	for key in checks:
		checks[key].set_pressed_no_signal(GameState.settings[key])
	sensitivity_label.text = GameState.text("sensitivity") + "   " + GameState.text("sensitivity_value") % int(GameState.settings.sensitivity_db)

func open() -> void:
	show()
	get_tree().paused = true

func close() -> void:
	if recalibration != null:
		recalibration.queue_free()
		recalibration = null
	panel.show()
	hide()
	get_tree().paused = false
	closed.emit()

func start_recalibration() -> void:
	panel.hide()
	recalibration = Control.new()
	recalibration.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(recalibration)
	CalibrationView.build_backdrop(recalibration)
	var flow := CalibrationFlow.new()
	flow.process_mode = Node.PROCESS_MODE_ALWAYS
	recalibration.add_child(flow)
	flow.finished.connect(func(_result: Dictionary) -> void:
		recalibration.queue_free()
		recalibration = null
		panel.show())
	UIFactory.button(recalibration, "close", Rect2(1550, 815, 290, 66), func() -> void:
		recalibration.queue_free()
		recalibration = null
		panel.show())
