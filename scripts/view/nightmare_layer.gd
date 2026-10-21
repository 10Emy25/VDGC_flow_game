extends Control
# 噩梦场景的一层视差背景（art/nightmare/ 里的一张 2000×1080 透明图）。
# 一个图块 = 原图 + 水平翻转的原图，共 4000 宽：接缝处左右像素一致，滚动循环时不会跳。
# 位置 x 由 RunView 的视差循环控制；这里只负责环境动态（起伏、上下飘、明暗闪烁）。

const LAYERS := [
	# 从后到前。factor = 跟镜头移动的比例（1.0 = 和 Mina 脚下的地面同步）
	{"file": "01_sky", "factor": 0.04, "flicker": 0.08},
	{"file": "02_flesh_clouds", "factor": 0.08, "bob_px": 10.0, "period": 7.0},
	{"file": "03_mountains_far", "factor": 0.15, "breathe": 0.012, "period": 6.0, "base_y": 814.0},
	{"file": "04_mountains_mid", "factor": 0.26, "breathe": 0.018, "period": 5.0, "base_y": 841.0},
	{"file": "05_mountains_near", "factor": 0.42, "breathe": 0.024, "period": 4.2, "base_y": 872.0},
	{"file": "06_ground_back", "factor": 0.65},
	{"file": "07_ground_front", "factor": 1.0},
]
const IMAGE_WIDTH := 2000.0
const TILE_WIDTH := IMAGE_WIDTH * 2.0

var config: Dictionary = {}
var age := 0.0

static func make(layer_config: Dictionary) -> Control:
	var node: Control = (load("res://scripts/view/nightmare_layer.gd") as GDScript).new()
	node.config = layer_config
	return node

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	size = Vector2(TILE_WIDTH, 1080)
	var texture: Texture2D = load("res://art/nightmare/%s.png" % config.file)
	for index in range(2):
		var slot := TextureRect.new()
		slot.texture = texture
		slot.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		slot.stretch_mode = TextureRect.STRETCH_SCALE
		slot.size = Vector2(IMAGE_WIDTH, 1080)
		slot.position.x = IMAGE_WIDTH * index
		slot.flip_h = index == 1
		slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(slot)
	pivot_offset = Vector2(0, config.get("base_y", 1080.0))
	# 每层相位错开，避免整个画面同步一起动
	age = float(config.factor) * 37.0
	visible = false

func set_horror(value: bool) -> void:
	visible = value

func _process(delta: float) -> void:
	if not visible: return
	age += delta
	var period: float = config.get("period", 5.0)
	var wave := sin(age * TAU / period)
	# 肉山像在呼吸：以山脚为轴，竖直方向轻微伸缩
	var breathe: float = config.get("breathe", 0.0)
	scale.y = 1.0 + breathe * wave
	# 肉云上下飘
	position.y = config.get("bob_px", 0.0) * sin(age * TAU / period + 1.3)
	# 天空偶尔暗一下
	var flicker: float = config.get("flicker", 0.0)
	if flicker > 0.0:
		var dip := maxf(0.0, sin(age * 0.9) * sin(age * 2.3) * sin(age * 5.1))
		modulate.v = 1.0 - flicker * dip * 3.0
