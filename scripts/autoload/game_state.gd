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
	settings.font_scale = clampf(float(settings.get("font_scale", 1.0)), 0.85, 1.15)
	ui_theme = UIFactory.build_theme(balance, dialogue)
	get_tree().node_added.connect(func(node: Node) -> void: scale_text.call_deferred(node))

func read_json(path: String) -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(path))

func text(key: String) -> String:
	return dialogue.strings.get(key, key)

func set_setting(key: String, value: Variant) -> void:
	if key == "font_scale": value = clampf(float(value), 0.85, 1.15)
	settings[key] = value
	if key == "font_scale": scale_all_text(get_tree().root)
	var config := ConfigFile.new()
	for setting in settings:
		config.set_value("settings", setting, settings[setting])
	config.save("user://settings.cfg")
	settings_changed.emit()

func scale_all_text(node: Node) -> void:
	scale_text(node)
	for child in node.get_children(): scale_all_text(child)

func scale_text(node: Node) -> void:
	if not is_instance_valid(node): return
	if node is Label or node is Button:
		if not node.has_meta("original_font_size"):
			node.set_meta("original_font_size", node.get_theme_font_size("font_size"))
		node.add_theme_font_size_override("font_size", roundi(float(node.get_meta("original_font_size")) * float(settings.get("font_scale", 1.0))))
