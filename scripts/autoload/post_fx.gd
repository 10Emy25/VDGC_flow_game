extends CanvasLayer

var stress := 0.0
var heartbeat := 0.0
var effect: ColorRect

func _ready() -> void:
	layer = 5
	effect = ColorRect.new()
	effect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	effect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var shader_material := ShaderMaterial.new()
	shader_material.shader = load("res://shaders/post_fx.gdshader")
	shader_material.set_shader_parameter("grain_texture", ArtRegistry.get_texture("tex_grain"))
	shader_material.set_shader_parameter("paper_texture", ArtRegistry.get_texture("tex_paper"))
	effect.material = shader_material
	add_child(effect)

func _process(_delta: float) -> void:
	effect.visible = GameState.world_real > 0.0
	effect.material.set_shader_parameter("world_real", GameState.world_real)
	effect.material.set_shader_parameter("stress", stress)
	effect.material.set_shader_parameter("heartbeat", heartbeat)
	effect.material.set_shader_parameter("reduce_distortion", GameState.settings.reduce_distortion)
