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
	main.show_clinic()
	await snapshot("02_calibration")
	var clinic: ClinicView = main.current_view
	clinic.flow.advance()
	clinic.flow.advance()
	clinic.flow.advance()
	for y in range(440, 551, 20):
		clinic.brush_at(Vector2(940, y))
	await snapshot("03_sand_brush")
	for y in range(405, 620, 22):
		for x in range(855, 1080, 22):
			if not clinic.transitioning:
				clinic.brush_at(Vector2(x, y))
	clinic._process(GameState.balance.sand.transition_s * 0.5)
	await snapshot("03b_trance")
	clinic._process(GameState.balance.sand.transition_s)
	var run: RunView = main.current_view
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
