extends MinaTestSuite
# S0 bedroom opening: data checks, narration order, props, close-ups, falling asleep, and the dream
# handing over to the flower-path song exactly when the music-box intro ends.

func _ready() -> void:
	preserve_user_files()
	GameState.settings.keyboard_mode = true
	check_data()
	var main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	main.show_calibration()
	main.current_view.flow.use_defaults()
	var intro: BedroomIntro = main.current_view
	check(intro != null, "Calibration leads into the bedroom")
	intro.process_mode = Node.PROCESS_MODE_DISABLED
	VoiceInput.missing_microphone = true
	GameState.settings.keyboard_mode = false
	main._process(0.0)
	check(not main.mic_warning.visible, "No microphone warning over the bedroom")
	GameState.settings.keyboard_mode = true
	check(intro.veil.visible and intro.pose_key == "bed_mina_asleep", "Opens in the dark on Mina in bed")
	intro._process(GameState.balance.intro.fade_in_s + 0.1)
	check(not intro.veil.visible, "The room fades in")
	# Narration: typed out, click finishes the line, a second click moves on.
	var heard: Array[String] = []
	var phone_hidden := false
	var phone_back := false
	var pill_in_palm := false
	var dt := 0.05
	var guard := 0
	while not intro.sleeping and guard < 3000:
		guard += 1
		intro._process(dt)
		if intro.typing and (heard.is_empty() or heard.back() != intro.narration.text):
			heard.append(intro.narration.text)
			check(intro.narration.visible_characters < intro.narration.get_total_character_count(), "Line is typed out: " + intro.narration.text)
			intro.press()
			check(not intro.typing and intro.narration.visible_characters == -1, "Click shows the whole line")
			var at := intro.index
			intro.press()
			intro._process(dt)
			check(intro.index == at + 1, "Second click moves on")
		if intro.pose_key == "bed_mina_phone":
			phone_hidden = phone_hidden or not intro.props.prop_phone.visible
		if phone_hidden and intro.pose_key == "bed_mina_book":
			phone_back = intro.props.prop_phone.visible and not intro.props.prop_book.visible
		if intro.insert_name == "pills" and intro.dropped:
			pill_in_palm = intro.pill.visible
	var expected: Array[String] = []
	for key in ["intro_day", "intro_cant_sleep", "intro_hands", "intro_must_sleep"]:
		expected.append(GameState.text(key))
	check(heard == expected, "Narration lines in order: %s" % [heard])
	check(phone_hidden and phone_back, "Phone leaves the nightstand while she holds it and comes back; book likewise")
	check(pill_in_palm, "A pill drops from the bottle into her palm")
	check(intro.sleeping and not intro.narration_box.visible, "She lies down to sleep; the narration box closes")
	# Falling asleep: eyes close, music starts in the dark, then the dream takes over.
	var bar: float = GameState.balance.bar_s
	var closing: float = GameState.balance.intro.sleep.lids.back()[0]
	intro._process(closing * 0.5)
	var half_lids := intro.lid_at(intro.sleep_age)
	check(half_lids < 1.0 and half_lids > 0.0, "Eyelids are closing")
	intro._process(closing)
	check(intro.pose_key == "bed_mina_asleep", "Asleep once the eyes are nearly shut")
	check(intro.music_age >= 0.0, "Music-box intro starts when the eyes close")
	var handed := []
	intro.fell_asleep.connect(func(elapsed: float) -> void: handed.append(elapsed))
	var music_before := intro.music_age
	while handed.is_empty() and intro.music_age < 20.0:
		intro._process(dt)
	check(handed.size() == 1, "Falls asleep once")
	near(handed[0], GameState.balance.intro.handover_bars * bar, "Hands over after the starry bar", dt + 0.001)
	var run: RunView = main.current_view
	check(run is RunView and run.dream_left > 0.0, "Wakes into the flower path through the dream")
	near(handed[0] + run.dream_left, GameState.balance.intro.music_bars * bar, "Song starts exactly when the intro ends")
	check(run.hud_layer.get_child(0).modulate.a < 0.01, "HUD hidden while the dream clears")
	check(BeatClock.master_key != "mus_song", "Song waits for the intro")
	run.process_mode = Node.PROCESS_MODE_DISABLED
	VoiceInput.process_mode = Node.PROCESS_MODE_DISABLED
	VoiceInput.tier = "TALK"
	VoiceInput.speed_target = 3.0
	VoiceInput.is_audible = true
	var material := run.dream_veil.material as ShaderMaterial
	var blur_start: float = material.get_shader_parameter("blur_px")
	run._process(run.dream_left * 0.5)
	var blur_mid: float = material.get_shader_parameter("blur_px")
	check(blur_mid < blur_start and blur_mid > 0.0, "Blur clears gradually (%.1f → %.1f px)" % [blur_start, blur_mid])
	near(run.model.x, 0.0, "Mina cannot move until the dream has cleared")
	run._process(run.dream_left + 0.01)
	check(run.dream_left <= 0.0 and BeatClock.master_key == "mus_song", "Song starts after the dream")
	check(not is_instance_valid(run.dream_veil) or run.dream_veil.is_queued_for_deletion(), "Dream veil removed")
	check(run.hud_layer.get_child(0).modulate.a > 0.99 and run.scale == Vector2.ONE, "HUD and camera back to normal")
	run._process(0.5)
	check(run.model.x > 0.0, "Voice moves Mina once the song is playing")
	VoiceInput.process_mode = Node.PROCESS_MODE_INHERIT
	if ResourceLoader.exists("res://scripts/dev/tester_mode.gd"):
		main.show_run(true, bar)
		var dreaming: RunView = main.current_view
		for pressed in [true, false]:
			var key := InputEventKey.new()
			key.physical_keycode = KEY_2
			key.pressed = pressed
			Input.parse_input_event(key)
		await get_tree().process_frame
		await get_tree().process_frame
		check(dreaming.dream_left <= 0.0 and dreaming.state.section == "S2", "Tester jump during the dream skips the rest of it")
	# Pausing in the bedroom freezes the opening.
	main.show_bedroom()
	var paused_intro: BedroomIntro = main.current_view
	await get_tree().process_frame
	main.toggle_settings()
	var index_before := paused_intro.index
	var age_before := paused_intro.age
	await get_tree().create_timer(0.2, true).timeout
	check(not paused_intro.can_process() and paused_intro.age == age_before and paused_intro.index == index_before, "Settings pauses the bedroom")
	main.settings_panel.close()
	main.queue_free()
	await get_tree().process_frame
	finish()

