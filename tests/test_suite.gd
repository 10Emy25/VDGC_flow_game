class_name MinaTestSuite
extends Node

var passes := 0
var failures := 0
var saved_files: Dictionary = {}

func check(condition: bool, message: String) -> void:
	if condition:
		passes += 1
	else:
		failures += 1
		push_error("FAIL: " + message)

func near(actual: float, expected: float, message: String, tolerance: float = 0.001) -> void:
	check(absf(actual - expected) <= tolerance, "%s (actual %.6f, expected %.6f)" % [message, actual, expected])

func preserve_user_files() -> void:
	for path in ["user://settings.cfg", "user://voice_calibration.cfg"]:
		saved_files[path] = FileAccess.get_file_as_bytes(path) if FileAccess.file_exists(path) else null

func finish() -> void:
	VoiceInput.set_process(false)
	VoiceInput.microphone.stop()
	Sfx.stop_all()
	# Let the audio mixer release stopped playbacks before headless shutdown.
	await get_tree().create_timer(0.1, true).timeout
	for path in saved_files:
		if saved_files[path] == null:
			if FileAccess.file_exists(path):
				DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
		else:
			var file := FileAccess.open(path, FileAccess.WRITE)
			file.store_buffer(saved_files[path])
	print("%s: %d passed, %d failed" % [name, passes, failures])
	get_tree().quit(1 if failures > 0 else 0)
