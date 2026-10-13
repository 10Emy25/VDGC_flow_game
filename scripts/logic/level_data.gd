class_name LevelData
extends RefCounted

var events: Array

func _init(data: Dictionary) -> void:
	# Own copy: the chase can be shifted at runtime (see shift_from) without touching GameState.level.
	events = data.events.duplicate(true)

# Move every event at or beyond `from_x` by `offset` metres and keep the list ordered.
func shift_from(from_x: float, offset: float) -> void:
	for event in events:
		if event.x >= from_x:
			event.x += offset
	events.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.x < b.x)

func first(kind: String) -> Dictionary:
	for event in events:
		if event.type == kind:
			return event
	return {}

func of_type(kind: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for event in events:
		if event.type == kind:
			result.append(event)
	return result

func section_at(x: float) -> String:
	var section := "S1"
	for event in events:
		if event.x > x:
			break
		if event.type == "section":
			section = event.id
	return section

func checkpoint_at(x: float, half_width: float) -> Dictionary:
	for event in events:
		if event.type == "checkpoint" and absf(x - event.x) <= half_width:
			return event
	return {}

func covered(x: float, speed: float, config: Dictionary) -> bool:
	if speed >= config.hide_speed:
		return false
	for event in events:
		if event.type == "cover" and absf(x - event.x) <= config.cover_half_width_m:
			return true
	return false

func validation_errors(config: Dictionary) -> Array[String]:
	var errors: Array[String] = []
	var previous := -INF
	for event in events:
		if event.x < previous:
			errors.append("Level events must be ordered by x")
		previous = event.x
		if event.type != "gaze":
			continue
		var found := false
		for cover in of_type("cover"):
			if cover.x >= event.x and cover.x - event.x <= config.m2.max_cover_distance_m:
				found = true
		if not found:
			errors.append("Gaze at %s has no cover within %s m" % [event.x, config.m2.max_cover_distance_m])
	return errors
