class_name MonsterDirector
extends RefCounted

var balance: Dictionary
var gap := 0.0
var active := false
var phase := "IDLE"
var phase_start := 0.0
var phase_end := 0.0
var pending: Dictionary = {}
var scheduled := 0.0
var delayed := false
var gaze_bars := 0
var scripted_first := false
var hearing_count := 0
var heard_s := 0.0
var sight_s := 0.0
var slam_left := 0.0
var beam_offset := 0.0
var time := 0.0
var clock := 0.0
var captured := false
var capture_cause := ""
var last_capture := -INF
var invulnerable_left := 0.0
var no_scare_left := 0.0
var grace_left := 0.0
var safe_hold_left := 0.0
var post_slow_left := 0.0
var first_freeze_left := 0.0
var in_safe := false
var was_safe := false
var finale := false
var lunge_left := 0.0
var last_lunge_bar := -1
var last_tell_bar := -1
var events: Array[String] = []

func _init(config: Dictionary) -> void:
	balance = config
	gap = balance.m1.spawn_gap

func spawn() -> void:
	active = true
	gap = balance.m1.spawn_gap
	grace_left = balance.m1.spawn_grace_s

func next_bar(value: float) -> float:
	return (floor(value / balance.bar_s) + 1.0) * balance.bar_s

func request_gaze(event: Dictionary, clock_time: float) -> void:
	if finale or not pending.is_empty() or phase != "IDLE":
		return
	pending = event.duplicate()
	gaze_bars = int(event.bars)
	scripted_first = event.get("scripted_first", false)
	delayed = false
	scheduled = next_bar(clock_time)
	# Warning starts at the next bar as specified. Tell occupies the remaining trigger bar.
	if not in_safe and no_scare_left <= 0.0:
		change_phase("TELL", clock_time, scheduled - clock_time)

func gaze_decision(bars: int, already_delayed: bool) -> Dictionary:
	var minimum: float = balance.m1.gaze_speed * bars * balance.bar_s + balance.m2.safety_margin_m
	if gap >= minimum:
		return {"action": "start", "bars": bars}
	if not already_delayed:
		return {"action": "delay", "bars": bars}
	var available := int(floor((gap - balance.m2.safety_margin_m) / balance.m1.gaze_speed / balance.bar_s))
	if available < 1:
		return {"action": "skip", "bars": 0}
	return {"action": "start", "bars": mini(bars, available)}

func reset_hearing() -> void:
	hearing_count = 0
	heard_s = 0.0
	slam_left = 0.0

func m1_speed(section: String) -> float:
	if not active or in_safe or grace_left > 0.0 or safe_hold_left > 0.0:
		return 0.0
	if finale:
		return balance.m1.base_speed.S5
	if first_freeze_left > 0.0:
		return 0.0
	if eye_busy() or post_slow_left > 0.0:
		return balance.m1.gaze_speed
	var base: float = balance.m1.base_speed.get(section, 0.0)
	if lunge_left > 0.0:
		base += balance.m1.lunge_m / balance.m1.lunge_s
	return base

# The wall fears the eye: it holds still from the first tell until the eye has closed.
func eye_busy() -> bool:
	return phase in ["TELL", "WARNING", "GAZE", "RECEDE"]

func can_lunge() -> bool:
	return active and not finale and not in_safe and not eye_busy() and grace_left <= 0.0 and safe_hold_left <= 0.0 and post_slow_left <= 0.0 and first_freeze_left <= 0.0 and invulnerable_left <= 0.0

# Every N bars the wall roars on the downbeat and lunges forward. One beat earlier it growls.
func update_lunge(delta: float) -> void:
	lunge_left = maxf(0.0, lunge_left - delta)
	var every: int = int(balance.m1.lunge_every_bars)
	var bar := int(floor(clock / balance.bar_s))
	var beat_s: float = balance.bar_s / balance.beats_per_bar
	var tell_bar := int(floor((clock + beat_s) / balance.bar_s))
	if tell_bar != last_tell_bar and tell_bar % every == 0 and tell_bar > bar:
		last_tell_bar = tell_bar
		if can_lunge():
			events.append("lunge_tell")
	if bar != last_lunge_bar:
		last_lunge_bar = bar
		# A lunge always follows its growl; never an unannounced one.
		if bar % every == 0 and last_tell_bar == bar and can_lunge():
			lunge_left = balance.m1.lunge_s
			events.append("lunge")

func try_capture(cause: String) -> bool:
	if captured or finale or invulnerable_left > 0.0 or time - last_capture < balance.respawn.min_capture_gap_s:
		return false
	captured = true
	capture_cause = cause
	last_capture = time
	events.append("capture")
	return true

