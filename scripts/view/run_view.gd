class_name RunView
extends Control

signal run_finished
signal flower_triggered
var flower_night_started: bool = false
var locker_pass: LockerPass
var night_continuation: NightContinuation
var final_confrontation: LastScream
var final_layer: CanvasLayer
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
# Face slam, darkness, lunges, obstacles.
var slam_face: TextureRect
var slam_text: Label
var slam_age := INF
const REVEAL_FACE_S := 1.0
var bloom_cursor := 0
var bloom_pending := false
var bloom_last_time := -1.0
var reveal_age := -1.0
var reveal_camera_px := 0.0
var reveal_clock_hold := 0.0
var beam_cone: Polygon2D
var darkness: ColorRect
var lunge_left := 0.0
var hint_left := 0.0
var hint_key := ""
var walls: Dictionary = {}
var drums_pending := false
var last_song_line := -1
var flash_left := 0.0
# Arriving from the bedroom: seconds of music-box intro left before the song starts.
var dream_left := 0.0
var dream_length := 0.0
var dream_veil: ColorRect
var dream_stars: DreamStars

func _ready() -> void:
	theme = GameState.ui_theme
	GameState.world_real = 0.0
	PostFX.stress = 0.0
	state = LevelModel.new(GameState.balance, GameState.level, GameState.song)
	model = state.run
	level = state.level
	tutorial = TutorialModel.new(GameState.balance.tutorial)
	song = SongModel.new(GameState.song)
	# The supplied opening recording plays to its real end before the chase starts.
	var opening_track: AudioStream = Sfx.get_stream("mus_song")
	if opening_track != null:
		state.song_end = opening_track.get_length()
	bridge_event = level.first("bridge")
	for error in level.validation_errors(GameState.balance):
		push_warning(error)
	if dream_left > 0.0:
		# The bedroom already stopped its sounds; the music-box intro keeps playing into the song.
		dream_length = (GameState.balance.intro.music_bars - GameState.balance.intro.handover_bars) * GameState.balance.bar_s
	else:
		Sfx.stop_all()
		start_song()
	# One complete collage panel per tile; do not overlay the old forest/ground artwork.
	for index in range(3):
		var backdrop := SceneBackdrop.new()
		backdrop.size = Vector2(1920, 1080)
		backdrop.mirrored = index % 2 == 0
		add_child(backdrop)
		layers.append({"sprite": backdrop, "factor": 0.2, "tile": index - 1, "width": 1920.0})
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
		if kind == "face_wall":
			var wall_dims: Array = GameState.balance.level_view.object_slots.face_wall
			var face_wall := dual("face_wall", Rect2(0, GameState.balance.layout.feet_y - wall_dims[1], wall_dims[0], wall_dims[1]), true)
			face_wall.z_index = 3
			face_wall.pivot_offset = Vector2(wall_dims[0] * 0.5, wall_dims[1])
			objects.append({"sprite": face_wall, "event": event, "kind": kind})
			walls[event.x] = face_wall
			continue
		if kind == "plank":
			var plank_dims: Array = GameState.balance.level_view.object_slots.plank
			var plank := dual("plank", Rect2(0, GameState.balance.layout.feet_y - 20, event.length_m * GameState.balance.px_per_m + plank_dims[0], plank_dims[1]))
			plank.z_index = 1
			objects.append({"sprite": plank, "event": event, "kind": kind})
			continue
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
		objects.append({"sprite": sprite, "event": event, "kind": kind})
	wall = dual("m1_wall", Rect2(0, GameState.balance.level_view.monster_feet_y - GameState.balance.level_view.monster_rect[1], GameState.balance.level_view.monster_rect[0], GameState.balance.level_view.monster_rect[1]), true)
	wall.animation_fps = GameState.balance.level_view.m1_fps
	wall.z_index = 2
	peek = dual("m1_face_peek", Rect2(-500, 270, 500, 500), true)
	peek.z_index = 2
	edge_shade = make_shade(Rect2(0, 0, GameState.balance.level_view.peek_max_px, 1080), Color.BLACK)
	shade = make_shade(Rect2(0, 0, 1920, 1080 * GameState.balance.m2.shadow_fraction), Color.BLACK)
	crack = UIFactory.texture(self, "m2_sky_crack", UIFactory.rect(GameState.balance.level_view.crack_rect))
	eye = UIFactory.texture(self, "m2_eye_open", UIFactory.rect(GameState.balance.level_view.eye_rect))
	eye.texture = EyeAnimation.at_openness(0.0)
	EyeAnimation.blink_frames()
	EyeAnimation.scan_frames()
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
	darkness = ColorRect.new()
	darkness.size = Vector2(1920, 1080)
	darkness.mouse_filter = Control.MOUSE_FILTER_IGNORE
	darkness.z_index = 10
	var dark_material := ShaderMaterial.new()
	dark_material.shader = load("res://shaders/darkness.gdshader")
	darkness.material = dark_material
	add_child(darkness)
	slam_face = UIFactory.texture(transition_layer, "m1_face_closeup", Rect2(0, 0, 1920, 1080))
	slam_face.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	slam_face.pivot_offset = Vector2(960, 540)
	slam_face.visible = false
	slam_text = UIFactory.label(transition_layer, "scream_slam", Rect2(0, 380, 1920, 320), int(GameState.balance.slam.text_size), Color("#d81e1e"))
	slam_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	slam_text.add_theme_color_override("font_outline_color", Color.BLACK)
	slam_text.add_theme_constant_override("outline_size", 18)
	slam_text.visible = false
	BeatClock.bar_started.connect(_on_bar)
	GameState.settings_changed.connect(refresh_hint)
	if dream_left > 0.0:
		dream_veil = ColorRect.new()
		dream_veil.size = Vector2(1920, 1080)
		dream_veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var veil_material := ShaderMaterial.new()
		veil_material.shader = load("res://shaders/dream_veil.gdshader")
		dream_veil.material = veil_material
		transition_layer.add_child(dream_veil)
		dream_stars = DreamStars.new()
		transition_layer.add_child(dream_stars)
		update_dream()
	update_view(0.0)

	locker_pass = LockerPass.new()
	locker_pass.run = self
	add_child(locker_pass)
	VoiceInput.set_gameplay_context(self)

