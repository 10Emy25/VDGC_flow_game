extends MinaTestSuite

func _ready() -> void:
	var b := GameState.balance
	var d := MonsterDirector.new(b)
	d.spawn()
	near(d.gap, 10, "Spawn gap")
	near(d.m1_speed("S2"), 0, "Spawn grace freezes wall")
	d.grace_left = 0
	d.gap = 10
	near(d.m1_speed("S2"), 3.8, "S2 base")
	near(d.m1_speed("S4"), 4.2, "S4 base")
	d.gap = 19
	near(d.m1_speed("S2"), 6, "Far rubber band")
	d.gap = 3.9
	near(d.m1_speed("S2"), 2.85, "Near slowdown retains exact spec tuning")
	d.phase = "GAZE"
	near(d.m1_speed("S4"), .8, "Wall fears gaze")
	d.scripted_first = true
	near(d.m1_speed("S3"), 0, "First gaze freezes wall")
	d.phase = "RECEDE"
	d.scripted_first = false
	near(d.m1_speed("S3"), .8, "Recede remains slow")
	d.phase = "IDLE"
	d.post_slow_left = 1.5
	near(d.m1_speed("S3"), .8, "Post-gaze grace")
	d.post_slow_left = 0
	d.gap = 7.84
	check(d.gaze_decision(2, false).action == "start", "Exact safety margin starts gaze")
	d.gap = 7.83
	check(d.gaze_decision(2, false).action == "delay", "Unsafe first attempt delays")
	check(d.gaze_decision(2, true).bars == 1, "Second attempt shortens to one bar")
	d.gap = 5.91
	check(d.gaze_decision(2, true).action == "skip", "Less than one safe bar skips")
	d = MonsterDirector.new(b)
	d.spawn()
	d.grace_left = 0
	d.gap = 2
	d.step(.01, 0, "S2", true, false, false, .01)
	near(d.gap, 12, "Safe zone maintains minimum gap")
	near(d.m1_speed("S2"), 0, "Safe zone freezes wall")
	d.step(.01, 0, "S2", false, false, false, .02)
	near(d.safe_hold_left, 6, "Leaving zone starts six-second hold")
	d.step(5.9, 0, "S2", false, false, false, 5.92)
	check(d.safe_hold_left > 0 and not d.captured, "Hold protects a breath")
	d.step(.11, 0, "S2", false, false, false, 6.03)
	check("roar" in d.events and d.safe_hold_left == 0, "Roar when hold ends")
	d = MonsterDirector.new(b)
	d.spawn()
	d.request_gaze({"x":590,"bars":2,"scripted_first":true}, .5)
	for tick in range(1, 1090):
		var clock := tick * .01
		d.gap = 30
		d.step(.01, 0, "S3", false, true, false, clock)
		if tick == 239: check(d.phase == "TELL", "Tell fills remainder of trigger bar")
		if tick == 241: check(d.phase == "WARNING", "Warning begins at next bar")
		if tick == 481: check(d.phase == "GAZE", "Gaze follows Warning")
		if tick == 481:
			check(d.phase == "GAZE", "Gaze after one Warning bar")
			near(d.phase_start, 4.8, "Gaze boundary")
			near(d.m1_speed("S3"), 0, "First gaze wall frozen")
		if tick == 961:
			check(d.phase == "RECEDE", "Two-bar gaze ends")
			check(d.first_freeze_left > 1.9, "First-gaze freeze extends two seconds")
		if tick == 1081:
			check(d.phase == "IDLE", "Half-bar Recede ends")
			check(d.post_slow_left > 1.4, "Post-Recede slow starts")
	d = gaze(b)
	d.step(.24, 0, "S3", false, true, true, .24)
	check(d.hearing_count == 0, "Hearing requires continuous quarter-second")
	d.step(.01, 0, "S3", false, true, true, .25)
	check(d.hearing_count == 1 and "slam" in d.events and not d.captured, "First sound warns even when hidden")
	d.step(1.01, 0, "S3", false, true, false, 1.26)
	d.step(.25, 0, "S3", false, true, true, 1.51)
	check(d.captured and d.capture_cause == "hearing", "Second sound captures")
	check(not d.try_capture("sight"), "One capture per incident")
	d.respawn(12)
	check(d.invulnerable_left == 3 and d.no_scare_left == 10, "Respawn protection timers")
	check(not d.try_capture("m1"), "Respawn invulnerability")
	d.invulnerable_left = 0
	check(not d.try_capture("m1"), "Three-second double-capture rule independent of invulnerability")
	d.time += 3.01
	check(d.try_capture("m1"), "Capture can occur after protection")
	d = gaze(b)
	d.step(.25, 0, "S3", false, true, true, .25)
	d.reset_hearing()
	check(d.hearing_count == 0 and d.slam_left == 0, "Hearing reset hook for R3 hold-breath scare")
	d.step(.25, 0, "S3", false, true, true, .5)
	check("slam" in d.events and not d.captured, "Reset gives fresh warning")
	d = gaze(b)
	d.step(.2, 0, "S3", false, true, true, .2)
	d.step(.01, 0, "S3", false, true, false, .21)
	d.step(.2, 0, "S3", false, true, true, .41)
	check(d.hearing_count == 0, "Silence breaks continuous hearing timer")
	d = gaze(b)
	d.step(.79, 0, "S3", false, false, false, 2.5)
	check(not d.captured, "Sight below 0.8 seconds safe")
	d.step(.01, 0, "S3", false, false, false, 2.51)
	check(d.captured and d.capture_cause == "sight", "Sight captures at cumulative 0.8 seconds")
	d = gaze(b)
	d.step(1, 0, "S3", false, true, false, 2.5)
	check(not d.captured and d.sight_s == 0, "Hidden and silent defeats beam")
	d = MonsterDirector.new(b)
	d.in_safe = true
	d.request_gaze({"x":670,"bars":2}, 0)
	d.step(2.5, 0, "S3", true, true, false, 2.5)
	check(d.phase == "IDLE", "No gaze starts in safe zone")
	d.no_scare_left = 10
	d.step(1, 0, "S3", false, true, false, 5)
	check(d.phase == "IDLE", "No gaze starts inside respawn scare protection")
	d.spawn()
	d.begin_finale()
	d.gap = -20
	d.step(1, 0, "S5", false, false, true, 6)
	near(d.gap, 3, "Finale clamps gap")
	check(not d.captured and not d.try_capture("hearing"), "Finale cannot capture")
	var level := LevelData.new(GameState.level)
	check(level.validation_errors(b).is_empty(), "All specified gazes have nearby cover")
	check(level.covered(600, .49, b), "Cover at low speed hides automatically")
	check(not level.covered(600, .5, b), "Hide speed is strict")
	check(not level.covered(601, 0, b), "Outside cover remains visible")
	finish()

func gaze(b: Dictionary) -> MonsterDirector:
	var d := MonsterDirector.new(b)
	d.phase = "GAZE"
	d.phase_end = 100
	return d
