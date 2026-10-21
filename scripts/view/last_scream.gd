class_name LastScream
extends Control
signal finished
const CENTER := Vector2(960, 540)
const MINA_RECT := Rect2(856, 396, 208, 288)
const WORD_ORIGINS := [Vector2(180, 200), Vector2(960, 70), Vector2(1740, 200), Vector2(1860, 540), Vector2(1740, 780), Vector2(960, 810), Vector2(180, 780), Vector2(60, 540)]
const SHOUT_SECONDS := 2.2
var phase := "roar"
var embedded := false
var light_reveal := 0.0
var roar_player: AudioStreamPlayer
var invitation := "They had never heard your voice, is it not?"
var age := 0.0
var quiet := 0.0
var charge := 0.0
var hits := 0
var radius := 0.055
var pulse := 0.0
var title: Label
var caption: Label
var hint: Label
var mina: TextureRect
var beast: TextureRect
var shade: ColorRect
var flash: ColorRect
var bedroom: TextureRect
var phone: Panel
var breath_clock := 0.0
var ended := false
var intro_black: ColorRect
var scream_bar: ProgressBar
var damage_bar: ProgressBar
var meter_label: Label
var meter_threshold: ColorRect
var scream_played := false
var replies := ["I deserve to be heard.", "I can be afraid and still stand.", "My voice matters."]
var idle_frames: Array[Texture2D] = []
var beast_frames: Array[Texture2D] = []
var enemies: Array[TextureRect] = []
var taunt: ScreamTaunt
var taunt_cloud: Array[ScreamTaunt] = []
var taunts := ["Nobody wants to hear you.", "You're always so afraid.", "Your voice doesn't matter."]
var heartbeat: AudioStreamPlayer
var dream_ending: DreamMessageEnding

func _ready() -> void:
	theme = GameState.ui_theme
	Sfx.stop_all()
	PostFX.stress = 0
	if not embedded: GameState.world_real = 0
	# Embedded mode preserves the live RunView map beneath this overlay.
	if not embedded:
		UIFactory.texture(self, "run_bg_far_real", Rect2(0, 0, 1920, 1080))
		UIFactory.texture(self, "run_bg_mid_real", Rect2(0, 0, 1920, 1080))
	beast_frames = ArtRegistry.frames("m1_wall", "m1_wall")
	for i in range(3):
		var enemy := UIFactory.texture(self, "m1_wall", Rect2([5, 1465, 760][i], [180, 180, -220][i], 400, 640))
		enemy.texture = beast_frames[0]
		enemy.size = Vector2(400, 640)
		enemies.append(enemy)
	beast = enemies[0]
	idle_frames = ArtRegistry.frames("mina_idle_real", "mina_idle")
	mina = UIFactory.texture(self, "mina_idle_real", MINA_RECT)
	mina.size = MINA_RECT.size
	mina.flip_h = true
	shade = ColorRect.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mat := ShaderMaterial.new()
	mat.shader = preload("res://shaders/matchlight.gdshader")
	mat.set_shader_parameter("center_uv", Vector2(0.5, 0.5))
	mat.set_shader_parameter("radius", radius)
	shade.material = mat
	add_child(shade)
	var tendrils := Control.new()
	tendrils.set_script(preload("res://scripts/view/scream_memories.gd"))
	tendrils.set("finale", self)
	add_child(tendrils)
	for i in range(8):
		var incoming := ScreamTaunt.new()
		incoming.position = WORD_ORIGINS[i]
		incoming.hide()
		add_child(incoming)
		taunt_cloud.append(incoming)
	taunt = taunt_cloud[0]
	bedroom = UIFactory.texture(self, "bedroom_day", Rect2(0, 0, 1920, 1080))
	bedroom.hide()
	flash = ColorRect.new()
	flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	flash.color = Color(1, 1, 1, 0)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(flash)
	title = UIFactory.label(self, "", Rect2(300, 110, 1320, 110), 64, Color.WHITE)
	caption = UIFactory.label(self, "", Rect2(210, 825, 1500, 100), 36, Color.WHITE)
	hint = UIFactory.label(self, "", Rect2(250, 982, 1420, 65), 24, Color("c4bfc8"))
	title.text = ""
	caption.text = ""
	hint.text = ""
	intro_black = ColorRect.new()
	intro_black.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	intro_black.color = Color.BLACK
	intro_black.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(intro_black)
	build_scream_meter()
	heartbeat = AudioStreamPlayer.new()
	heartbeat.stream = Sfx.get_stream("amb_final_heartbeat")
	heartbeat.volume_db = -18
	add_child(heartbeat)
	roar_player = AudioStreamPlayer.new()
	roar_player.stream = Sfx.next_monster_roar()
	roar_player.volume_db = -16
	add_child(roar_player)
	roar_player.finished.connect(func() -> void:
		if phase == "roar":
			roar_player.stream = Sfx.next_monster_roar()
			if not Sfx.silent(): roar_player.play())
	if not Sfx.silent(): roar_player.play()

