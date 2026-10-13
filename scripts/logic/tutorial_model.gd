class_name TutorialModel
extends RefCounted

var stages: Array
var index := 0
var age := 0.0
var held := 0.0

func _init(data: Array) -> void:
	stages = data

func step(delta: float, tier_index: int) -> void:
	if complete():
		return
	age += delta
	if tier_index >= stages[index].tier:
		held += delta
	if age >= stages[index].min_s and held >= stages[index].hold_s:
		index += 1
		age = 0.0
		held = 0.0

func complete() -> bool:
	return index >= stages.size()
