class_name Stat extends Resource

@export var current_value: float = 0.0:
	set(new_value):
		current_value = clamp(new_value, min_value, max_value)
		emit_changed()
@export var min_value: float = -INF
@export var max_value: float = INF
var per_modifier := 1.0
var flat_modifier := 0.0

signal value_changed(new_value: float)

func add_value(amount: float):
	current_value += amount
	value_changed.emit(current_value)

func subtract_value(amount: float):
	current_value -= amount
	value_changed.emit(current_value)

func set_value(new_value: float):
	current_value = new_value
	value_changed.emit(current_value)

func set_max_value(new_value: float):
	max_value = new_value
	current_value = min(current_value,max_value)
	value_changed.emit(current_value)

func apply_modifier(mod: float, is_percentage: bool = false):
	if is_percentage:
		per_modifier += mod
	else:
		flat_modifier += mod
	value_changed.emit(current_value)

func get_current_value() -> float:
	return (current_value + flat_modifier) * per_modifier

func get_min_value() -> float:
	return min_value

func get_max_value() -> float:
	return (max_value + flat_modifier) * per_modifier
