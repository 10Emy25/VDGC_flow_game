extends Node
func _ready() -> void:
	VoiceInput.process_mode = Node.PROCESS_MODE_DISABLED
	var day: AtlasTexture = load("res://art/scene_day.tres")
	assert(day.region == Rect2(120, 118, 1434, 1002))
	assert(day.get_width() == 1434)
	assert(day.filter_clip)
	var main: Control = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	main.show_run()
	var run: RunView = main.current_view
	run.set_process(false)
	var days := run.layers.filter(func(l): return l.sprite is SceneBackdrop)
	var nights := run.layers.filter(func(l): return not (l.sprite is SceneBackdrop))
	assert(days.size() == 3, "Three bright collage tiles")
	assert(nights.size() == 7 * 3, "Seven nightmare parallax layers, three tiles each")
	GameState.world_real = 1
	run.update_view(0)
	for layer in days:
		var bg: SceneBackdrop = layer.sprite
		assert(bg.day.visible, "Opening remains bright until actual monster reveal")
		assert(bg.day.stretch_mode == TextureRect.STRETCH_SCALE)
		assert(bg.day.size == Vector2(1920, 1080))
	for layer in nights: assert(not layer.sprite.visible, "Nightmare layers hidden during the song")
	run.state.face_slam()
	run.update_view(0)
	for layer in days: assert(not layer.sprite.day.visible)
	for layer in nights: assert(layer.sprite.visible, "Nightmare layers shown after the monster reveal")
	# Back-to-front order and parallax: the front ground moves with the floor, the sky barely moves.
	assert(nights[0].factor < nights[nights.size() - 1].factor and nights[nights.size() - 1].factor == 1.0)
	# Every screen column is covered by each layer's tiles at any scroll position.
	for x in [0.0, 37.5, 999.0, 2500.0]:
		run.model.x = x
		run.update_view(0)
		for i in range(0, nights.size(), 3):
			var left := INF
			var right := -INF
			for j in range(3):
				left = minf(left, nights[i + j].sprite.position.x)
				right = maxf(right, nights[i + j].sprite.position.x + nights[i + j].width)
			assert(left <= 0.0 and right >= 1920.0, "Layer tiles cover the screen")
	var background: Control = nights[0].sprite
	run.start_night_continuation()
	assert(background.is_visible_in_tree(), "Listening chase keeps the same horror backdrop")
	print("Scene backdrop passed: bright collage opening, layered nightmare parallax on monster reveal, full coverage and continuity")
	get_tree().quit()
