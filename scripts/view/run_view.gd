class_name RunView
extends Control

signal milestone_finished
var model: RunModel
var tutorial: TutorialModel
var song: SongModel
var level: LevelData
var layers: Array[Dictionary] = []
var world_props: Array[Dictionary] = []
var mina: DualSprite
var bridge: DualSprite
var bridge_gap: ColorRect
var bridge_event: Dictionary
var bridge_progress := 0.0
var bridge_ready := false
var bridge_waiting := false
var meter: VoiceMeter
var prompt: Label
var lyrics: HBoxContainer
var next_line: Label
var syllable_labels: Dictionary = {}
var sung: Dictionary = {}
var song_cycle := -1
var displayed_line := -1
var input_hint: Label
var finished := false
var hud_layer: CanvasLayer

func _ready() -> void:
	theme = GameState.ui_theme
	GameState.world_real = 0.0
	PostFX.stress = 0.0
	model = RunModel.new(GameState.balance)
	tutorial = TutorialModel.new(GameState.balance.tutorial)
	song = SongModel.new(GameState.song)
	level = LevelData.new(GameState.level)
	model.x = level.first("section").x
	bridge_event = level.first("bridge")
	Sfx.stop_all()
	Sfx.loop("mus_song", true, GameState.balance.audio.song_db)
	Sfx.loop("mus_pad", true, GameState.balance.audio.pad_db)
	BeatClock.reset("mus_song")
	for layer_index in range(3):
		var key: String = GameState.balance.parallax.keys[layer_index]
		var factor: float = GameState.balance.parallax.factors[layer_index]
		for index in range(3):
			var sprite := dual(key, Rect2(0, 0, 1920, 1080))
			layers.append({"sprite": sprite, "factor": factor, "tile": index - 1, "width": 1920.0})
	for index in range(6):
		var sprite := dual("run_ground", Rect2(0, GameState.balance.layout.feet_y, 512, 220))
		layers.append({"sprite": sprite, "factor": 1.0, "tile": index - 1, "width": 512.0})
	var rng := RandomNumberGenerator.new()
	rng.seed = GameState.balance.s1.decor_seed
	var spacing: float = GameState.balance.s1.decor_spacing_m
	var distance: float = level.first("section").x
	while distance < level.first("r1_end").x:
		if distance < bridge_event.x or distance > bridge_event.x + bridge_event.length_m:
			var prop := dual("flower_open", Rect2(0, GameState.balance.layout.feet_y - 160, 110, 160))
			prop.modulate = Color.from_hsv(rng.randf_range(0.0, 1.0), 0.12, 1.0)
			world_props.append({"sprite": prop, "x": distance + rng.randf_range(-0.5, 0.5), "offset_y": rng.randf_range(-10, 10), "life": INF})
		distance += spacing
	bridge_gap = ColorRect.new()
	bridge_gap.color = Color(GameState.balance.palette.quiet)
	bridge_gap.size = Vector2(bridge_event.length_m * GameState.balance.px_per_m, 220)
	bridge_gap.position.y = GameState.balance.layout.feet_y
	bridge_gap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bridge_gap)
	bridge = dual("flower_bridge", Rect2(0, 1080, bridge_event.length_m * GameState.balance.px_per_m, 240))
	mina = dual("mina_idle", Rect2(GameState.balance.player_screen_x - GameState.balance.layout.mina_rect[0] * 0.5, GameState.balance.layout.feet_y - GameState.balance.layout.mina_rect[1], GameState.balance.layout.mina_rect[0], GameState.balance.layout.mina_rect[1]))
	hud_layer = CanvasLayer.new()
	hud_layer.layer = 8
	add_child(hud_layer)
	UIFactory.texture(hud_layer, "ui_lyrics_bar", UIFactory.rect(GameState.balance.layout.lyrics_rect))
	lyrics = HBoxContainer.new()
	lyrics.theme = GameState.ui_theme
	lyrics.position = Vector2(310, 53)
	lyrics.size = Vector2(1300, 66)
	lyrics.alignment = BoxContainer.ALIGNMENT_CENTER
	lyrics.add_theme_constant_override("separation", 0)
	lyrics.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud_layer.add_child(lyrics)
	next_line = UIFactory.label(hud_layer, "empty_lyrics", Rect2(310, 116, 1300, 48), GameState.balance.ui.next_lyrics_size)
	prompt = UIFactory.prompt(hud_layer, "hum_walk", UIFactory.rect(GameState.balance.layout.prompt_rect))
	meter = VoiceMeter.new()
	var meter_rect := UIFactory.rect(GameState.balance.layout.meter_rect)
	meter.position = meter_rect.position
	meter.size = meter_rect.size
	hud_layer.add_child(meter)
	var caption := UIFactory.label(hud_layer, "path_caption", Rect2(55, 40, 185, 115), GameState.balance.ui.small_size)
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	input_hint = UIFactory.label(hud_layer, "keyboard_hint" if GameState.settings.keyboard_mode else "mic_hint", Rect2(590, 1008, 1260, 46), GameState.balance.ui.small_size)
	GameState.settings_changed.connect(refresh_hint)

func refresh_hint() -> void:
	input_hint.text = GameState.text("keyboard_hint" if GameState.settings.keyboard_mode else "mic_hint")

