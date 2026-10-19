extends CanvasLayer
# TESTER MODE — development shortcuts. Only runs in debug builds (editor / F5), never in an exported release.
# To remove it completely: delete the folder scripts/dev/. Nothing else depends on it.
#
#   1-5  jump to the start of S1 … S5 (from anywhere, even the title screen)
#   6    jump to the next checkpoint
#   7    god mode on/off (nothing can catch you)
#   8    skip the song: jump to 3 s before the face slam (S1 only)
#   0    hide/show this overlay

var main: Control
var god := false
var label: Label

func _ready() -> void:
	layer = 40
	process_mode = Node.PROCESS_MODE_ALWAYS
	label = Label.new()
	label.position = Vector2(24, 1000)
	label.add_theme_font_size_override("font_size", 20)
	label.add_theme_color_override("font_color", Color(1, 0.9, 0.3))
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 6)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(label)

func _process(_delta: float) -> void:
	var run := current_run()
	var where := ""
	if run != null:
		where = "   |   %s  %.0f m  gap %.1f m  eye %s" % [run.state.section, run.model.x, run.state.director.gap, run.state.director.phase]
		if god:
			run.state.director.invulnerable_left = maxf(run.state.director.invulnerable_left, 0.5)
	var cinematic: bool = main.current_view is LastScream and main.current_view.phase in ["shock", "reveal"]
	if run != null and run.night_continuation != null:
		cinematic = run.night_continuation.phase in ["blackout", "look", "listen"] or run.night_continuation.elapsed >= 73
	if run != null and run.locker_pass != null and run.locker_pass.active: cinematic = true
	if run != null and run.final_confrontation != null: cinematic = true
	label.modulate.a = 0 if cinematic else 1
	label.text = "TESTER  1-5 section · 6 next checkpoint · 7 god %s · 8 skip song · N night · 9 finale · 0 hide%s" % ["ON" if god else "off", where]

func _input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	match event.physical_keycode:
		KEY_1: go_section("S1")
		KEY_2: go_section("S2")
		KEY_3: go_section("S3")
		KEY_4: go_section("S4")
		KEY_5: go_section("S5")
		KEY_N:
			main.show_run()
			main.current_view.model.x = main.current_view.locker_pass.locker_x - 25
			main.current_view.state.bridge_ready = true
			main.current_view.state.bridge_progress = 1.0
		KEY_9: main.show_last_scream()
		KEY_6: next_checkpoint()
		KEY_7: god = not god
		KEY_8: skip_song()
		KEY_0: label.visible = not label.visible
		_: return
	get_viewport().set_input_as_handled()

func current_run() -> RunView:
	if main != null and main.current_view is RunView and is_instance_valid(main.current_view):
		return main.current_view
	return null

func ensure_run() -> RunView:
	if get_tree().paused:
		main.settings_panel.close()
	if current_run() == null:
		main.show_run()
	# Still waking up from the bedroom: skip the rest of the dream so the jump applies at once.
	if current_run().dream_left > 0.0:
		current_run().end_dream()
	return current_run()

func go_section(id: String) -> void:
	if id == "S1":
		main.show_run()
		return
	var run := ensure_run()
	for event in run.state.level.of_type("section"):
		if event.id == id:
			teleport(run, event.x)
			return

func next_checkpoint() -> void:
	var run := ensure_run()
	for cp in run.state.level.of_type("checkpoint"):
		if cp.x > run.model.x + 1.0:
			teleport(run, cp.x)
			return

func skip_song() -> void:
	var run := ensure_run()
	if run.state.section == "S1" and Sfx.loops.has("mus_song"):
		Sfx.loops["mus_song"].seek(maxf(0.0, run.song.duration - 3.0))

# Put Mina at x as if she had just arrived there: events at x fire on the next frame, the chase is live,
# and that spot becomes the checkpoint.
func teleport(run: RunView, x: float) -> void:
	var s := run.state
	var chase := x >= s.chase_start_x() - 0.01
	if chase and not s.slammed:
		s.slammed = true
		s.bridge_ready = true
		s.bridge_progress = 1.0
		s.seen_scares["face_slam"] = true
	s.run.reset_position(x)
	s.section = s.level.section_at(x - 0.01) if chase else "S1"
	s.cursor = 0
	while s.cursor < s.level.events.size() and s.level.events[s.cursor].x < x - 0.01:
		s.cursor += 1
	s.director.finale = false
	if s.section != "S1":
		s.director.spawn()
	s.director.respawn(s.balance.m1.respawn_gap)
	s.status = "running"
	s.slip_left = 0.0
	s.wall_progress.clear()
	s.save_checkpoint({"x": x, "type": "checkpoint", "id": "TEST", "section": s.level.section_at(x)})
	run.parallax_x = x
	run.last_view_x = x
	run.slam_age = INF
	run.handle_message({"type": "section", "id": s.level.section_at(x)})
	print("[tester] teleported to %.0f m (%s)" % [x, s.level.section_at(x)])
