class_name LevelModel
extends RefCounted

var balance: Dictionary
var level: LevelData
var run: RunModel
var director: MonsterDirector
var section := "S1"
var status := "running"
var time := 0.0
var clock := 0.0
var cursor := 0
var hidden := false
var checkpoint: Dictionary = {}
var safe_id := ""
var flow := 0.0 # Snapshot slot; the R3 flow system has not been added.
var seen_scares: Dictionary = {}
var bridge_progress := 0.0
var bridge_ready := false
var bridge_waiting := false
var status_age := 0.0
var finale_hits := 0
var finale_start := 0.0
var last_call_bar := -1
var last_hit_bar := -1
var surge_left := 0.0
var was_shouting := false
var messages: Array[Dictionary] = []

func _init(config: Dictionary, data: Dictionary) -> void:
	balance = config
	level = LevelData.new(data)
	run = RunModel.new(config)
	director = MonsterDirector.new(config)
	run.x = level.first("section").x
	section = level.section_at(run.x)
	checkpoint = {"event": level.first("checkpoint"), "flow": flow, "flags": {}}

func step(delta: float, target: float, shouting: bool, audible: bool, tier: int, clock_time: float = -1.0) -> void:
	messages.clear()
	var left := delta
	var start_clock := clock if clock_time < 0.0 else clock_time - delta
	var advanced := 0.0
	while left > 0.000001 and status != "complete":
		var dt: float = minf(left, balance.simulation.max_step_s)
		advanced += dt
		clock = start_clock + advanced
		time += dt
		step_once(dt, target, shouting, audible, tier)
		left -= dt

func step_once(delta: float, target: float, shouting: bool, audible: bool, tier: int) -> void:
	if status != "running":
		status_age += delta
		director.time += delta
		if status == "captured" and status_age >= balance.respawn.capture_anim_s:
			status = "fading"
			status_age = 0.0
		elif status == "fading" and status_age >= balance.respawn.fade_s:
			respawn()
		elif status == "flash" and status_age >= balance.finale.flash_s:
			status = "complete"
			messages.append({"type": "ending"})
		return
	var old_x := run.x
	run.step(delta, target, shouting)
	var bridge: Dictionary = level.first("bridge")
	bridge_waiting = not bridge_ready and run.x >= bridge.x
	if bridge_waiting:
		run.x = bridge.x
		run.speed = 0.0
		run.acceleration_rate = 0.0
		if tier >= 2:
			bridge_progress = minf(1.0, bridge_progress + delta / (balance.bar_s * balance.s1.bridge_bars))
			if bridge_progress >= 1.0:
				bridge_ready = true
				messages.append({"type": "bridge"})
	if surge_left > 0.0:
		var portion := minf(delta, surge_left)
		run.x += balance.finale.surge_m * portion / balance.finale.surge_s
		surge_left -= portion
	director.in_safe = not level.checkpoint_at(run.x, balance.safe_zone.half_width_m).is_empty()
	process_events()
	var safe := level.checkpoint_at(run.x, balance.safe_zone.half_width_m)
	if not safe.is_empty():
		if safe.id != safe_id:
			save_checkpoint(safe)
			messages.append({"type": "safe"})
		safe_id = safe.id
	else:
		safe_id = ""
	hidden = level.covered(run.x, run.speed, balance) and run.gate_state.is_empty()
	director.step(delta, run.x - old_x, section, not safe.is_empty(), hidden, audible, clock)
	for event in director.events:
		messages.append({"type": event})
	if director.captured:
		status = "captured"
		status_age = 0.0
		hidden = false
		run.speed = 0.0
	elif section == "S5" and status == "running":
		step_finale(shouting)
	was_shouting = shouting

func process_events() -> void:
	while cursor < level.events.size() and level.events[cursor].x <= run.x:
		var event: Dictionary = level.events[cursor]
		cursor += 1
		match event.type:
			"section":
				section = event.id
				messages.append({"type": "section", "id": section})
				if section == "S2" and not director.active:
					director.spawn()
			"gate":
				var action := run.enter_gate(event.x)
				messages.append({"type": action})
			"gaze":
				director.request_gaze(event, clock)
				if event.has("subtitle"):
					messages.append({"type": "subtitle", "key": event.subtitle})
			"subtitle":
				messages.append(event)
			"finale":
				director.begin_finale()
				finale_start = time
				last_call_bar = int(floor(clock / balance.bar_s))
				messages.append({"type": "subtitle", "key": "finale_subtitle"})
			"door":
				finish_run()
		# song_cut, face_slam, scare decorations: R3 presentation hooks, not played in R2.

func save_checkpoint(event: Dictionary) -> void:
	checkpoint = {"event": event.duplicate(), "flow": flow, "flags": seen_scares.duplicate()}

func respawn() -> void:
	var event: Dictionary = checkpoint.event
	run.reset_position(event.x)
	section = level.section_at(event.x)
	flow = checkpoint.flow
	seen_scares.merge(checkpoint.flags)
	cursor = 0
	while cursor < level.events.size() and level.events[cursor].x <= event.x:
		cursor += 1
	director.active = section != "S1"
	director.finale = section == "S5"
	director.respawn(event.get("respawn_gap", balance.m1.respawn_gap))
	bridge_ready = event.x > level.first("bridge").x
	bridge_progress = 1.0 if bridge_ready else 0.0
	bridge_waiting = false
	hidden = false
	safe_id = ""
	surge_left = 0.0
	status = "running"
	status_age = 0.0
	was_shouting = false
	messages.append({"type": "respawn"})

func step_finale(shouting: bool) -> void:
	var bar := int(floor(clock / balance.bar_s))
	if bar != last_call_bar:
		last_call_bar = bar
		messages.append({"type": "beat_call"})
	if shouting and not was_shouting:
		var closest := int(floor((clock + balance.finale.window_early_s) / balance.bar_s))
		var offset: float = clock - closest * balance.bar_s
		if closest != last_hit_bar and offset >= -balance.finale.window_early_s - 0.000001 and offset <= balance.finale.window_late_s + 0.000001:
			last_hit_bar = closest
			finale_hits += 1
			surge_left = balance.finale.surge_s
			messages.append({"type": "surge"})
			if finale_hits >= balance.finale.hits:
				run.x = level.first("door").x
				finish_run()

func finish_run() -> void:
	if status != "running":
		return
	status = "flash"
	run.x = level.first("door").x
	status_age = 0.0
	messages.append({"type": "flash"})
