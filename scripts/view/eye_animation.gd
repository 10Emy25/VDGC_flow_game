class_name EyeAnimation
extends RefCounted

const SOURCE_REGION := Rect2i(675, 135, 1120, 560)
const FRAME_COUNT := 18
const VIBRATION_FPS := 50.0
static var cached_frames: Array[Texture2D] = []
static var cached_vibration_frames: Array[Texture2D] = []

static func frames() -> Array[Texture2D]:
 if not cached_frames.is_empty(): return cached_frames
 for number in range(1500,1518):
  # Crop a common canvas region at runtime, keeping every source frame aligned.
  # Retain only the eye pixels in memory, not 18 mostly empty full-size canvases.
  var source: Texture2D = ResourceLoader.load("res://art/eye_animation/IMG_%d.PNG" % number, "Texture2D", ResourceLoader.CACHE_MODE_IGNORE)
  var pixels := source.get_image()
  if pixels.is_compressed(): pixels.decompress()
  cached_frames.append(ImageTexture.create_from_image(pixels.get_region(SOURCE_REGION)))
 return cached_frames

static func at_openness(amount: float) -> Texture2D:
 var sequence := frames()
 return sequence[clampi(roundi(clampf(amount,0.0,1.0)*(FRAME_COUNT-1)),0,FRAME_COUNT-1)]

static func vibration_frames() -> Array[Texture2D]:
 if not cached_vibration_frames.is_empty(): return cached_vibration_frames
 for number in range(1,4):
  var source: Texture2D = ResourceLoader.load("res://art/eye_vibration/shake_%d.png" % number, "Texture2D", ResourceLoader.CACHE_MODE_IGNORE)
  var pixels := source.get_image()
  if pixels.is_compressed(): pixels.decompress()
  cached_vibration_frames.append(ImageTexture.create_from_image(pixels.get_region(SOURCE_REGION)))
 return cached_vibration_frames

static func vibration_at(elapsed: float) -> Texture2D:
 var sequence := vibration_frames()
 var index := floori(maxf(elapsed,0.0) * VIBRATION_FPS + 0.000001) % sequence.size()
 return sequence[index]

const BLINK_FPS := 20.0
const SCAN_FPS := 10.0
# The supplied blink goes open -> closed. Return through 3 and 2, then scan starts open.
const BLINK_ORDER := [0,1,2,3,2,1]
const BLINK_HOLDS := [3,1,1,1,1,1]
const SCAN_HOLDS := [4,1,9,2,1,1,1,1,6,1,1,1,1,2,9,1]
const SCAN_ORDER := [0,1,2,3,4,5,6,7,8,7,6,5,4,3,2,1]
# Pupil centers measured from each cropped source image, in the same aligned canvas.
const PUPILS := [Vector2(616.2,286.8),Vector2(584.7,302.0),Vector2(543.8,312.8),Vector2(558.7,318.1),Vector2(618.8,323.0),Vector2(633.8,321.2),Vector2(655.9,319.4),Vector2(678.3,315.2),Vector2(706.0,314.6)]
static var cached_blink: Array[Texture2D] = []
static var cached_scan: Array[Texture2D] = []

static func load_sequence(folder: String, count: int) -> Array[Texture2D]:
 var result: Array[Texture2D] = []
 for number in range(1,count+1):
  var source: Texture2D = ResourceLoader.load("res://art/%s/frame_%d.png" % [folder,number], "Texture2D", ResourceLoader.CACHE_MODE_IGNORE)
  var pixels := source.get_image()
  if pixels.is_compressed(): pixels.decompress()
  result.append(ImageTexture.create_from_image(pixels.get_region(SOURCE_REGION)))
 return result

static func blink_frames() -> Array[Texture2D]:
 if cached_blink.is_empty(): cached_blink = load_sequence("eye_blink",4)
 return cached_blink

static func scan_frames() -> Array[Texture2D]:
 if cached_scan.is_empty(): cached_scan = load_sequence("eye_scan",9)
 return cached_scan

static func held_frame_index(elapsed: float, fps: float, holds: Array, loop: bool) -> int:
 var total := 0
 for hold in holds: total += int(hold)
 var tick := floori(maxf(elapsed,0.0)*fps + 0.000001)
 tick = tick % total if loop else mini(tick,total-1)
 for index in holds.size():
  if tick < int(holds[index]): return index
  tick -= int(holds[index])
 return holds.size()-1

static func blink_duration() -> float:
 var total := 0
 for hold in BLINK_HOLDS: total += int(hold)
 return total/BLINK_FPS

static func gaze_at(elapsed: float) -> Texture2D:
 var blink_time := blink_duration()
 if elapsed < blink_time:
  var step := held_frame_index(elapsed,BLINK_FPS,BLINK_HOLDS,false)
  return blink_frames()[BLINK_ORDER[step]]
 return scan_frames()[scan_index(elapsed)]

static func scan_index(elapsed: float) -> int:
 return SCAN_ORDER[held_frame_index(elapsed-blink_duration(),SCAN_FPS,SCAN_HOLDS,true)]

static func beam_active(elapsed: float) -> bool:
 return elapsed >= blink_duration()

static func pupil_at(elapsed: float) -> Vector2:
 return PUPILS[scan_index(elapsed)]

static func scan_direction(elapsed: float) -> float:
 var offset: float = pupil_at(elapsed).x - PUPILS[0].x
 return offset / (PUPILS[0].x-PUPILS[2].x if offset < 0.0 else PUPILS[8].x-PUPILS[0].x)
