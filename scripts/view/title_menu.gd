class_name TitleMenu
extends Control
signal new_game
signal settings_requested
signal quit_requested
const ART_SIZE := Vector2(2360, 1640)
const NEW_REGION := Rect2(235, 735, 850, 430)
const SETTINGS_REGION := Rect2(220, 1180, 900, 380)
const QUIT_REGION := Rect2(1755, 1210, 585, 380)
const SOUND_REGION := Rect2(2040, 990, 220, 170)
var new_button: Button
var settings_button: Button
var quit_button: Button
var sound_button: Button
var normal_new: TextureRect
var sound_icon: TextureRect
var sound_textures: Array[AtlasTexture] = []
var menu_music: AudioStreamPlayer
var text_materials: Array[ShaderMaterial] = []
var muted := false
var hotspots: Array[Dictionary] = []
var hover_art: Array[TextureRect] = []
var scare_art: TextureRect
var static_audio: AudioStreamPlayer
var laugh_audio: AudioStreamPlayer
var scare_wait := 0.0
var scare_elapsed := 0.0
var scare_duration := 0.0
var scare_active := false
var scare_rng := RandomNumberGenerator.new()

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var art := TextureRect.new()
	# This supplied variant has the old baked-in speaker removed.
	art.texture = preload("res://art/title_menu_new_hover.png")
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_SCALE
	art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art.material = text_material()
	add_child(art)
	# Restore the normal New sign over the speaker-free background.
	normal_new = TextureRect.new()
	normal_new.texture = atlas_region(preload("res://art/title_menu.png"), NEW_REGION)
	normal_new.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	normal_new.stretch_mode = TextureRect.STRETCH_SCALE
	normal_new.mouse_filter = Control.MOUSE_FILTER_IGNORE
	normal_new.material = text_material()
	add_child(normal_new)
	for texture in [preload("res://art/menu_unmuted.png"), preload("res://art/menu_muted.png")]:
		sound_textures.append(atlas_region(texture, SOUND_REGION))
	sound_icon = TextureRect.new()
	sound_icon.texture = sound_textures[0]
	sound_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	sound_icon.stretch_mode = TextureRect.STRETCH_SCALE
	sound_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(sound_icon)
	# Crop only the matching sign from each supplied hover illustration.
	add_hover_art(preload("res://art/title_menu_new_hover.png"), NEW_REGION)
	add_hover_art(preload("res://art/title_menu_settings_hover.png"), SETTINGS_REGION)
	add_hover_art(preload("res://art/title_menu_quit_hover.png"), QUIT_REGION)
	add_hover_art(preload("res://art/menu_unmuted.png"), SOUND_REGION, true)
	# Hit areas sit over the lettering already present in the supplied illustration.
	new_button = hotspot("New game", NEW_REGION, begin_new)
	settings_button = hotspot("Settings", SETTINGS_REGION, func() -> void: settings_requested.emit())
	quit_button = hotspot("Quit", QUIT_REGION, func() -> void: quit_requested.emit())
	sound_button = hotspot("Mute menu music", SOUND_REGION, toggle_music)
	new_button.focus_neighbor_bottom = new_button.get_path_to(settings_button)
	settings_button.focus_neighbor_top = settings_button.get_path_to(new_button)
	settings_button.focus_neighbor_right = settings_button.get_path_to(quit_button)
	quit_button.focus_neighbor_left = quit_button.get_path_to(settings_button)
	menu_music = AudioStreamPlayer.new()
	menu_music.stream = Sfx.get_stream("mus_title")
	menu_music.volume_db = -16
	# Keep the menu track playing while the settings panel pauses the game.
	menu_music.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(menu_music)
	if not Sfx.silent(): menu_music.play()
	resized.connect(layout_hotspots)
	layout_hotspots()
	new_button.grab_focus()
	setup_scare()
	GameState.settings_changed.connect(refresh_text_art)
	refresh_text_art()

func text_material(darken := false) -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = preload("res://shaders/art_text_size.gdshader")
	material.set_shader_parameter("darken", darken)
	text_materials.append(material)
	return material

func refresh_text_art() -> void:
	for material in text_materials:
		material.set_shader_parameter("font_scale", GameState.settings.get("font_scale", 1.0))

