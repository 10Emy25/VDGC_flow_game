class_name BedroomIntro
extends Control
# S0: Mina's bedroom at night. Plays the steps in data/intro.json (poses, narration, close-ups, sounds),
# then she falls asleep: her eyes close, the music-box "Twinkle, Twinkle" starts in the dark, and
# fell_asleep hands over to the flower path, which wakes up from a blur while the intro finishes.

signal fell_asleep(music_elapsed: float)

var cfg: Dictionary
var audio: Dictionary
var steps: Array = []
var index := -1
var step: Dictionary = {}
var step_age := 0.0
var typed_age := 0.0
var skip := false
var age := 0.0
var stage: Control
var pose_back: TextureRect
var pose_front: TextureRect
var pose_key := ""
var pose_tween: Tween
var pose_rect: Rect2
var cg_back: TextureRect
var cg_front: TextureRect
var cg_key := ""
var cg_tween: Tween
var props: Dictionary = {}
var glow: TextureRect
var inserts: Dictionary = {}
var insert_name := ""
var insert_age := 0.0
var hand_left: TextureRect
var hand_right: TextureRect
var bottle: TextureRect
var palm: TextureRect
var pill: TextureRect
var rattled := false
var dropped := false
var veil: ColorRect
var stars: DreamStars
var hud_layer: CanvasLayer
var caption: Label
var narration_box: TextureRect
var narration: Label
var more: Polygon2D
var typing := false
var typed := 0.0
var trembling := false
var sleeping := false
var sleep_age := 0.0
var sleep_zoom_from := 1.0
var music_age := -1.0
var done := false

func _ready() -> void:
	theme = GameState.ui_theme
	GameState.world_real = 0.0
	PostFX.stress = 0.0
	cfg = GameState.balance.intro
	audio = GameState.balance.audio
	steps = GameState.read_json("res://data/intro.json").steps
	Sfx.stop_all()
	Sfx.loop("amb_night", true, audio.night_db)
	Sfx.loop("amb_clock", true, audio.intro_clock_db)
	var screen := Vector2(GameState.balance.layout.screen[0], GameState.balance.layout.screen[1])
	stage = Control.new()
	stage.size = screen
	stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage.pivot_offset = Vector2(cfg.focus[0], cfg.focus[1])
	add_child(stage)
	UIFactory.texture(stage, "bedroom_bg", Rect2(Vector2.ZERO, screen))
	for key in cfg.props:
		props[key] = UIFactory.texture(stage, key, UIFactory.rect(cfg.props[key]))
	pose_rect = UIFactory.rect(cfg.bed_rect)
	pose_back = UIFactory.texture(stage, "bed_mina_asleep", pose_rect)
	pose_front = UIFactory.texture(stage, "bed_mina_asleep", pose_rect)
	for node in [pose_back, pose_front]:
		node.pivot_offset = Vector2(pose_rect.size.x * 0.5, pose_rect.size.y)
	pose_back.texture = null
	pose_front.texture = null
	glow = make_glow()
	stage.add_child(glow)
	cg_back = make_cg_layer(screen)
	cg_front = make_cg_layer(screen)
	build_inserts(screen)
	veil = ColorRect.new()
	veil.size = screen
	veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var veil_material := ShaderMaterial.new()
	veil_material.shader = load("res://shaders/dream_veil.gdshader")
	veil.material = veil_material
	add_child(veil)
	stars = DreamStars.new()
	add_child(stars)
	hud_layer = CanvasLayer.new()
	hud_layer.layer = 8
	add_child(hud_layer)
	caption = UIFactory.label(hud_layer, "intro_caption", Rect2(60, 44, 600, 54), GameState.balance.ui.small_size, Color(GameState.balance.palette.cool))
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	var box := UIFactory.rect(cfg.narration_rect)
	narration_box = UIFactory.texture(hud_layer, "ui_narration", box)
	narration = UIFactory.label(hud_layer, "empty_lyrics", box.grow_individual(-60, -16, -90, -16), GameState.balance.ui.therapist_size, Color("#e8eef2"))
	narration.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var path: String = GameState.dialogue.fonts.therapist
	if ResourceLoader.exists(path):
		narration.add_theme_font_override("font", load(path))
	more = Polygon2D.new()
	more.polygon = PackedVector2Array([Vector2(-11, -6), Vector2(11, -6), Vector2(0, 7)])
	more.color = Color(GameState.balance.palette.cool)
	more.position = box.end - Vector2(48, 34)
	hud_layer.add_child(more)
	say("")
	set_veil(0.0, 1.0, 1.0, 0.0)
	next_step()

