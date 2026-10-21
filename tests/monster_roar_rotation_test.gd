extends Node

func _ready() -> void:
 Sfx.monster_roar_index = 0
 for i in range(6):
  var stream: AudioStreamWAV = Sfx.next_monster_roar()
  assert(stream == Sfx.get_stream(Sfx.MONSTER_ROARS[i % 3]))
  assert(stream.get_length() > 3.0 and stream.get_length() < 5.1)
  assert(not stream.stereo, "Mono sources retain the game's explicit left/right cues")
  assert(stream.loop_mode == AudioStreamWAV.LOOP_DISABLED)
 Sfx.play_at("sfx_m1_roar", -12, 1, -1)
 assert(Sfx.monster_roar_index == 1, "Normal monster events use the shared sequence")
 var old_roar := AudioStreamPlayer2D.new()
 Sfx.add_child(old_roar)
 Sfx.active_monster_roar = old_roar
 Sfx.play_at("sfx_m1_growl", -18, 1, 1)
 assert(Sfx.active_monster_roar == null and old_roar.is_queued_for_deletion())
 var finale := LastScream.new()
 add_child(finale)
 finale.set_process(false)
 assert(finale.roar_player.stream == Sfx.get_stream(Sfx.MONSTER_ROARS[1]))
 finale.roar_player.finished.emit()
 assert(finale.roar_player.stream == Sfx.get_stream(Sfx.MONSTER_ROARS[2]))
 finale.roar_player.finished.emit()
 assert(finale.roar_player.stream == Sfx.get_stream(Sfx.MONSTER_ROARS[0]))
 finale.enter("auto_scream")
 var next_index: int = Sfx.monster_roar_index
 finale.roar_player.finished.emit()
 assert(Sfx.monster_roar_index == next_index, "Roars stop when Mina's scream starts")
 finale.queue_free()
 Sfx.stop_all()
 await get_tree().process_frame
 await get_tree().process_frame
 print("Monster roar rotation passed: three full clips, repeated 1-2-3 order, chase/finale continuity, direction-warning cleanup and stop at Mina scream")
 get_tree().quit()
