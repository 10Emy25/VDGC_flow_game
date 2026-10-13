extends MinaTestSuite

func _ready() -> void:
	var b := GameState.balance
	var s := LevelModel.new(b, GameState.level)
	check(s.section == "S1" and not s.director.active, "No threat in S1")
	place(s, 219.9)
	s.run.speed = 3
	s.step(.1, 3, false, true, 2)
	check(s.section == "S2" and s.director.active, "Boundary starts chase")
	check(s.checkpoint.event.id == "CP1", "Checkpoint enters at leading zone edge")
	check(s.messages.all(func(m: Dictionary) -> bool: return m.type != "face_slam"), "R3 face slam not played")
	var cp6 := checkpoint(s, "CP6")
	s.flow = 42
	s.seen_scares = {"future_scare":true}
	s.save_checkpoint(cp6)
	s.flow = 1
	s.run.x = 1010
	s.respawn()
	near(s.run.x, 960, "Respawn at checkpoint center")
	near(s.director.gap, 15, "Custom respawn gap")
	near(s.flow, 42, "Checkpoint flow snapshot preserved for R3")
	check(s.seen_scares.has("future_scare"), "Checkpoint preserves seen flags")
	check(s.section == "S4" and s.director.phase == "IDLE", "Respawn restores section and resets gaze")
	check(s.director.invulnerable_left == 3 and s.director.no_scare_left == 10, "Respawn safety timers")
	check(s.level.events[s.cursor].x > 960, "Past events not replayed")
	s = LevelModel.new(b, GameState.level)
	place(s, 280)
	s.save_checkpoint(checkpoint(s, "CP1"))
	s.director.grace_left = 0
	s.director.safe_hold_left = 0
	s.director.gap = -1
	s.step(.02, 0, false, false, 0)
	check(s.status == "captured", "Wall captures")
	s.step(1.18, 0, false, false, 0)
	check(s.status == "captured", "Capture holds full 1.2 seconds")
	s.step(.04, 0, false, false, 0)
	check(s.status == "fading", "Capture then fades")
	s.step(.52, 0, false, false, 0)
	check(s.status == "running" and s.run.x == 222, "Fade then respawn")
	for cp in s.level.of_type("checkpoint"):
		s.save_checkpoint(cp)
		s.respawn()
		near(s.run.x, cp.x, "Every checkpoint can restore")
		check(s.section == s.level.section_at(cp.x), "Every checkpoint restores correct section")
	var finale := LevelModel.new(b, GameState.level)
	place(finale, 1084)
	finale.step(.02, 7, true, true, 3, 2.12)
	check(finale.finale_hits == 1, "Early downbeat window grants surge")
	var start := finale.run.x
	finale.step(.5, 0, false, false, 0, 2.62)
	check(finale.run.x - start >= 12, "Surge supplies 12 meters over half-second")
	finale = LevelModel.new(b, GameState.level)
	place(finale, 1084)
	finale.step(.02, 7, true, true, 3, 3.01)
	check(finale.finale_hits == 0, "Late miss does not surge")
	finale = LevelModel.new(b, GameState.level)
	place(finale, 1084)
	for bar in range(4):
		finale.step(.02, 0, false, false, 0, bar * 2.4 - .02)
		finale.step(.02, 7, true, true, 3, bar * 2.4 + .01)
	check(finale.finale_hits == 4 and finale.status == "flash", "Four distinct onsets finish")
	near(finale.run.x, 1140, "Fourth hit reaches door")
	finale.step(1.02, 0, false, false, 0)
	check(finale.status == "complete" and finale.messages.any(func(m: Dictionary) -> bool: return m.type == "ending"), "White flash leads to ending")
	finale = LevelModel.new(b, GameState.level)
	place(finale, 1139.99)
	finale.run.speed = 3
	finale.step(.02, 3, false, true, 2)
	check(finale.status == "flash", "Normal movement can reach door without hits")
	finale = LevelModel.new(b, GameState.level)
	place(finale, 1079.99)
	finale.run.speed = 3
	finale.step(.02, 3, false, true, 2, 1.22)
	check(finale.section == "S5" and not finale.messages.any(func(m: Dictionary) -> bool: return m.type == "beat_call"), "Entering finale mid-bar does not call off-beat")
	finale.step(.02, 0, false, false, 0, 2.42)
	check(finale.messages.any(func(m: Dictionary) -> bool: return m.type == "beat_call"), "Finale calls on next downbeat")
	finish()

func place(s: LevelModel, x: float) -> void:
	s.run.reset_position(x)
	s.bridge_ready = true
	s.bridge_progress = 1
	s.section = s.level.section_at(x)
	s.cursor = 0
	while s.cursor < s.level.events.size() and s.level.events[s.cursor].x <= x:
		s.cursor += 1
	if s.section != "S1":
		s.director.spawn()
		s.director.grace_left = 0
	if s.section == "S5":
		s.director.begin_finale()
	s.messages.clear()

func checkpoint(s: LevelModel, id: String) -> Dictionary:
	for event in s.level.of_type("checkpoint"):
		if event.id == id:
			return event
	return {}
