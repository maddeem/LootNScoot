class_name Math

static func radianSegment(radian: float, num_segments: int) -> int:
	var normalized_radian = fmod(fmod(radian, TAU) + TAU, TAU)
	var segment_size = TAU / float(num_segments)
	return floor(normalized_radian / segment_size) + 1

static func get_sprite_direction(from : Vector2, to : Vector2) -> int:
	from = MouseTracker.cord2Grid(from)
	to = MouseTracker.cord2Grid(to)
	var dir = int(ceil(((atan2(from.y-to.y,from.x-to.x) + PI)/TAU) * 8)-1)
	match dir:
		0: return 6
		1: return 7
		2: return 0
		3: return 1
		4: return 2
		5: return 3
		6: return 4
		7: return 5
	return -1