func enter(next: String) -> void:
	phase = next
	age = 0
	quiet = 0
	charge = 0
	if phase == "auto_scream":
		scream_played = true
		roar_player.stop()
		Sfx.play("sfx_mina_fear_scream", -12)
	elif phase == "player_light":
		intro_black.color.a = 1
		set_meter_visible(true)
		caption.text = ""
		hint.text = "SCREAM. Let your voice bring back the light."
		if not Sfx.silent(): heartbeat.play()
	elif phase == "invitation":
		caption.text = ""
		hint.text = "Your voice is the light."
	elif phase == "voice":
		set_meter_visible(true)
		caption.text = ""
		hint.text = "Raise your voice. Shatter their words."
		for i in range(taunt_cloud.size()):
			taunt_cloud[i].reset(taunts[hits])
			taunt_cloud[i].position = WORD_ORIGINS[i]
			taunt_cloud[i].show()
	elif phase == "reply":
		caption.text = replies[hits - 1]
		hint.text = ""
		set_meter_visible(false)
	elif phase == "white":
		set_meter_visible(false)
		heartbeat.stop()
		Sfx.stop_all()
		Sfx.play("sfx_all_clear", -14)
		caption.text = ""
		hint.text = ""
	elif phase == "wake":
		dream_ending = DreamMessageEnding.new()
		dream_ending.finished.connect(func() -> void: finished.emit())
		add_child(dream_ending)

