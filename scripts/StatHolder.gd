extends Resource
class_name StatHolder

var _stats_by_name: Dictionary = {}
var _stat_list: Array[Stat] = []

@export var StatList : Array[Stat]:
	get:
		return _stat_list
	set(value):
		_stat_list = value
		_build_stat_dictionary()

func _build_stat_dictionary():
	_stats_by_name.clear()
	for stat_obj in _stat_list:
		if stat_obj is Stat and stat_obj.name:
			_stats_by_name[stat_obj.name] = stat_obj
		else:
			push_warning("StatHolder: Encountered an invalid stat object or missing 'name' in StatList. Object: %s" % str(stat_obj))

func _get(property: StringName) -> Variant:
	if _stats_by_name.has(property):
		return _stats_by_name[property]
	return null
