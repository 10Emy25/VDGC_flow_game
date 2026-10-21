extends Node
func _ready() -> void:
	VoiceInput.process_mode = Node.PROCESS_MODE_DISABLED
	BeatClock.process_mode = Node.PROCESS_MODE_DISABLED
	var main: Control = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	main.show_run()
	var run: RunView = main.current_view
	run.set_process(false)
	var recording: AudioStreamWAV = Sfx.get_stream("mus_song")
	var end: float = recording.get_length()
	assert(absf(end - 32.397042) < 0.01)
	assert(is_equal_approx(run.state.song_end, end))
	assert(recording.loop_mode == AudioStreamWAV.LOOP_DISABLED)
	# The old 19.2-second cue must not cut the new recording.
	run.state.step(19.3, 3, false, true, 2, 19.3)
	assert(run.state.section == "S1" and not run.state.slammed)
	run.state.step(end - 19.3 - 0.01, 3, false, true, 2, end - 0.01)
	assert(run.state.section == "S1" and not run.state.slammed)
	run.state.step(0.03, 3, false, true, 2, end + 0.02)
	assert(run.state.slammed and run.state.section == "S2")
	assert(is_equal_approx(run.locker_pass.locker_x, 803 + run.state.level_offset))
	print("Full opening track passed: no cut at 19.2s; original chase starts after all 32.397s; cabinet follows original map shift")
	get_tree().quit()
