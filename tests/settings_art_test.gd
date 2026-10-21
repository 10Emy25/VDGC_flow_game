extends Node

func _ready() -> void:
 var original: float = GameState.settings.font_scale
 GameState.settings.font_scale = 1.0
 var main: Control = load("res://scenes/main.tscn").instantiate()
 add_child(main)
 var menu: TitleMenu = main.current_view
 menu.menu_music.play(2.0)
 main.toggle_settings()
 var settings: SettingsPanel = main.settings_panel
 assert(settings.visible and settings.art_page.visible and get_tree().paused)
 assert(not settings.panel.visible and menu.menu_music.stream_paused)
 assert(not settings.laugh_audio.playing, "Settings does not play a laugh")
 assert(settings.font_plus.get_rect().has_point(Vector2(1950,715)*settings.size/Vector2(2360,1640)))
 settings.font_plus.pressed.emit()
 assert(is_equal_approx(GameState.settings.font_scale,1.05))
 assert(settings.font_percent.text == "105%")
 assert(is_equal_approx(float(settings.art_material.get_shader_parameter("font_scale")),1.05))
 for material in menu.text_materials:
  assert(is_equal_approx(float(material.get_shader_parameter("font_scale")),1.05))
 var dialogue := UIFactory.label(main,"",Rect2(0,0,1000,100),40)
 dialogue.text = "Mina...I am really worried"
 await get_tree().process_frame
 assert(dialogue.get_theme_font_size("font_size") == 42)
 settings.font_plus.pressed.emit()
 assert(dialogue.get_theme_font_size("font_size") == 44)
 settings.font_minus.pressed.emit()
 assert(dialogue.get_theme_font_size("font_size") == 42)
 var count := settings.cursor_presses
 settings.cursor_minus.pressed.emit()
 settings.cursor_plus.pressed.emit()
 assert(settings.cursor_presses == count+2)
 assert(is_equal_approx(GameState.settings.font_scale,1.05))
 GameState.settings.font_scale = 1.15
 settings.refresh()
 assert(settings.font_plus.disabled and not settings.font_minus.disabled)
 settings.change_font(0.05)
 assert(is_equal_approx(GameState.settings.font_scale,1.15))
 GameState.settings.font_scale = 0.85
 settings.refresh()
 assert(settings.font_minus.disabled)
 settings.change_font(-0.05)
 assert(is_equal_approx(GameState.settings.font_scale,0.85))
 settings.homepage.pressed.emit()
 assert(not settings.visible and not get_tree().paused)
 assert(main.current_view == menu and not menu.menu_music.stream_paused)
 assert(not settings.static_audio.playing and not settings.laugh_audio.playing)
 menu.sound_button.pressed.emit()
 main.toggle_settings()
 assert(settings.sounds_muted and menu.menu_music.stream_paused)
 settings.close()
 main.show_warning()
 main.toggle_settings()
 settings.homepage.pressed.emit()
 assert(main.current_view is TitleMenu and not get_tree().paused)
 assert(not settings.visible)
 # Restore the in-memory setting; file writes are denied in the sandbox.
 GameState.settings.font_scale = original
 GameState.settings_changed.emit()
 GameState.scale_all_text(get_tree().root)
 print("Settings art passed: scaled hotspots, font +/- and limits, existing/new dialogue sizes, artwork text scale, cursor press feedback, homepage from menu/game, paused/resumed music and mute")
 main.queue_free()
 await get_tree().process_frame
 await get_tree().process_frame
 get_tree().quit()
