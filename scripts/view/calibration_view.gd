class_name CalibrationView
extends Control
# Before the story: tune the microphone to the player's voice (a moment of silence, a normal hello,
# one loud call). The same backdrop is used for recalibration from the settings panel.

signal finished
var flow: CalibrationFlow

func _ready() -> void:
	theme = GameState.ui_theme
	GameState.world_real = 0.0
	PostFX.stress = 0.0
	Sfx.stop_all()
	build_backdrop(self)
	flow = CalibrationFlow.new()
	add_child(flow)
	flow.finished.connect(func(_result: Dictionary) -> void: finished.emit())

static func build_backdrop(parent: Control) -> void:
	var background := ColorRect.new()
	background.size = Vector2(GameState.balance.layout.screen[0], GameState.balance.layout.screen[1])
	background.color = Color(GameState.balance.palette.cream)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(background)
	UIFactory.label(parent, "calibration_title", Rect2(400, 150, 1120, 90), GameState.balance.ui.title_size)
	var note := UIFactory.label(parent, "calibration_note", Rect2(360, 255, 1200, 60), GameState.balance.ui.body_size)
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