func make_glow() -> TextureRect:
	var config: Dictionary = cfg.phone_glow
	var gradient := Gradient.new()
	gradient.set_color(0, Color(0.78, 0.88, 1.0, config.alpha))
	gradient.set_color(1, Color(0.78, 0.88, 1.0, 0.0))
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(1.0, 0.5)
	texture.width = 256
	texture.height = 256
	var node := TextureRect.new()
	node.texture = texture
	node.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var radius: float = config.radius
	node.position = Vector2(config.center[0], config.center[1]) - Vector2(radius, radius)
	node.size = Vector2(radius, radius) * 2.0
	var additive := CanvasItemMaterial.new()
	additive.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	node.material = additive
	node.hide()
	return node

func build_inserts(screen: Vector2) -> void:
	for insert in ["hands", "pills"]:
		var root := Control.new()
		root.size = screen
		root.mouse_filter = Control.MOUSE_FILTER_IGNORE
		root.hide()
		add_child(root)
		UIFactory.texture(root, "insert_blanket", Rect2(Vector2.ZERO, screen))
		inserts[insert] = root
	hand_left = UIFactory.texture(inserts.hands, "insert_hand_left", UIFactory.rect(cfg.hands.insert_hand_left))
	hand_right = UIFactory.texture(inserts.hands, "insert_hand_right", UIFactory.rect(cfg.hands.insert_hand_right))
	var pills: Dictionary = cfg.pills
	palm = UIFactory.texture(inserts.pills, "insert_hand_palm", UIFactory.rect(pills.palm_rect))
	bottle = UIFactory.texture(inserts.pills, "insert_hand_bottle", UIFactory.rect(pills.bottle_rect))
	bottle.pivot_offset = Vector2(pills.bottle_pivot[0], pills.bottle_pivot[1])
	pill = UIFactory.texture(inserts.pills, "prop_pill", Rect2(Vector2.ZERO, Vector2(pills.pill_size[0], pills.pill_size[1])))
	pill.hide()
	for node in [hand_left, hand_right, bottle, palm]:
		node.set_meta("home", node.position)

func _process(delta: float) -> void:
	if done:
		return
	age += delta
	if sleeping:
		update_sleep(delta)
	else:
		var fade := 1.0 - clampf(age / cfg.fade_in_s, 0.0, 1.0)
		set_veil(0.0, 1.0, fade * fade, 0.0)
		caption.modulate.a = 0.7 * (1.0 - fade)
		stage.scale = Vector2.ONE * lerpf(1.0, cfg.push_in, smoothstep(0.0, 1.0, age / cfg.push_in_s))
		step_age += delta
		if step_done():
			next_step()
	update_typing(delta)
	update_pose_motion()
	update_insert(delta)
	if glow.visible:
		glow.modulate.a = 0.85 + 0.15 * sin(age * 23.0) * sin(age * 7.0)

func step_done() -> bool:
	if step_age < float(step.get("wait", 0.0)) and not skip:
		return false
	var line: String = step.get("say", "")
	if line.is_empty():
		return true
	if typing:
		return false
	return skip or step_age - typed_age >= cfg.say_hold_s

func next_step() -> void:
	index += 1
	if index >= steps.size():
		start_sleep()
		return
	step = steps[index]
	step_age = 0.0
	typed_age = 0.0
	skip = false
	if step.has("pose"):
		set_pose(step.pose)
	if step.has("cg"):
		set_cg(step.cg)
	for key in step.get("hide", []):
		if props.has(key): props[key].hide()
	for key in step.get("show", []):
		if props.has(key): props[key].show()
	if step.has("sfx"):
		var sound: String = step.sfx
		Sfx.play(sound, step.get("db", audio.get(sound.trim_prefix("sfx_") + "_db", audio.default_db)))
	if step.has("clock_db"):
		Sfx.set_loop_volume("amb_clock", step.clock_db, 1.0)
	if step.has("heart"):
		if step.heart:
			Sfx.loop("mus_heart", true, audio.intro_heart_db - 18.0)
			Sfx.set_loop_volume("mus_heart", audio.intro_heart_db, 2.0)
		else:
			Sfx.set_loop_volume("mus_heart", audio.mic_mute_db, 2.5)
	trembling = step.get("tremble", false)
	glow.visible = step.get("glow", false)
	set_insert(step.get("insert", ""))
	if step.has("say"):
		say(step.say)
	if step.get("sleep", false):
		start_sleep()

func say(key: String) -> void:
	var line := "" if key.is_empty() else GameState.text(key)
	narration.text = line
	narration.visible_characters = 0
	typed = 0.0
	typing = not line.is_empty()
	narration_box.visible = typing
	narration.visible = typing
	more.hide()

func update_typing(delta: float) -> void:
	if typing:
		typed += delta * cfg.type_cps
		narration.visible_characters = int(typed)
		if typed >= narration.get_total_character_count():
			finish_typing()
	more.visible = narration.visible and not typing and not sleeping and fmod(age, 1.0) < 0.6

