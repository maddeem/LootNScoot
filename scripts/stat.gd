class_name Stat extends Resource

@export var name : String = ""
var current_value : float
@export var base_value: float = 0.0:
	set(value):
		base_value = max(value,min_value)
		current_value = base_value
@export var min_value: float = 0
var per_modifier := 1.0
var flat_modifier := 0.0

func apply_modifier(mod: float, is_percentage: bool = false):
	if is_percentage:
		per_modifier += mod
	else:
		flat_modifier += mod

func get_total() -> float:
	return (base_value + flat_modifier) * per_modifier

func get_current() -> float:
	return current_value

func subtract_current(amount : float):
	current_value = max(current_value-amount,0)
	return current_value

func increment() -> void:
	current_value += get_total()

func use_total() -> int:
	var ret = floor(current_value)
	current_value -= ret
	return ret

func increment_and_use_total() -> int:
	increment()
	return use_total()

func get_percent_of_total() -> float:
	return current_value / get_total()
