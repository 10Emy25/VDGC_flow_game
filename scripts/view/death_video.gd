class_name DeathVideo
extends CanvasLayer
# 死亡视频：被抓、画面变黑之后，复活之前播放。播放时整个游戏暂停（音乐、怪物、节拍都停住）。
# can_skip 为 true 时，右下角出现一个圈，中间写着 SPACE；按住空格，圈转满一圈就跳过。

signal finished

const SKIP_HOLD_S := 0.8              # 按住空格多少秒才算跳过（改成 0.01 就是一按就跳）
const RING_RADIUS := 46.0             # 圈的半径
const RING_MARGIN := Vector2(90, 90)  # 圈中心离屏幕右下角的距离
const RING_WIDTH := 5.0               # 圈的粗细
const DEATH_SOUNDS := ["res://video/death1.mp3", "res://video/death2.mp3"]  # 每次随机放一个

var can_skip := false
var player: VideoStreamPlayer
var sound: AudioStreamPlayer
var ratio_box: AspectRatioContainer
var ring: Control
var hold := 0.0
var spin := 0.0
var done := false

func _init(video_path: String, skippable: bool) -> void:
	layer = 50
	process_mode = Node.PROCESS_MODE_ALWAYS
	can_skip = skippable
	# 黑底：视频是 4:3，左右空出来的地方是黑的
	var black := ColorRect.new()
	black.color = Color.BLACK
	black.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(black)
	ratio_box = AspectRatioContainer.new()
	ratio_box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ratio_box.ratio = 4.0 / 3.0
	add_child(ratio_box)
	player = VideoStreamPlayer.new()
	player.stream = load(video_path)
	player.expand = true
	player.finished.connect(close)
	ratio_box.add_child(player)
	sound = AudioStreamPlayer.new()
	sound.stream = load(DEATH_SOUNDS[randi() % DEATH_SOUNDS.size()])
	add_child(sound)
	# 跳过提示圈
	ring = Control.new()
	ring.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ring.theme = GameState.ui_theme
	ring.visible = can_skip
	ring.draw.connect(draw_ring)
	add_child(ring)

func _ready() -> void:
	get_tree().paused = true
	player.play()
	sound.play()

func _process(delta: float) -> void:
	if done:
		return
	# 就算中途开关了设置面板，视频播放期间游戏也保持暂停
	get_tree().paused = true
	var texture := player.get_video_texture()
	if texture != null and texture.get_height() > 0:
		ratio_box.ratio = float(texture.get_width()) / texture.get_height()
	if not can_skip:
		return
	spin += delta * 5.0
	if Input.is_physical_key_pressed(KEY_SPACE):
		hold += delta
		if hold >= SKIP_HOLD_S:
			close()
			return
	else:
		hold = 0.0
	ring.queue_redraw()

func draw_ring() -> void:
	var center := ring.get_viewport_rect().size - RING_MARGIN
	ring.draw_circle(center, RING_RADIUS + 12.0, Color(0, 0, 0, 0.5))
	ring.draw_arc(center, RING_RADIUS, 0.0, TAU, 64, Color(1, 1, 1, 0.25), RING_WIDTH, true)
	if hold > 0.0:
		# 按住空格：从 12 点方向开始转满一圈
		var start := -PI * 0.5
		ring.draw_arc(center, RING_RADIUS, start, start + TAU * hold / SKIP_HOLD_S, 64, Color.WHITE, RING_WIDTH, true)
	else:
		# 没按的时候：一小段弧一直在转，提示可以操作
		ring.draw_arc(center, RING_RADIUS, spin, spin + PI * 0.5, 24, Color(1, 1, 1, 0.8), RING_WIDTH, true)
	var font := ring.get_theme_default_font()
	var font_size := 17
	ring.draw_string(font, center + Vector2(-RING_RADIUS, font_size * 0.35), "SPACE", HORIZONTAL_ALIGNMENT_CENTER, RING_RADIUS * 2.0, font_size, Color.WHITE)

func close() -> void:
	if done:
		return
	done = true
	player.stop()
	sound.stop()
	get_tree().paused = false
	finished.emit()
	queue_free()
