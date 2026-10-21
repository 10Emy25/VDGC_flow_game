class_name NightContinuation
extends CanvasLayer
var run: Control
var phase := "blackout"
var age := 0.0
var elapsed := 0.0
var danger := 0.22
var facing := 1
var monster_side := -1
var switch_clock := 0.0
var next_switch := 14.0
var roar_clock := 0.0
var next_roar := 2.0
var distance_on_entry := 0.0
var veil: ColorRect
var light: ColorRect
var match_flame: Label
var words: Label
var status: Label
var direction_hint: Label
var closing_left: AudioStreamPlayer
var closing_right: AudioStreamPlayer
var scare_face: TextureRect
var scare_age := 0.0
var scare_active := false
var scare_count := 0
var next_scare := 7.5
var rng := RandomNumberGenerator.new()

func _ready() -> void:
	layer = 8
	rng.randomize()
	distance_on_entry = run.model.x
	for child in run.get_children():
		if child == self or child == run.mina: continue
		var map_layer := false
		for item in run.layers:
			if item.sprite == child: map_layer = true
		if not map_layer and (child is CanvasItem or child is CanvasLayer): child.hide()
	run.mina.show()
	run.mina.z_index = 4
	run.mina.position.y = GameState.balance.layout.feet_y - run.mina.size.y
	run.mina.scale = Vector2.ONE
	Sfx.stop_all()
	PostFX.stress = 0
	light = ColorRect.new()
	light.size = Vector2(1920, 1080)
	light.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mat := ShaderMaterial.new()
	mat.shader = preload("res://shaders/matchlight.gdshader")
	mat.set_shader_parameter("center_uv", Vector2(GameState.balance.player_screen_x / 1920.0, 0.63))
	mat.set_shader_parameter("radius", 0.17)
	light.material = mat
	add_child(light)
	light.hide()
	veil = ColorRect.new()
	veil.size = Vector2(1920, 1080)
	veil.color = Color(0.005, 0.005, 0.015, 1)
	veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(veil)
	match_flame = UIFactory.label(self, "", Rect2(825, 650, 50, 60), 44, Color("ffd58b"))
	match_flame.text = "✦"
	match_flame.hide()
	words = UIFactory.label(self, "", Rect2(200, 170, 1520, 90), 42, Color.WHITE)
	status = UIFactory.label(self, "", Rect2(240, 940, 1440, 60), 25, Color("ded5c4"))
	words.text = ""
	status.text = ""
	scare_face = UIFactory.texture(self, "m1_face_peek", Rect2(0, 0, 780, 900))
	scare_face.hide()
	direction_hint = UIFactory.label(self, "", Rect2(230, 270, 1460, 60), 29, Color("e6d8bd"))
	direction_hint.text = ""
	closing_left = closing_voice(-0.95)
	closing_right = closing_voice(0.95)

func closing_voice(pan: float) -> AudioStreamPlayer:
	var bus_name := "FinalApproachLeft" if pan < 0 else "FinalApproachRight"
	if AudioServer.get_bus_index(bus_name) < 0:
		AudioServer.add_bus()
		var index: int = AudioServer.bus_count - 1
		AudioServer.set_bus_name(index, bus_name)
		var panner := AudioEffectPanner.new()
		panner.pan = pan
		AudioServer.add_bus_effect(index, panner)
	var player := AudioStreamPlayer.new()
	player.stream = Sfx.get_stream("amb_m1_breath")
	player.bus = bus_name
	player.volume_db = -40
	add_child(player)
	return player

func step(delta: float) -> void:
	age += delta
	if phase == "blackout":
		# The running frame is interrupted immediately; no fade or scene change.
		advance_map(delta, VoiceInput.speed_target)
		veil.color.a = 1
		if age >= 0.38:
			phase = "look"
			age = 0
			Sfx.play("sfx_match_strike", -12)
			light.show()
			match_flame.show()
	elif phase == "look":
		veil.color.a = maxf(0, 1 - age / 0.09)
		advance_map(0, 0)
		facing = -1 if age < 0.55 or (age >= 1.05 and age < 1.5) else 1
		run.mina.scale.x = facing
		words.text = "Where did it go?" if age >= 0.6 else ""
		if age >= 1.9:
			phase = "listen"
			age = 0
			words.text = "Listen carefully."
		direction_hint.text = "It can come from any direction. Be careful."
	elif phase == "listen":
		if age >= 1.2:
			phase = "night"
			age = 0
			Sfx.loop("amb_clock", true, -26)
	elif phase == "night":
		update_chase(delta)
	elif phase == "caught":
		words.text = "IT FOUND YOU."
		status.text = "ENTER — try again"
	update_scare(delta)
	var closing: float = clampf((elapsed - 73) / 12, 0, 1)
	(light.material as ShaderMaterial).set_shader_parameter("radius", lerpf(0.17, 0.055, closing))
	match_flame.modulate.a = (0.8 + 0.2 * sin(age * 20)) * (1 - closing)
	match_flame.position.x = GameState.balance.player_screen_x + 65 * facing

