extends MinaTestSuite

var main: Control
var run: RunView

func _ready() -> void:
	preserve_user_files()
	GameState.settings.keyboard_mode = true
	VoiceInput.process_mode = Node.PROCESS_MODE_DISABLED
	BeatClock.process_mode = Node.PROCESS_MODE_DISABLED
	main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	main.show_run()
	run = main.current_view
	run.process_mode = Node.PROCESS_MODE_DISABLED
	place(345)
	var original_cal := [VoiceInput.model.floor_db, VoiceInput.model.talk_db, VoiceInput.model.cal_shout_db]
	VoiceInput.set_calibration(-50, -40, -28, false)
	VoiceInput.model.sensitivity_db = -10
	run.meter._process(0)
	check(run.meter.tier_labels[0].position.x + run.meter.tier_labels[0].size.x <= run.meter.tier_labels[1].position.x, "Voice labels remain distinct at guarded calibration and extreme sensitivity")
	VoiceInput.set_calibration(original_cal[0], original_cal[1], original_cal[2], false)
	VoiceInput.model.sensitivity_db = GameState.settings.sensitivity_db
	run.state.director.gap = .1
	advance(.05)
	check(run.state.status == "captured" and run.mina.base_key == "mina_caught", "Capture uses caught sprite")
	advance(1.22)
	check(run.overlay.visible and run.state.status == "fading", "Capture fades to black")
	advance(.52)
	check(run.state.status == "running" and run.model.x == 330, "View returns to CP1")
	check(run.state.director.invulnerable_left > 2.9, "View respawn protection")
	place(458)
	run.state.director.phase = "GAZE"
	run.state.director.phase_start = 0
	run.state.director.phase_end = 100
	advance(.02)
	check(run.state.hidden and run.mina.base_key == "mina_crouch", "Cover automatically crouches")
	check(run.mina.z_index < 3 and run.beam.visible, "Hidden Mina behind cover while beam remains visible")
	key(KEY_SHIFT, true)
	advance(.26)
	check(run.state.director.hearing_count == 1 and run.hand.visible, "Actual keyboard hum gives warning slam")
	key(KEY_SHIFT, false)
	advance(1.02)
	key(KEY_SHIFT, true)
	advance(.26)
	check(run.state.status == "captured" and run.state.director.capture_cause == "hearing", "Second keyboard sound captures")
	key(KEY_SHIFT, false)
	place(244.9)
	run.model.speed = 7
	key(KEY_SPACE, true)
	advance(.03)
	advance(.3)
	check(run.model.gate_state == "jumping" and run.mina.position.y < 500, "Fast gate draws jump arc")
	key(KEY_SPACE, false)
	place(294.9)
	run.model.speed = 3
	key(KEY_CTRL, true)
	advance(.04)
	check(run.model.gate_state == "stumbling" and run.model.speed == 0, "Slow gate stumbles")
	key(KEY_CTRL, false)
	place(330)
	advance(.02)
	check(run.state.safe_id == "CP1" and run.state.director.m1_speed("S2") == 0, "Safe puddle freezes wall")
	run.model.x = 334
	advance(.02)
	check(run.state.director.safe_hold_left > 5.9, "Leaving puddle holds wall")
	run.process_mode = Node.PROCESS_MODE_PAUSABLE
	main.toggle_settings()
	var clock := run.state.clock
	var paused_time := run.state.time
	await get_tree().create_timer(.05, true).timeout
	near(run.state.clock, clock, "Settings pause R2 state")
	near(run.state.time, paused_time, "Settings pause all R2 timers")
	check(not run.can_process(), "Run view cannot process during settings")
	main.settings_panel.close()
	run.process_mode = Node.PROCESS_MODE_DISABLED
	place(345)
	run.handle_message({"type":"face_slam"})
	advance(.05)
	check(run.slam_face.visible and run.slam_text.visible and run.slam_text.text == "SCREAM!!!", "Face slam shows the face and SCREAM!!!")
	near(GameState.world_real, 1, "Face slam switches to the real world")
	advance(2.2)
	check(not run.slam_face.visible and not run.slam_text.visible, "Face slam clears")
	check(run.darkness.visible, "Nightmare world is dark around Mina")
	place(262)
	run.model.speed = 3
	advance(.05)
	check(run.state.wall_waiting == 262 and run.prompt.text == GameState.text("wall_hint"), "Face wall stops Mina and asks for a shout")
	key(KEY_SPACE, true)
	advance(.45)
	advance(.45)
	key(KEY_SPACE, false)
	check(run.state.walls_broken.has(262.0) or run.state.walls_broken.has(262), "Shouting breaks the face wall")
	place(884)
	GameState.world_real = 1
	var time_scale := Engine.time_scale
	for bar in range(1, 5):
		key(KEY_SPACE, false)
		BeatClock.elapsed = bar * 2.4 - .02
		advance(.02, false)
		key(KEY_SPACE, true)
		BeatClock.elapsed = bar * 2.4 + .01
		advance(.02, false)
	key(KEY_SPACE, false)
	check(run.state.finale_hits == 4 and run.overlay.visible and run.overlay.color == Color.WHITE, "Four onsets show finale white flash")
	near(GameState.world_real, 0, "Finale returns color in four increments when real world is active")
	near(Engine.time_scale, time_scale, "Surge does not change engine time scale")
	advance(1.02)
	check(main.current_view is EndingView, "Flash reaches clinic ending")
	var ending: EndingView = main.current_view
	ending.process_mode = Node.PROCESS_MODE_DISABLED
	check(ending.line.text == GameState.text("ending_therapist"), "Ending therapist line")
	ending._process(2.01)
	check(ending.speaker.visible and ending.line.text == GameState.text("ending_me"), "Ending ME label and line")
	ending._process(3.0)
	check(not main.current_view is EndingView, "Ending reaches end screen")
	var restart: Button
	for child in main.current_view.get_children():
		if child is Button: restart = child
	check(restart != null and restart.text == GameState.text("restart"), "End screen has Restart")
	restart.pressed.emit()
	check(main.current_view is ClinicView and main.current_view.flow.stage == 0, "Restart returns to calibration without warning")
	main.queue_free()
	await get_tree().process_frame
	finish()

