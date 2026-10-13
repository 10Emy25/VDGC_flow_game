extends Node

signal settings_changed
var balance: Dictionary
var dialogue: Dictionary
var song: Dictionary
var level: Dictionary
var settings: Dictionary
var world_real := 0.0
var ui_theme: Theme

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	balance = read_json("res://data/balance.json")
	dialogue = read_json("res://data/dialogue.json")
	song = read_json("res://data/song.json")
	level = read_json("res://data/level.json")
	settings = balance.input_defaults.duplicate()
	var config := ConfigFile.new()
	if config.load("user://settings.cfg") == OK:
		for key in settings:
			settings[key] = config.get_value("settings", key, settings[key])
	settings.sensitivity_db = clampf(float(settings.sensitivity_db), balance.sensitivity.min_db, balance.sensitivity.max_db)
	ui_theme = UIFactory.build_theme(balance, dialogue)

func read_json(path: String) -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(path))

func text(key: String) -> String:
	return dialogue.strings.get(key, key)

func set_setting(key: String, value: Variant) -> void:
	settings[key] = value
	var config := ConfigFile.new()
	for setting in settings:
		config.set_value("settings", setting, settings[setting])
	config.save("user://settings.cfg")
	settings_changed.emit()