func start_song() -> void:
	Sfx.loop("mus_song", true, GameState.balance.audio.song_db)
	# This opening is a single full recording; never restart its first note at the ending cue.
	var opening_track: AudioStream = Sfx.get_stream("mus_song")
	if opening_track is AudioStreamWAV: opening_track.loop_mode = AudioStreamWAV.LOOP_DISABLED
	Sfx.loop("mus_pad", true, GameState.balance.audio.pad_db)
	BeatClock.reset("mus_song")

# From black and starry, through a soft pastel blur, to the clear flower path; the HUD arrives last.
func update_dream() -> void:
	var config: Dictionary = GameState.balance.intro.dream
	var progress := clampf(1.0 - dream_left / maxf(dream_length, 0.01), 0.0, 1.0)
	var material := dream_veil.material as ShaderMaterial
	material.set_shader_parameter("lids", 1.0)
	material.set_shader_parameter("darkness", 1.0 - smoothstep(0.0, 0.3, progress))
	material.set_shader_parameter("blur_px", config.blur_px * (1.0 - smoothstep(0.08, 0.97, progress)))
	material.set_shader_parameter("haze", config.haze * (1.0 - smoothstep(0.25, 1.0, progress)))
	material.set_shader_parameter("vignette", 0.6 * (1.0 - smoothstep(0.2, 1.0, progress)))
	dream_stars.music_time = GameState.balance.intro.music_bars * GameState.balance.bar_s - dream_left
	dream_stars.strength = 1.0 - smoothstep(0.1, 0.55, progress)
	pivot_offset = Vector2(960, 540)
	scale = Vector2.ONE * lerpf(config.zoom, 1.0, smoothstep(0.0, 1.0, progress))
	var hud_alpha := clampf(1.0 - dream_left / config.hud_fade_s, 0.0, 1.0)
	for child in hud_layer.get_children():
		if child is CanvasItem:
			child.modulate.a = hud_alpha

func end_dream() -> void:
	dream_left = 0.0
	dream_veil.queue_free()
	dream_stars.queue_free()
	scale = Vector2.ONE
	for child in hud_layer.get_children():
		if child is CanvasItem:
			child.modulate.a = 1.0
	start_song()

