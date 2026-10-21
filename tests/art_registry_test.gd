extends MinaTestSuite

func _ready() -> void:
	# Fixture PNG and SVG are created/imported by tools/run_tests.py, then removed.
	var texture := ArtRegistry.get_texture("r1_override_probe_cute")
	near(texture.get_width(), 94, "Same-name PNG overrides 256px SVG")
	near(texture.get_height(), 37, "Different aspect PNG loads")
	check(texture == ArtRegistry.get_texture("r1_override_probe_cute"), "Textures cached")
	var frames := ArtRegistry.frames("r1_override_probe_cute", "mina_idle")
	check(frames.size() == int(GameState.balance.art_frames.mina_idle), "Frame count comes from balance")
	near(frames[0].get_width(), 94.0 / GameState.balance.art_frames.mina_idle, "Strip splits new resolution evenly")
	var slot := UIFactory.texture(self, "r1_override_probe_cute", Rect2(25, 50, 300, 360))
	check(slot.size == Vector2(300, 360), "Slot size unaffected by replacement")
	check(slot.stretch_mode == TextureRect.STRETCH_KEEP_ASPECT_CENTERED and slot.expand_mode == TextureRect.EXPAND_IGNORE_SIZE, "Replacement keeps aspect and centers")
	var dual := DualSprite.new()
	dual.base_key = "r1_override_probe"
	dual.size = Vector2(300, 360)
	add_child(dual)
	check(dual.real_frames[0].atlas == texture, "Missing real version derives from cute PNG")
	check(dual.real.material.get_shader_parameter("derive_real"), "Real derive shader enabled")
	GameState.world_real = 0.35
	dual.update_blend()
	near(dual.real.modulate.a, 0.35, "Dual blend obeys GameState")
	near(dual.cute.modulate.a, 0.65, "Cute complement")
	GameState.settings.reduce_distortion = true
	dual.update_blend()
	check(dual.real.material.get_shader_parameter("reduce_distortion"), "Reduce distortion reaches sprite shader")
	var mina := DualSprite.new()
	mina.base_key = "mina_idle"
	mina.size = Vector2(300, 360)
	add_child(mina)
	check(mina.real.material.get_shader_parameter("source_size") == mina.real_frames[0].get_size(), "Standalone Mina frames use their full texture size")
	GameState.world_real = 0
	finish()
