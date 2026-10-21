extends Node
func _ready() -> void:
	VoiceInput.process_mode = Node.PROCESS_MODE_DISABLED
	var day: AtlasTexture = load("res://art/scene_day.tres")
	var night: AtlasTexture = load("res://art/scene_night.tres")
	assert(day.region == Rect2(120, 118, 1434, 1002))
	assert(night.region == Rect2(116, 1276, 1433, 1001))
	assert(day.atlas == night.atlas)
	assert(day.get_width() == 1434 and night.get_width() == 1433)
	assert(day.filter_clip and night.filter_clip)
	assert(day.region.end.y < night.region.position.y)
	var main: Control = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	main.show_run()
	var run: RunView = main.current_view
	run.set_process(false)
	assert(run.layers.size() == 3, "No old mid/near forest or ground layers covering the new artwork")
	GameState.world_real = 1
	run.update_view(0)
	for layer in run.layers:
		var bg: SceneBackdrop = layer.sprite
		assert(bg.day.visible and not bg.night.visible, "Opening remains bright until actual monster reveal")
		assert(bg.day.stretch_mode == TextureRect.STRETCH_SCALE)
		assert(bg.day.size == Vector2(1920, 1080))
	run.state.face_slam()
	run.update_view(0)
	for layer in run.layers: assert(layer.sprite.night.visible and not layer.sprite.day.visible)
	var background: Control = run.layers[0].sprite
	run.start_night_continuation()
	assert(background.is_visible_in_tree(), "Listening chase keeps the same horror backdrop")
	assert(background.night.visible)
	print("Scene backdrop passed: exact upper/lower atlas crops, no white frame, full-frame image, bright opening, horror on monster reveal and continuity")
	get_tree().quit()