func make_decoration() -> void:
	var sections := level.of_type("section")
	for index in range(sections.size()):
		var event: Dictionary = sections[index]
		var end_x: float = sections[index + 1].x if index + 1 < sections.size() else level.first("door").x
		if event.id == "S1":
			# The flower path may run on past S2's nominal start if the song is still playing.
			end_x = maxf(end_x, GameState.balance.song_view.s1_decor_end_m)
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
				world_props.append({"sprite": prop, "x": distance + rng.randf_range(-0.5, 0.5), "life": INF, "section": event.id})
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
	if final_confrontation != null: return
	if locker_pass != null and locker_pass.active:
		locker_pass.step(delta)
		return
	if night_continuation != null:
		night_continuation.step(delta)
		return
	if finished:
		return
	if reveal_age >= 0.0:
		step_nightmare_reveal(delta)
		return
	if dream_left > 0.0:
		dream_left -= delta
		if dream_left <= 0.0:
			end_dream()
		else:
			update_dream()
			update_view(delta)
			return
	var tier_index: int = ["QUIET", "HUM", "TALK", "SHOUT"].find(VoiceInput.tier)
	if state.section == "S1":
		tutorial.step(delta, tier_index)
	model.guard_enabled = not GameState.settings.keyboard_mode
	state.step(delta, VoiceInput.speed_target, VoiceInput.is_shouting, VoiceInput.is_audible, tier_index, BeatClock.elapsed - reveal_clock_hold)
	for message in state.messages:
		handle_message(message)
	if state.section == "S1":
		update_song()
	update_view(delta)
	if locker_pass != null: locker_pass.update_follow_scene()

func start_night_continuation() -> void:
	flower_night_started = true
	night_continuation = NightContinuation.new()
	night_continuation.run = self
	add_child(night_continuation)

func start_last_scream() -> LastScream:
	if final_confrontation != null: return final_confrontation
	if night_continuation != null:
		night_continuation.closing_left.stop()
		night_continuation.closing_right.stop()
		night_continuation.hide()
	hud_layer.hide()
	mina.hide()
	final_layer = CanvasLayer.new()
	final_layer.layer = 8
	add_child(final_layer)
	final_confrontation = LastScream.new()
	final_confrontation.embedded = true
	final_confrontation.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	final_layer.add_child(final_confrontation)
	return final_confrontation

func handle_message(message: Dictionary) -> void:
	var audio: Dictionary = GameState.balance.audio
	match message.type:
		"section", "respawn":
			if state.section != "S1":
				if Sfx.loops.has("mus_song"):
					Sfx.loop("mus_song", false)
					BeatClock.adopt_master("mus_pad")
				GameState.world_real = 1.0
				if not Sfx.loops.has("mus_drums"):
					drums_pending = true
			else:
				Sfx.loop("mus_song", true, audio.song_db)
		"face_slam":
			slam_age = 0.0
			reveal_age = 0.0
			model.speed = 0.0
			for prop in world_props:
				if prop.get("section", "S1") == "S1":
					if prop.x > model.x + 2.0: prop.life = 0.0
				else:
					prop.x += message.get("offset", 0.0)
			walls.clear()
			for object in objects:
				if object.kind == "face_wall": walls[object.event.x] = object.sprite
			if Sfx.loops.has("mus_song"):
				Sfx.loop("mus_song", false)
				BeatClock.adopt_master("mus_pad")
			Sfx.play("sfx_title_laugh", audio.slam_db + (audio.reduce_scare_db if GameState.settings.reduce_scares else 0.0))
			GameState.world_real = 1.0
			if not GameState.settings.reduce_scares:
				shake_left = GameState.balance.slam.shake_s
		"lunge_tell":
			Sfx.play_at("sfx_m1_growl", audio.growl_db, 1.0, -0.6)
			show_hint("lunge_hint", GameState.balance.bar_s / GameState.balance.beats_per_bar + 0.4)
		"lunge":
			Sfx.play_at("sfx_m1_roar", audio.threat_db, 1.0, -0.6)
			lunge_left = GameState.balance.m1.lunge_s
		"wall_break":
			Sfx.play("sfx_wall_break", audio.break_db)
			if walls.has(message.x):
				var broken: Control = walls[message.x]
				var crumble := create_tween()
				crumble.tween_property(broken, "scale", Vector2(1.25, 0.2), 0.25)
				crumble.parallel().tween_property(broken, "modulate:a", 0.0, 0.25)
		"slip":
			Sfx.play("sfx_stumble", audio.gate_db)
			show_hint("slip_hint", 1.2)
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
		"capture":
			Sfx.play("sfx_m2_grab" if state.director.capture_cause == "hearing" else "sfx_capture", audio.capture_db)
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

