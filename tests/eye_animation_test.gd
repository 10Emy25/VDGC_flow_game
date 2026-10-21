extends Node
func _ready() -> void:
 VoiceInput.set_process(false)
 BeatClock.set_process(false)
 var sequence := EyeAnimation.frames()
 assert(sequence.size() == 18)
 for texture in sequence:
  assert(texture.get_size() == Vector2(1120,560))
 assert(EyeAnimation.at_openness(-1) == sequence[0])
 assert(EyeAnimation.at_openness(2) == sequence[17])
 var main: Control = load("res://scenes/main.tscn").instantiate()
 add_child(main)
 main.show_run()
 var run: RunView = main.current_view
 run.set_process(false)
 run.state.section = "S2"
 var director: MonsterDirector = run.state.director
 director.phase = "WARNING"
 director.phase_start = 0
 director.phase_end = 2
 for sample in [0.0,0.5,1.0]:
  run.state.clock = sample*2
  run.update_view(0)
  assert(run.eye.visible and run.eye.texture == EyeAnimation.at_openness(sample))
  assert(run.eye.scale == Vector2.ONE, "Actual artwork replaces synthetic squashing")
  assert(not run.beam.visible)
 var blink := EyeAnimation.blink_frames()
 var scanning := EyeAnimation.scan_frames()
 assert(blink.size() == 4 and scanning.size() == 9)
 assert(is_equal_approx(EyeAnimation.blink_duration(),0.4))
 director.phase = "GAZE"
 # Explicit authored durations and boundaries, including a second scan loop without another blink.
 var samples := [
  [0.0,blink[0]],[0.14999,blink[0]],[0.15,blink[1]],
  [0.20,blink[2]],[0.25,blink[3]],[0.30,blink[2]],[0.35,blink[1]],
  [0.4,scanning[0]],[0.79999,scanning[0]],[0.8,scanning[1]],
  [0.9,scanning[2]],[1.79999,scanning[2]],[1.8,scanning[3]],
  [1.99999,scanning[3]],[2.0,scanning[4]],[2.1,scanning[5]],
  [2.2,scanning[6]],[2.3,scanning[7]],[2.4,scanning[8]],
  [2.99999,scanning[8]],[3.0,scanning[7]],[3.1,scanning[6]],
  [3.2,scanning[5]],[3.3,scanning[4]],[3.4,scanning[3]],
  [3.6,scanning[2]],[4.5,scanning[1]],[4.6,scanning[0]]]
 for sample in samples:
  run.state.clock = sample[0]
  run.update_view(0)
  assert(run.eye.texture == sample[1] and run.beam.visible == EyeAnimation.beam_active(sample[0]), "Blink/scan frame at %.5fs" % sample[0])
 var held_texture := run.eye.texture
 run.update_view(0)
 assert(run.eye.texture == held_texture, "Pausing game time holds the current image")
 director.phase = "RECEDE"
 for sample in [0.0,0.5,1.0]:
  run.state.clock = sample*2
  run.update_view(0)
  assert(run.eye.texture == EyeAnimation.at_openness(1.0-sample))
  assert(not run.beam.visible)
 assert(director.phase_start == 0 and director.phase_end == 2, "Animation doesn't change danger timing")
 director.phase = "IDLE"
 run.update_view(0)
 assert(not run.eye.visible)
 run.state.section = "S5"
 run.state.finale_start = 0
 run.state.time = 0
 run.update_view(0)
 assert(run.eye.texture == sequence[17])
 run.state.time = GameState.balance.finale.eye_close_s
 run.update_view(0)
 assert(not run.eye.visible and run.eye.texture == sequence[0])
 main.queue_free()
 await get_tree().process_frame
 await get_tree().process_frame
 print("Eye animation passed: 18 aligned frames, bounded lookup, warning open / one 20fps blink then 10fps ping-pong scans with authored holds / recede reverse, stable scale, shared beam timing and finale close")
 get_tree().quit()
