extends Node
# Records the opening (title → bedroom → falling asleep → flower path) with Godot's Movie Maker, sound included.
# Keyboard mode, so no microphone is needed; after the song starts it hums for a few seconds so Mina walks.
#
#   godot --path . --write-movie /tmp/opening.avi --fixed-fps 30 --scene res://tests/intro_movie.tscn
#
# Optional: SKIP_TO_SLEEP=1 starts at the last bedroom step (eyes closing).

var main: Control

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	GameState.settings.keyboard_mode = true
	main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	# Hide the tester-mode overlay so the recording looks like the game.
	for child in main.get_children():
		if child.has_method("current_run"):
			child.label.visible = false
	await get_tree().create_timer(1.5).timeout
	main.show_calibration()
	await get_tree().create_timer(1.0).timeout
	main.current_view.flow.use_defaults()
	if OS.get_environment("SKIP_TO_SLEEP") == "1":
		var intro: BedroomIntro = main.current_view
		intro.index = intro.steps.size() - 2
		intro.next_step()
	while not main.current_view is RunView:
		await get_tree().process_frame
	var run: RunView = main.current_view
	while run.dream_left > 0.0:
		await get_tree().process_frame
	await get_tree().create_timer(1.5).timeout
	press(KEY_SHIFT, true)
	await get_tree().create_timer(5.0).timeout
	press(KEY_SHIFT, false)
	await get_tree().create_timer(1.5).timeout
	get_tree().quit()

func press(code: int, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.pressed = pressed
	Input.parse_input_event(event)
