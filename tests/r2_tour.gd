extends "res://tests/r2_scene_test.gd"

var output_dir: String

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	preserve_user_files()
	output_dir = OS.get_environment("TOUR_DIR")
	if output_dir.is_empty(): output_dir = "user://tour"
	DirAccess.make_dir_recursive_absolute(output_dir)
	GameState.settings.keyboard_mode = true
	VoiceInput.process_mode = Node.PROCESS_MODE_DISABLED
	BeatClock.process_mode = Node.PROCESS_MODE_DISABLED
	main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	main.show_run()
	run = main.current_view
	run.process_mode = Node.PROCESS_MODE_DISABLED
	place(280)
	run.state.director.gap = 3.8
	key(KEY_SPACE, true)
	advance(.02)
	await snapshot("01_chase")
	key(KEY_SPACE, false)
	place(600)
	run.state.director.phase = "GAZE"
	run.state.director.phase_start = 0
	run.state.director.phase_end = 100
	advance(.02)
	await snapshot("02_hidden_gaze")
	run.state.director.phase = "RECEDE"
	run.handle_message({"type":"recede"})
	run.update_view(0)
	await snapshot("02b_recede")
	run.state.director.phase = "GAZE"
	key(KEY_SHIFT, true)
	advance(.28)
	advance(.2)
	await snapshot("03_warning_slam")
	key(KEY_SHIFT, false)
	place(280)
	run.state.director.gap = .01
	advance(.02)
	await snapshot("04_capture")
	advance(1.22)
	await snapshot("05_fade")
	advance(.52)
	await snapshot("06_respawn")
	place(469.9)
	run.model.speed = 7
	key(KEY_SPACE, true)
	advance(.03)
	advance(.3)
	await snapshot("07_jump_gate")
	key(KEY_SPACE, false)
	place(519.9)
	run.model.speed = 3
	key(KEY_CTRL, true)
	advance(.04)
	await snapshot("08_stumble")
	key(KEY_CTRL, false)
	place(400)
	advance(.02)
	await snapshot("09_safe_zone")
	place(850)
	run.state.director.phase = "WARNING"
	run.state.director.phase_start = 0
	run.state.director.phase_end = 100
	advance(.02)
	await snapshot("10_warning_cover")
	place(1084)
	key(KEY_SPACE, true)
	BeatClock.elapsed = 2.41
	advance(.02, false)
	await snapshot("11_finale")
	key(KEY_SPACE, false)
	for bar in range(2,5):
		advance(.02)
		key(KEY_SPACE, true)
		BeatClock.elapsed = bar * 2.4 + .01
		advance(.02, false)
		key(KEY_SPACE, false)
	await snapshot("12_white_flash")
	advance(1.02)
	var ending: EndingView = main.current_view
	ending.process_mode = Node.PROCESS_MODE_DISABLED
	await snapshot("13_ending")
	ending._process(2.01)
	await snapshot("14_mina_line")
	ending._process(3)
	await snapshot("15_end_screen")
	main.queue_free()
	await get_tree().process_frame
	finish()

func snapshot(filename: String) -> void:
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	check(image.save_png(output_dir.path_join(filename + ".png")) == OK, "Screenshot " + filename)
