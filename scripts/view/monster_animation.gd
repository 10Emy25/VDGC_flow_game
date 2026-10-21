@tool
class_name MonsterAnimation
extends RefCounted

const SOURCE_REGION := Rect2i(510,65,1555,1560)
const BOTTOM_PADDING := 17.0
static var cached_frames: Array[Texture2D] = []
static var cached_face: Texture2D

static func frames() -> Array[Texture2D]:
 if not cached_frames.is_empty(): return cached_frames
 for number in range(1,5):
  var source: Texture2D = ResourceLoader.load("res://art/monster_chase/frame_%d.png" % number, "Texture2D", ResourceLoader.CACHE_MODE_IGNORE)
  var pixels := source.get_image()
  if pixels.is_compressed(): pixels.decompress()
  cached_frames.append(ImageTexture.create_from_image(pixels.get_region(SOURCE_REGION)))
 return cached_frames

static func at_time(elapsed: float, fps: float = 8.0) -> Texture2D:
 var sequence := frames()
 return sequence[floori(maxf(elapsed,0) * fps + 0.000001) % sequence.size()]

static func face() -> Texture2D:
 if cached_face == null:
  cached_face = ImageTexture.create_from_image(frames()[0].get_image().get_region(Rect2i(250,0,1000,850)))
 return cached_face