func place(x: float) -> void:
	run.clear_left = 0.0
	run.shake_left = 0.0
	run.subtitle_left = 0.0
	run.ring_left = 0.0
	run.state = LevelModel.new(GameState.balance, GameState.level, GameState.song)
	run.model = run.state.run
	run.level = run.state.level
	run.model.x = x
	run.state.bridge_ready = true
	run.state.bridge_progress = 1
	run.state.section = run.level.section_at(x)
	run.state.slammed = run.state.section != "S1"
	run.state.cursor = 0
	while run.state.cursor < run.level.events.size() and run.level.events[run.state.cursor].x <= x:
		run.state.cursor += 1
	for cp in run.level.of_type("checkpoint"):
		if cp.x <= x: run.state.save_checkpoint(cp)
	if run.state.section != "S1":
		run.state.director.spawn()
		run.state.director.grace_left = 0
	if run.state.section == "S5": run.state.director.begin_finale()
	run.parallax_x = x
	run.last_view_x = x
	run.handle_message({"type":"section","id":run.state.section})
	BeatClock.elapsed = 0

func advance(delta: float, clock_advance: bool = true) -> void:
	VoiceInput._process(delta)
	if clock_advance: BeatClock.elapsed += delta
	run._process(delta)
	if is_instance_valid(run) and run.is_inside_tree():
		# Frozen view fixtures need their presentation children advanced explicitly.
		run.meter._process(delta)
		run.mina._process(delta)
		run.wall._process(delta)
		run.peek._process(delta)

func key(code: int, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = pressed
	Input.parse_input_event(event)
	Input.flush_buffered_events()
