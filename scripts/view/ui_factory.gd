class_name UIFactory
extends RefCounted

static func build_theme(balance: Dictionary, dialogue: Dictionary) -> Theme:
	var result := Theme.new()
	result.default_font_size = balance.ui.body_size
	var path: String = dialogue.fonts.system
	if ResourceLoader.exists(path):
		result.default_font = load(path)
	for state in ["normal", "hover", "pressed", "focus"]:
		var style := StyleBoxFlat.new()
		style.bg_color = Color(balance.palette.cream if state == "normal" else balance.palette.mint)
		style.border_color = Color(balance.palette.ink)
		style.set_border_width_all(2)
		style.set_corner_radius_all(16)
		style.content_margin_left = 24
		style.content_margin_right = 24
		style.content_margin_top = 12
		style.content_margin_bottom = 12
		result.set_stylebox(state, "Button", style)
		var color_key: String = "font_color" if state == "normal" else "font_" + state + "_color"
		for type in ["Button", "CheckButton"]:
			result.set_color(color_key, type, Color(balance.palette.ink))
	result.set_color("font_color", "Label", Color(balance.palette.ink))
	result.set_font_size("font_size", "Button", balance.ui.button_size)
	result.set_font_size("font_size", "CheckButton", balance.ui.button_size)
	return result

static func label(parent: Node, key: String, rect: Rect2, font_size: int = 0, color: Color = Color.TRANSPARENT) -> Label:
	var node := Label.new()
	node.theme = GameState.ui_theme
	node.text = GameState.text(key)
	node.position = rect.position
	node.size = rect.size
	node.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	node.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if font_size > 0:
		node.add_theme_font_size_override("font_size", font_size)
	if color != Color.TRANSPARENT:
		node.add_theme_color_override("font_color", color)
	parent.add_child(node)
	return node

static func button(parent: Node, key: String, rect: Rect2, action: Callable) -> Button:
	var node := Button.new()
	node.theme = GameState.ui_theme
	node.text = GameState.text(key)
	node.position = rect.position
	node.size = rect.size
	node.pressed.connect(action)
	# Space belongs to voice input after a pointer click, so buttons release focus.
	node.pressed.connect(node.release_focus)
	parent.add_child(node)
	return node

static func texture(parent: Node, key: String, rect: Rect2) -> TextureRect:
	var node := TextureRect.new()
	node.texture = ArtRegistry.get_texture(key)
	node.position = rect.position
	node.size = rect.size
	node.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	node.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(node)
	return node

static func rect(values: Array) -> Rect2:
	return Rect2(values[0], values[1], values[2], values[3])

static func subtitle(parent: Node, key: String, rect_value: Rect2, voice: String = "therapist") -> Label:
	texture(parent, "ui_subtitle", rect_value)
	var node := label(parent, key, rect_value, GameState.balance.ui.therapist_size, Color(GameState.balance.palette.cool if voice == "me" else GameState.balance.palette.warm))
	var path: String = GameState.dialogue.fonts.therapist
	if ResourceLoader.exists(path):
		node.add_theme_font_override("font", load(path))
	return node

static func prompt(parent: Node, key: String, rect_value: Rect2) -> Label:
	var node := label(parent, key, rect_value, GameState.balance.ui.system_size, Color.WHITE)
	node.add_theme_color_override("font_outline_color", Color(GameState.balance.palette.ink))
	node.add_theme_constant_override("outline_size", GameState.balance.ui.outline_px)
	return node
