@tool
class_name MinaAnimation
extends RefCounted

const RUN_REGION := Rect2i(760,350,980,1830)
# Same-sized canvas, translated to align the standing feet with the run cycle's ground.
const IDLE_REGION := Rect2i(760,245,980,1830)
static var cached_run: Array[Texture2D] = []
static var cached_idle: Array[Texture2D] = []

static func supports(key: String) -> bool:
 return key.trim_suffix("_cute").trim_suffix("_real") in ["mina_idle","mina_walk","mina_jog","mina_run","mina_crouch","mina_caught","mina_crying"]

static func load_frame(path: String, region: Rect2i) -> Texture2D:
 var source: Texture2D = ResourceLoader.load(path,"Texture2D",ResourceLoader.CACHE_MODE_IGNORE)
 var image := source.get_image()
 if image.is_compressed(): image.decompress()
 return ImageTexture.create_from_image(image.get_region(region))

static func run_frames() -> Array[Texture2D]:
 if cached_run.is_empty():
  for number in range(1,9):
   cached_run.append(load_frame("res://art/mina_animation/run_%d.png" % number,RUN_REGION))
 return cached_run

static func idle_frames() -> Array[Texture2D]:
 if cached_idle.is_empty():
  cached_idle.append(load_frame("res://art/mina_animation/idle.png",IDLE_REGION))
 return cached_idle

static func frames(key: String) -> Array[Texture2D]:
 return run_frames() if key.trim_suffix("_cute").trim_suffix("_real") in ["mina_walk","mina_jog","mina_run"] else idle_frames()
