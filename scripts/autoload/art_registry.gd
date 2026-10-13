@tool
extends Node

var cache: Dictionary = {}
var warned: Dictionary = {}

func has_texture(key: String) -> bool:
	return ResourceLoader.exists("res://art/%s.png" % key) or ResourceLoader.exists("res://art/%s.svg" % key)

func get_texture(key: String) -> Texture2D:
	if cache.has(key):
		return cache[key]
	for extension in ["png", "svg"]:
		var path := "res://art/%s.%s" % [key, extension]
		if ResourceLoader.exists(path):
			cache[key] = load(path)
			return cache[key]
	if not warned.has(key):
		push_warning("Missing art key: %s" % key)
		warned[key] = true
	if key != "fallback" and has_texture("fallback"):
		cache[key] = get_texture("fallback")
	else:
		var img := Image.create(32, 32, false, Image.FORMAT_RGBA8)
		for y in range(32):
			for x in range(32):
				img.set_pixel(x, y, Color.MAGENTA if (x / 8 + y / 8) % 2 == 0 else Color.BLACK)
		cache[key] = ImageTexture.create_from_image(img)
	return cache[key]

func frames(key: String, base_key: String = "") -> Array[Texture2D]:
	var source := get_texture(key)
	var lookup := base_key if not base_key.is_empty() else key.trim_suffix("_cute").trim_suffix("_real")
	var frame_config: Dictionary
	if Engine.is_editor_hint():
		frame_config = JSON.parse_string(FileAccess.get_file_as_string("res://data/balance.json")).art_frames
	else:
		frame_config = GameState.balance.art_frames
	var count: int = maxi(1, int(frame_config.get(lookup, 1)))
	var result: Array[Texture2D] = []
	for index in range(maxi(count, 1)):
		var frame := AtlasTexture.new()
		frame.atlas = source
		frame.region = Rect2(float(index) * source.get_width() / count, 0, float(source.get_width()) / count, source.get_height())
		result.append(frame)
	return result
