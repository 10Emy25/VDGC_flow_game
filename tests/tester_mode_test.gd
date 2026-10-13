extends MinaTestSuite
# Checks the optional tester shortcuts. Passes trivially if scripts/dev/ has been deleted.

var main: Control

func _ready() -> void:
	if not ResourceLoader.exists("res://scripts/dev/tester_mode.gd"):
		check(true, "Tester mode removed; nothing to test")
		finish()
		return
	preserve_user_files()
	GameState.settings.keyboard_mode = true
	main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	await get_tree().process_frame
	press(KEY_3)
	await frames(3)
	var run: RunView = main.current_view
	check(run is RunView and run.state.section == "S3" and run.state.director.active and run.state.slammed, "Key 3 from the title screen starts S3 with the chase live")
	check(GameState.world_real > 0.99 and not Sfx.loops.has("mus_song"), "S3 jump uses the nightmare look and no song")
	press(KEY_6)
	await frames(2)
	check(run.model.x > 420.5, "Key 6 jumps to the next checkpoint")
	press(KEY_7)
	run.state.director.gap = -1
	await frames(3)
	check(run.state.status == "running", "Key 7 god mode: the wall cannot catch")
	press(KEY_7)
	press(KEY_5)
	await frames(3)
	check(run.state.section == "S5" and run.state.director.finale, "Key 5 reaches the finale")
	press(KEY_2)
	await frames(3)
	check(main.current_view.state.section == "S2" and main.current_view.state.director.active, "Key 2 starts the chase")
	press(KEY_1)
	await frames(2)
	check(main.current_view.state.section == "S1" and not main.current_view.state.slammed, "Key 1 restarts the flower path")
	main.queue_free()
	await get_tree().process_frame
	finish()

func press(code: int) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.keycode = code
	event.pressed = true
	Input.parse_input_event(event)
	Input.flush_buffered_events()
	var up := event.duplicate()
	up.pressed = false
	Input.parse_input_event(up)
	Input.flush_buffered_events()

func frames(n: int) -> void:
	for i in range(n):
		await get_tree().process_frame