func dual(key: String, rect_value: Rect2) -> DualSprite:
	var sprite := DualSprite.new()
	sprite.base_key = key
	sprite.position = rect_value.position
	sprite.size = rect_value.size
	add_child(sprite)
	return sprite

func _process(delta: float) -> void:
	if finished:
		return
	var tier_index: int = ["QUIET", "HUM", "TALK", "SHOUT"].find(VoiceInput.tier)
	tutorial.step(delta, tier_index)
	model.step(delta, VoiceInput.speed_target, VoiceInput.is_shouting)
	bridge_waiting = not bridge_ready and model.x >= bridge_event.x
	if bridge_waiting:
		model.x = bridge_event.x
		model.speed = 0.0
		model.acceleration_rate = 0.0
		if tier_index >= 2:
			bridge_progress += delta / (GameState.balance.bar_s * GameState.balance.s1.bridge_bars)
			if bridge_progress >= 1.0:
				bridge_progress = 1.0
				bridge_ready = true
				Sfx.play("sfx_bridge", GameState.balance.audio.bridge_db)
	prompt.text = GameState.text("bridge_hint") if bridge_waiting else ("" if tutorial.complete() else GameState.text(tutorial.stages[tutorial.index].key))
	prompt.visible = not prompt.text.is_empty()
	meter.pulse_tier = 2 if bridge_waiting else (0 if tutorial.complete() else tutorial.stages[tutorial.index].tier)
	for layer in layers:
		layer.sprite.position.x = layer.tile * layer.width - fposmod(model.x * GameState.balance.px_per_m * layer.factor, layer.width)
	var camera_x: float = model.x * GameState.balance.px_per_m - GameState.balance.player_screen_x
	for prop in world_props:
		prop.sprite.position.x = prop.x * GameState.balance.px_per_m - camera_x - prop.sprite.size.x * 0.5
		prop.sprite.visible = prop.sprite.position.x > -prop.sprite.size.x and prop.sprite.position.x < GameState.balance.layout.screen[0]
		prop.life -= delta
		if prop.life <= 0.0:
			prop.sprite.queue_free()
	world_props = world_props.filter(func(prop: Dictionary) -> bool: return prop.life > 0.0)
	bridge_gap.position.x = bridge_event.x * GameState.balance.px_per_m - camera_x
	bridge.position.x = bridge_gap.position.x
	bridge.position.y = lerpf(1080.0, GameState.balance.layout.feet_y - 100.0, bridge_progress)
	var key := "mina_idle"
	if model.speed > GameState.balance.s1.idle_speed_epsilon:
		key = "mina_walk" if model.speed < GameState.balance.s1.walk_max else ("mina_jog" if model.speed < GameState.balance.s1.jog_max else "mina_run")
	if mina.base_key != key:
		mina.base_key = key
	mina.animation_fps = GameState.balance.s1.animation_base_fps + model.speed * GameState.balance.s1.animation_speed_fps
	update_song()
	if model.x >= level.first("r1_end").x:
		model.x = level.first("r1_end").x
		finished = true
		milestone_finished.emit()

func update_song() -> void:
	var cycle := int(BeatClock.elapsed / song.duration)
	if cycle != song_cycle:
		song_cycle = cycle
		sung.clear()
	var current := song.current(BeatClock.elapsed)
	var line_index: int = song.syllables[current].line
	if line_index != displayed_line:
		displayed_line = line_index
		for child in lyrics.get_children():
			lyrics.remove_child(child)
			child.queue_free()
		syllable_labels.clear()
		for index in range(song.syllables.size()):
			if song.syllables[index].line == line_index:
				var label := Label.new()
				label.text = song.syllables[index].text
				label.add_theme_font_size_override("font_size", GameState.balance.ui.lyrics_size)
				var syllable_slot := MarginContainer.new()
				syllable_slot.add_theme_constant_override("margin_right", 12 if song.syllables[index].word_end else 0)
				lyrics.add_child(syllable_slot)
				syllable_slot.add_child(label)
				syllable_labels[index] = label
		next_line.text = song.lines[(line_index + 1) % song.lines.size()]
	if VoiceInput.is_audible and not sung.has(current):
		sung[current] = true
		var flower := dual("flower_bud", Rect2(0, GameState.balance.layout.feet_y - 140, 110, 140))
		world_props.append({"sprite": flower, "x": model.x, "life": GameState.balance.s1.bloom_life_s})
		flower.pivot_offset = Vector2(flower.size.x * 0.5, flower.size.y)
		flower.scale = Vector2.ONE * 0.15
		var bloom := create_tween()
		bloom.tween_property(flower, "scale", Vector2.ONE, GameState.song.unit_s)
		bloom.tween_callback(func() -> void:
			if is_instance_valid(flower):
				flower.base_key = "flower_open")
		Sfx.play("sfx_bloom", GameState.balance.audio.bloom_db)
		move_child(mina, get_child_count() - 1)
	for index in syllable_labels:
		var color := Color(GameState.balance.palette.gold if sung.has(index) else GameState.balance.palette.ink)
		syllable_labels[index].add_theme_color_override("font_color", color)
		syllable_labels[index].modulate.a = 1.0 if current == index or sung.has(index) else 0.5