func show_hint(key: String, seconds: float) -> void:
	hint_key = key
	hint_left = seconds

# Drums and heartbeat join on an even bar so the accented "shout bar" lines up with the wall's lunges.
func _on_bar(index: int) -> void:
	if night_continuation != null or (locker_pass != null and locker_pass.active): return
	if not drums_pending or index % int(GameState.balance.m1.lunge_every_bars) != 0:
		return
	drums_pending = false
	Sfx.loop("mus_drums", true, GameState.balance.audio.drums_db)
	Sfx.loop("mus_heart", true, GameState.balance.audio.heart_db)

func update_horror(delta: float) -> void:
	var b: Dictionary = GameState.balance
	var d := state.director
	var h: Dictionary = b.horror
	# Face slam overlay.
	if slam_age < INF:
		slam_age += delta
		var cfg: Dictionary = b.slam
		var gentle: bool = GameState.settings.reduce_scares
		slam_face.visible = slam_age < cfg.face_s + 0.3
		var fade_in: float = clampf(slam_age / cfg.reduce_fade_s, 0.0, 1.0) if gentle else 1.0
		var fade_out: float = 1.0 - clampf((slam_age - cfg.face_s) / 0.3, 0.0, 1.0)
		slam_face.modulate.a = fade_in * fade_out
		slam_face.scale = Vector2.ONE * lerpf(1.0, cfg.scale_to, clampf(slam_age / cfg.scale_s, 0.0, 1.0))
		slam_text.visible = slam_age < cfg.text_s
		slam_text.position = Vector2(0, 380) + (Vector2.ZERO if gentle else Vector2(sin(slam_age * 71.0), cos(slam_age * 53.0)) * 10.0)
		if slam_age > cfg.text_s + 0.3:
			slam_age = INF
			slam_face.visible = false
			slam_text.visible = false
	# Darkness: the nightmare world is lit only around Mina; it closes in as the wall gets near.
	var real: float = GameState.world_real
	var near: float = clampf(1.0 - d.gap / b.m1.max_gap, 0.0, 1.0) if d.active else 0.0
	var mat := darkness.material as ShaderMaterial
	darkness.visible = real > 0.05 and state.section != "S1" or real > 0.3
	mat.set_shader_parameter("center", Vector2(b.player_screen_x, b.layout.feet_y - 180))
	mat.set_shader_parameter("radius", h.light_radius_px * (1.0 - near * 0.25) * (1.4 if state.section == "S5" else 1.0))
	mat.set_shader_parameter("soft", h.light_soft_px)
	mat.set_shader_parameter("strength", h.darkness * real * (0.5 if not state.safe_id.is_empty() else 1.0))
	mat.set_shader_parameter("flicker", near)
	if reveal_age >= 0.0:
		var amount := clampf(-reveal_camera_px / maxf(-reveal_pan_distance(), 1.0), 0.0, 1.0)
		mat.set_shader_parameter("center", Vector2(lerpf(b.player_screen_x - reveal_camera_px, wall.position.x + wall.size.x * 0.5, amount), b.layout.feet_y - 330))
		mat.set_shader_parameter("radius", lerpf(h.light_radius_px, 570.0, amount))
	# Lunge: the wall lurches forward and the screen jolts.
	lunge_left = maxf(0.0, lunge_left - delta)
	if lunge_left > 0.0:
		var t: float = 1.0 - lunge_left / b.m1.lunge_s
		wall.position.x += sin(t * PI) * h.lunge_lurch_px
		if not GameState.settings.reduce_scares:
			position += Vector2(sin(state.time * 67.0), cos(state.time * 41.0)) * h.lunge_shake_px * (1.0 - t)
	elif d.active and d.gap < h.near_shake_gap and state.status == "running" and not GameState.settings.reduce_scares:
		position += Vector2(sin(state.time * 37.0), cos(state.time * 29.0)) * h.near_shake_px * (1.0 - d.gap / h.near_shake_gap)
	if Sfx.loops.has("mus_heart"):
		Sfx.loops["mus_heart"].volume_db = lerpf(b.audio.heart_db - 14.0, b.audio.heart_db, near)
		Sfx.loops["mus_heart"].pitch_scale = lerpf(0.9, 1.35, near)
	# Face walls: shudder while being shouted at; reappear after a respawn.
	for wall_x in walls:
		var face_wall: Control = walls[wall_x]
		if not state.walls_broken.has(wall_x):
			face_wall.scale = Vector2.ONE
			face_wall.modulate.a = 1.0
			if state.wall_waiting == wall_x:
				var progress: float = state.wall_progress.get(wall_x, 0.0) / b.obstacles.face_wall.break_s
				face_wall.position.x += sin(state.time * 90.0) * 10.0 * progress
				face_wall.modulate = Color(1.0, 1.0 - progress * 0.5, 1.0 - progress * 0.5)
	# Covers glow once the sky starts to open.
	for object in objects:
		if object.kind == "cover":
			var glow: float = b.level_view.cover_glow * (0.6 + 0.4 * sin(state.time * 8.0)) if d.phase in ["TELL", "WARNING"] else 0.0
			object.sprite.modulate = Color(1.0 + glow, 1.0 + glow, 1.0 + glow * 0.6)

