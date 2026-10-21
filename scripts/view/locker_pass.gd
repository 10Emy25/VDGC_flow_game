class_name LockerPass
extends Node2D
# Camera position is expressed in metres, matching RunView's scrolling world.
const LOCKER_X := 803.0
const TRIGGER_LEAD_M := 8.0
var run: Control
var active := false
var entered := false
var phase := "follow"
var age := 0.0
var camera_m := 0.0
var camera_locked := false
var locker_event: Dictionary = {}
var locker_x: float:
	get: return float(locker_event.get("x", LOCKER_X))
var locker: DualSprite
var trigger: Area2D
var probe: Area2D
var monster: TextureRect
var black: ColorRect

func _ready() -> void:
	z_index = 6
	# Observe the existing late-stage cabinet; do not move/add any map objects.
	for item in run.objects:
		if item.kind == "cover" and item.event.get("art", "") == "cover_locker":
			locker = item.sprite
			locker_event = item.event
			break
	# Actual overlap detection; the probe follows Mina's world-space position.
	trigger = Area2D.new()
	trigger.name = "LockerApproachArea"
	trigger.position = Vector2((locker_x - 5) * GameState.balance.px_per_m, GameState.balance.layout.feet_y)
	trigger.collision_layer = 0
	trigger.collision_mask = 2
	var shape := CollisionShape2D.new()
	var zone := RectangleShape2D.new()
	zone.size = Vector2(6 * GameState.balance.px_per_m, 500)
	shape.shape = zone
	trigger.add_child(shape)
	add_child(trigger)
	probe = Area2D.new()
	probe.collision_layer = 2
	probe.collision_mask = 0
	probe.monitoring = false
	var body := CollisionShape2D.new()
	var capsule := CircleShape2D.new()
	capsule.radius = 20
	body.shape = capsule
	probe.add_child(body)
	add_child(probe)
	trigger.area_entered.connect(on_arrival)
	monster = UIFactory.texture(run, "m1_wall", Rect2(-900, 140, 650, 750))
	monster.texture = ArtRegistry.frames("m1_wall", "m1_wall")[0]
	monster.size = Vector2(850, 850.0 * MonsterAnimation.SOURCE_REGION.size.y / MonsterAnimation.SOURCE_REGION.size.x)
	monster.position.y = GameState.balance.level_view.monster_feet_y - monster.size.y + MonsterAnimation.BOTTOM_PADDING * monster.size.y / MonsterAnimation.SOURCE_REGION.size.y
	monster.z_index = 7
	monster.hide()
	black = ColorRect.new()
	black.size = Vector2(1920, 1080)
	black.color = Color.BLACK
	black.z_index = 30
	black.mouse_filter = Control.MOUSE_FILTER_IGNORE
	run.add_child(black)
	black.hide()
	camera_m = run.model.x
	update_follow_scene()

func _physics_process(_delta: float) -> void:
	trigger.position.x = (locker_x - 5) * GameState.balance.px_per_m
	probe.position = Vector2(run.model.x * GameState.balance.px_per_m, GameState.balance.layout.feet_y)
	# Retry overlaps after respawn; a contact during capture must not start the film.
	if not entered and trigger.overlaps_area(probe): on_arrival(probe)

func on_arrival(area: Area2D) -> void:
	if area != probe or entered or run.dream_left > 0 or run.state.status != "running": return
	# Do not take control while the landmark is still offscreen.
	if locker == null or not locker.is_visible_in_tree(): return
	entered = true
	active = true
	phase = "approach"
	age = 0
	camera_m = run.model.x
	run.hud_layer.hide()
	locker.z_index = 6
	run.position = Vector2.ZERO
	for node in [run.wall, run.peek, run.eye, run.crack, run.beam, run.hand, run.shade, run.edge_shade, run.slam_face, run.slam_text]: node.hide()
	Sfx.set_loop_volume("mus_song", -25, 2)

func update_follow_scene() -> void:
	if not active: camera_m = run.model.x
	# Before activation, the unmodified original RunView owns object projection/culling.
	if active and locker != null:
		locker.position.x = (locker_x - camera_m) * GameState.balance.px_per_m + GameState.balance.player_screen_x - locker.size.x * 0.5
		locker.show()

func render_camera() -> void:
	for item in run.layers:
		item.sprite.position.x = item.tile * item.width - fposmod(camera_m * GameState.balance.px_per_m * item.factor, item.width)
	var left: float = camera_m * GameState.balance.px_per_m - GameState.balance.player_screen_x
	for item in run.world_props: item.sprite.position.x = item.x * GameState.balance.px_per_m - left - item.sprite.size.x * 0.5
	run.mina.position.x = run.model.x * GameState.balance.px_per_m - left - run.mina.size.x * 0.5
	# Keep the existing occluded view through the film, following Mina as the camera stops.
	(run.darkness.material as ShaderMaterial).set_shader_parameter("center", Vector2(run.mina.position.x + run.mina.size.x * 0.5, GameState.balance.layout.feet_y - 180))
	update_follow_scene()

func step(delta: float) -> void:
	age += delta
	if phase == "approach":
		run.model.x = move_toward(run.model.x, locker_x + 0.2, delta * 7)
		var lock_at: float = locker_x - (960 - GameState.balance.player_screen_x) / GameState.balance.px_per_m
		camera_m = minf(run.model.x, lock_at)
		camera_locked = camera_m >= lock_at
		run.mina.base_key = "mina_run"
		run.mina.animation_fps = 11
		if run.model.x >= locker_x:
			phase = "hide"
			age = 0
			run.mina.base_key = "mina_crouch"
			Sfx.play("sfx_mina_pant", -18)
	elif phase == "hide":
		if age >= 1.8:
			phase = "pass"
			age = 0
			monster.show()
			Sfx.play_at("sfx_m1_roar", -8, 0.9, -1)
	elif phase == "pass":
		monster.texture = MonsterAnimation.at_time(age, GameState.balance.level_view.m1_fps)
		monster.position.x = lerpf(-950, 2200, minf(age / 3.6, 1))
		if age >= 4.2:
			monster.hide()
			phase = "emerge"
			age = 0
	elif phase == "emerge":
		run.model.x = move_toward(run.model.x, locker_x + 5.0, delta * 2)
		run.mina.base_key = "mina_walk"
		if age >= 2.8:
			phase = "look"
			age = 0
			run.mina.base_key = "mina_idle"
	elif phase == "look":
		run.mina.pivot_offset = run.mina.size * 0.5
		run.mina.scale.x = -1 if age < 0.7 or (age > 1.35 and age < 2) else 1
		if age >= 2.6:
			phase = "black"
			age = 0
			black.show()
			Sfx.play("sfx_title_laugh", -10)
	elif phase == "black":
		camera_m = lerpf(camera_m, run.model.x, minf(1, delta * 10))
		if age >= 0.65:
			active = false
			phase = "complete"
			camera_locked = false
			run.mina.scale = Vector2.ONE
			run.mina.position.x = GameState.balance.player_screen_x - run.mina.size.x * 0.5
			run.start_night_continuation()
			return
	render_camera()
