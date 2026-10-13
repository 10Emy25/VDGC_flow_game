extends MinaTestSuite

func _ready() -> void:
	for variation in range(8):
		var result := simulate(variation, false)
		check(result.complete, "Rhythmic run %d reaches door: %s" % [variation, result])
		check(result.captures == 0, "Rhythmic run %d avoids capture: %s" % [variation, result])
		check(result.shout_s <= 90, "Rhythmic run %d shout budget: %.2f" % [variation, result.shout_s])
		check(result.gazes == 4, "Run %d visits all four gazes" % variation)
		check(result.gates == LevelData.new(GameState.level).of_type("gate").size(), "Run %d crosses every specified gate" % variation)
	var talk := simulate(0, true)
	check(talk.captures > 0, "Talking alone eventually captured")
	check(talk.chase_capture_s < 20, "Talking alone is caught soon after the slam: %.1f s" % talk.chase_capture_s)
	print("talk_only: ", talk)
	var d := MonsterDirector.new(GameState.balance)
	d.phase = "GAZE"
	d.phase_end = 100
	var slams := 0
	for index in range(200):
		d.step(.01, 0, "S3", false, true, true, index * .01)
		if "slam" in d.events: slams += 1
		if d.captured: break
	check(slams == 1 and d.captured and d.capture_cause == "hearing", "Loud while hidden gives one slam then capture")
	finish()

func simulate(variation: int, talk_only: bool) -> Dictionary:
	var s := LevelModel.new(GameState.balance, GameState.level, GameState.song)
	var voice := VoiceModel.new(GameState.balance)
	var shout_s := 0.0
	var captures := 0
	var gazes := 0
	var gates := 0
	var chase_start := 0.0
	var capture_time := 0.0
	var dt := 1.0 / 60.0
	for index in range(60000):
		var tier := policy(s, variation, talk_only)
		var rules_tier := 2 if tier == 4 else tier
		var db: float = voice.floor_db - 8
		if tier == 2: db = voice.thresholds()[1]
		elif tier == 3: db = voice.thresholds()[2]
		elif tier == 4: db = (voice.thresholds()[1] + voice.thresholds()[2]) * .5 # a loud talking voice, ~5 m/s
		var sample := voice.sample(db)
		if sample.is_shouting: shout_s += dt
		s.step(dt, sample.speed_target, sample.is_shouting, sample.is_audible, rules_tier)
		for message in s.messages:
			if message.type == "face_slam": chase_start = s.time
			elif message.type == "gaze": gazes += 1
			elif message.type in ["jumping", "stumbling"]: gates += 1
			elif message.type == "capture":
				captures += 1
				capture_time = s.time - chase_start
		if s.status == "complete" or captures > 0: break
	var result := {"complete":s.status == "complete", "captures":captures, "shout_s":shout_s, "gazes":gazes, "gates":gates, "x":s.run.x, "section":s.section, "phase":s.director.phase, "gap":s.director.gap, "time":s.time, "chase_capture_s":capture_time}
	if not talk_only: print("shout_40 ", variation, ": ", result)
	return result

func policy(s: LevelModel, variation: int, talk_only: bool) -> int:
	if talk_only: return 2
	if s.section == "S1": return 2
	if s.section == "S5":
		var beat := fposmod(s.clock, s.balance.bar_s)
		return 3 if beat < .2 else 0
	var d := s.director
	if d.eye_busy() or not d.pending.is_empty():
		return 0 if s.magnet or s.hidden or d.phase == "GAZE" else 2
	if s.wall_waiting >= 0.0: return 3
	if s.slip_left > 0.0: return 0
	for plank in s.level.of_type("plank"):
		if s.run.x > plank.x - 7 and s.run.x < plank.x + plank.length_m: return 4
	for wall in s.level.of_type("face_wall"):
		if wall.x >= s.run.x and wall.x - s.run.x < 6 and not s.walls_broken.has(wall.x): return 3
	for gate in s.level.of_type("gate"):
		if gate.x >= s.run.x and gate.x - s.run.x < 10 and s.run.gate_state.is_empty():
			if s.run.guarded: return 0
			return 3
	if not s.run.gate_state.is_empty(): return 0
	# A real player shouts when the wall is right behind them.
	if d.gap < 3.0 and not s.run.guarded: return 3
	# Shout bar / breathe bar, answering the wall's lunges on even bars, with a small reaction delay.
	var bar := int(floor((s.clock - variation * .08) / s.balance.bar_s))
	return 3 if bar % 2 == 0 else 0
