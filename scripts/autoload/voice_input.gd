extends Node

var model: VoiceModel
var capture: AudioEffectCapture
var microphone: AudioStreamPlayer
var db := 0.0
var mic_db := 0.0
var speed_target := 0.0
var is_audible := false
var is_shouting := false
var level01 := 0.0
var tier := "QUIET"
var missing_microphone := false
var silence_s := 0.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	model = VoiceModel.new(GameState.balance)
	db = model.rms_db(PackedVector2Array())
	mic_db = db
	var config := ConfigFile.new()
	if config.load("user://voice_calibration.cfg") == OK:
		var defaults: Dictionary = GameState.balance.calibration_defaults
		set_calibration(config.get_value("voice", "floor_db", defaults.floor_db), config.get_value("voice", "talk_db", defaults.talk_db), config.get_value("voice", "cal_shout_db", defaults.cal_shout_db), false)
	var bus := AudioServer.get_bus_index("Mic")
	if bus < 0:
		AudioServer.add_bus()
		bus = AudioServer.bus_count - 1
		AudioServer.set_bus_name(bus, "Mic")
	capture = AudioEffectCapture.new()
	AudioServer.add_bus_effect(bus, capture, 0)
	AudioServer.set_bus_volume_db(bus, GameState.balance.audio.mic_mute_db)
	AudioServer.set_bus_mute(bus, true)
	microphone = AudioStreamPlayer.new()
	microphone.stream = AudioStreamMicrophone.new()
	microphone.bus = "Mic"
	microphone.process_mode = Node.PROCESS_MODE_ALWAYS
	# The Dummy driver has no recording device. Keep the silent fallback active in tests.
	microphone.autoplay = AudioServer.get_driver_name() != "Dummy"
	add_child(microphone)

func _exit_tree() -> void:
	if is_instance_valid(microphone):
		microphone.stop()
	var bus := AudioServer.get_bus_index("Mic")
	if bus >= 0:
		AudioServer.remove_bus(bus)
	capture = null

func _process(delta: float) -> void:
	var available := capture.get_frames_available()
	var frames := capture.get_buffer(available) if available > 0 else PackedVector2Array()
	mic_db = model.smooth(mic_db, model.rms_db(frames), delta)
	if mic_db <= GameState.balance.voice.missing_db:
		silence_s += delta
	else:
		silence_s = 0.0
	missing_microphone = silence_s >= GameState.balance.voice.missing_s
	model.sensitivity_db = GameState.settings.sensitivity_db
	db = model.keyboard_db(Input.is_physical_key_pressed(KEY_SPACE), Input.is_physical_key_pressed(KEY_CTRL), Input.is_physical_key_pressed(KEY_SHIFT)) if GameState.settings.keyboard_mode else mic_db
	var state := model.sample(db)
	speed_target = state.speed_target
	is_audible = state.is_audible
	is_shouting = state.is_shouting
	level01 = state.level01
	tier = state.tier

func set_calibration(floor_value: float, talk_value: float, shout_value: float, save: bool = true) -> void:
	model.set_calibration(floor_value, talk_value, shout_value)
	if save:
		var config := ConfigFile.new()
		config.set_value("voice", "floor_db", floor_value)
		config.set_value("voice", "talk_db", talk_value)
		config.set_value("voice", "cal_shout_db", shout_value)
		config.save("user://voice_calibration.cfg")
