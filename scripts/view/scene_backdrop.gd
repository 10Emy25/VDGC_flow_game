class_name SceneBackdrop
extends Control
# Native atlas regions crop the supplied sheet without regenerating or altering its pixels.
var day: TextureRect
var night: TextureRect
var horror := false
var mirrored := false

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	day = make_slot(preload("res://art/scene_day.tres"))
	night = make_slot(preload("res://art/scene_night.tres"))
	set_horror(horror)

func make_slot(texture_value: Texture2D) -> TextureRect:
	var slot := TextureRect.new()
	slot.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	slot.texture = texture_value
	slot.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	# Preserve the entire crop in the game's wide frame, with no white margins/letterbox.
	slot.stretch_mode = TextureRect.STRETCH_SCALE
	slot.flip_h = mirrored
	slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(slot)
	return slot

func set_horror(value: bool) -> void:
	horror = value
	if day != null: day.visible = not value
	if night != null: night.visible = value
