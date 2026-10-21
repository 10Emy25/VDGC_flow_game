extends Node

func _ready() -> void:
 var keyboard_before: bool = GameState.settings.keyboard_mode
 GameState.settings.keyboard_mode = false
 VoiceInput.set_process(false)
 var sensitivity_before: float = GameState.settings.sensitivity_db
 var calibration_before := [VoiceInput.model.floor_db, VoiceInput.model.talk_db, VoiceInput.model.cal_shout_db]
 var main: Control = load("res://scenes/main.tscn").instantiate()
 add_child(main)
 main.show_run()
 var run: RunView = main.current_view
 run.set_process(false)
 var noise: float = VoiceInput.model.thresholds()[0] + 3
 run.state.director.phase = "IDLE"
 assert(is_equal_approx(VoiceInput.gameplay_mic_db(noise), noise))
 for phase in ["WARNING", "GAZE"]:
  run.state.director.phase = phase
  var protected_db: float = VoiceInput.gameplay_mic_db(noise)
  assert(is_equal_approx(noise-protected_db,6))
  assert(not VoiceInput.model.sample(protected_db).is_audible)
  var loud: float = VoiceInput.model.thresholds()[2]+10
  assert(VoiceInput.model.sample(VoiceInput.gameplay_mic_db(loud)).is_shouting, "Intentional loud voice still counts")
 run.state.director.phase = "RECEDE"
 assert(is_equal_approx(VoiceInput.gameplay_mic_db(noise),noise), "Normal input returns when the eye closes")
 run.state.director.phase = "GAZE"
 GameState.settings.keyboard_mode = true
 assert(is_equal_approx(VoiceInput.gameplay_mic_db(noise),noise))
 GameState.settings.keyboard_mode = false
 run.state.status = "captured"
 assert(is_equal_approx(VoiceInput.gameplay_mic_db(noise),noise))
 run.state.status = "running"
 main.toggle_settings()
 assert(main.settings_panel.visible and get_tree().paused)
 assert(is_equal_approx(VoiceInput.gameplay_mic_db(noise),noise))
 for item in main.settings_panel.art_buttons:
  assert(item.button.text != "More settings")
 var esc := InputEventKey.new()
 esc.physical_keycode = KEY_ESCAPE
 esc.pressed = true
 main.settings_panel._input(esc)
 assert(not main.settings_panel.visible and not get_tree().paused)
 main.toggle_settings()
 main.settings_panel.esc_button.pressed.emit()
 assert(not main.settings_panel.visible and not get_tree().paused)
 assert(is_equal_approx(VoiceInput.gameplay_mic_db(noise),noise-6))
 assert(GameState.settings.sensitivity_db == sensitivity_before)
 assert(calibration_before == [VoiceInput.model.floor_db, VoiceInput.model.talk_db, VoiceInput.model.cal_shout_db])
 # Starting the locker film must not remove the dark occluded view.
 PostFX.stress = 0.65
 run.darkness.show()
 run.locker_pass.locker.show()
 run.locker_pass.on_arrival(run.locker_pass.probe)
 assert(run.locker_pass.active and run.darkness.visible)
 assert(is_equal_approx(PostFX.stress,0.65))
 run.locker_pass.step(0.1)
 var center: Vector2 = run.darkness.material.get_shader_parameter("center")
 assert(is_equal_approx(center.x,run.mina.position.x+run.mina.size.x*0.5))
 assert(is_equal_approx(VoiceInput.gameplay_mic_db(noise),noise), "Cinematic releases the quiet assist")
 # Follow the actual embedded finale -> phone ending -> replay signal chain.
 main.show_last_scream()
 var finale: LastScream = run.final_confrontation
 finale.set_process(false)
 finale.enter("wake")
 assert(is_equal_approx(VoiceInput.gameplay_mic_db(noise),noise))
 var ending: DreamMessageEnding = finale.dream_ending
 ending.set_process(false)
 ending.phase = "black"
 ending._process(2.5)
 ending.replay.pressed.emit()
 assert(main.current_view is TitleMenu, "Ending replay returns to the current illustrated menu")
 main.current_view.new_button.pressed.emit()
 assert(main.current_view is BedroomIntro)
 main.show_end_screen()
 for child in main.current_view.get_children():
  if child is Button and child.text == GameState.text("restart"): child.pressed.emit()
 assert(main.current_view is TitleMenu, "Legacy end-screen restart also returns to the current menu")
 assert(is_equal_approx(VoiceInput.gameplay_mic_db(noise),noise), "Menu has normal mic input")
 GameState.settings.keyboard_mode = keyboard_before
 main.queue_free()
 await get_tree().process_frame
 await get_tree().process_frame
 print("Flow bug fixes passed: both replay paths, Esc key/button and no More, vignette retention/following, temporary quiet noise attenuation, loud/keyboard input, and full recovery without changing calibration")
 get_tree().quit()
