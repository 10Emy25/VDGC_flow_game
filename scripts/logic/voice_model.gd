class_name VoiceModel
extends RefCounted

var floor_db: float
var talk_db: float
var cal_shout_db: float
var sensitivity_db := 0.0
var balance: Dictionary

func _init(config: Dictionary) -> void:
	balance = config
	var defaults: Dictionary = config.calibration_defaults
	set_calibration(defaults.floor_db, defaults.talk_db, defaults.cal_shout_db)

func set_calibration(floor_value: float, talk_value: float, shout_value: float) -> void:
	floor_db = floor_value
	talk_db = talk_value
	cal_shout_db = shout_value

func thresholds() -> Array[float]:
	return [floor_db + balance.hum_offset_db + sensitivity_db, talk_db + sensitivity_db,
		talk_db + balance.shout_fraction * (cal_shout_db - talk_db) + sensitivity_db]

func sample(value: float) -> Dictionary:
	var t := thresholds()
	var speed := 0.0
	var tier := "QUIET"
	if value >= t[2]:
		speed = balance.speeds.shout
		tier = "SHOUT"
	elif value >= t[1]:
		speed = lerpf(balance.speeds.talk, balance.speeds.shout, (value - t[1]) / (t[2] - t[1]))
		tier = "TALK"
	elif value >= t[0]:
		speed = lerpf(balance.speeds.hum, balance.speeds.talk, (value - t[0]) / (t[1] - t[0]))
		tier = "HUM"
	return {"speed_target": speed, "tier": tier, "is_audible": value >= t[0],
		"is_shouting": value >= t[2], "level01": clampf((value - floor_db) / (cal_shout_db - floor_db), 0.0, 1.0)}

func keyboard_db(shout: bool, talk: bool, hum: bool) -> float:
	var t := thresholds()
	if shout:
		return t[2] + balance.voice.keyboard_offset_db
	if talk:
		return t[1] + balance.voice.keyboard_offset_db
	if hum:
		return t[0] + balance.voice.keyboard_offset_db
	return minf(floor_db, t[0]) - balance.voice.quiet_margin_db

func smooth(previous: float, raw: float, delta: float) -> float:
	var tau: float = balance.voice.attack_s if raw > previous else balance.voice.release_s
	return lerpf(previous, raw, 1.0 - exp(-delta / tau))

func rms_db(frames: PackedVector2Array) -> float:
	if frames.is_empty():
		return 20.0 * log(balance.voice.min_rms) / log(10.0)
	var energy := 0.0
	for frame in frames:
		energy += (frame.x * frame.x + frame.y * frame.y) * 0.5
	return 20.0 * log(maxf(sqrt(energy / frames.size()), balance.voice.min_rms)) / log(10.0)