func finish_typing() -> void:
	typing = false
	narration.visible_characters = -1
	typed_age = step_age

# Click, Space or Enter: finish the line being typed, then move on.
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		press()
		accept_event()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode in [KEY_SPACE, KEY_ENTER, KEY_KP_ENTER]:
		press()
		get_viewport().set_input_as_handled()

func press() -> void:
	if sleeping or done:
		return
	if typing:
		finish_typing()
	elif not str(step.get("say", "")).is_empty():
		skip = true

func set_pose(key: String) -> void:
	if key == pose_key:
		return
	pose_key = key
	if pose_tween != null and pose_tween.is_valid():
		pose_tween.kill()
	pose_back.texture = pose_front.texture
	pose_back.modulate.a = 1.0
	pose_front.texture = ArtRegistry.get_texture(key)
	if pose_back.texture == null:
		pose_front.modulate.a = 1.0
		return
	# Fade the new pose in over the old one, then let the old one go, so the room never shows through.
	var fade: float = cfg.pose_fade_s
	pose_front.modulate.a = 0.0
	pose_tween = create_tween()
	pose_tween.tween_property(pose_front, "modulate:a", 1.0, fade)
	pose_tween.parallel().tween_property(pose_back, "modulate:a", 0.0, fade * 0.6).set_delay(fade * 0.5)

func make_cg_layer(screen: Vector2) -> TextureRect:
	var node := TextureRect.new()
	node.position = Vector2(-12, -12)
	node.size = screen + Vector2(24, 24)
	node.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	node.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	node.modulate.a = 0.0
	stage.add_child(node)
	return node

func set_cg(key: String) -> void:
	if key == cg_key:
		return
	cg_key = key
	if cg_tween != null and cg_tween.is_valid():
		cg_tween.kill()
	var fade: float = cfg.get("cg_fade_s", 0.8)
	cg_back.texture = cg_front.texture
	cg_back.modulate.a = cg_front.modulate.a
	cg_front.modulate.a = 0.0
	cg_tween = create_tween()
	if key.is_empty():
		cg_front.texture = null
		cg_tween.tween_property(cg_back, "modulate:a", 0.0, fade)
	else:
		cg_front.texture = ArtRegistry.get_texture(key)
		cg_tween.tween_property(cg_front, "modulate:a", 1.0, fade)
		cg_tween.tween_callback(func(): cg_back.modulate.a = 0.0)

func shake(t: float, seed_value: float, amount: float) -> Vector2:
	var hz: float = cfg.tremble_hz
	return Vector2(sin(t * hz * 6.1 + seed_value) + sin(t * hz * 3.7 + seed_value * 2.0), cos(t * hz * 5.3 + seed_value) + sin(t * hz * 2.3 + seed_value * 3.0)) * 0.5 * amount

func update_pose_motion() -> void:
	var lying := pose_key in ["bed_mina_asleep", "bed_mina_awake", "bed_mina_drowsy", "bed_mina_turn"]
	var breath: float = 1.0 + (cfg.breath_scale * sin(age * TAU * cfg.breath_hz) if lying else 0.0)
	var offset := shake(age, 0.0, cfg.tremble_px) if trembling else Vector2.ZERO
	for node in [pose_back, pose_front]:
		node.scale = Vector2(1.0, breath)
		node.position = pose_rect.position + offset
	var cg_shake := shake(age, 0.0, 4.0) if trembling else Vector2.ZERO
	for node in [cg_back, cg_front]:
		node.position = Vector2(-12, -12) + cg_shake

func set_insert(insert: String) -> void:
	if insert == insert_name:
		return
	var fade: float = cfg.insert_fade_s
	if not insert_name.is_empty():
		var old: Control = inserts[insert_name]
		var out := create_tween()
		out.tween_property(old, "modulate:a", 0.0, fade)
		out.tween_callback(old.hide)
	insert_name = insert
	insert_age = 0.0
	rattled = false
	dropped = false
	pill.hide()
	if insert.is_empty() or not inserts.has(insert):
		return
	var node: Control = inserts[insert]
	node.show()
	node.modulate.a = 0.0
	create_tween().tween_property(node, "modulate:a", 1.0, fade)

