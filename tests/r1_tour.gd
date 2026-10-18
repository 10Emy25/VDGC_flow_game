extends MinaTestSuite

var main: Control
var output_dir: String

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	preserve_user_files()
	output_dir = OS.get_environment("TOUR_DIR")
	if output_dir.is_empty():
		output_dir = "user://tour"
	DirAccess.make_dir_recursive_absolute(output_dir)
	GameState.settings.keyboard_mode = true
	main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	await snapshot("01_warning")
	main.show_calibration()
	await snapshot("02_calibration")
	var calibration: CalibrationView = main.current_view
	calibration.flow.advance()
	calibration.flow.advance()
	calibration.flow.advance()
	var intro: BedroomIntro = main.current_view
	intro.process_mode = Node.PROCESS_MODE_DISABLED
	for index in range(80):
		intro._process(0.05)
	await snapshot("03_bedroom")
	while intro.step.get("insert", "") != "hands":
		intro._process(0.05)
		intro.press()
	intro._process(0.6)
	await snapshot("03b_shaking_hands")
	while not intro.sleeping:
		intro._process(0.05)
		intro.press()
	for index in range(60):
		intro._process(0.05)
	await snapshot("03c_falling_asleep")
	while main.current_view == intro:
		intro._process(0.05)
	var run: RunView = main.current_view
	run.process_mode = Node.PROCESS_MODE_DISABLED
	run._process(run.dream_left * 0.5)
	await snapshot("03d_dream_clearing")
	run._process(run.dream_left + 0.01)
	run.process_mode = Node.PROCESS_MODE_PAUSABLE
	await snapshot("04_flower_path")
	main.toggle_settings()
	await snapshot("05_settings")
	main.settings_panel.close()
	key(KEY_CTRL, true)
	await get_tree().create_timer(0.6).timeout
	await snapshot("06_karaoke")
	run.model.x = 88
	run.bridge_progress = 0.45
	await snapshot("07_bridge")
	key(KEY_CTRL, false)
	# Exercise the §3 real-world services on a render-capable driver, without adding a scare.
	run.process_mode = Node.PROCESS_MODE_DISABLED
	GameState.world_real = 1.0
	PostFX.stress = 0.7
	for child in run.get_children():
		if child is DualSprite: child.update_blend()
	await snapshot("08_core_real_preview")
	GameState.settings.reduce_distortion = true
	for child in run.get_children():
		if child is DualSprite: child.update_blend()
	await snapshot("09_reduced_distortion")
	GameState.world_real = 0
	main.show_end_screen()
	await snapshot("10_end_screen")
	main.queue_free()
	await get_tree().process_frame
	finish()

func key(code: int, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.pressed = pressed
	Input.parse_input_event(event)

func snapshot(filename: String) -> void:
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	check(image.save_png(output_dir.path_join(filename + ".png")) == OK, "Screenshot " + filename)
