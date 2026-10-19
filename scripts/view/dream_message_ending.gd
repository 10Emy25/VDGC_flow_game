class_name DreamMessageEnding
extends Control
signal finished
var phase := "wake"
var age := 0.0
var choice := ""
var sent_reply := false
var mina: TextureRect
var subtitle: Label
var phone: Panel
var first_message: Label
var second_message: Label
var reply_message: Label
var choice_ok: Button
var choice_silence: Button
var white: ColorRect
var dim: ColorRect
var sticker: FlowerSticker
var replay: Button
var sticker_origin := Vector2(1460, 690)

func _ready() -> void:
	theme = GameState.ui_theme
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	UIFactory.texture(self, "bedroom_day", Rect2(0, 0, 1920, 1080))
	mina = UIFactory.texture(self, "bed_mina_awake", Rect2(180, 340, 1460, 580))
	mina.size = Vector2(1460, 580)
	subtitle = UIFactory.label(self, "", Rect2(260, 70, 1400, 100), 38, Color("453f50"))
	subtitle.text = ""
	build_phone()
	dim = ColorRect.new()
	dim.size = Vector2(1920, 1080)
	dim.color = Color(0, 0, 0, 0)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)
	sticker = FlowerSticker.new()
	sticker.position = sticker_origin
	sticker.scale = Vector2.ONE * 0.72
	sticker.hide()
	add_child(sticker)
	white = ColorRect.new()
	white.size = Vector2(1920, 1080)
	white.color = Color.WHITE
	white.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(white)
	Sfx.stop_all()
	Sfx.play("sfx_mina_exhale", -17)

func build_phone() -> void:
	phone = Panel.new()
	phone.position = Vector2(1140, 170)
	phone.size = Vector2(650, 750)
	var style := StyleBoxFlat.new()
	style.bg_color = Color("fcf7ec")
	style.border_color = Color("323442")
	style.set_border_width_all(7)
	style.set_corner_radius_all(30)
	phone.add_theme_stylebox_override("panel", style)
	add_child(phone)
	UIFactory.label(phone, "", Rect2(30, 20, 590, 70), 29, Color("45404e")).text = "BEST FRIEND"
	first_message = message("Mina...I am really worried", Rect2(35, 115, 580, 95))
	second_message = message("pls call me", Rect2(35, 230, 580, 70))
	reply_message = message("OK", Rect2(370, 320, 235, 60))
	reply_message.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	choice_ok = UIFactory.button(phone, "", Rect2(40, 340, 260, 65), func() -> void: choose("OK"))
	choice_ok.text = "OK"
	choice_silence = UIFactory.button(phone, "", Rect2(350, 340, 260, 65), func() -> void: choose("..."))
	choice_silence.text = "..."
	for node in [first_message, second_message, reply_message, choice_ok, choice_silence]: node.hide()
	phone.hide()

func message(text: String, rect: Rect2) -> Label:
	var label := UIFactory.label(phone, "", rect, 29, Color("3c3947"))
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var backing := StyleBoxFlat.new()
	backing.bg_color = Color("e7e9e2")
	backing.set_corner_radius_all(14)
	backing.content_margin_left = 18
	backing.content_margin_right = 18
	label.add_theme_stylebox_override("normal", backing)
	return label

func enter(next: String) -> void:
	phase = next
	age = 0
	match phase:
		"ring":
			subtitle.text = ""
			Sfx.play("sfx_phone", -13)
		"first_message":
			mina.texture = ArtRegistry.get_texture("bed_mina_phone")
			phone.show()
			first_message.show()
		"second_message": second_message.show()
		"choice":
			choice_ok.show()
			choice_silence.show()
		"flower":
			sticker.show()
			sticker.morph = 0
			sticker.scale = Vector2.ONE * 0.72
			Sfx.play("sfx_phone", -19)
		"zoom": Sfx.loop("mus_flower_nightmare", true, -32)
		"ghost": Sfx.play("sfx_capture", -13)
		"black":
			sticker.hide()
			dim.color.a = 1
			Sfx.set_loop_volume("mus_flower_nightmare", -45, 1.2)

func choose(value: String) -> void:
	if phase != "choice" or value not in ["OK", "..."]: return
	choice = value
	choice_ok.hide()
	choice_silence.hide()
	sent_reply = value == "OK"
	reply_message.visible = sent_reply
	enter("after_choice")

func _process(delta: float) -> void:
	age += delta
	match phase:
		"wake":
			mina.position.y = 340 - sin(minf(age / 0.45, 1) * PI) * 8
			white.color.a = maxf(0, 1 - age / 1.2)
			if age >= 1.3 and subtitle.text == "":
				subtitle.text = "It is just a dream.."
				Sfx.play("sfx_just_a_dream", -16)
			if age >= 5: enter("ring")
		"ring":
			if age >= 0.45: mina.texture = ArtRegistry.get_texture("bed_mina_reach")
			if age >= 1.6: enter("first_message")
		"first_message":
			if age >= 1.8: enter("second_message")
		"second_message":
			if age >= 1.1: enter("choice")
		"after_choice":
			if age >= 1: enter("flower")
		"flower":
			if age >= 3: enter("zoom")
		"zoom":
			var t: float = clampf(age / 10, 0, 1)
			var ease: float = t * t * (3 - 2 * t)
			sticker.position = sticker_origin.lerp(Vector2(960, 540), ease)
			sticker.scale = Vector2.ONE * lerpf(0.72, 8.5, ease)
			sticker.morph = smoothstep(0.45, 1, t)
			dim.color.a = smoothstep(0.2, 0.8, t) * 0.94
			Sfx.loop("mus_flower_nightmare", true, lerpf(-32, -9, t))
			if age >= 10: enter("ghost")
		"ghost":
			sticker.morph = 1
			if not GameState.settings.reduce_scares:
				sticker.position = Vector2(960, 540) + Vector2(sin(age * 37), cos(age * 43)) * 3
			if age >= 2.3: enter("black")
		"black":
			if age >= 2.4:
				Sfx.loop("mus_flower_nightmare", false)
				phase = "done"
				replay = UIFactory.button(self, "", Rect2(760, 850, 400, 70), restart)
				replay.text = "Play again"

func restart() -> void:
	if phase != "done": return
	Sfx.stop_all()
	finished.emit()
