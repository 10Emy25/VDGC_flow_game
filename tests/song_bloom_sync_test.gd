extends Node
func _ready() -> void:
 VoiceInput.set_process(false)
 BeatClock.set_process(false)
 var main: Control = load("res://scenes/main.tscn").instantiate()
 add_child(main)
 main.show_run()
 var run: RunView = main.current_view
 run.set_process(false)
 var cues: Array = GameState.balance.song_view.bloom_cues
 assert(cues.size() > 20)
 assert(cues.back().time > 26 and cues.back().time < run.state.song_end)
 assert(Sfx.get_stream("sfx_bloom").get_length() < 0.13)
 var count := run.world_props.size()
 for cue in cues:
  run.step_song_blooms(cue.time-0.01,true)
  assert(run.world_props.size() == count, "Voice queues the flower without firing between notes")
  run.step_song_blooms(cue.time,false)
  count += 1
  assert(run.world_props.size() == count, "Flower and chime trigger together on the recorded note")
  run.step_song_blooms(cue.time,false)
  assert(run.world_props.size() == count, "One flower per note")
 run.step_song_blooms(30,true)
 run.step_song_blooms(32,true)
 assert(run.world_props.size() == count, "No 19.2s loop or chimes during recording tail")
 run.step_song_blooms(0,false)
 run.step_song_blooms(cues[0].time,false)
 assert(run.world_props.size() == count, "Silence produces no flower")
 run.step_song_blooms(25,true)
 assert(run.world_props.size() == count, "A stalled frame never bursts overdue chimes")
 main.queue_free()
 await get_tree().process_frame
 await get_tree().process_frame
 print("Song bloom sync passed: recording-specific note cues, buffered vocal input, simultaneous bloom/chime, no duplicates, silence, no old loop, no stale burst and short chime")
 get_tree().quit()
