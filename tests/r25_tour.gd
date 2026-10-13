extends "res://tests/r2_scene_test.gd"
# Rendered tour of the R2.5 rework: dark verse, face slam, lunge, face wall, plank, eye, cover, finale.

var output_dir: String

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	preserve_user_files()
	output_dir = OS.get_environment("TOUR_DIR")
	if output_dir.is_empty(): output_dir = "user://tour25"
	DirAccess.make_dir_recursive_absolute(output_dir)
	GameState.settings.keyboard_mode = true
	VoiceInput.process_mode = Node.PROCESS_MODE_DISABLED
	BeatClock.process_mode = Node.PROCESS_MODE_DISABLED
	main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	main.show_run()
	run = main.current_view
	run.process_mode = Node.PROCESS_MODE_DISABLED
	# S1, first verse.
	run.state.bridge_ready = true
	run.model.x = 30
	BeatClock.elapsed = 6.1
	for i in range(3): advance(.02, false)
	run.update_song()
	await snapshot("01_twinkle")
	# S1, changed verse.
	run.model.x = 120
	BeatClock.elapsed = 30.0
	run.flash_left = 0
	GameState.world_real = .27
	advance(.02, false)
	run.update_song()
	run.flash_left = 0
	GameState.world_real = .27
	run.update_view(0)
	await snapshot("02_dark_verse")
	BeatClock.elapsed = 45.0
	GameState.world_real = .55
	advance(.02, false)
	run.update_song()
	run.flash_left = 0
	GameState.world_real = .55
	run.update_view(0)
	await snapshot("03_rosie")
	# Face slam.
	place(196)
	run.handle_message({"type":"face_slam"})
	advance(.12)
	await snapshot("04_face_slam")
	advance(.9)
	await snapshot("05_scream_text")
	# Chase with a lunge.
	place(345)
	run.state.director.gap = 3.5
	run.handle_message({"type":"lunge"})
	advance(.2)
	await snapshot("06_lunge")
	# Face wall.
	place(261.9)
	run.model.speed = 3
	advance(.1)
	key(KEY_SPACE, true)
	advance(.3)
	await snapshot("07_face_wall")
	key(KEY_SPACE, false)
	# Plank.
	place(362)
	run.model.speed = 3
	advance(.05)
	await snapshot("08_plank")
	# Eye opening during warning, cover glowing.
	place(450)
	run.state.director.phase = "WARNING"
	run.state.director.phase_start = 0
	run.state.director.phase_end = 2.4
	BeatClock.elapsed = 1.4
	advance(.02, false)
	await snapshot("09_eye_opening")
	run.state.director.phase = "GAZE"
	run.state.director.phase_start = 0
	run.state.director.phase_end = 100
	run.model.x = 458
	advance(.3)
	await snapshot("10_hidden_gaze")
	place(884)
	advance(.02)
	await snapshot("11_finale")
	main.queue_free()
	await get_tree().process_frame
	finish()

func snapshot(filename: String) -> void:
	# The frozen fixture only advances a few children; let every DualSprite pick up world_real.
	for child in run.get_children():
		if child is DualSprite: child._process(0.0)
	PostFX._process(0.0)
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	image.resize(960, 540)
	check(image.save_png(output_dir.path_join(filename + ".png")) == OK, "Screenshot " + filename)
