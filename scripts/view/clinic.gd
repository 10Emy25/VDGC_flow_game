class_name ClinicView
extends Control

signal entered_dream
var flow: CalibrationFlow
var sand: TextureRect
var figure: TextureRect
var doll: TextureRect
var subtitle: Label
var hint: Label
var mask_image: Image
var mask_texture: ImageTexture
var sand_material: ShaderMaterial
var brushing := false
var brush_ready := false
var transitioning := false
var transition_time := 0.0
var particles: Array[Dictionary] = []
var last_brush := Vector2.INF
var wash: ColorRect
var particle_layer: Node2D
var sand_sound_age := 0.0
var hud_layer: CanvasLayer

func _ready() -> void:
	theme = GameState.ui_theme
	GameState.world_real = 0.0
	PostFX.stress = 0.0
	Sfx.stop_all()
	Sfx.loop("amb_clinic", true, GameState.balance.audio.clinic_db)
	Sfx.loop("amb_clock", true, GameState.balance.audio.clock_db)
	UIFactory.texture(self, "clinic_bg", Rect2(Vector2.ZERO, Vector2(GameState.balance.layout.screen[0], GameState.balance.layout.screen[1])))
	hud_layer = CanvasLayer.new()
	hud_layer.layer = 8
	add_child(hud_layer)
	UIFactory.label(hud_layer, "clinic_caption", Rect2(60, 44, 600, 54), GameState.balance.ui.small_size).horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	UIFactory.texture(self, "sandtray", UIFactory.rect(GameState.balance.layout.tray_rect))
	doll = UIFactory.texture(self, "buried_runner_doll", UIFactory.rect(GameState.balance.layout.doll_rect))
	sand = UIFactory.texture(self, "sand_layer", UIFactory.rect(GameState.balance.layout.sand_rect))
	var mask_size: Array = GameState.balance.layout.mask_size
	mask_image = Image.create(mask_size[0], mask_size[1], false, Image.FORMAT_RGBA8)
	mask_image.fill(Color.BLACK)
	mask_texture = ImageTexture.create_from_image(mask_image)
	sand_material = ShaderMaterial.new()
	sand_material.shader = load("res://shaders/sand_mask.gdshader")
	sand_material.set_shader_parameter("brush_mask", mask_texture)
	sand.material = sand_material
	figure = UIFactory.texture(self, "clinic_figure", UIFactory.rect(GameState.balance.layout.figure_rect))
	flow = CalibrationFlow.new()
	hud_layer.add_child(flow)
	flow.finished.connect(calibration_finished)
	particle_layer = Node2D.new()
	add_child(particle_layer)
	particle_layer.draw.connect(draw_particles)
	wash = ColorRect.new()
	wash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	wash.color = Color(GameState.balance.palette.mint, 0.0)
	wash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var trance_material := ShaderMaterial.new()
	trance_material.shader = load("res://shaders/clinic_trance.gdshader")
	trance_material.set_shader_parameter("pastel", Color(GameState.balance.palette.mint))
	var doll_rect := UIFactory.rect(GameState.balance.layout.doll_rect)
	trance_material.set_shader_parameter("focus", doll_rect.get_center() / Vector2(GameState.balance.layout.screen[0], GameState.balance.layout.screen[1]))
	wash.material = trance_material
	add_child(wash)
	wash.hide()

func calibration_finished(_result: Dictionary) -> void:
	flow.hide()
	brush_ready = true
	figure.hide()
	subtitle = UIFactory.subtitle(hud_layer, "tidy", UIFactory.rect(GameState.balance.layout.subtitle_rect))
	hint = UIFactory.label(hud_layer, "brush_hint", Rect2(410, 815, 1100, 52), GameState.balance.ui.small_size)
	move_child(wash, get_child_count() - 1)

func _gui_input(event: InputEvent) -> void:
	if not brush_ready or transitioning:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		brushing = event.pressed
		last_brush = Vector2.INF
		Sfx.loop("sfx_sand", false)
		if brushing:
			brush_at(event.position)
	elif event is InputEventMouseMotion and brushing:
		brush_at(event.position)

func sand_draw_rect() -> Rect2:
	var texture_size := sand.texture.get_size()
	var scale_value := minf(sand.size.x / texture_size.x, sand.size.y / texture_size.y)
	var drawn := texture_size * scale_value
	return Rect2(sand.position + (sand.size - drawn) * 0.5, drawn)

