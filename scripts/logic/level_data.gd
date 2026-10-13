class_name LevelData
extends RefCounted

var events: Array

func _init(data: Dictionary) -> void:
	events = data.events

func first(kind: String) -> Dictionary:
	for event in events:
		if event.type == kind:
			return event
	return {}
