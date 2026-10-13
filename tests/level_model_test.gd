extends MinaTestSuite

func _ready() -> void:
	var b := GameState.balance
	var s := LevelModel.new(b, GameState.level, GameState.song)
	check(s.section == "S1" and not s.director.active, "No threat in S1")
	near(s.song_end, 19.2, "Model knows when the song is cut off (~20 s)")
	place(s, 230, true)
	s.run.speed = 3
	s.step(1, 3, false, true, 2, 10)
	check(s.section == "S1" and s.run.x > 232, "No waiting at the end of the flower path")
	var gate_before: float = s.level.first("gate").x
	var x_at_slam := s.run.x
	s.step(.02, 3, false, true, 2, 19.21)
	check(s.slammed and s.section == "S2" and s.director.active, "Song cut triggers the face slam and the chase")
	check(s.messages.any(func(m: Dictionary) -> bool: return m.type == "face_slam"), "Face slam message")
	check(s.checkpoint.event.id == "SLAM" and s.checkpoint.event.section == "S2", "Slam saves a chase checkpoint")
	near(s.level.first("gate").x - gate_before, s.checkpoint.event.x - 200, "Chase shifted to begin at the slam point", .001)
	check(GameState.level.events.any(func(e: Dictionary) -> bool: return e.type == "gate" and e.x == 245), "Shared level data untouched")
	near(s.director.gap, 8, "Wall appears 8 m behind")
	# Slow players get slammed wherever they are; respawn keeps them in the chase.
	s = LevelModel.new(b, GameState.level, GameState.song)
	place(s, 10, true)
	s.bridge_ready = false
	s.step(.02, 0, false, false, 0, 19.3)
	check(s.slammed and s.bridge_ready, "Slam before the bridge lowers it for the chase")
	s.director.grace_left = 0
	s.director.gap = -1
	s.step(.02, 0, false, false, 0, 19.32)
	s.step(1.8, 0, false, false, 0, 21.1)
	check(s.status == "running" and s.section == "S2" and s.director.active and is_equal_approx(s.run.x, 10), "Respawn after an early slam stays in the chase")
	# Face walls.
	s = LevelModel.new(b, GameState.level, GameState.song)
	place(s, 261.9)
	s.run.speed = 3
	s.step(.1, 3, false, true, 2)
	check(s.wall_waiting == 262 and is_equal_approx(s.run.x, 262), "Arriving slowly at a face wall stops Mina")
	s.step(.5, 7, true, true, 3)
	check(not s.walls_broken.has(262.0), "Wall holds before 0.8 s of shouting")
	s.step(.35, 7, true, true, 3)
	check(s.walls_broken.has(262.0), "0.8 s of shouting breaks the wall")
	s.step(.5, 7, true, true, 3)
	check(s.run.x > 262.5, "Mina continues after the wall")
	s = LevelModel.new(b, GameState.level, GameState.song)
	place(s, 261.5)
	s.run.speed = 7
	s.step(.1, 7, true, true, 3)
	check(s.walls_broken.has(262.0) and s.run.x > 262, "Ramming at shout speed smashes straight through")
	s.save_checkpoint(checkpoint(s, "CP0"))
	s.save_checkpoint({"x": 230, "type": "checkpoint", "id": "T", "section": "S2"})
	s.respawn()
	check(not s.walls_broken.has(262.0), "Walls ahead of the checkpoint rebuild after respawn")
	# Planks.
	s = LevelModel.new(b, GameState.level, GameState.song)
	place(s, 361)
	s.run.speed = 7
	s.step(.35, 7, true, true, 3)
	check(s.slip_left > 0 and s.run.speed == 0, "Shouting across the plank slips")
	s = LevelModel.new(b, GameState.level, GameState.song)
	place(s, 361)
	s.run.speed = 3
	s.step(2, 3, false, true, 2)
	check(s.slip_left == 0 and s.run.x > 366, "Talking pace crosses the plank")
	# Cover magnet.
	s = LevelModel.new(b, GameState.level, GameState.song)
	place(s, 452)
	s.director.phase = "WARNING"
	s.director.phase_start = 0
	s.director.phase_end = 100
	s.run.speed = 7
	for i in range(60):
		s.step(1.0 / 60.0, 7, true, true, 3)
	check(s.magnet and is_equal_approx(s.run.x, 458) and s.hidden, "Nearby cover pulls Mina in and hides her even if she was running")
	s.director.phase = "IDLE"
	s.step(.5, 7, true, true, 3)
	check(not s.magnet and s.run.x > 458, "Magnet lets go when the eye is done")
	# Regression: after dying and respawning at the checkpoint before the eye, hiding must still work.
	for attempt in range(2):
		s = LevelModel.new(b, GameState.level, GameState.song)
		place(s, 425)
		s.save_checkpoint(checkpoint(s, "CP2"))
		if attempt == 1:
			s.director.grace_left = 0
			s.director.safe_hold_left = 0
			s.director.gap = -1
			s.step(.02, 0, false, false, 0)
			s.step(1.8, 0, false, false, 0)
			check(s.status == "running" and is_equal_approx(s.run.x, 420), "Died and respawned at CP2")
		var hid_in_gaze := false
		var caught := false
		for i in range(60 * 25):
			var busy := s.director.eye_busy() or not s.director.pending.is_empty()
			var tier := 0 if busy else 3
			s.step(1.0 / 60.0, 7.0 if tier == 3 else 0.0, tier == 3, tier == 3, tier)
			if s.director.phase == "GAZE" and s.hidden: hid_in_gaze = true
			if s.status != "running": caught = true
			if s.run.x > 470 and s.director.phase == "IDLE" and hid_in_gaze: break
		check(hid_in_gaze and not caught, "First eye can be hidden from (%s)" % ("after respawn" if attempt == 1 else "first try"))
	# Same check for every eye in the level, respawning at the checkpoint before it.
	for gaze in LevelData.new(GameState.level).of_type("gaze"):
		s = LevelModel.new(b, GameState.level, GameState.song)
		var before: Dictionary = {}
		for cp in s.level.of_type("checkpoint"):
			if cp.x < gaze.x: before = cp
		place(s, before.x + 5)
		s.save_checkpoint(before)
		s.director.grace_left = 0
		s.director.safe_hold_left = 0
		s.director.gap = -1
		s.step(.02, 0, false, false, 0)
		s.step(1.8, 0, false, false, 0)
		var hid := false
		var lost := false
		for i in range(60 * 30):
			var busy := s.director.eye_busy() or not s.director.pending.is_empty()
			var tier := 0 if busy or s.run.guarded else 3
			s.step(1.0 / 60.0, 7.0 if tier == 3 else 0.0, tier == 3, tier == 3, tier)
			if s.director.phase == "GAZE" and s.hidden and absf(s.run.x - gaze.x) < 15: hid = true
			if s.status != "running": lost = true
			if hid and s.director.phase == "IDLE" and s.run.x > gaze.x + 20: break
		check(hid and not lost, "Eye at %d m can be hidden from after respawning at %s" % [gaze.x, before.id])
	# Checkpoints.
	s = LevelModel.new(b, GameState.level, GameState.song)
	place(s, 345)
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
	check(s.status == "running" and s.run.x == 330, "Fade then respawn")
	check(s.director.invulnerable_left > 2.9 and s.director.no_scare_left > 9.9, "Respawn safety timers")
	for cp in s.level.of_type("checkpoint"):
		s.save_checkpoint(cp)
		s.respawn()
		near(s.run.x, cp.x, "Every checkpoint can restore")
		check(s.section == s.level.section_at(cp.x), "Every checkpoint restores correct section")
	var finale := LevelModel.new(b, GameState.level, GameState.song)
	place(finale, 884)
	finale.step(.02, 7, true, true, 3, 2.12)
	check(finale.finale_hits == 1, "Early downbeat window grants surge")
	var start := finale.run.x
	finale.step(.5, 0, false, false, 0, 2.62)
	check(finale.run.x - start >= 12, "Surge supplies 12 meters over half-second")
	finale = LevelModel.new(b, GameState.level, GameState.song)
	place(finale, 884)
	finale.step(.02, 7, true, true, 3, 3.01)
	check(finale.finale_hits == 0, "Late miss does not surge")
	finale = LevelModel.new(b, GameState.level, GameState.song)
	place(finale, 884)
	for bar in range(4):
		finale.step(.02, 0, false, false, 0, bar * 2.4 - .02)
		finale.step(.02, 7, true, true, 3, bar * 2.4 + .01)
	check(finale.finale_hits == 4 and finale.status == "flash", "Four distinct onsets finish")
	near(finale.run.x, 940, "Fourth hit reaches door")
	finale.step(1.02, 0, false, false, 0)
	check(finale.status == "complete" and finale.messages.any(func(m: Dictionary) -> bool: return m.type == "ending"), "White flash leads to ending")
	finale = LevelModel.new(b, GameState.level, GameState.song)
	place(finale, 939.99)
	finale.run.speed = 3
	finale.step(.02, 3, false, true, 2)
	check(finale.status == "flash", "Normal movement can reach door without hits")
	finale = LevelModel.new(b, GameState.level, GameState.song)
	place(finale, 879.99)
	finale.run.speed = 3
	finale.step(.02, 3, false, true, 2, 1.22)
	check(finale.section == "S5" and not finale.messages.any(func(m: Dictionary) -> bool: return m.type == "beat_call"), "Entering finale mid-bar does not call off-beat")
	finale.step(.02, 0, false, false, 0, 2.42)
	check(finale.messages.any(func(m: Dictionary) -> bool: return m.type == "beat_call"), "Finale calls on next downbeat")
	finish()

func place(s: LevelModel, x: float, song: bool = false) -> void:
	s.run.reset_position(x)
	s.bridge_ready = true
	s.bridge_progress = 1
	s.section = "S1" if song else s.level.section_at(x)
	s.slammed = s.section != "S1"
	s.cursor = 0
	while s.cursor < s.level.events.size() and s.level.events[s.cursor].x <= x and (not song or s.level.events[s.cursor].x < 200):
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
