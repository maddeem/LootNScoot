class_name Math

const DIR_MAP = [6, 7, 0, 1, 2, 3, 4, 5]
const INV_TAU_TIMES_8 = 8.0 / TAU  # Pre-compute division

static func get_sprite_direction(from : Vector2, to : Vector2) -> int:
	from = MouseTracker.cord2Grid(from)
	to = MouseTracker.cord2Grid(to)
	var dx = from.x - to.x
	var dy = from.y - to.y
	var dir = int((atan2(dy, dx) + PI) * INV_TAU_TIMES_8) - 1
	return DIR_MAP[dir & 7]

static func angle_between(pos1 : Vector2, pos2 : Vector2) -> float:
	return atan2(pos1.y - pos2.y, pos1.x - pos2.x)
