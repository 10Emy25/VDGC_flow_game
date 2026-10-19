extends Node
func _ready() -> void:
	VoiceInput.process_mode = Node.PROCESS_MODE_DISABLED
	var main: Control = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	main.show_run()
	var run: RunView = main.current_view
	run.set_process(false)
	var layer: Control = run.layers[0].sprite
	var film: LockerPass = run.locker_pass
	assert(run.state.song_end == SongModel.new(GameState.song).duration)
	assert(run.level.events == GameState.level.events)
	assert(film.locker_x == 803)
	# The original song ending shifts later encounters. The observer must follow the live event.
	run.model.x = 230
	run.state.face_slam()
	assert(film.locker_x == 833)
	run.model.x = film.locker_x - 6
	run.state.messages.clear()
	run.update_view(0)
	for i in range(5): await get_tree().physics_frame
	assert(film.active)
	film.step(3.1)
	assert(film.camera_locked)
	film.step(1)
	film.step(1.9)
	film.step(4.3)
	film.step(2.9)
	film.step(2.7)
	film.step(0.7)
	assert(run.night_continuation != null and not film.active)
	var night: NightContinuation = run.night_continuation
	night.step(0.4)
	night.step(2)
	night.step(1.3)
	assert(night.direction_hint.text.contains("any direction"))
	night.elapsed = 84.9
	night.step(0.2)
	assert(main.current_view == run and run.layers[0].sprite == layer)
	assert(run.final_confrontation != null and run.final_confrontation.embedded)
	print("V6 integration: original cabinet placement, dynamic shift tracking, camera film, S2 and same-map finale passed")
	get_tree().quit()
