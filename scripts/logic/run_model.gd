class_name RunModel
extends RefCounted

var balance: Dictionary
var x := 0.0
var speed := 0.0
var shouting_s := 0.0
var quiet_s := 0.0
var guarded := false
var bonus_left := 0.0
var scare_age := INF
var was_shouting := false
var acceleration_rate := 0.0
var previous_target := 0.0

func _init(config: Dictionary) -> void:
	balance = config

func scripted_scare() -> void:
	scare_age = 0.0

func step(delta: float, target: float, shouting: bool) -> void:
	if shouting:
		shouting_s += delta
		quiet_s = 0.0
		if shouting_s >= balance.throat_guard.after_s:
			guarded = true
	else:
		quiet_s += delta
		shouting_s = 0.0
		if quiet_s >= balance.throat_guard.reset_s:
			guarded = false
	if shouting and not was_shouting and scare_age <= balance.instinct_bonus.window_s:
		bonus_left = balance.instinct_bonus.duration_s
		# A scare can award the bonus once.
		scare_age = INF
	was_shouting = shouting
	scare_age += delta
	if guarded:
		target = minf(target, balance.throat_guard.cap)
	if bonus_left > 0.0:
		target *= balance.instinct_bonus.mult
		bonus_left = maxf(0.0, bonus_left - delta)
	var old_speed := speed
	if target > speed:
		if not is_equal_approx(target, previous_target) or acceleration_rate <= 0.0:
			acceleration_rate = (target - speed) / balance.accel_s
		speed = minf(target, speed + acceleration_rate * delta)
	else:
		acceleration_rate = 0.0
		speed = target + (speed - target) * pow(0.5, delta / balance.decel_half_life_s)
	previous_target = target
	x += (old_speed + speed) * 0.5 * delta
