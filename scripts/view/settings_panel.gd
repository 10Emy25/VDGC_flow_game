class_name SettingsPanel
extends Control

signal opened
signal homepage_requested
signal closed
signal recalibrate_requested
var checks: Dictionary = {}
var sensitivity_label: Label
var recalibration: Control
var panel: Control
var art_page: Control
var font_minus: Button
var font_plus: Button
var homepage: Button
var cursor_minus: Button
var cursor_plus: Button
var esc_button: Button
var font_percent: Label
var art_material: ShaderMaterial
var art_buttons: Array[Dictionary] = []
var static_audio: AudioStreamPlayer
var laugh_audio: AudioStreamPlayer
var sounds_muted := false
var cursor_presses := 0

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
	build_art_page()
	refresh()
	panel.hide()
	hide()

func build_art_page() -> void:
	art_page = Control.new()
	add_child(art_page)
	art_page.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var art := TextureRect.new()
	art.texture = preload("res://art/settings_menu.png")
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_SCALE
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art_page.add_child(art)
	art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	art_material = ShaderMaterial.new()
	art_material.shader = preload("res://shaders/art_text_size.gdshader")
	art_material.set_shader_parameter("settings_page", true)
	art.material = art_material
	font_minus = art_button("Smaller text", Rect2(1440, 650, 290, 145), func() -> void: change_font(-0.05))
	font_plus = art_button("Larger text", Rect2(1815, 585, 270, 260), func() -> void: change_font(0.05))
	homepage = art_button("Homepage", Rect2(510, 910, 1250, 310), func() -> void:
		close()
		homepage_requested.emit())
	cursor_minus = art_button("Cursor size −", Rect2(1435, 1320, 290, 145), cursor_feedback)
	cursor_plus = art_button("Cursor size +", Rect2(1800, 1270, 270, 260), cursor_feedback)
	font_percent = UIFactory.label(art_page, "", Rect2(), 28, Color("f1d5cd"))
	font_percent.add_theme_color_override("font_outline_color", Color.BLACK)
	font_percent.add_theme_constant_override("outline_size", 5)
	esc_button = art_button("Close settings (Esc)", Rect2(1950, 1515, 350, 85), close)
	esc_button.text = "ESC · Back"
	esc_button.add_theme_color_override("font_color", Color("f1d5cd"))
	for key in ["static_audio", "laugh_audio"]:
		var player := AudioStreamPlayer.new()
		player.stream = load("res://audio/sfx_title_%s.wav" % ("static" if key == "static_audio" else "laugh"))
		player.volume_db = -8 if key == "static_audio" else -7
		add_child(player)
		set(key, player)
	resized.connect(layout_art)
	layout_art()

func art_button(label: String, region: Rect2, action: Callable) -> Button:
	var button := Button.new()
	button.tooltip_text = label
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	var hover := StyleBoxFlat.new()
	hover.bg_color = Color(1, 0.8, 0.8, 0.09)
	hover.set_corner_radius_all(12)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	var pressed := StyleBoxFlat.new()
	pressed.bg_color = Color(0, 0, 0, 0.4)
	pressed.set_corner_radius_all(12)
	button.add_theme_stylebox_override("pressed", pressed)
	button.pressed.connect(func() -> void:
		button.release_focus()
		action.call())
	art_page.add_child(button)
	art_buttons.append({"button": button, "region": region})
	return button

func layout_art() -> void:
	var factor := size / Vector2(2360, 1640)
	for item in art_buttons:
		item.button.position = item.region.position * factor
		item.button.size = item.region.size * factor
	font_percent.position = Vector2(2120, 680) * factor
	font_percent.size = Vector2(210, 95) * factor

func change_font(delta: float) -> void:
	GameState.set_setting("font_scale", snappedf(float(GameState.settings.get("font_scale", 1.0)) + delta, 0.05))

func cursor_feedback() -> void:
	# Reserved controls: provide a real press response without altering the pointer.
	cursor_presses += 1

func refresh() -> void:
	for key in checks:
		checks[key].set_pressed_no_signal(GameState.settings[key])
	if is_instance_valid(art_material):
		var amount: float = GameState.settings.get("font_scale", 1.0)
		art_material.set_shader_parameter("font_scale", amount)
		font_percent.text = "%d%%" % roundi(amount * 100)
		font_minus.disabled = amount <= 0.8501
		font_plus.disabled = amount >= 1.1499
	sensitivity_label.text = GameState.text("sensitivity") + "   " + GameState.text("sensitivity_value") % int(GameState.settings.sensitivity_db)

func open() -> void:
	panel.hide()
	art_page.show()
	show()
	get_tree().paused = true
	# Listeners pause the menu first, then the scare sounds play on this ALWAYS panel.
	opened.emit()
	if not sounds_muted and not Sfx.silent() and not GameState.settings.reduce_scares:
		static_audio.play()

func close() -> void:
	static_audio.stop()
	laugh_audio.stop()
	if recalibration != null:
		recalibration.queue_free()
		recalibration = null
	panel.hide()
	art_page.show()
	hide()
	get_tree().paused = false
	closed.emit()

func start_recalibration() -> void:
	art_page.hide()
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

func _input(event: InputEvent) -> void:
	if visible and event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_ESCAPE:
		close()
		get_viewport().set_input_as_handled()