func brush_at(point: Vector2) -> void:
	var rect_value := sand_draw_rect()
	if not rect_value.has_point(point):
		last_brush = Vector2.INF
		return
	# Interpolate mouse strokes so fast drags leave no gaps in the mask.
	if last_brush != Vector2.INF:
		var distance := last_brush.distance_to(point)
		var steps := maxi(1, int(ceil(distance / (GameState.balance.sand.brush_radius_px * 0.3))))
		for index in range(steps):
			stamp(last_brush.lerp(point, float(index + 1) / steps), rect_value)
	else:
		stamp(point, rect_value)
	last_brush = point
	mask_texture.update(mask_image)
	if sand_sound_age >= GameState.balance.sand.sound_interval_s:
		Sfx.play("sfx_sand", GameState.balance.audio.sand_db)
		sand_sound_age = 0.0
	for index in range(GameState.balance.layout.sand_particle_count):
		particles.append({"point": point, "velocity": Vector2(randf_range(-50, 50), randf_range(-75, -25)), "life": GameState.balance.layout.sand_particle_life_s})
	if reveal_fraction() >= GameState.balance.sand.reveal_target:
		start_transition()

func stamp(point: Vector2, rect_value: Rect2) -> void:
	var scale_value := Vector2(mask_image.get_width(), mask_image.get_height()) / rect_value.size
	var center := (point - rect_value.position) * scale_value
	var radius: float = GameState.balance.sand.brush_radius_px * scale_value.x
	for y in range(maxi(0, int(center.y - radius)), mini(mask_image.get_height(), int(ceil(center.y + radius)))):
		for x in range(maxi(0, int(center.x - radius)), mini(mask_image.get_width(), int(ceil(center.x + radius)))):
			var amount := 1.0 - smoothstep(radius * 0.6, radius, center.distance_to(Vector2(x, y)))
			if amount > mask_image.get_pixel(x, y).r:
				mask_image.set_pixel(x, y, Color(amount, amount, amount, 1.0))

func reveal_fraction() -> float:
	var rect_value := sand_draw_rect()
	var scale_value := Vector2(mask_image.get_width(), mask_image.get_height()) / rect_value.size
	var doll_rect := UIFactory.rect(GameState.balance.layout.doll_rect)
	var top_left := (doll_rect.position - rect_value.position) * scale_value
	var bottom_right := (doll_rect.end - rect_value.position) * scale_value
	var revealed := 0.0
	var count := 0
	for y in range(maxi(0, int(top_left.y)), mini(mask_image.get_height(), int(bottom_right.y))):
		for x in range(maxi(0, int(top_left.x)), mini(mask_image.get_width(), int(bottom_right.x))):
			revealed += mask_image.get_pixel(x, y).r
			count += 1
	return revealed / maxi(count, 1)

func start_transition() -> void:
	transitioning = true
	wash.show()
	brushing = false
	subtitle.text = GameState.text("find")
	hint.hide()
	Sfx.play("sfx_blur_in", GameState.balance.audio.blur_db)
	Sfx.set_loop_volume("amb_clinic", GameState.balance.audio.mic_mute_db, GameState.balance.sand.transition_s)

func _process(delta: float) -> void:
	sand_sound_age += delta
	if flow != null and not flow.done and flow.stage == 1:
		figure.flip_h = VoiceInput.is_audible
	for particle in particles:
		particle.life -= delta
		particle.point += particle.velocity * delta
	particles = particles.filter(func(p: Dictionary) -> bool: return p.life > 0.0)
	if transitioning:
		transition_time += delta
		var progress := clampf(transition_time / GameState.balance.sand.transition_s, 0.0, 1.0)
		wash.material.set_shader_parameter("progress", progress)
		if particles.size() < 80:
			particles.append({"point": Vector2(randf_range(450, 1470), randf_range(250, 760)), "velocity": Vector2(0, -GameState.balance.layout.particle_rise_px), "life": GameState.balance.layout.sand_particle_life_s})
		if progress >= 1.0:
			transitioning = false
			entered_dream.emit()
	particle_layer.queue_redraw()

func draw_particles() -> void:
	for particle in particles:
		particle_layer.draw_circle(particle.point, 2.5, Color(GameState.balance.palette.gold, clampf(particle.life / GameState.balance.layout.sand_particle_life_s, 0.0, 1.0)))