func update_view(delta: float) -> void:
	var b: Dictionary = GameState.balance
	var d := state.director
	var in_song := state.section == "S1"
	# Keep the bright collage throughout the song, even during the old lyric-color flashes.
	# The monster reveal is the only transition to the red nightmare panel.
	for layer in layers:
		if layer.sprite is SceneBackdrop:
			layer.sprite.set_horror(state.slammed or not in_song)
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
		prompt_key = ("bridge_hint" if bridge_waiting else ("" if tutorial.complete() else tutorial.stages[tutorial.index].key))
	elif hint_left > 0.0: prompt_key = hint_key
	elif state.section == "S5": prompt_key = "finale_hint"
	elif state.wall_waiting >= 0.0: prompt_key = "wall_hint"
	elif state.on_plank and d.phase == "IDLE": prompt_key = "plank_hint"
	elif d.slam_left > 0.0: prompt_key = "slam_hint"
	elif clear_left > 0.0 and d.phase in ["RECEDE", "IDLE"]: prompt_key = "clear_hint"
	elif state.hidden: prompt_key = "hidden_hint"
	elif d.phase == "GAZE": prompt_key = "gaze_hint"
	elif d.phase == "WARNING": prompt_key = "warning_hint"
	elif d.phase == "TELL": prompt_key = "tell_hint"
	elif not state.safe_id.is_empty(): prompt_key = "safe_hint"
	elif clear_left > 0.0: prompt_key = "clear_hint"
	if state.status == "running" and state.still_s >= b.stuck.after_s and d.phase in ["IDLE", "TELL"] and (not in_song or bridge_waiting):
		if state.wall_waiting >= 0.0: prompt_key = "stuck_wall"
		elif state.slip_left > 0.0 or state.on_plank: prompt_key = "stuck_plank"
		elif bridge_waiting: prompt_key = "stuck_bridge"
		elif not model.gate_state.is_empty(): prompt_key = "stuck_gate"
		elif not state.safe_id.is_empty(): prompt_key = "stuck_safe"
		else: prompt_key = "stuck_quiet"
	prompt.text = "" if prompt_key.is_empty() else GameState.text(prompt_key)
	prompt.visible = not prompt.text.is_empty()
	hint_left = maxf(0.0, hint_left - delta)
	meter.pulse_tier = 3 if state.wall_waiting >= 0.0 else 2 if bridge_waiting else (0 if tutorial.complete() or not in_song else tutorial.stages[tutorial.index].tier)
	clear_left = maxf(0.0, clear_left - delta)
	if state.messages.any(func(m: Dictionary) -> bool: return m.type == "respawn"):
		parallax_x = model.x
	else:
		parallax_x += (model.x - last_view_x) * (b.finale.parallax_mult if state.section == "S5" and state.finale_hits > 0 else 1.0)
	last_view_x = model.x
	for layer in layers:
		var camera_distance: float = model.x if layer.factor == 1.0 else parallax_x
		layer.sprite.position.x = layer.tile * layer.width - fposmod((camera_distance * b.px_per_m + reveal_camera_px) * layer.factor, layer.width)
	var camera_x: float = model.x * b.px_per_m - b.player_screen_x + reveal_camera_px
	for prop in world_props:
		prop.sprite.position.x = prop.x * b.px_per_m - camera_x - prop.sprite.size.x * 0.5
		prop.sprite.visible = prop.sprite.position.x > -prop.sprite.size.x and prop.sprite.position.x < b.layout.screen[0]
		prop.life -= delta
		if prop.life <= 0.0:
			prop.sprite.queue_free()
	world_props = world_props.filter(func(prop: Dictionary) -> bool: return prop.life > 0.0)
	for object in objects:
		object.sprite.position.x = object.event.x * b.px_per_m - camera_x - (0.0 if object.kind == "gate" else object.sprite.size.x * 0.5)
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
	mina.animation_fps = 11.0
	if reveal_age >= 0.0: mina.base_key = "mina_idle"
	mina.position.x = b.player_screen_x - mina.size.x * 0.5 - reveal_camera_px
	wall.visible = d.active and state.status != "complete"
	wall.position.x = b.player_screen_x - d.gap * b.px_per_m - wall.size.x - reveal_camera_px
	var presence: float = clampf((b.level_view.peek_end_gap - d.gap) / (b.level_view.peek_end_gap - b.level_view.peek_begin_gap), 0.0, 1.0)
	peek.visible = d.active and d.gap >= b.level_view.peek_begin_gap and d.gap <= b.level_view.peek_end_gap
	peek.position.x = -peek.size.x + presence * b.level_view.peek_max_px
	edge_shade.color.a = presence * 0.4 if d.active else 0.0
	crack.visible = d.phase in ["WARNING", "GAZE", "RECEDE"]
	shade.visible = crack.visible
	shade.color.a = 0.4
	eye.visible = d.phase in ["WARNING", "GAZE", "RECEDE"]
	eye.scale = Vector2.ONE
	eye.pivot_offset = eye.size * 0.5
	if state.section == "S5":
		var eye_age: float = state.time - state.finale_start
		var closing := clampf(eye_age / b.finale.eye_close_s, 0.0, 1.0)
		eye.visible = eye_age < b.finale.eye_close_s
		eye.modulate.a = 1.0 - closing
		eye.texture = EyeAnimation.at_openness(1.0 - closing)
	else:
		eye.modulate.a = 1.0
		var phase_progress := clampf((state.clock - d.phase_start) / maxf(d.phase_end - d.phase_start, 0.001), 0.0, 1.0)
		var openness := 1.0
		if d.phase == "WARNING": openness = phase_progress
		elif d.phase == "RECEDE": openness = 1.0 - phase_progress
		if d.phase == "GAZE":
			eye.texture = EyeAnimation.gaze_at(state.clock - d.phase_start)
		else:
			eye.texture = EyeAnimation.at_openness(openness)
	update_eye_beam()
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
	update_horror(delta)
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
	var part: String = song.syllables[current].part
	# The dream decays line by line: each part ramps the real look from its first to its last line.
	var ramp: Array = GameState.balance.song_view.part_world_real.get(part, [0.0, 0.0])
	var first_line := song.line_parts.find(part)
	var last_line := song.line_parts.rfind(part)
	var through: float = 0.0 if last_line <= first_line else float(line_index - first_line) / float(last_line - first_line)
	var target_real: float = lerpf(ramp[0], ramp[1], through)
	GameState.world_real = move_toward(GameState.world_real, target_real, get_process_delta_time() / GameState.balance.song_view.world_lerp)
	if line_index != last_song_line:
		last_song_line = line_index
		# A single-frame glimpse of the real world whenever a changed line begins.
		if part != "twinkle" and not GameState.settings.reduce_scares:
			flash_left = GameState.balance.song_view.dark_flash_s
	if flash_left > 0.0:
		flash_left -= get_process_delta_time()
		GameState.world_real = 1.0 if flash_left > 0.0 else target_real
	if VoiceInput.is_audible and not sung.has(current) and not song.syllables[current].cut:
		sung[current] = true
	# The recording is the master. Voice requests are quantized to its authored attacks,
	# rather than emitted on an arbitrary microphone frame or the old 19.2s lyric loop.
	step_song_blooms(maxf(0.0, BeatClock.elapsed - AudioServer.get_output_latency()), VoiceInput.is_audible)
	for index in syllable_labels:
		var ink := Color(GameState.balance.palette.ink)
		if song.syllables[index].part != "twinkle":
			ink = Color("#7a1414")
		var color := Color(GameState.balance.palette.gold) if sung.has(index) else ink
		syllable_labels[index].add_theme_color_override("font_color", color)
		syllable_labels[index].modulate.a = 1.0 if current == index or sung.has(index) else 0.5

