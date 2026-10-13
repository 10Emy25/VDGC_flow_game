extends Node

signal bar_started(index: int)
signal beat(index_in_bar: int)
var elapsed := 0.0
var master_key := ""
var last_bar := -1
var last_beat := -1
var last_position := 0.0
var completed_loops := 0
var clock_offset := 0.0

func reset(key: String = "") -> void:
	elapsed = 0.0
	master_key = key
	last_position = 0.0
	completed_loops = 0
	clock_offset = 0.0
	last_bar = -1
	last_beat = -1

func _process(delta: float) -> void:
	var position := Sfx.master_position(master_key) if not master_key.is_empty() else -1.0
	if position >= 0.0:
		var duration: float = Sfx.get_stream(master_key).get_length()
		if position - last_position < -duration * 0.5:
			completed_loops += 1
		elapsed = clock_offset + completed_loops * duration + position
		last_position = position
	else:
		elapsed += delta
	var bar := int(elapsed / GameState.balance.bar_s)
	var current_beat := int(elapsed / (GameState.balance.bar_s / GameState.balance.beats_per_bar))
	if bar != last_bar:
		last_bar = bar
		bar_started.emit(bar)
	if current_beat != last_beat:
		last_beat = current_beat
		beat.emit(current_beat % int(GameState.balance.beats_per_bar))

func time_to_next_bar() -> float:
	return GameState.balance.bar_s - fmod(elapsed, GameState.balance.bar_s)

func adopt_master(key: String) -> void:
	var position := maxf(Sfx.master_position(key), 0.0)
	clock_offset = elapsed - position
	last_position = position
	completed_loops = 0
	master_key = key