func respawn(respawn_gap: float) -> void:
	gap = respawn_gap
	captured = false
	capture_cause = ""
	phase = "IDLE"
	pending.clear()
	invulnerable_left = balance.respawn.invuln_s
	no_scare_left = balance.respawn.no_scare_s
	grace_left = 0.0
	safe_hold_left = 0.0
	post_slow_left = 0.0
	first_freeze_left = 0.0
	lunge_left = 0.0
	was_safe = false
	reset_hearing()
	sight_s = 0.0

func begin_finale() -> void:
	finale = true
	pending.clear()
	phase = "IDLE"
	post_slow_left = 0.0
	gap = maxf(gap, balance.finale.min_gap)

func step(delta: float, distance: float, section: String, safe: bool, hidden: bool, audible: bool, clock_time: float) -> void:
	events.clear()
	time += delta
	clock = clock_time
	in_safe = safe
	invulnerable_left = maxf(0.0, invulnerable_left - delta)
	no_scare_left = maxf(0.0, no_scare_left - delta)
	grace_left = maxf(0.0, grace_left - delta)
	slam_left = maxf(0.0, slam_left - delta)
	first_freeze_left = maxf(0.0, first_freeze_left - delta)
	var was_held := safe_hold_left > 0.0 or post_slow_left > 0.0
	safe_hold_left = maxf(0.0, safe_hold_left - delta)
	post_slow_left = maxf(0.0, post_slow_left - delta)
	if captured:
		return
	if safe:
		gap = maxf(gap, balance.m1.safe_gap)
	elif was_safe:
		safe_hold_left = balance.safe_zone.hold_s
	was_safe = safe
	advance_gaze()
	if active and was_held and safe_hold_left <= 0.0 and post_slow_left <= 0.0 and first_freeze_left <= 0.0 and not safe:
		events.append("roar")
	if active:
		update_lunge(delta)
		gap += distance - m1_speed(section) * delta
		# Keep the wall on screen: outrunning it only buys breathing room up to max_gap.
		gap = minf(gap, balance.m1.max_gap)
		if safe:
			gap = maxf(gap, balance.m1.safe_gap)
		if finale:
			gap = maxf(gap, balance.finale.min_gap)
		elif gap <= 0.0:
			try_capture("m1")
	if phase != "GAZE" or captured:
		return
	var sweep: float = balance.m2.beam_half_range_m
	var travel: float = fposmod((clock - phase_start) * balance.m2.beam_speed, sweep * 4.0)
	beam_offset = -sweep + travel if travel <= sweep * 2.0 else sweep * 3.0 - travel
	if not hidden and absf(beam_offset) <= balance.m2.beam_half_width_m:
		sight_s += delta
		if sight_s + 0.000001 >= balance.m2.sight_s:
			try_capture("sight")
	if slam_left > 0.0:
		heard_s = 0.0
	elif audible:
		heard_s += delta
		if heard_s + 0.000001 >= balance.m2.hear_s:
			heard_s = 0.0
			hearing_count += 1
			if hearing_count == 1:
				slam_left = balance.m2.slam_s
				events.append("slam")
			else:
				try_capture("hearing")
	else:
		heard_s = 0.0

func advance_gaze() -> void:
	if finale:
		return
	if phase == "IDLE" and not pending.is_empty() and clock >= scheduled:
		if in_safe or no_scare_left > 0.0:
			scheduled = next_bar(clock)
		else:
			change_phase("TELL", scheduled, balance.m2.tell_bars * balance.bar_s)
	if phase == "TELL" and clock >= phase_end:
		if in_safe:
			phase_end += balance.bar_s
			return
		change_phase("WARNING", phase_end, balance.m2.warning_bars * balance.bar_s)
	elif phase == "WARNING" and clock >= phase_end:
		if in_safe:
			phase_end += balance.bar_s
			return
		# Evaluate the margin immediately before sight/hearing become active.
		var decision := gaze_decision(gaze_bars, delayed)
		if decision.action == "delay":
			delayed = true
			phase_end += balance.bar_s
			events.append("gaze_delayed")
		elif decision.action == "skip":
			phase = "IDLE"
			pending.clear()
			events.append("gaze_skipped")
		else:
			gaze_bars = decision.bars
			reset_hearing()
			sight_s = 0.0
			change_phase("GAZE", phase_end, gaze_bars * balance.bar_s)
	elif phase == "GAZE" and clock >= phase_end:
		if scripted_first:
			first_freeze_left = balance.m2.first_freeze_s
		change_phase("RECEDE", phase_end, balance.m2.recede_bars * balance.bar_s)
	elif phase == "RECEDE" and clock >= phase_end:
		phase = "IDLE"
		pending.clear()
		post_slow_left = balance.m1.post_gaze_slow_s
		events.append("all_clear")

func change_phase(value: String, start: float, duration: float) -> void:
	phase = value
	phase_start = start
	phase_end = start + duration
	events.append(value.to_lower())