func quiet_input_assist_db() -> float:
	# Only soften incidental room noise during the eye's quiet warning/gaze.
	# Chases, jumping, wall breaking and the final scream always keep normal sensitivity.
	if finished or dream_left > 0.0 or state.status != "running" or final_confrontation != null or night_continuation != null:
		return 0.0
	if locker_pass != null and locker_pass.active: return 0.0
	if state.director.phase in ["WARNING", "GAZE"]:
		return float(GameState.balance.voice.quiet_obstacle_attenuation_db)
	return 0.0

# All projection uses the same temporary camera offset; no scene/map switch.
func reveal_pan_distance() -> float:
	return GameState.balance.player_screen_x - state.director.gap * GameState.balance.px_per_m - wall.size.x * 0.5 - 960.0

func step_nightmare_reveal(delta: float) -> void:
	reveal_age += delta
	reveal_clock_hold += delta
	var target := reveal_pan_distance()
	var pan_age := reveal_age - REVEAL_FACE_S
	if pan_age < 0.0:
		reveal_camera_px = 0.0
	else:
		# The face fills the screen first; only then reveal the creature on the map.
		slam_age = INF
		slam_face.hide()
		slam_text.hide()
		if pan_age < 0.45:
			reveal_camera_px = lerpf(0.0, target, smoothstep(0.0, 0.45, pan_age))
		elif pan_age < 1.55:
			reveal_camera_px = target
		else:
			reveal_camera_px = lerpf(target, 0.0, smoothstep(1.55, 2.10, pan_age))
	if pan_age + 0.000001 >= 2.10:
		reveal_age = -1.0
		reveal_camera_px = 0.0
	update_view(delta)

