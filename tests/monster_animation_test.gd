extends Node
func _ready() -> void:
 VoiceInput.set_process(false)
 BeatClock.set_process(false)
 var sequence := MonsterAnimation.frames()
 assert(sequence.size() == 4)
 for frame in sequence:
  assert(frame.get_size() == Vector2(1555,1560))
 for i in range(12):
  assert(MonsterAnimation.at_time(float(i)/8) == sequence[i%4])
 assert(ArtRegistry.frames("m1_wall","m1_wall") == sequence)
 assert(ArtRegistry.get_texture("m1_wall") == sequence[0])
 assert(ArtRegistry.get_texture("m1_face_peek") == MonsterAnimation.face())
 var main: Control = load("res://scenes/main.tscn").instantiate()
 add_child(main)
 main.show_run()
 var run: RunView = main.current_view
 run.set_process(false)
 assert(run.wall.real_frames == sequence)
 var x_before: float = run.model.x
 var gap_before: float = run.state.director.gap
 run.wall.animation_time = 0
 run.wall._process(0.125)
 assert(run.wall.real.texture == sequence[1])
 var visible_bottom: float = run.wall.position.y + run.wall.real.position.y + run.wall.real.size.y * (1.0 - MonsterAnimation.BOTTOM_PADDING/MonsterAnimation.SOURCE_REGION.size.y)
 assert(absf(visible_bottom-GameState.balance.level_view.monster_feet_y)<0.1)
 assert(run.model.x == x_before and run.state.director.gap == gap_before)
 assert(is_equal_approx(run.locker_pass.monster.position.y+run.locker_pass.monster.size.y*(1.0-MonsterAnimation.BOTTOM_PADDING/MonsterAnimation.SOURCE_REGION.size.y),GameState.balance.level_view.monster_feet_y))
 run.locker_pass.active = true
 run.locker_pass.phase = "pass"
 run.locker_pass.age = 0
 run.locker_pass.step(0.125)
 assert(run.locker_pass.monster.texture == sequence[1])
 var finale := LastScream.new()
 add_child(finale)
 finale.set_process(false)
 finale.enter("voice")
 finale._process(0.125)
 for enemy in finale.enemies:
  assert(enemy.texture == sequence[1])
 finale.queue_free()
 main.queue_free()
 await get_tree().process_frame
 await get_tree().process_frame
 print("Monster animation passed: four ordered full frames, 8fps wrap, updated peek/close-up, chase/finale/locker playback, floor alignment and unchanged model/gap")
 get_tree().quit()