func update_insert(delta: float) -> void:
	if insert_name.is_empty():
		return
	insert_age += delta
	var amount: float = cfg.insert_tremble_px
	var degrees: float = cfg.insert_tremble_deg
	if insert_name == "hands":
		hand_left.position = hand_left.get_meta("home") + shake(insert_age, 1.3, amount)
		hand_right.position = hand_right.get_meta("home") + shake(insert_age, 4.1, amount)
		hand_left.rotation_degrees = shake(insert_age, 2.2, degrees).x
		hand_right.rotation_degrees = shake(insert_age, 5.7, degrees).y
	elif insert_name == "pills":
		var pills: Dictionary = cfg.pills
		bottle.position = bottle.get_meta("home") + shake(insert_age, 0.7, amount)
		palm.position = palm.get_meta("home") + shake(insert_age, 3.3, amount * 0.6)
		bottle.rotation_degrees = pills.bottle_tilt_deg * smoothstep(0.0, 1.0, insert_age / pills.tilt_s) + shake(insert_age, 6.0, degrees).x
		if not rattled and insert_age >= pills.rattle_at_s:
			rattled = true
			Sfx.play("sfx_pills", audio.pills_db)
		if not dropped and insert_age >= pills.drop_at_s:
			dropped = true
			drop_pill()

func bottle_mouth() -> Vector2:
	var pills: Dictionary = cfg.pills
	var local := Vector2(pills.bottle_mouth[0], pills.bottle_mouth[1]) - bottle.pivot_offset
	return bottle.position + bottle.pivot_offset + local.rotated(bottle.rotation)

func drop_pill() -> void:
	var pills: Dictionary = cfg.pills
	var target: Vector2 = palm.position + Vector2(pills.palm_target[0], pills.palm_target[1])
	pill.position = bottle_mouth() - pill.size * 0.5
	pill.rotation = 0.0
	pill.pivot_offset = pill.size * 0.5
	pill.show()
	var fall := create_tween()
	fall.tween_property(pill, "position", target - pill.size * 0.5, pills.drop_s).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	fall.parallel().tween_property(pill, "rotation", 2.4, pills.drop_s)
	fall.tween_property(pill, "position:y", target.y - pill.size.y * 0.5 - 14.0, 0.09).set_ease(Tween.EASE_OUT)
	fall.tween_property(pill, "position:y", target.y - pill.size.y * 0.5, 0.09).set_ease(Tween.EASE_IN)

func lid_at(t: float) -> float:
	var keys: Array = cfg.sleep.lids
	for k in range(1, keys.size()):
		if t <= keys[k][0]:
			var span: float = maxf(keys[k][0] - keys[k - 1][0], 0.001)
			return lerpf(keys[k - 1][1], keys[k][1], smoothstep(0.0, 1.0, (t - keys[k - 1][0]) / span))
	return keys.back()[1]

func start_sleep() -> void:
	if sleeping:
		return
	sleeping = true
	sleep_age = 0.0
	say("")
	set_insert("")
	trembling = false
	glow.hide()
	set_pose("bed_mina_drowsy")
	sleep_zoom_from = stage.scale.x
	for key in ["amb_night", "amb_clock", "mus_heart"]:
		Sfx.set_loop_volume(key, audio.mic_mute_db, cfg.sleep.fade_sound_s)

func update_sleep(delta: float) -> void:
	sleep_age += delta
	var closing: float = cfg.sleep.lids.back()[0]
	var progress := clampf(sleep_age / closing, 0.0, 1.0)
	var lids := lid_at(sleep_age)
	stage.scale = Vector2.ONE * lerpf(sleep_zoom_from, cfg.sleep.zoom, smoothstep(0.0, 1.0, progress))
	caption.modulate.a = 0.7 * (1.0 - progress)
	if lids < cfg.sleep.asleep_below:
		set_pose("bed_mina_asleep")
	set_veil(cfg.sleep.blur_px * progress, lids, smoothstep(0.75, 1.0, progress), 0.0)
	if music_age < 0.0 and sleep_age >= closing:
		# Eyes closed: the room goes quiet and the music box begins in the dark.
		music_age = 0.0
		for key in ["amb_night", "amb_clock", "mus_heart"]:
			Sfx.loop(key, false)
		Sfx.play("mus_dream_intro", audio.dream_intro_db)
		return
	if music_age >= 0.0:
		music_age += delta
		stars.music_time = music_age
		stars.strength = clampf(music_age / cfg.stars.fade_in_s, 0.0, 1.0)
		set_veil(cfg.sleep.blur_px, 0.0, 1.0, 0.0)
		if music_age >= cfg.handover_bars * GameState.balance.bar_s:
			done = true
			fell_asleep.emit(music_age)

func set_veil(blur: float, lids: float, darkness: float, haze: float) -> void:
	veil.visible = blur > 0.5 or lids < 0.999 or darkness > 0.001 or haze > 0.001
	var material := veil.material as ShaderMaterial
	material.set_shader_parameter("blur_px", blur)
	material.set_shader_parameter("lids", lids)
	material.set_shader_parameter("darkness", darkness)
	material.set_shader_parameter("haze", haze)
	material.set_shader_parameter("vignette", 0.6 * clampf(maxf(maxf(darkness, 1.0 - lids), blur / maxf(cfg.sleep.blur_px, 1.0)), 0.0, 1.0))
