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
var gate_state := ""
var gate_left := 0.0
var gate_x := 0.0
var jump_progress := 0.0
# Vocal-health guard; the view turns it off in keyboard mode (holding Space is not a throat).
var guard_enabled := true

func enter_gate(edge: float, shouting: bool = false) -> String:
	gate_x = edge
	x = edge
	# Shouting at the edge always jumps once Mina is moving at a jog or faster.
	if speed >= balance.speed_gate.min_speed or (shouting and speed >= balance.speed_gate.assist_speed):
		gate_state = "jumping"
		gate_left = balance.speed_gate.jump_s
		jump_progress = 0.0
	else:
		gate_state = "stumbling"
		gate_left = balance.speed_gate.stumble_s
		speed = 0.0
		acceleration_rate = 0.0
	return gate_state

func _init(config: Dictionary) -> void:
	balance = config

func scripted_scare() -> void:
	scare_age = 0.0

func step(delta: float, target: float, shouting: bool) -> void:
	var old_x := x
	if shouting:
		shouting_s += delta
		quiet_s = 0.0
		if guard_enabled and shouting_s >= balance.throat_guard.after_s:
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
	if not gate_state.is_empty():
		gate_left = maxf(0.0, gate_left - delta)
		match gate_state:
			"jumping":
				jump_progress = 1.0 - gate_left / balance.speed_gate.jump_s
				if gate_left <= 0.0:
					x = maxf(x, gate_x + balance.speed_gate.width_m)
					gate_state = ""
			"stumbling":
				x = old_x
				speed = 0.0
				acceleration_rate = 0.0
				if gate_left <= 0.0:
					gate_state = "climbing"
					gate_left = balance.speed_gate.climb_s
			"climbing":
				x = lerpf(gate_x, gate_x + balance.speed_gate.width_m, 1.0 - gate_left / balance.speed_gate.climb_s)
				speed = balance.speed_gate.width_m / balance.speed_gate.climb_s
				if gate_left <= 0.0:
					gate_state = ""
					speed = 0.0
					acceleration_rate = 0.0

func reset_position(value: float) -> void:
	x = value
	speed = 0.0
	shouting_s = 0.0
	quiet_s = 0.0
	guarded = false
	bonus_left = 0.0
	scare_age = INF
	was_shouting = false
	acceleration_rate = 0.0
	previous_target = 0.0
	gate_state = ""
	gate_left = 0.0
	jump_progress = 0.0
