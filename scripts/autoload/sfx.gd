extends Node

var streams: Dictionary = {}
var loops: Dictionary = {}
var fades: Dictionary = {}
var warned: Dictionary = {}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE

func get_stream(key: String) -> AudioStream:
	if streams.has(key):
		return streams[key]
	for extension in ["wav", "ogg"]:
		var path := "res://audio/%s.%s" % [key, extension]
		if ResourceLoader.exists(path):
			var stream: AudioStream = load(path)
			# amb_* and mus_* loop, except a one-shot music intro (mus_*_intro).
			if (key.begins_with("amb_") or key.begins_with("mus_")) and not key.ends_with("_intro"):
				if stream is AudioStreamWAV:
					stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
					stream.loop_begin = 0
					# data.size() is the *compressed* size for QOA/IMA imports; use the decoded length instead.
					stream.loop_end = int(round(stream.get_length() * stream.mix_rate))
				elif stream is AudioStreamOggVorbis:
					stream.loop = true
			streams[key] = stream
			return stream
	if not warned.has(key):
		push_warning("Missing audio key: %s" % key)
		warned[key] = true
	streams[key] = null
	return null

# Tests run on the Dummy driver and stay silent; Godot's Movie Maker also uses it but records what plays.
func silent() -> bool:
	return AudioServer.get_driver_name() == "Dummy" and not OS.has_feature("movie")

func play(key: String, volume_db: float = -10.0, pitch: float = 1.0) -> void:
	play_at(key, volume_db, pitch, 0.0)

func play_at(key: String, volume_db: float, pitch: float, pan: float) -> void:
	var stream := get_stream(key)
	if stream == null:
		return
	if silent():
		return
	# A screen-space 2D player gives replaceable sounds stereo pan without a world camera.
	var player := AudioStreamPlayer2D.new()
	player.stream = stream
	player.volume_db = volume_db
	player.pitch_scale = pitch
	player.position = Vector2(get_viewport().get_visible_rect().size.x * (clampf(pan, -1.0, 1.0) + 1.0) * 0.5, get_viewport().get_visible_rect().size.y * 0.5)
	player.max_distance = get_viewport().get_visible_rect().size.x * 2.0
	player.attenuation = 0.0
	add_child(player)
	player.finished.connect(player.queue_free)
	player.play()

func loop(key: String, enabled: bool, volume_db: float = -10.0) -> void:
	if not enabled:
		if loops.has(key):
			loops[key].stop()
			loops[key].queue_free()
			loops.erase(key)
		return
	if loops.has(key):
		loops[key].volume_db = volume_db
		return
	var stream := get_stream(key)
	if stream == null:
		return
	if silent():
		return
	var player := AudioStreamPlayer.new()
	player.stream = stream
	player.volume_db = volume_db
	add_child(player)
	loops[key] = player
	player.play()

func set_loop_volume(key: String, db: float, fade_s: float) -> void:
	if not loops.has(key):
		return
	if fades.has(key) and fades[key].is_valid():
		fades[key].kill()
	var tween := create_tween()
	fades[key] = tween
	tween.tween_property(loops[key], "volume_db", db, fade_s)

func stop_all() -> void:
	for tween in fades.values():
		if tween.is_valid():
			tween.kill()
	fades.clear()
	for child in get_children():
		child.stop()
		child.queue_free()
	loops.clear()

func master_position(key: String) -> float:
	if not loops.has(key) or not loops[key].playing:
		return -1.0
	return loops[key].get_playback_position() + AudioServer.get_time_since_last_mix()
