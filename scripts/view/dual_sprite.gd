@tool
class_name DualSprite
extends Control

@export var base_key := "":
	set(value):
		base_key = value
		if is_inside_tree():
			refresh()
@export var real_only := false
@export var animation_fps := 0.0
@export_range(0.0, 1.0) var preview_real := 0.0:
	set(value):
		preview_real = value
		if is_inside_tree():
			update_blend()
var registry: Node
var editor_registry: Node
var cute: TextureRect
var real: TextureRect
var cute_frames: Array[Texture2D] = []
var real_frames: Array[Texture2D] = []
var animation_time := 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	refresh()

func refresh() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	if base_key.is_empty():
		return
	registry = get_node_or_null("/root/ArtRegistry")
	if registry == null and Engine.is_editor_hint():
		if editor_registry == null:
			editor_registry = load("res://scripts/autoload/art_registry.gd").new()
		registry = editor_registry
	if registry == null:
		return
	var cute_key := base_key + "_cute"
	var real_key := base_key + "_real"
	var has_cute: bool = registry.has_texture(cute_key)
	var has_real: bool = registry.has_texture(real_key)
	if real_only:
		real_frames = registry.frames(base_key, base_key)
		cute_frames = real_frames
	else:
		cute_frames = registry.frames(cute_key if has_cute or not has_real else real_key, base_key)
		real_frames = registry.frames(real_key if has_real or not has_cute else cute_key, base_key)
	cute = make_slot(cute_frames[0], false, not has_cute and has_real and not real_only)
	real = make_slot(real_frames[0], not has_real and has_cute and not real_only, false)
	update_blend()

func make_slot(texture_value: Texture2D, derive_real: bool, derive_cute: bool) -> TextureRect:
	var slot := TextureRect.new()
	slot.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	slot.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	slot.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	slot.texture = texture_value
	slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var shader_material := ShaderMaterial.new()
	shader_material.shader = load("res://shaders/dual_derive.gdshader")
	shader_material.set_shader_parameter("derive_real", derive_real)
	shader_material.set_shader_parameter("derive_cute", derive_cute)
	# Canvas UVs address the whole atlas, so wobble must use its full pixel size.
	shader_material.set_shader_parameter("source_size", texture_value.atlas.get_size() if texture_value is AtlasTexture else texture_value.get_size())
	shader_material.set_shader_parameter("hatch_texture", registry.get_texture("tex_hatch"))
	slot.material = shader_material
	add_child(slot)
	return slot

func _process(delta: float) -> void:
	if cute == null or not is_instance_valid(cute):
		return
	animation_time += delta
	var frame := int(animation_time * animation_fps)
	cute.texture = cute_frames[frame % cute_frames.size()]
	real.texture = real_frames[frame % real_frames.size()]
	update_blend()

func update_blend() -> void:
	var state = get_node_or_null("/root/GameState")
	if cute == null:
		return
	var amount: float = 1.0 if real_only else (preview_real if Engine.is_editor_hint() or state == null else state.world_real)
	cute.modulate.a = 1.0 - amount
	real.modulate.a = amount
	for slot in [cute, real]:
		slot.material.set_shader_parameter("real_amount", amount)
		slot.material.set_shader_parameter("reduce_distortion", state != null and state.settings.get("reduce_distortion", false))

func _exit_tree() -> void:
	if is_instance_valid(editor_registry):
		editor_registry.free()
		editor_registry = null