func advance_map(delta: float, speed: float) -> void:
	run.model.x += speed * delta * facing
	for item in run.layers:
		item.sprite.position.x = item.tile * item.width - fposmod(run.model.x * GameState.balance.px_per_m * item.factor, item.width)
	var key := "mina_run" if speed > 0 else "mina_idle"
	if run.mina.base_key != key: run.mina.base_key = key
	run.mina.animation_fps = 11 if speed > 0 else 2
	run.mina.pivot_offset = run.mina.size * 0.5
	run.mina.scale.x = facing

func update_chase(delta: float) -> void:
	elapsed += delta
	var vocal: float = clampf(VoiceInput.level01 * 1.7, 0, 1)
	var speed: float = (125 + 680 * vocal) / GameState.balance.px_per_m if VoiceInput.is_audible else 0.0
	advance_map(delta, speed)
	danger = clampf(danger + delta * (0.035 + ((-0.085 if facing != monster_side else 0.12) * (0.5 + vocal) if speed > 0 else 0.0)), 0, 1)
	switch_clock += delta
	roar_clock += delta
	if switch_clock >= next_switch:
		switch_clock = 0
		next_switch = rng.randf_range(12, 18)
		monster_side = facing if rng.randf() < 0.78 else -facing
		Sfx.play_at("sfx_m1_growl", -18, 0.86, monster_side)
		roar_clock = 0
		next_roar = 0.6
	if roar_clock >= next_roar:
		roar_clock = 0
		next_roar = rng.randf_range(2.1, 3.1)
		Sfx.play_at("sfx_m1_roar", -22 + 15 * minf(switch_clock / 4, 1) + 8 * danger, 0.92 + 0.13 * danger, monster_side)
	words.text = "Listen carefully." if elapsed < 2 else ""
	direction_hint.text = "It can come from any direction. Be careful." if elapsed < 13 else ""
	status.text = "SCREAM TO RUN    A / D TO TURN    LISTEN FOR THE ROAR"
	if elapsed >= next_scare and elapsed < 70 and scare_count < 5:
		trigger_scare()
		next_scare = elapsed + rng.randf_range(9, 16)
	if elapsed >= 73:
		danger = minf(danger, 0.88)
		status.text = ""
		words.text = ""
		var closing: float = clampf((elapsed - 73) / 11, 0, 1)
		veil.color.a = smoothstep(0, 1, closing)
		for player in [closing_left, closing_right]:
			player.volume_db = lerpf(-32, -5, closing)
			player.pitch_scale = lerpf(0.8, 1.14, closing)
			if not player.playing and not Sfx.silent(): player.play()
		if elapsed >= 82 and elapsed - delta < 82:
			Sfx.play_at("sfx_m1_roar", -6, 1.05, -1)
			Sfx.play_at("sfx_m1_growl", -6, 1.1, 1)
	if elapsed >= 85:
		veil.color.a = 1
		phase = "finale"
		run.flower_triggered.emit()
	elif danger >= 1:
		phase = "caught"
		Sfx.play("sfx_capture", -8)
		advance_map(0, 0)

func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo: return
	if phase == "night":
		if event.physical_keycode == KEY_A: facing = -1
		elif event.physical_keycode == KEY_D: facing = 1
	elif phase == "caught" and event.physical_keycode == KEY_ENTER:
		veil.color.a = 0
		closing_left.stop()
		closing_right.stop()
		elapsed = 0
		danger = 0.22
		facing = 1
		monster_side = -1
		switch_clock = 0
		roar_clock = 0
		scare_count = 0
		next_scare = 7.5
		scare_active = false
		scare_face.hide()
		run.model.x = distance_on_entry
		phase = "night"
		age = 0
		Sfx.loop("amb_clock", true, -26)

func trigger_scare() -> void:
	scare_active = true
	scare_age = 0
	scare_count += 1
	scare_face.position = Vector2(100 if monster_side < 0 else 1050, 80)
	scare_face.pivot_offset = scare_face.size * 0.5
	scare_face.scale = Vector2.ONE * 0.85
	scare_face.modulate.a = 0.45 if GameState.settings.reduce_scares else 1
	scare_face.show()
	Sfx.play_at("sfx_title_laugh", -19 if GameState.settings.reduce_scares else -7, 1.0, monster_side)

func update_scare(delta: float) -> void:
	if not scare_active: return
	scare_age += delta
	var duration: float = 0.65 if GameState.settings.reduce_scares else 0.28
	var t: float = clampf(scare_age / duration, 0, 1)
	scare_face.scale = Vector2.ONE * lerpf(0.85, 1.18, t)
	scare_face.modulate.a = (0.45 if GameState.settings.reduce_scares else 1.0) * (1 - t)
	if t >= 1 or phase != "night":
		scare_active = false
		scare_face.hide()
