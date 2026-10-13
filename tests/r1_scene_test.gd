extends MinaTestSuite

func _ready() -> void:
	preserve_user_files()
	GameState.settings.keyboard_mode = true
	var main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	check(main.settings_button.visible, "Settings button present on warning")
	for child in main.current_view.get_children():
		if child is Button:
			child.pressed.emit()
	var clinic: ClinicView = main.current_view
	check(clinic.flow.stage == 0, "Clinic begins with silence")
	check(clinic.flow.get_parent() == clinic.hud_layer and clinic.hud_layer.layer > PostFX.layer, "Clinic text stays above trance and PostFX")
	var event := InputEventKey.new()
	event.physical_keycode = KEY_SPACE
	event.pressed = true
	for index in range(3):
		clinic.flow._unhandled_input(event)
	check(clinic.brush_ready, "Three keyboard samples open sand brush")
	near(VoiceInput.model.floor_db, -50, "Keyboard clinic uses defaults")
	var config := ConfigFile.new()
	check(config.load("user://voice_calibration.cfg") == OK, "Calibration saved")
	near(config.get_value("voice", "talk_db"), -32, "Saved calibration values")
	check(clinic.reveal_fraction() == 0.0, "Doll starts buried")
	clinic.brush_at(Vector2(480, 330))
	check(clinic.reveal_fraction() == 0.0, "Brushing outside doll cannot reveal it")
	clinic.last_brush = Vector2.INF
	for y in range(405, 620, 22):
		for x in range(855, 1080, 22):
			if not clinic.transitioning:
				clinic.brush_at(Vector2(x, y))
	check(clinic.reveal_fraction() >= 0.7, "Doll reveal threshold measured from mask")
	check(clinic.transitioning, "Doll reveal begins trance")
	clinic._process(GameState.balance.sand.transition_s)
	var run: RunView = main.current_view
	check(run != null, "Trance reaches S1")
	check(run.hud_layer.layer > PostFX.layer and run.prompt.get_parent() == run.hud_layer, "Run text stays above distortion")
	run.process_mode = Node.PROCESS_MODE_DISABLED
	VoiceInput.process_mode = Node.PROCESS_MODE_DISABLED
	BeatClock.process_mode = Node.PROCESS_MODE_DISABLED
	VoiceInput.tier = "QUIET"
	VoiceInput.speed_target = 0
	VoiceInput.is_shouting = false
	VoiceInput.is_audible = false
	VoiceInput._process(3.1)
	check(VoiceInput.missing_microphone, "Silent Dummy capture detects missing microphone after three seconds")
	run._process(1)
	near(run.model.x, 0, "Silence permits standing still")
	check(run.prompt.text == GameState.text("hum_walk"), "First tutorial prompt")
	var keyboard := InputEventKey.new()
	keyboard.physical_keycode = KEY_K
	keyboard.pressed = true
	main._input(keyboard)
	check(not GameState.settings.keyboard_mode, "K toggles keyboard mode")
	main._input(keyboard)
	check(GameState.settings.keyboard_mode, "K toggles back")
	run.process_mode = Node.PROCESS_MODE_PAUSABLE
	var paused_x := run.model.x
	main.toggle_settings()
	check(get_tree().paused and main.settings_panel.visible, "Settings pauses run")
	check(not run.can_process(), "Run cannot process while settings is open")
	await get_tree().create_timer(0.05, true).timeout
	near(run.model.x, paused_x, "Paused movement stays fixed through frames")
	run.process_mode = Node.PROCESS_MODE_DISABLED
	GameState.set_setting("show_voice_meter", false)
	run.meter._process(0)
	check(not run.meter.visible, "Voice meter toggle")
	check(config.load("user://settings.cfg") == OK and not config.get_value("settings", "show_voice_meter", true), "Settings persisted")
	main.settings_panel.start_recalibration()
	var recalibration: Control = main.settings_panel.recalibration
	var flow: CalibrationFlow
	for child in recalibration.get_children():
		if child is CalibrationFlow:
			flow = child
	check(flow != null and flow.can_process(), "Recalibration processes while paused")
	flow.use_defaults()
	check(main.settings_panel.recalibration == null, "Recalibration returns to settings")
	GameState.settings.keyboard_mode = false
	main.settings_panel.start_recalibration()
	for child in main.settings_panel.recalibration.get_children():
		if child is CalibrationFlow:
			flow = child
	flow.stage = 2
	flow.samples = [[-50.0], [-32.0], [-30.0]]
	flow.advance()
	check(flow.retries == 1 and not flow.done, "Weak call gets one retry")
	flow.samples[2] = [-29.0]
	flow.advance()
	check(flow.done and main.settings_panel.recalibration == null, "Second weak call uses guarded thresholds without another retry")
	GameState.settings.keyboard_mode = true
	VoiceInput.set_calibration(-50, -32, -14, false)
	main.settings_panel.close()
	check(not get_tree().paused and not main.settings_panel.visible, "Close resumes run")
	VoiceInput.tier = "TALK"
	VoiceInput.speed_target = 3
	VoiceInput.is_audible = true
	BeatClock.elapsed = 0.1
	run.update_song()
	check(run.sung.has(0), "Audible syllable marked gold")
	check(run.world_props.back().sprite.base_key == "flower_bud", "Sung syllable begins as bud")
	run.process_mode = Node.PROCESS_MODE_PAUSABLE
	await get_tree().create_timer(GameState.song.unit_s + 0.05).timeout
	run.process_mode = Node.PROCESS_MODE_DISABLED
	check(run.world_props.back().sprite.base_key == "flower_open", "Bud becomes open flower")
	var prop_count := run.world_props.size()
	run.update_song()
	check(run.world_props.size() == prop_count, "Each syllable blooms once per loop")
	BeatClock.elapsed = 19.3
	run.update_song()
	check(run.world_props.size() == prop_count + 1, "Next song loop can bloom again")
	run.model.x = run.bridge_event.x - 0.001
	run.model.speed = 3
	run._process(0.1)
	near(run.model.x, 70, "Bridge prevents crossing")
	near(run.model.speed, 0, "Mina stops at bridge edge")
	var progress := run.bridge_progress
	VoiceInput.tier = "HUM"
	VoiceInput.speed_target = 1.5
	run._process(1)
	near(run.bridge_progress, progress, "Hum cannot raise bridge")
	VoiceInput.tier = "TALK"
	VoiceInput.speed_target = 3
	run._process(2.31)
	check(run.bridge_ready, "One cumulative bar of TALK raises bridge")
	run._process(0.3)
	check(run.model.x > 70, "Raised bridge permits crossing")
	run.model.x = 240
	run._process(0.1)
	check(run.state.section == "S1" and run.model.x >= 240, "Flower path keeps going while the song plays: no waiting")
	BeatClock.elapsed = run.song.duration + 0.01
	run._process(0.02)
	check(main.current_view == run and run.state.section == "S2" and run.slam_face.visible, "Song cut leads into the face slam and S2")
	check(run.state.level.first("gate").x > 260, "The chase is shifted to start where the slam happened")
	main.show_clinic()
	check(main.current_view is ClinicView and main.current_view.flow.stage == 0, "Replay calibrates again, skipping warning")
	main.queue_free()
	await get_tree().process_frame
	finish()
