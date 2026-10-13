class_name RunView
extends Control

signal run_finished
var state: LevelModel
var model: RunModel
var tutorial: TutorialModel
var song: SongModel
var level: LevelData
var layers: Array[Dictionary] = []
var world_props: Array[Dictionary] = []
var objects: Array[Dictionary] = []
var mina: DualSprite
var bridge: DualSprite
var bridge_gap: ColorRect
var bridge_event: Dictionary
var bridge_progress: float:
	get: return state.bridge_progress
	set(value): state.bridge_progress = value
var bridge_ready: bool:
	get: return state.bridge_ready
	set(value): state.bridge_ready = value
var bridge_waiting: bool:
	get: return state.bridge_waiting
var meter: VoiceMeter
var prompt: Label
var lyrics: HBoxContainer
var lyrics_back: TextureRect
var next_line: Label
var syllable_labels: Dictionary = {}
var sung: Dictionary = {}
var song_cycle := -1
var displayed_line := -1
var input_hint: Label
var caption: Label
var progress_label: Label
var subtitle: Label
var subtitle_back: TextureRect
var subtitle_left := 0.0
var hud_layer: CanvasLayer
var finished := false
var wall: DualSprite
var peek: DualSprite
var eye: TextureRect
var crack: TextureRect
var beam: TextureRect
var hand: TextureRect
var shade: ColorRect
var edge_shade: ColorRect
var beat_ring: TextureRect
var ring_left := 0.0
var shake_left := 0.0
var clear_left := 0.0
var overlay: ColorRect
var parallax_x := 0.0
var last_view_x := 0.0

