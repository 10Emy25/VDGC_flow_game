extends RefCounted
# 天空怪物（M2）抓住 Mina 时，从左上方伸下来的手。
# 三帧共用同一个抓取点（PIVOT），切帧时手不会跳。
# 时间线（从被抓那一刻算起）：下伸 → 张开 → 合拢攥住 → 带着 Mina 拽回天上。

const PIVOT := Vector2(868.0, 654.5)       # 抓取点在帧图里的像素位置（1112×781）
const TO_SKY := Vector2(-0.880, -0.474)    # 从手指向胳膊根部（天空）的方向
const GRAB_HEIGHT := 0.45                  # 抓在 Mina 图框从上往下 45% 的位置（躯干）
const DESCEND_S := 1.0                     # 从屏幕左上角慢慢探出、加速扑下来的时长（= 音效里重击的时刻）
const OPEN_AT := 0.7                       # 下伸到这一刻换成张开的手
const HOLD_UNTIL := 1.7                    # 攥住停顿到这一刻
const LIFT_S := 0.9                        # 拽回天上的时长（和黑屏淡出重叠）
const START_DISTANCE := 1250.0             # 起点刚好在屏幕左边外面
const LIFT_DISTANCE := 1500.0

static var cached_frames: Array[Texture2D] = []

static func frames() -> Array[Texture2D]:
 if not cached_frames.is_empty(): return cached_frames
 for number in range(1, 4):
  cached_frames.append(load("res://art/sky_hand_grab/frame_%d.png" % number) as Texture2D)
 return cached_frames

# 返回 {frame: 帧序号, offset: 手相对抓取点的位移, carry: Mina 跟着手的位移}
static func pose(age: float) -> Dictionary:
 if age < DESCEND_S:
  var u := clampf(age / DESCEND_S, 0.0, 1.0)
  # 先慢慢探出来，中间猛地加速，快到 Mina 时收住
  var reach := 4.0 * u * u * u if u < 0.5 else 1.0 - pow(-2.0 * u + 2.0, 3.0) * 0.5
  return {"frame": 1 if age >= OPEN_AT else 0, "offset": TO_SKY * START_DISTANCE * (1.0 - reach), "carry": Vector2.ZERO}
 if age < HOLD_UNTIL:
  # 攥住的一下：手和 Mina 一起轻微往回弹
  var k := age - DESCEND_S
  var squeeze := sin(k * 18.0) * 6.0 * exp(-k * 6.0)
  return {"frame": 2, "offset": TO_SKY * squeeze, "carry": TO_SKY * squeeze}
 var v := clampf((age - HOLD_UNTIL) / LIFT_S, 0.0, 1.0)
 var lift := TO_SKY * LIFT_DISTANCE * v * v * v
 return {"frame": 2, "offset": lift, "carry": lift}