func hotspot(label: String, region: Rect2, action: Callable) -> Button:
	var button := Button.new()
	button.tooltip_text = label
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.focus_mode = Control.FOCUS_ALL
	button.text = ""
	var empty := StyleBoxEmpty.new()
	for state in ["normal", "hover", "focus", "pressed", "hover_pressed"]:
		button.add_theme_stylebox_override(state, empty)
	var index := hotspots.size()
	button.mouse_entered.connect(func() -> void: show_hover(index))
	button.mouse_exited.connect(func() -> void:
		# An exit from the previous button must not clear the next button.
		hover_art[index].hide())
	button.pressed.connect(func() -> void:
		finish_scare()
		show_hover(-1)
		button.release_focus()
		action.call())
	add_child(button)
	hotspots.append({"button":button, "region":region})
	return button

func atlas_region(texture: Texture2D, region: Rect2) -> AtlasTexture:
	var atlas := AtlasTexture.new()
	atlas.atlas = texture
	atlas.region = region
	return atlas

func add_hover_art(texture: Texture2D, region: Rect2, darken := false) -> void:
	var atlas := atlas_region(texture, region)
	var overlay := TextureRect.new()
	overlay.texture = atlas
	overlay.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	overlay.stretch_mode = TextureRect.STRETCH_SCALE
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.material = text_material(darken)
	add_child(overlay)
	overlay.hide()
	hover_art.append(overlay)

func show_hover(index: int) -> void:
	for i in hover_art.size():
		hover_art[i].visible = i == index

func layout_hotspots() -> void:
	var factor := size / ART_SIZE
	normal_new.position = NEW_REGION.position * factor
	normal_new.size = NEW_REGION.size * factor
	sound_icon.position = SOUND_REGION.position * factor
	sound_icon.size = SOUND_REGION.size * factor
	for i in hotspots.size():
		var item := hotspots[i]
		item.button.position = item.region.position * factor
		item.button.size = item.region.size * factor
		hover_art[i].position = item.button.position
		hover_art[i].size = item.button.size

func setup_scare() -> void:
	scare_rng.randomize()
	scare_wait = scare_rng.randf_range(6.0, 12.0)
	scare_art = TextureRect.new()
	scare_art.texture = preload("res://art/title_menu_scare.png")
	scare_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	scare_art.stretch_mode = TextureRect.STRETCH_SCALE
	scare_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(scare_art)
	scare_art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scare_art.material = text_material()
	scare_art.hide()
	static_audio = AudioStreamPlayer.new()
	static_audio.stream = preload("res://audio/sfx_title_static.wav")
	static_audio.volume_db = -8
	add_child(static_audio)
	laugh_audio = AudioStreamPlayer.new()
	laugh_audio.stream = preload("res://audio/sfx_title_laugh.wav")
	laugh_audio.volume_db = -7
	add_child(laugh_audio)

func _process(delta: float) -> void:
	if GameState.settings.get("reduce_scares", false):
		if scare_active: finish_scare()
		return
	if scare_active:
		scare_elapsed += delta
		if scare_elapsed >= scare_duration:
			finish_scare()
		else:
			# A single short dropout makes the image feel like a broken signal.
			scare_art.visible = not (scare_elapsed >= 0.075 and scare_elapsed < 0.11)
	else:
		scare_wait -= delta
		if scare_wait <= 0.0: start_scare()

func start_scare() -> void:
	if GameState.settings.get("reduce_scares", false): return
	scare_active = true
	scare_elapsed = 0.0
	scare_duration = scare_rng.randf_range(1.1, 1.3)
	scare_art.show()
	# Keep the playback cursor: the warm track resumes rather than restarting.
	menu_music.stream_paused = true
	if not muted and not Sfx.silent():
		static_audio.pitch_scale = scare_rng.randf_range(0.9, 1.12)
		static_audio.play()
		laugh_audio.pitch_scale = scare_rng.randf_range(0.96, 1.08)
		laugh_audio.play()

func finish_scare() -> void:
	scare_active = false
	if is_instance_valid(scare_art): scare_art.hide()
	if is_instance_valid(static_audio): static_audio.stop()
	if is_instance_valid(laugh_audio): laugh_audio.stop()
	if is_instance_valid(menu_music): menu_music.stream_paused = false
	scare_wait = scare_rng.randf_range(9.0, 19.0)

func _notification(what: int) -> void:
	# Do not leave a frozen horror image behind the paused settings panel.
	if what == NOTIFICATION_PAUSED and is_instance_valid(scare_art):
		finish_scare()

func begin_new() -> void:
	menu_music.stop()
	new_game.emit()

func toggle_music() -> void:
	muted = not muted
	sound_icon.texture = sound_textures[1 if muted else 0]
	hover_art[3].texture = sound_icon.texture
	menu_music.volume_db = -80 if muted else -16
	if muted:
		static_audio.stop()
		laugh_audio.stop()
	sound_button.tooltip_text = "Unmute menu music" if muted else "Mute menu music"