func _ready() -> void:
	theme = GameState.ui_theme
	GameState.world_real = 0.0
	PostFX.stress = 0.0
	state = LevelModel.new(GameState.balance, GameState.level)
	model = state.run
	level = state.level
	tutorial = TutorialModel.new(GameState.balance.tutorial)
	song = SongModel.new(GameState.song)
	bridge_event = level.first("bridge")
	for error in level.validation_errors(GameState.balance):
		push_warning(error)
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
	make_decoration()
	bridge_gap = ColorRect.new()
	bridge_gap.color = Color(GameState.balance.palette.quiet)
	bridge_gap.size = Vector2(bridge_event.length_m * GameState.balance.px_per_m, 220)
	bridge_gap.position.y = GameState.balance.layout.feet_y
	bridge_gap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bridge_gap)
	bridge = dual("flower_bridge", Rect2(0, 1080, bridge_event.length_m * GameState.balance.px_per_m, 240))
	for event in level.events:
		var kind: String = event.type
		if kind not in ["cover", "checkpoint", "gate", "door"]:
			continue
		var slots: Dictionary = GameState.balance.level_view.object_slots
		var slot_key := "door" if kind == "door" else kind
		var dims: Array = slots[slot_key]
		var key: String = event.get("art", {"checkpoint":"safe_puddle", "gate":"gap_crack", "door":"light_door"}.get(kind, ""))
		var sprite: Control
		if kind in ["door", "checkpoint"]:
			sprite = UIFactory.texture(self, key, Rect2(0, GameState.balance.layout.feet_y - dims[1] * (0.5 if kind == "checkpoint" else 1.0), dims[0], dims[1]))
		else:
			sprite = dual(key, Rect2(0, GameState.balance.layout.feet_y - (0 if kind == "gate" else dims[1]), dims[0], dims[1]))
		sprite.z_index = 3 if kind == "cover" else 1
		objects.append({"sprite": sprite, "x": event.x, "kind": kind})
	wall = dual("m1_wall", Rect2(0, GameState.balance.layout.feet_y - 1080, 900, 1080), true)
	wall.animation_fps = GameState.balance.level_view.m1_fps
	wall.z_index = 2
	peek = dual("m1_face_peek", Rect2(-500, 270, 500, 500), true)
	peek.z_index = 2
	edge_shade = make_shade(Rect2(0, 0, GameState.balance.level_view.peek_max_px, 1080), Color.BLACK)
	shade = make_shade(Rect2(0, 0, 1920, 1080 * GameState.balance.m2.shadow_fraction), Color.BLACK)
	crack = UIFactory.texture(self, "m2_sky_crack", UIFactory.rect(GameState.balance.level_view.crack_rect))
	eye = UIFactory.texture(self, "m2_eye_open", UIFactory.rect(GameState.balance.level_view.eye_rect))
	var beam_size: Array = GameState.balance.level_view.beam_rect
	beam = UIFactory.texture(self, "m2_beam", Rect2(0, GameState.balance.layout.feet_y - beam_size[1], beam_size[0], beam_size[1]))
	var additive := CanvasItemMaterial.new()
	additive.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	beam.material = additive
	var hand_size: Array = GameState.balance.level_view.hand_rect
	hand = UIFactory.texture(self, "m2_hand", Rect2(0, -40, hand_size[0], hand_size[1]))
	mina = dual("mina_idle", Rect2(GameState.balance.player_screen_x - GameState.balance.layout.mina_rect[0] * 0.5, GameState.balance.layout.feet_y - GameState.balance.layout.mina_rect[1], GameState.balance.layout.mina_rect[0], GameState.balance.layout.mina_rect[1]))
	beat_ring = UIFactory.texture(self, "ui_beat_ring", Rect2(GameState.balance.player_screen_x - 250, GameState.balance.layout.feet_y - 430, 500, 500))
	beat_ring.pivot_offset = beat_ring.size * 0.5
	hud_layer = CanvasLayer.new()
	hud_layer.layer = 8
	add_child(hud_layer)
	lyrics_back = UIFactory.texture(hud_layer, "ui_lyrics_bar", UIFactory.rect(GameState.balance.layout.lyrics_rect))
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
	caption = UIFactory.label(hud_layer, "path_caption", Rect2(55, 40, 185, 115), GameState.balance.ui.small_size)
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	input_hint = UIFactory.label(hud_layer, "keyboard_hint" if GameState.settings.keyboard_mode else "mic_hint", Rect2(590, 1008, 1260, 46), GameState.balance.ui.small_size)
	progress_label = UIFactory.label(hud_layer, "empty_lyrics", UIFactory.rect(GameState.balance.level_view.progress_rect), GameState.balance.ui.small_size)
	var subtitle_rect := UIFactory.rect(GameState.balance.level_view.subtitle_rect)
	subtitle_back = UIFactory.texture(hud_layer, "ui_subtitle", subtitle_rect)
	subtitle = UIFactory.subtitle(hud_layer, "empty_lyrics", subtitle_rect)
	# UIFactory.subtitle supplies a backing; share that one rather than drawing twice.
	subtitle_back.queue_free()
	subtitle_back = hud_layer.get_child(hud_layer.get_child_count() - 2)
	var transition_layer := CanvasLayer.new()
	transition_layer.layer = 9
	add_child(transition_layer)
	overlay = make_shade(Rect2(0, 0, 1920, 1080), Color.BLACK, transition_layer)
	GameState.settings_changed.connect(refresh_hint)
	update_view(0.0)

func make_decoration() -> void:
	var sections := level.of_type("section")
	for index in range(sections.size()):
		var event: Dictionary = sections[index]
		var end_x: float = sections[index + 1].x if index + 1 < sections.size() else level.first("door").x
		var rng := RandomNumberGenerator.new()
		rng.seed = GameState.balance.level_view.decor_seeds[event.id]
		var distance: float = event.x
		var spacing: float = GameState.balance.s1.decor_spacing_m if event.id == "S1" else GameState.balance.level_view.decor_spacing_m
		while distance < end_x:
			if event.id != "S1" or distance < bridge_event.x or distance > bridge_event.x + bridge_event.length_m:
				var key := "flower_open" if event.id in ["S1", "S5"] or rng.randf() > 0.5 else "prop_school_item"
				if event.id in ["S2", "S3", "S4"] and rng.randf() < 0.15:
					key = "cover_desk"
				var prop := dual(key, Rect2(0, GameState.balance.layout.feet_y - 160, 110, 160))
				if event.id == "S1":
					prop.modulate = Color.from_hsv(rng.randf_range(0.0, 1.0), 0.12, 1.0)
				world_props.append({"sprite": prop, "x": distance + rng.randf_range(-0.5, 0.5), "life": INF})
			distance += spacing