func _process(delta: float) -> void:
	if dream_ending != null: return
	age += delta
	pulse = maxf(0, pulse - delta * 0.65)
	if phase in ["auto_scream", "player_light", "invitation", "voice", "reply"]:
		mina.texture = idle_frames[0]
		mina.position.y = MINA_RECT.position.y + sin(age * 9) * (2 if hits == 0 else 0.5)
	quiet = 0.0 if VoiceInput.is_audible else quiet + delta
	update_scream_meter(delta)
	if phase == "roar":
		roar_player.volume_db = lerpf(-16, -5, minf(age / 7.5, 1))
		if age >= 7.5: enter("auto_scream")
	elif phase == "auto_scream":
		# The pre-recorded cry briefly reveals her in proportion to its envelope.
		var envelope: float = sin(clampf(age / 1.8, 0, 1) * PI)
		intro_black.color.a = 1 - envelope * 0.65
		radius = 0.05 + envelope * 0.12
		if age >= 1.8: enter("player_light")
	elif phase == "player_light":
		var intensity: float = clampf(VoiceInput.level01, 0, 1)
		if VoiceInput.is_shouting:
			light_reveal = minf(1, light_reveal + delta * 0.19 * maxf(0.5, intensity))
		intro_black.color.a = 1 - light_reveal
		radius = lerpf(radius, 0.03 + light_reveal * 0.12 + intensity * 0.09, minf(1, delta * 3))
		if light_reveal >= 1: enter("invitation")
	elif phase == "invitation":
		caption.text = invitation.left(int(age * 14))
		radius = lerpf(radius, 0.22, minf(1, delta))
		if age >= 7: enter("voice")
	elif phase == "voice":
		charge = minf(1, charge + delta / SHOUT_SECONDS) if VoiceInput.is_shouting else maxf(0, charge - delta * 0.12)
		for i in range(taunt_cloud.size()):
			var incoming: ScreamTaunt = taunt_cloud[i]
			incoming.damage = charge
			var travel: float = fposmod(maxf(0, age - i * 0.22), 7.0) / 7.0
			incoming.position = WORD_ORIGINS[i].lerp(CENTER, travel)
			incoming.modulate.a = minf(1, maxf(0, age - i * 0.28) / 2.2) * 0.9 * (1 - smoothstep(0.78, 1.0, travel))
		heartbeat.volume_db = -10
		heartbeat.pitch_scale = 1.05 + charge * 0.2
		hint.text = "SCREAM — BREAK THEIR WORDS" if VoiceInput.is_shouting else "LOUDER. SCREAM to break the words."
		for i in range(hits, enemies.size()): enemies[i].texture = MonsterAnimation.at_time(age, GameState.balance.level_view.m1_fps)
		radius = lerpf(radius, 0.18 + hits * 0.06 + (VoiceInput.level01 * 0.16 if VoiceInput.is_shouting else 0), minf(1, delta * 4))
		if charge >= 1:
			hits += 1
			pulse = 1
			enemies[hits - 1].modulate.a = 0
			for incoming in taunt_cloud: incoming.shattered = true
			Sfx.play("sfx_wall_break", -16, 0.85 + hits * 0.1)
			enter("reply")
	elif phase == "reply":
		heartbeat.volume_db = -17
		heartbeat.pitch_scale = 0.9
		radius = lerpf(radius, 0.22 + hits * 0.08, minf(1, delta * 2))
		if age >= 3.2 and (quiet >= 0.6 or hits >= 3): enter("white" if hits >= 3 else "voice")
	elif phase == "white":
		if age >= 1.4:
			for incoming in taunt_cloud: incoming.hide()
		flash.color.a = minf(1, age / 2.5)
		if age >= 3.5: enter("wake")
	(shade.material as ShaderMaterial).set_shader_parameter("radius", radius + pulse * 0.2)
	if GameState.settings.keyboard_mode and phase in ["player_light", "voice"]: hint.text = "Hold SPACE to SCREAM. Release to breathe."

func build_scream_meter() -> void:
	meter_label = UIFactory.label(self, "", Rect2(620, 865, 680, 38), 23, Color("ffe3ac"))
	var back := StyleBoxFlat.new()
	back.bg_color = Color("282331")
	back.set_corner_radius_all(8)
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color("ffe1a1")
	fill.set_corner_radius_all(8)
	scream_bar = ProgressBar.new()
	scream_bar.position = Vector2(620, 914)
	scream_bar.size = Vector2(680, 24)
	scream_bar.max_value = 1
	scream_bar.show_percentage = false
	scream_bar.add_theme_stylebox_override("background", back)
	scream_bar.add_theme_stylebox_override("fill", fill)
	add_child(scream_bar)
	meter_threshold = ColorRect.new()
	meter_threshold.position = Vector2(1096, 907)
	meter_threshold.size = Vector2(3, 38)
	meter_threshold.color = Color.WHITE
	add_child(meter_threshold)
	damage_bar = ProgressBar.new()
	damage_bar.position = Vector2(620, 948)
	damage_bar.size = Vector2(680, 5)
	damage_bar.max_value = 1
	damage_bar.show_percentage = false
	damage_bar.add_theme_stylebox_override("background", back.duplicate())
	damage_bar.add_theme_stylebox_override("fill", fill.duplicate())
	add_child(damage_bar)
	set_meter_visible(false)

func set_meter_visible(value: bool) -> void:
	for node in [scream_bar, damage_bar, meter_label, meter_threshold]: node.visible = value

func update_scream_meter(delta: float) -> void:
	var thresholds: Array[float] = VoiceInput.model.thresholds()
	var floor_db: float = VoiceInput.model.floor_db
	var volume: float = clampf((VoiceInput.db - floor_db) / maxf(1, thresholds[2] - floor_db) * 0.7, 0, 1)
	scream_bar.value = move_toward(scream_bar.value, volume, delta * 4)
	damage_bar.value = charge
	meter_label.text = "SCREAM — THEIR WORDS ARE BREAKING" if VoiceInput.is_shouting else "YOUR VOICE  →  SCREAM"