func update_eye_beam() -> void:
	var d := state.director
	var elapsed := state.clock - d.phase_start
	beam.visible = d.phase == "GAZE" and EyeAnimation.beam_active(elapsed)
	if not beam.visible: return
	# Drawing and sight detection use exactly the same authored scan sample.
	d.beam_offset = EyeAnimation.scan_direction(elapsed) * GameState.balance.m2.beam_half_range_m
	beam.position.x = GameState.balance.player_screen_x + d.beam_offset * GameState.balance.px_per_m - beam.size.x * 0.5
	var pupil := eye.position + EyeAnimation.pupil_at(elapsed) / Vector2(EyeAnimation.SOURCE_REGION.size) * eye.size
	var origin := pupil - beam.position
	if beam_cone == null:
		beam.texture = null
		beam_cone = Polygon2D.new()
		beam_cone.use_parent_material = true
		beam.add_child(beam_cone)
		beam_cone.vertex_colors = PackedColorArray([Color(0.83,0.87,0.68,0.06),Color(0.83,0.87,0.68,0.06),Color(0.83,0.87,0.68,0.42),Color(0.83,0.87,0.68,0.42)])
	beam_cone.polygon = PackedVector2Array([origin+Vector2(-14,0),origin+Vector2(14,0),Vector2(beam.size.x,beam.size.y),Vector2(0,beam.size.y)])

func step_song_blooms(audio_time: float, audible: bool) -> void:
	var cues: Array = GameState.balance.song_view.bloom_cues
	if audio_time < bloom_last_time - 0.1:
		bloom_cursor = 0
		bloom_pending = false
	bloom_last_time = audio_time
	bloom_pending = bloom_pending or audible
	while bloom_cursor < cues.size() and float(cues[bloom_cursor].time) <= audio_time + 0.000001:
		var cue: Dictionary = cues[bloom_cursor]
		# Skip stale attacks after a stall/seek, instead of bursting several sounds at once.
		if bloom_pending and audio_time - float(cue.time) <= 0.1:
			spawn_song_flower(float(cue.pitch))
		bloom_pending = false
		bloom_cursor += 1

func spawn_song_flower(pitch: float) -> void:
	var flower := dual("flower_bud", Rect2(0, GameState.balance.layout.feet_y - 140, 110, 140))
	world_props.append({"sprite": flower, "x": model.x, "life": GameState.balance.s1.bloom_life_s})
	flower.pivot_offset = Vector2(flower.size.x * 0.5, flower.size.y)
	flower.scale = Vector2.ONE * 0.15
	var bloom := create_tween()
	bloom.tween_property(flower, "scale", Vector2.ONE, 0.14)
	bloom.tween_callback(func() -> void:
		if is_instance_valid(flower): flower.base_key = "flower_open")
	Sfx.play("sfx_bloom", GameState.balance.audio.bloom_db, pitch)
	move_child(mina, get_child_count() - 1)