func refresh_hint() -> void:
	input_hint.text = GameState.text("keyboard_hint" if GameState.settings.keyboard_mode else "mic_hint")

func dual(key: String, rect_value: Rect2, real_only: bool = false) -> DualSprite:
	var sprite := DualSprite.new()
	sprite.real_only = real_only
	sprite.base_key = key
	sprite.position = rect_value.position
	sprite.size = rect_value.size
	add_child(sprite)
	return sprite

func make_shade(rect_value: Rect2, color: Color, parent: Node = null) -> ColorRect:
	var node := ColorRect.new()
	node.position = rect_value.position
	node.size = rect_value.size
	node.color = color
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	(parent if parent != null else self).add_child(node)
	return node

func _process(delta: float) -> void:
	if finished:
		return
	var tier_index: int = ["QUIET", "HUM", "TALK", "SHOUT"].find(VoiceInput.tier)
	if state.section == "S1":
		tutorial.step(delta, tier_index)
	state.step(delta, VoiceInput.speed_target, VoiceInput.is_shouting, VoiceInput.is_audible, tier_index, BeatClock.elapsed)
	for message in state.messages:
		handle_message(message)
	if state.section == "S1":
		update_song()
	update_view(delta)

func handle_message(message: Dictionary) -> void:
	var audio: Dictionary = GameState.balance.audio
	match message.type:
		"section", "respawn":
			if state.section != "S1":
				Sfx.loop("mus_song", false)
				BeatClock.adopt_master("mus_pad")
			else:
				Sfx.loop("mus_song", true, audio.song_db)
		"subtitle":
			subtitle.text = GameState.text(message.key)
			subtitle_left = GameState.balance.level_view.subtitle_s
		"bridge": Sfx.play("sfx_bridge", audio.bridge_db)
		"jumping": Sfx.play("sfx_jump", audio.gate_db)
		"stumbling": Sfx.play("sfx_stumble", audio.gate_db)
		"safe":
			if state.section != "S1":
				Sfx.play("sfx_safe", audio.safe_db)
				Sfx.set_loop_volume("mus_pad", GameState.balance.level_view.safe_music_db, GameState.balance.level_view.fade_s)
		"roar":
			Sfx.play("sfx_m1_roar", audio.threat_db)
			Sfx.set_loop_volume("mus_pad", audio.pad_db, GameState.balance.level_view.fade_s)
		"warning": Sfx.play("sfx_m2_crack", audio.warning_db)
		"slam":
			Sfx.play_at("sfx_m2_slam", audio.warning_db + (audio.reduce_scare_db if GameState.settings.reduce_scares else 0.0), 1.0, -0.5)
			shake_left = GameState.balance.m2.slam_s
		"recede":
			Sfx.play("sfx_all_clear", audio.warning_db)
			clear_left = GameState.balance.bar_s
		"all_clear": clear_left = GameState.balance.bar_s
		"capture": Sfx.play("sfx_m2_grab" if state.director.capture_cause == "hearing" else "sfx_capture", audio.capture_db)
		"beat_call":
			Sfx.play("sfx_beat_call", audio.beat_db)
			ring_left = GameState.balance.finale.ring_s
		"surge": GameState.world_real = maxf(0.0, GameState.world_real - GameState.balance.finale.world_return)
		"flash":
			Sfx.play("sfx_door", audio.door_db)
			Sfx.stop_all()
		"ending":
			finished = true
			run_finished.emit()