func check_data() -> void:
	var intro: Dictionary = GameState.balance.intro
	var steps: Array = GameState.read_json("res://data/intro.json").steps
	check(steps.size() > 5 and steps.back().get("sleep", false), "Intro ends by falling asleep")
	for step in steps:
		if step.has("pose"):
			check(ArtRegistry.has_texture(step.pose), "Pose art exists: " + step.pose)
		if step.has("say") and not str(step.say).is_empty():
			check(GameState.dialogue.strings.has(step.say), "Narration line exists: " + step.say)
		if step.has("sfx"):
			check(ResourceLoader.exists("res://audio/%s.wav" % step.sfx) or ResourceLoader.exists("res://audio/%s.ogg" % step.sfx), "Sound exists: " + step.sfx)
		if step.has("insert"):
			check(step.insert in ["hands", "pills", ""], "Known close-up: " + str(step.insert))
		for key in step.get("show", []) + step.get("hide", []):
			check(intro.props.has(key), "Known prop: " + key)
	for key in ["bedroom_bg", "insert_blanket", "insert_hand_left", "insert_hand_right", "insert_hand_bottle", "insert_hand_palm", "prop_pill", "ui_narration"]:
		check(ArtRegistry.has_texture(key), "Art exists: " + key)
	# The music-box intro is the first two lines of the song, so it lasts exactly music_bars.
	var units := 0
	for line in GameState.song.lines.slice(0, 2):
		for syllable in line.syllables:
			units += int(syllable[1])
	near(units * GameState.song.unit_s, intro.music_bars * GameState.balance.bar_s, "Intro melody fills music_bars")
	check(intro.handover_bars < intro.music_bars, "Dream has time to clear before the song")
	var bedroom_track: AudioStream = Sfx.get_stream("mus_bedroom")
	check(bedroom_track is AudioStreamWAV, "User music box loads for the bedroom")
	near(bedroom_track.get_length(), 64.0, "Bedroom music box preserves its full recording")
	check(bedroom_track.stereo, "Bedroom music preserves stereo")
	check(bedroom_track.loop_mode == AudioStreamWAV.LOOP_FORWARD, "Bedroom music loops during player-paced dialogue")
	var stream: AudioStream = Sfx.get_stream("mus_dream_intro")
	check(stream != null and stream.get_length() >= intro.music_bars * GameState.balance.bar_s, "Music-box intro audio exists and is long enough")
	check(stream is AudioStreamWAV and stream.loop_mode == AudioStreamWAV.LOOP_DISABLED, "Music-box intro plays once")
