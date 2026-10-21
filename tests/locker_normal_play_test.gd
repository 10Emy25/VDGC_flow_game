extends Node
func _ready() -> void:
	VoiceInput.process_mode = Node.PROCESS_MODE_DISABLED
	BeatClock.process_mode = Node.PROCESS_MODE_DISABLED
	GameState.settings.keyboard_mode = false
	var main: Control = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	main.show_run()
	var run: RunView = main.current_view
	run.set_process(false)
	var original := LevelModel.new(GameState.balance, GameState.level, GameState.song)
	# Only the new recording duration intentionally differs from the original opening.
	original.song_end = Sfx.get_stream("mus_song").get_length()
	var policy: Node = load("res://tests/playthrough.gd").new()
	var voice := VoiceModel.new(GameState.balance)
	var saw_original_slam := false
	var visited := {"S1":true}
	var saw_locker_before_trigger := false
	var camera_stopped := false
	assert(run.state.song_end == original.song_end and run.state.song_end < INF)
	assert(run.level.events == original.level.events)
	for i in range(60000):
		var tier: int = policy.policy(run.state, 0, false)
		var db: float = voice.floor_db - 8
		if tier == 2: db = voice.thresholds()[1]
		elif tier == 3: db = voice.thresholds()[2]
		elif tier == 4: db = (voice.thresholds()[1] + voice.thresholds()[2]) * 0.5
		var sample: Dictionary = voice.sample(db)
		VoiceInput.db = db
		VoiceInput.speed_target = sample.speed_target
		VoiceInput.level01 = sample.level01
		VoiceInput.is_audible = sample.is_audible
		VoiceInput.is_shouting = sample.is_shouting
		VoiceInput.tier = sample.tier
		BeatClock.elapsed += 1.0 / 60.0
		if not run.locker_pass.entered:
			original.step(1.0 / 60.0, sample.speed_target, sample.is_shouting, sample.is_audible, 2 if tier == 4 else tier, BeatClock.elapsed)
		run._process(1.0 / 60.0)
		# Advance visual tweens on the same accelerated clock as the simulation.
		for tween in get_tree().get_processed_tweens(): tween.custom_step(1.0 / 60.0)
		if not run.locker_pass.entered:
			assert(is_equal_approx(run.model.x, original.run.x), "Original movement must remain unchanged")
			assert(run.state.section == original.section and run.state.status == original.status)
			assert(run.level.events == original.level.events, "Do not relocate map events")
			visited[run.state.section] = true
			if run.state.slammed: saw_original_slam = true
			if run.locker_pass.locker.is_visible_in_tree(): saw_locker_before_trigger = true
		if run.locker_pass.camera_locked: camera_stopped = true
		if run.night_continuation != null:
			assert(saw_original_slam and visited.has("S2") and visited.has("S3") and visited.has("S4"))
			assert(saw_locker_before_trigger and camera_stopped)
			print("V6 NORMAL PLAY PASSED: original song/slam/chase/obstacles match original LevelModel frame by frame; late cabinet triggers automatically; no shortcuts")
			policy.free()
			get_tree().quit()
			return
		if i % 30 == 0: await get_tree().physics_frame
	print("Failed at x=", run.model.x, " state=", run.state.status, " section=", run.state.section, " cabinet=", run.locker_pass.locker_x)
	assert(false)
	get_tree().quit(1)