func update_view(delta: float) -> void:
	var b: Dictionary = GameState.balance
	var d := state.director
	var in_song := state.section == "S1"
	lyrics_back.visible = in_song
	lyrics.visible = in_song
	next_line.visible = in_song
	caption.text = GameState.text("path_caption" if in_song else "path_" + state.section)
	caption.add_theme_color_override("font_color", Color(b.palette.ink if in_song else b.palette.warm))
	caption.add_theme_color_override("font_outline_color", Color(b.palette.ink))
	caption.add_theme_constant_override("outline_size", 0 if in_song else b.ui.outline_px)
	progress_label.text = GameState.text("run_progress") % [state.section, int(model.x), int(level.first("door").x)]
	subtitle_left = maxf(0.0, subtitle_left - delta)
	subtitle.visible = subtitle_left > 0.0
	subtitle_back.visible = subtitle.visible
	var prompt_key := ""
	if state.status != "running":
		prompt_key = "capture_hint"
	elif in_song:
		prompt_key = "bridge_hint" if bridge_waiting else ("" if tutorial.complete() else tutorial.stages[tutorial.index].key)
	elif state.section == "S5": prompt_key = "finale_hint"
	elif d.slam_left > 0.0: prompt_key = "slam_hint"
	elif clear_left > 0.0 and d.phase in ["RECEDE", "IDLE"]: prompt_key = "clear_hint"
	elif state.hidden: prompt_key = "hidden_hint"
	elif d.phase == "GAZE": prompt_key = "gaze_hint"
	elif d.phase == "WARNING": prompt_key = "warning_hint"
	elif d.phase == "TELL": prompt_key = "tell_hint"
	elif not state.safe_id.is_empty(): prompt_key = "safe_hint"
	elif clear_left > 0.0: prompt_key = "clear_hint"
	prompt.text = "" if prompt_key.is_empty() else GameState.text(prompt_key)
	prompt.visible = not prompt.text.is_empty()
	meter.pulse_tier = 2 if bridge_waiting else (0 if tutorial.complete() or not in_song else tutorial.stages[tutorial.index].tier)
	clear_left = maxf(0.0, clear_left - delta)
	if state.messages.any(func(m: Dictionary) -> bool: return m.type == "respawn"):
		parallax_x = model.x
	else:
		parallax_x += (model.x - last_view_x) * (b.finale.parallax_mult if state.section == "S5" and state.finale_hits > 0 else 1.0)
	last_view_x = model.x
	for layer in layers:
		var camera_distance: float = model.x if layer.factor == 1.0 else parallax_x
		layer.sprite.position.x = layer.tile * layer.width - fposmod(camera_distance * b.px_per_m * layer.factor, layer.width)
	var camera_x: float = model.x * b.px_per_m - b.player_screen_x
	for prop in world_props:
		prop.sprite.position.x = prop.x * b.px_per_m - camera_x - prop.sprite.size.x * 0.5
		prop.sprite.visible = prop.sprite.position.x > -prop.sprite.size.x and prop.sprite.position.x < b.layout.screen[0]
		prop.life -= delta
		if prop.life <= 0.0:
			prop.sprite.queue_free()
	world_props = world_props.filter(func(prop: Dictionary) -> bool: return prop.life > 0.0)
	for object in objects:
		object.sprite.position.x = object.x * b.px_per_m - camera_x - (0.0 if object.kind == "gate" else object.sprite.size.x * 0.5)
		object.sprite.visible = object.sprite.position.x > -object.sprite.size.x and object.sprite.position.x < b.layout.screen[0]
	bridge_gap.position.x = bridge_event.x * b.px_per_m - camera_x
	bridge.position.x = bridge_gap.position.x
	bridge.position.y = lerpf(1080.0, b.layout.feet_y - 100.0, bridge_progress)
	var key := "mina_idle"
	if state.status in ["captured", "fading"]: key = "mina_caught"
	elif state.hidden: key = "mina_crouch"
	elif model.speed > b.s1.idle_speed_epsilon:
		key = "mina_walk" if model.speed < b.s1.walk_max else ("mina_jog" if model.speed < b.s1.jog_max else "mina_run")
	if mina.base_key != key:
		mina.base_key = key
	mina.z_index = 0 if state.hidden else 4
	mina.position.y = b.layout.feet_y - b.layout.mina_rect[1] - (sin(PI * model.jump_progress) * b.speed_gate.jump_height_px if model.gate_state == "jumping" else 0.0)
	mina.animation_fps = b.s1.animation_base_fps + model.speed * b.s1.animation_speed_fps
	wall.visible = d.active and state.status != "complete"
	wall.position.x = b.player_screen_x - d.gap * b.px_per_m - wall.size.x
	var presence: float = clampf((b.level_view.peek_end_gap - d.gap) / (b.level_view.peek_end_gap - b.level_view.peek_begin_gap), 0.0, 1.0)
	peek.visible = d.active and d.gap >= b.level_view.peek_begin_gap and d.gap <= b.level_view.peek_end_gap
	peek.position.x = -peek.size.x + presence * b.level_view.peek_max_px
	edge_shade.color.a = presence * 0.4 if d.active else 0.0
	crack.visible = d.phase in ["WARNING", "GAZE", "RECEDE"]
	shade.visible = crack.visible
	shade.color.a = 0.4
	eye.visible = d.phase in ["GAZE", "RECEDE"]
	if state.section == "S5":
		var eye_age: float = state.time - state.finale_start
		eye.visible = eye_age < b.finale.eye_close_s
		eye.modulate.a = 1.0 - clampf(eye_age / b.finale.eye_close_s, 0.0, 1.0)
		eye.texture = ArtRegistry.get_texture("m2_eye_closed" if eye_age > b.finale.eye_close_s * 0.5 else "m2_eye_open")
		eye.pivot_offset = eye.size * 0.5
		eye.scale.y = lerpf(1.0, 0.08, clampf(eye_age / b.finale.eye_close_s, 0.0, 1.0))
	else:
		eye.modulate.a = 1.0
		eye.scale.y = 1.0
		eye.texture = ArtRegistry.get_texture("m2_eye_closed" if d.phase == "RECEDE" else "m2_eye_open")
	beam.visible = d.phase == "GAZE"
	beam.position.x = b.player_screen_x + d.beam_offset * b.px_per_m - beam.size.x * 0.5
	hand.visible = d.slam_left > 0.0
	hand.position.x = b.player_screen_x - b.m2.slam_offset_m * b.px_per_m - hand.size.x * 0.5
	hand.position.y = lerpf(-hand.size.y, b.layout.feet_y - hand.size.y, clampf((b.m2.slam_s - d.slam_left) / (b.m2.slam_s * 0.2), 0.0, 1.0))
	shake_left = maxf(0.0, shake_left - delta)
	position = Vector2.ZERO
	if shake_left > 0.0 and not GameState.settings.reduce_scares:
		position = Vector2(sin(state.time * 61.0), cos(state.time * 49.0)) * b.m2.slam_shake_px * shake_left / b.m2.slam_s
	if d.active and state.status not in ["flash", "complete"]:
		var near_volume: float = clampf((b.audio.m1_far_m - d.gap) / (b.audio.m1_far_m - b.audio.m1_near_m), 0.0, 1.0)
		var db: float = lerpf(b.audio.m1_far_db, b.audio.m1_near_db, near_volume)
		Sfx.loop("amb_m1_breath", true, db)
		Sfx.loop("amb_m1_sand", true, db)
	else:
		Sfx.loop("amb_m1_breath", false)
		Sfx.loop("amb_m1_sand", false)
	Sfx.loop("amb_m2_light", d.phase == "GAZE", b.audio.warning_db)
	ring_left = maxf(0.0, ring_left - delta)
	beat_ring.visible = ring_left > 0.0
	beat_ring.modulate.a = ring_left / b.finale.ring_s
	beat_ring.scale = Vector2.ONE * lerpf(1.3, 0.8, ring_left / b.finale.ring_s)
	overlay.visible = state.status in ["fading", "flash"]
	overlay.color = Color.WHITE if state.status == "flash" else Color(0, 0, 0, clampf(state.status_age / b.respawn.fade_s, 0.0, 1.0))
	PostFX.stress = 0.0 if in_song or not state.safe_id.is_empty() else (b.level_view.gaze_stress if d.phase == "GAZE" else clampf(1.0 - d.gap / b.level_view.chase_stress_gap, 0.0, 1.0))

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
