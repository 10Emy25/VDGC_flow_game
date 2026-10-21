extends Node
func _ready() -> void:
 VoiceInput.set_process(false)
 BeatClock.set_process(false)
 var running := MinaAnimation.run_frames()
 var standing := MinaAnimation.idle_frames()
 assert(running.size() == 8 and standing.size() == 1)
 for frame in running + standing:
  assert(frame.get_size() == Vector2(980,1830))
  assert(not frame is AtlasTexture, "Each supplied image remains a full independent pose")
 for key in ["mina_walk", "mina_jog", "mina_run"]:
  assert(ArtRegistry.frames(key+"_cute",key) == running)
  assert(ArtRegistry.frames(key+"_real",key) == running)
 assert(ArtRegistry.frames("mina_idle_real","mina_idle") == standing)
 var main: Control = load("res://scenes/main.tscn").instantiate()
 add_child(main)
 main.show_run()
 var run: RunView = main.current_view
 run.set_process(false)
 run.model.speed = 0
 run.update_view(0)
 assert(run.mina.real_frames == standing)
 run.mina._process(5)
 assert(run.mina.real.texture == standing[0])
 run.model.speed = 7
 run.update_view(0)
 assert(run.mina.base_key == "mina_run" and run.mina.real_frames == running)
 run.mina.animation_time = 0
 run.mina.animation_fps = 8
 for i in range(1,17):
  run.mina._process(0.125)
  assert(run.mina.real.texture == running[i%8])
 var old_slot: TextureRect = run.mina.real
 run.mina.base_key = "mina_run"
 assert(run.mina.real == old_slot, "Repeated cinematic assignments do not rebuild the sprite")
 run.model.speed = 0
 run.update_view(0)
 assert(run.mina.real_frames == standing)
 run.state.hidden = true
 run.update_view(0)
 assert(run.mina.base_key == "mina_crouch" and run.mina.real_frames == standing)
 run.state.hidden = false
 run.state.status = "captured"
 run.update_view(0)
 assert(run.mina.base_key == "mina_caught" and run.mina.real_frames == standing)
 run.state.status = "running"
 run.start_night_continuation()
 run.night_continuation.advance_map(0,1)
 assert(run.mina.real_frames == running)
 run.night_continuation.advance_map(0,0)
 assert(run.mina.real_frames == standing)
 main.show_last_scream()
 assert(run.final_confrontation.idle_frames == standing)
 for key in ["mina_crouch", "mina_caught", "mina_crying"]:
  assert(ArtRegistry.frames(key,key) == standing)
  assert(ArtRegistry.get_texture(key) == standing[0])
 var finale: LastScream = run.final_confrontation
 finale.set_process(false)
 assert(finale.mina.texture == standing[0])
 for phase in ["auto_scream", "player_light", "invitation", "voice", "reply"]:
  finale.enter(phase)
  finale._process(0.01)
  assert(finale.mina.texture == standing[0])
 var flower: FlowerNight = load("res://scenes/flower_night.tscn").instantiate()
 add_child(flower)
 flower.set_process(false)
 assert(flower.run_frames == running and flower.crouch_tex == standing[0])
 flower.animate_feet(0.1)
 assert(flower.sprite.hframes == 1 and flower.sprite.vframes == 1)
 assert(flower.sprite.texture in running)
 flower.queue_free()
 main.queue_free()
 await get_tree().process_frame
 await get_tree().process_frame
 print("Mina animation passed: eight whole ordered poses, single static standing pose, speed modes and loops, stable same-key assignments, night stop/run, finale idle and new standing art for all dream states including hide/caught/finale")
 get_tree().quit()
