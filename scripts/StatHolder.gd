extends Resource
class_name StatHolder

var _stats_by_name: Dictionary = {}

@export var StatList : Array[Stat]:
	set(value):
		StatList = value
		_build_stat_dictionary()

func _build_stat_dictionary():
	for stat_obj in StatList:
		_stats_by_name[stat_obj.name] = stat_obj.duplicate()

func _get(property: StringName):
	if _stats_by_name.has(property):
		return _stats_by_name[property]
