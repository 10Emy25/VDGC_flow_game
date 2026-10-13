class_name Calibration
extends RefCounted

var balance: Dictionary

func _init(config: Dictionary) -> void:
	balance = config

func percentile(samples: Array[float], fraction: float, fallback: float) -> float:
	if samples.is_empty():
		return fallback
	var sorted := samples.duplicate()
	sorted.sort()
	# Nearest-rank percentile, including the endpoints.
	return sorted[clampi(int(ceil(fraction * sorted.size())) - 1, 0, sorted.size() - 1)]

func evaluate(silence: Array[float], talk: Array[float], shout: Array[float]) -> Dictionary:
	var rules: Dictionary = balance.calibration
	var defaults: Dictionary = balance.calibration_defaults
	var floor_value := percentile(silence, rules.floor_percentile, defaults.floor_db)
	var audible: Array[float] = []
	for value in talk:
		if value > floor_value + rules.talk_margin_db:
			audible.append(value)
	var talk_value := percentile(audible, rules.talk_percentile, floor_value)
	var shout_value: float = shout.max() if not shout.is_empty() else floor_value
	if talk_value < floor_value + rules.talk_margin_db:
		talk_value = floor_value + rules.talk_fallback_db
	var retry: bool = shout_value < talk_value + rules.shout_margin_db
	if retry:
		shout_value = talk_value + rules.shout_fallback_db
	return {"floor_db": floor_value, "talk_db": talk_value, "cal_shout_db": shout_value, "retry": retry}

func defaults() -> Dictionary:
	var result: Dictionary = balance.calibration_defaults.duplicate()
	result.retry = false
	return result
