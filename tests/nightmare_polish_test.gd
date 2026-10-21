extends Node
func _ready() -> void:
 VoiceInput.set_process(false)
 BeatClock.set_process(false)
 var main: Control = load("res://scenes/main.tscn").instantiate()
 add_child(main)
 main.show_run()
 var run: RunView = main.current_view
 run.set_process(false)
 var frames := MinaAnimation.run_frames()
 for speed in [0.02,1.0,3.0,7.0]:
  run.model.speed = speed
  run.update_view(0)
  assert(run.mina.animation_fps == 11.0)
  run.mina.animation_time = 0
  run.mina._process(1.0/11.0)
  assert(run.mina.real.texture == frames[1], "Same run cadence regardless of world speed")
 assert(run.mina.size == Vector2(240,288))
 assert(run.wall.size == Vector2(1140,1370))
 var d := run.state.director
 run.state.face_slam()
 for message in run.state.messages: run.handle_message(message)
 assert(run.reveal_age == 0.0)
 var x: float = run.model.x
 var gap: float = d.gap
 var clock: float = run.state.clock
 run._process(0.1)
 assert(run.slam_face.visible and is_zero_approx(run.reveal_camera_px), "Face jump scare precedes the monster pan")
 run._process(0.9)
 assert(not run.slam_face.visible and is_zero_approx(run.reveal_camera_px))
 run._process(0.45)
 assert(run.model.x == x and d.gap == gap and run.state.clock == clock)
 assert(run.mina.base_key == "mina_idle")
 assert(is_equal_approx(run.wall.position.x + run.wall.size.x*0.5,960.0))
 assert(run.darkness.visible, "Keep peripheral occlusion in cinematic")
 var old_time := run.wall.animation_time
 run.wall._process(0.125)
 assert(run.wall.animation_time > old_time, "Monster still writhes while chase positions freeze")
 run._process(1.1)
 assert(is_equal_approx(run.reveal_camera_px,run.reveal_pan_distance()))
 run._process(0.275)
 assert(run.reveal_camera_px < 0 and run.reveal_camera_px > run.reveal_pan_distance())
 run._process(0.275)
 assert(run.reveal_age < 0 and is_zero_approx(run.reveal_camera_px))
 assert(run.model.x == x and d.gap == gap)
 assert(is_equal_approx(run.mina.position.x+run.mina.size.x*0.5,GameState.balance.player_screen_x))
 assert(is_equal_approx(run.reveal_clock_hold,3.1))
 BeatClock.elapsed = clock + run.reveal_clock_hold + 0.02
 run._process(0.02)
 assert(is_equal_approx(run.state.clock,clock+0.02), "Resuming excludes cinematic time from hazard clock")
 # Beam originates at the pupil and lands at the exact gameplay detection position.
 d.active = false
 d.phase = "GAZE"
 d.phase_start = 0
 d.phase_end = 100
 for t in [0.0,0.25,0.4,0.9,2.0,2.4,3.0,3.6,4.6]:
  run.state.clock = t
  d.step(0,0,"S2",false,true,false,t)
  run.update_view(0)
  assert(run.beam.visible == EyeAnimation.beam_active(t))
  if run.beam.visible:
   var foot_x: float = run.beam.position.x + run.beam.size.x*0.5
   assert(is_equal_approx(foot_x,GameState.balance.player_screen_x + d.beam_offset*GameState.balance.px_per_m))
   var pupil := run.eye.position + EyeAnimation.pupil_at(t)/Vector2(EyeAnimation.SOURCE_REGION.size)*run.eye.size
   var top := (run.beam_cone.polygon[0]+run.beam_cone.polygon[1])*0.5+run.beam.position
   assert(top.is_equal_approx(pupil))
 var detector := MonsterDirector.new(GameState.balance)
 detector.phase = "GAZE"
 detector.phase_end = 100
 detector.step(0.3,0,"S2",false,false,false,0.3)
 assert(detector.sight_s == 0, "Blink cannot illuminate/capture")
 detector.step(0.79,0,"S2",false,false,false,2.0)
 assert(not detector.captured)
 detector.step(0.01,0,"S2",false,false,false,2.01)
 assert(detector.captured and detector.capture_cause == "sight")
 main.queue_free()
 await get_tree().process_frame
 await get_tree().process_frame
 print("V32 passed: constant run cadence, smaller Mina/larger monster, frozen chase and animated monster, pan-left/hold/pan-back camera, preserved occlusion, ping-pong pupil/beam/collision synchronization")
 get_tree().quit()
