extends Node
class_name DungeonMaker

#=============================================================================
# ==== Helper Functions & Classes ============================================
#=============================================================================

# Helper to create a 2D grid, mimicking the Python list comprehension
static func create_grid(width: int, height: int, default_value) -> Array:
	var grid: Array = []
	grid.resize(width)
	for x in width:
		var column: Array = []
		column.resize(height)
		column.fill(default_value)
		grid[x] = column
	return grid

# A custom Rect class to mirror the Python implementation's use of x1, y1, x2, y2.
# Named DG_Rect to avoid conflict with Godot's built-in Rect2/Rect2i.
class DG_Rect:
	var x1: int
	var y1: int
	var x2: int
	var y2: int

	func _init(x: int, y: int, w: int, h: int):
		self.x1 = x
		self.y1 = y
		self.x2 = x + w
		self.y2 = y + h

	func center() -> Vector2i:
		var center_x = (x1 + x2) / 2
		var center_y = (y1 + y2) / 2
		return Vector2i(center_x, center_y)

	func intersect(other: DG_Rect) -> bool:
		# returns true if this rectangle intersects with another one
		return (x1 <= other.x2 and x2 >= other.x1 and
				y1 <= other.y2 and y2 >= other.y1)

# Helper class for the BSP tree algorithm
class Leaf:
	var x: int
	var y: int
	var width: int
	var height: int
	var MIN_LEAF_SIZE: int = 10
	var child_1: Leaf = null
	var child_2: Leaf = null
	var room: DG_Rect = null
	var hall: DG_Rect = null

	func _init(x1: int, y1: int, w: int, h: int):
		self.x = x1
		self.y = y1
		self.width = w
		self.height = h

	func split_leaf() -> bool:
		# begin splitting the leaf into two children
		if child_1 != null or child_2 != null:
			return false # This leaf has already been split

		# Determine the direction of the split
		var split_horizontally = [true, false].pick_random()
		if float(width) / float(height) >= 1.25:
			split_horizontally = false
		elif float(height) / float(width) >= 1.25:
			split_horizontally = true

		var max_size = (height if split_horizontally else width) - MIN_LEAF_SIZE
		if max_size <= MIN_LEAF_SIZE:
			return false # the leaf is too small to split further

		var split = randi_range(MIN_LEAF_SIZE, max_size) # determine where to split the leaf

		if split_horizontally:
			child_1 = Leaf.new(x, y, width, split)
			child_2 = Leaf.new(x, y + split, width, height - split)
		else:
			child_1 = Leaf.new(x, y, split, height)
			child_2 = Leaf.new(x + split, y, width - split, height)

		return true

	func create_rooms(bsp_tree_generator) -> void:
		if child_1 or child_2:
			# recursively search for children until you hit the end of the branch
			if child_1:
				child_1.create_rooms(bsp_tree_generator)
			if child_2:
				child_2.create_rooms(bsp_tree_generator)

			if child_1 and child_2:
				bsp_tree_generator.create_hall(child_1.get_room(), child_2.get_room())
		else:
			# Create rooms in the end branches of the bsp tree
			var w = randi_range(bsp_tree_generator.ROOM_MIN_SIZE, min(bsp_tree_generator.ROOM_MAX_SIZE, width - 1))
			var h = randi_range(bsp_tree_generator.ROOM_MIN_SIZE, min(bsp_tree_generator.ROOM_MAX_SIZE, height - 1))
			var room_x = randi_range(x, x + (width - 1) - w)
			var room_y = randi_range(y, y + (height - 1) - h)
			room = DG_Rect.new(room_x, room_y, w, h)
			bsp_tree_generator.create_room(room)

	func get_room():
		if room:
			return room
		else:
			var room_1 = null
			var room_2 = null
			if child_1:
				room_1 = child_1.get_room()
			if child_2:
				room_2 = child_2.get_room()

			if not child_1 and not child_2:
				return null
			elif not room_2:
				return room_1
			elif not room_1:
				return room_2
			# If both room_1 and room_2 exist, pick one
			elif randf() < 0.5:
				return room_1
			else:
				return room_2


#=============================================================================
# ==== Algorithm Classes ======================================================
#=============================================================================

class TunnelingAlgorithm:
	var level: Array
	var ROOM_MAX_SIZE: int = 15
	var ROOM_MIN_SIZE: int = 6
	var MAX_ROOMS: int = 30

	func generate_level(map_width: int, map_height: int) -> Array:
		level = DungeonMaker.create_grid(map_width, map_height, 1)
		var rooms: Array = []
		var num_rooms: int = 0

		for r in MAX_ROOMS:
			var w = randi_range(ROOM_MIN_SIZE, ROOM_MAX_SIZE)
			var h = randi_range(ROOM_MIN_SIZE, ROOM_MAX_SIZE)
			var x = randi_range(0, map_width - w - 1)
			var y = randi_range(0, map_height - h - 1)

			var new_room = DG_Rect.new(x, y, w, h)
			var failed = false
			for other_room in rooms:
				if new_room.intersect(other_room):
					failed = true
					break

			if not failed:
				create_room(new_room)
				var new_pos = new_room.center()

				if num_rooms != 0:
					var prev_pos = rooms[num_rooms - 1].center()
					if randi_range(0, 1) == 1:
						create_hor_tunnel(prev_pos.x, new_pos.x, prev_pos.y)
						create_vir_tunnel(prev_pos.y, new_pos.y, new_pos.x)
					else:
						create_vir_tunnel(prev_pos.y, new_pos.y, prev_pos.x)
						create_hor_tunnel(prev_pos.x, new_pos.x, new_pos.y)

				rooms.append(new_room)
				num_rooms += 1

		return level

	func create_room(room: DG_Rect) -> void:
		for x in range(room.x1 + 1, room.x2):
			for y in range(room.y1 + 1, room.y2):
				level[x][y] = 0

	func create_hor_tunnel(x1: int, x2: int, y: int) -> void:
		for x in range(min(x1, x2), max(x1, x2) + 1):
			level[x][y] = 0

	func create_vir_tunnel(y1: int, y2: int, x: int) -> void:
		for y in range(min(y1, y2), max(y1, y2) + 1):
			level[x][y] = 0

# ---
class BSPTree:
	var level: Array
	var room = null
	var MAX_LEAF_SIZE: int = 24
	var ROOM_MAX_SIZE: int = 15
	var ROOM_MIN_SIZE: int = 6
	var _leafs: Array

	func generate_level(map_width: int, map_height: int) -> Array:
		level = DungeonMaker.create_grid(map_width, map_height, 1)
		_leafs = []
		
		var root_leaf = Leaf.new(0, 0, map_width, map_height)
		_leafs.append(root_leaf)

		var split_successfully = true
		while split_successfully:
			split_successfully = false
			for l in _leafs:
				if l.child_1 == null and l.child_2 == null:
					if (l.width > MAX_LEAF_SIZE or l.height > MAX_LEAF_SIZE or randf() > 0.8):
						if l.split_leaf():
							_leafs.append(l.child_1)
							_leafs.append(l.child_2)
							split_successfully = true

		root_leaf.create_rooms(self)
		return level

	func create_room(r: DG_Rect) -> void:
		for x in range(r.x1 + 1, r.x2):
			for y in range(r.y1 + 1, r.y2):
				level[x][y] = 0

	func create_hall(room1: DG_Rect, room2: DG_Rect) -> void:
		var p1 = room1.center()
		var p2 = room2.center()
		if randi_range(0, 1) == 1:
			create_hor_tunnel(p1.x, p2.x, p1.y)
			create_vir_tunnel(p1.y, p2.y, p2.x)
		else:
			create_vir_tunnel(p1.y, p2.y, p1.x)
			create_hor_tunnel(p1.x, p2.x, p2.y)

	func create_hor_tunnel(x1: int, x2: int, y: int) -> void:
		for x in range(min(x1, x2), max(x1, x2) + 1):
			level[x][y] = 0

	func create_vir_tunnel(y1: int, y2: int, x: int) -> void:
		for y in range(min(y1, y2), max(y1, y2) + 1):
			level[x][y] = 0

# ---
class DrunkardsWalk:
	var level: Array
	var _percent_goal: float = 0.4
	var walk_iterations: int = 25000
	var weighted_toward_center: float = 0.15
	var weighted_toward_previous_direction: float = 0.7
	var _filled: int
	var _previous_direction: String
	var drunkard_x: int
	var drunkard_y: int
	var filled_goal: int

	func generate_level(map_width: int, map_height: int) -> Array:
		walk_iterations = max(walk_iterations, (map_width * map_height * 10))
		level = DungeonMaker.create_grid(map_width, map_height, 1)
		_filled = 0
		_previous_direction = ""
		
		drunkard_x = randi_range(2, map_width - 2)
		drunkard_y = randi_range(2, map_height - 2)
		filled_goal = (map_width * map_height) * _percent_goal

		for i in walk_iterations:
			_walk(map_width, map_height)
			if _filled >= filled_goal:
				break
		
		return level

	func _walk(map_width: int, map_height: int) -> void:
		var north: float = 1.0
		var south: float = 1.0
		var east: float = 1.0
		var west: float = 1.0

		if drunkard_x < map_width * 0.25: east += weighted_toward_center
		elif drunkard_x > map_width * 0.75: west += weighted_toward_center
		if drunkard_y < map_height * 0.25: south += weighted_toward_center
		elif drunkard_y > map_height * 0.75: north += weighted_toward_center

		if _previous_direction == "north": north += weighted_toward_previous_direction
		if _previous_direction == "south": south += weighted_toward_previous_direction
		if _previous_direction == "east": east += weighted_toward_previous_direction
		if _previous_direction == "west": west += weighted_toward_previous_direction

		var total = north + south + east + west
		north /= total
		south /= total
		east /= total
		# west /= total # Implicit

		var choice = randf()
		var dx = 0
		var dy = 0
		var direction = ""
		if 0 <= choice and choice < north:
			dx = 0; dy = -1; direction = "north"
		elif choice < north + south:
			dx = 0; dy = 1; direction = "south"
		elif choice < north + south + east:
			dx = 1; dy = 0; direction = "east"
		else:
			dx = -1; dy = 0; direction = "west"

		if (drunkard_x + dx > 0 and drunkard_x + dx < map_width - 1 and
			drunkard_y + dy > 0 and drunkard_y + dy < map_height - 1):
			drunkard_x += dx
			drunkard_y += dy
			if level[drunkard_x][drunkard_y] == 1:
				level[drunkard_x][drunkard_y] = 0
				_filled += 1
			_previous_direction = direction

# ---
class CellularAutomata:
	var level: Array
	var caves: Array
	var iterations: int = 30000
	const neighbors = [
		Vector2i.UP, Vector2i.DOWN,
		Vector2i.RIGHT, Vector2i.LEFT
	]
	var neighborsCount: int = 4
	var wall_probability: float = 0.5
	var ROOM_MIN_SIZE: int = 16
	var smooth_edges: bool = true
	var smoothing: int = 1

	func generate_level(map_width: int, map_height: int) -> Array:
		caves = []
		level = DungeonMaker.create_grid(map_width, map_height, 1)
		_random_fill_map(map_width, map_height)
		_create_caves(map_width, map_height)
		_get_caves(map_width, map_height)
		_connect_caves(map_width, map_height)
		_clean_up_map(map_width, map_height)
		return level

	func _random_fill_map(map_width: int, map_height: int) -> void:
		for y in range(1, map_height - 1):
			for x in range(1, map_width - 1):
				if randf() >= wall_probability:
					level[x][y] = 0

	func _create_caves(map_width: int, map_height: int) -> void:
		for i in iterations:
			var tile_x = randi_range(1, map_width - 2)
			var tile_y = randi_range(1, map_height - 2)
			var adjacent = _get_adjacent_walls(tile_x, tile_y)  
			if adjacent > neighborsCount:
				level[tile_x][tile_y] = 1
			elif adjacent < neighborsCount:
				level[tile_x][tile_y] = 0
		_clean_up_map(map_width, map_height)

	func _clean_up_map(map_width: int, map_height: int) -> void:
		if smooth_edges:
			for i in 5:
				for x in range(1, map_width - 1):
					for y in range(1, map_height - 1):
						if level[x][y] == 1 and _get_adjacent_walls_simple(x, y) <= smoothing:
							level[x][y] = 0

	func _create_tunnel(p1: Vector2i, p2: Vector2i, current_cave: Dictionary, map_width: int, map_height: int) -> void:
		var drunkard_pos = p2
		while not current_cave.has(drunkard_pos):
			var north = 1.0
			var south = 1.0
			var east = 1.0
			var west = 1.0
			var weight = 1.0

			if drunkard_pos.x < p1.x: east += weight
			elif drunkard_pos.x > p1.x: west += weight
			if drunkard_pos.y < p1.y: south += weight
			elif drunkard_pos.y > p1.y: north += weight

			var total = north + south + east + west
			north /= total
			south /= total
			east /= total
			
			var choice = randf()
			var delta = Vector2i.ZERO
			if choice < north: delta = Vector2i.UP
			elif choice < north + south: delta = Vector2i.DOWN
			elif choice < north + south + east: delta = Vector2i.RIGHT
			else: delta = Vector2i.LEFT

			var next_pos = drunkard_pos + delta
			if next_pos.x > 0 and next_pos.x < map_width - 1 and next_pos.y > 0 and next_pos.y < map_height - 1:
				drunkard_pos = next_pos
				if level[drunkard_pos.x][drunkard_pos.y] == 1:
					level[drunkard_pos.x][drunkard_pos.y] = 0

	func _get_adjacent_walls_simple(x: int, y: int) -> int:
		var wall_counter = 0
		if level[x][y - 1] == 1: wall_counter += 1 # North
		if level[x][y + 1] == 1: wall_counter += 1 # South
		if level[x - 1][y] == 1: wall_counter += 1 # West
		if level[x + 1][y] == 1: wall_counter += 1 # East
		return wall_counter

	func _get_adjacent_walls(tile_x: int, tile_y: int) -> int:
		var wall_counter = 0
		for x in range(tile_x - 1, tile_x + 2):
			for y in range(tile_y - 1, tile_y + 2):
				if level[x][y] == 1:
					if x != tile_x or y != tile_y:
						wall_counter += 1
		return wall_counter

	func _get_caves(map_width: int, map_height: int) -> void:
		for x in range(0, map_width):
			for y in range(0, map_height):
				if level[x][y] == 0:
					_flood_fill(x, y)
		
		for cave_set in caves:
			for tile in cave_set:
				level[tile.x][tile.y] = 0

	func _flood_fill(x: int, y: int) -> void:
		var cave: Dictionary = {} # Using Dict as a Set for performance
		var start_tile = Vector2i(x, y)
		var to_be_filled: Array = [start_tile] # Using Array as a Stack

		while not to_be_filled.is_empty():
			var tile: Vector2i = to_be_filled.pop_back()
			if not cave.has(tile):
				cave[tile] = true
				level[tile.x][tile.y] = 1 # Mark as visited
				
				for direction in neighbors:
					var dir = direction + tile
					if level[dir.x][dir.y] == 0:
						if not to_be_filled.has(dir) and not cave.has(dir):
							to_be_filled.push_back(dir)
		
		if cave.size() >= ROOM_MIN_SIZE:
			caves.append(cave)

	func _connect_caves(map_width: int, map_height: int) -> void:
		for current_cave in caves:
			var p1 = current_cave.keys()[0]
			var p2 = null
			var distance = INF

			for next_cave in caves:
				if next_cave != current_cave:
					if not _check_connectivity(current_cave, next_cave):
						var next_point = next_cave.keys()[0]
						var new_distance = p1.distance_squared_to(next_point)
						if new_distance < distance:
							p2 = next_point
							distance = new_distance
			
			if p2 != null:
				_create_tunnel(p1, p2, current_cave, map_width, map_height)

	func _check_connectivity(cave1: Dictionary, cave2: Dictionary) -> bool:
		var connected_region: Dictionary = {}
		var start = cave1.keys()[0]
		var to_be_filled: Array = [start]

		while not to_be_filled.is_empty():
			var tile: Vector2i = to_be_filled.pop_back()
			if not connected_region.has(tile):
				connected_region[tile] = true
				for direction in neighbors:
					var dir = direction + tile
					if level[dir.x][dir.y] == 0:
						if not to_be_filled.has(dir) and not connected_region.has(dir):
							to_be_filled.push_back(dir)

		var end = cave2.keys()[0]
		return end in connected_region

# ---
class RoomAddition:
	const neighbors = [
		Vector2i.UP, Vector2i.DOWN,
		Vector2i.RIGHT, Vector2i.LEFT
	]
	var level: Array
	var rooms: Array
	var ROOM_MAX_SIZE: int = 18
	var ROOM_MIN_SIZE: int = 16
	var MAX_NUM_ROOMS: int = 30
	var SQUARE_ROOM_MAX_SIZE: int = 12
	var SQUARE_ROOM_MIN_SIZE: int = 6
	var build_room_attempts: int = 500
	var place_room_attempts: int = 20
	var max_tunnel_length: int = 12
	var include_shortcuts: bool = true
	var shortcut_attempts: int = 500
	var shortcut_length: int = 5
	var min_pathfinding_distance: int = 50
	var wall_probability: float = 0.45
	var neighborCount: int = 4
	var astar_grid: AStarGrid2D

	func generate_level(map_width: int, map_height: int) -> Array:
		rooms = []
		level = DungeonMaker.create_grid(map_width, map_height, 1)

		var first_room = _generate_room_square() # Start with a simple square room
		var room_w = len(first_room)
		var room_h = len(first_room[0])
		var room_x = (map_width / 2 - room_w / 2) - 1
		var room_y = (map_height / 2 - room_h / 2) - 1
		_add_room(room_x, room_y, first_room)

		for i in build_room_attempts:
			var room = _generate_room_cellular_automata()
			var placement = _place_room(room, map_width, map_height)
			if placement.is_empty():
				continue

			var new_room_x = placement["x"]
			var new_room_y = placement["y"]
			var wall_tile = placement["wall_tile"]
			var direction = placement["direction"]
			var tunnel_length = placement["tunnel_length"]
			
			_add_room(new_room_x, new_room_y, room)
			_add_tunnel(wall_tile, direction, tunnel_length)
			
			if len(rooms) >= MAX_NUM_ROOMS:
				break
		
		if include_shortcuts:
			_add_shortcuts(map_width, map_height)
		
		return level

	func _generate_room_square() -> Array:
		var room_w = randi_range(SQUARE_ROOM_MIN_SIZE, SQUARE_ROOM_MAX_SIZE)
		var room_h = randi_range(SQUARE_ROOM_MIN_SIZE, SQUARE_ROOM_MAX_SIZE)
		var room = DungeonMaker.create_grid(room_w, room_h, 1)
		for x in range(1, room_w - 1):
			for y in range(1, room_h - 1):
				room[x][y] = 0
		return room

	func _generate_room_cellular_automata() -> Array:
		while true:
			var room = DungeonMaker.create_grid(ROOM_MAX_SIZE, ROOM_MAX_SIZE, 1)
			for y in range(2, ROOM_MAX_SIZE - 2):
				for x in range(2, ROOM_MAX_SIZE - 2):
					if randf() >= wall_probability:
						room[x][y] = 0
			
			for i in 4:
				for y in range(1, ROOM_MAX_SIZE - 1):
					for x in range(1, ROOM_MAX_SIZE - 1):
						var adjacent = _get_adjacent_walls(x, y, room)
						if adjacent > neighborCount:
							room[x][y] = 1
						elif adjacent < neighborCount:
							room[x][y] = 0
			
			room = _flood_fill_room(room)
			if _check_room_exists(room):
				return room
		return []

	func _get_room_dimensions(room: Array) -> Vector2i:
		if not room.is_empty():
			return Vector2i(len(room), len(room[0]))
		return Vector2i.ZERO

	func _check_room_exists(room: Array) -> bool:
		var dims = _get_room_dimensions(room)
		for x in dims.x:
			for y in dims.y:
				if room[x][y] == 0:
					return true
		return false

	func _flood_fill_room(room: Array) -> Array:
		var dims = _get_room_dimensions(room)
		var largest_region: Dictionary = {}
		var temp_room = deep_copy_array(room) # Work on a copy
		
		for x in dims.x:
			for y in dims.y:
				if temp_room[x][y] == 0:
					var new_region = {}
					var to_be_filled = [Vector2i(x,y)]
					while not to_be_filled.is_empty():
						var tile: Vector2i = to_be_filled.pop_back()
						if not new_region.has(tile):
							new_region[tile] = true
							temp_room[tile.x][tile.y] = 1
							
							for n_delta in neighbors:
								var n_pos = tile + n_delta
								if temp_room[n_pos.x][n_pos.y] == 0:
									if not new_region.has(n_pos) and not to_be_filled.has(n_pos):
										to_be_filled.push_back(n_pos)
					
					if new_region.size() > largest_region.size():
						largest_region = new_region
		
		var final_room = DungeonMaker.create_grid(dims.x, dims.y, 1)
		for tile in largest_region:
			final_room[tile.x][tile.y] = 0
		return final_room
		
	func deep_copy_array(arr: Array) -> Array:
		var new_arr = []
		for item in arr:
			if item is Array:
				new_arr.append(deep_copy_array(item))
			else:
				new_arr.append(item)
		return new_arr

	func _get_adjacent_walls(tile_x: int, tile_y: int, room: Array) -> int:
		var wall_counter = 0
		for x in range(tile_x - 1, tile_x + 2):
			for y in range(tile_y - 1, tile_y + 2):
				if room[x][y] == 1:
					if x != tile_x or y != tile_y:
						wall_counter += 1
		return wall_counter

	func _place_room(room: Array, map_width: int, map_height: int) -> Dictionary:
		var room_dims = _get_room_dimensions(room)
		
		for i in place_room_attempts:
			var wall_tile = null
			var directions = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]
			var direction = directions.pick_random()
			
			while wall_tile == null:
				var tile_x = randi_range(1, map_width - 2)
				var tile_y = randi_range(1, map_height - 2)
				if (level[tile_x][tile_y] == 1 and
					level[tile_x + direction.x][tile_y + direction.y] == 1 and
					level[tile_x - direction.x][tile_y - direction.y] == 0):
					wall_tile = Vector2i(tile_x, tile_y)

			var start_room_x = -1
			var start_room_y = -1
			while start_room_x == -1:
				var x = randi_range(0, room_dims.x - 1)
				var y = randi_range(0, room_dims.y - 1)
				if room[x][y] == 0:
					start_room_x = wall_tile.x - x
					start_room_y = wall_tile.y - y
			
			for tunnel_length in max_tunnel_length:
				var possible_room_x = start_room_x + direction.x * tunnel_length
				var possible_room_y = start_room_y + direction.y * tunnel_length

				if _get_overlap(room, possible_room_x, possible_room_y, map_width, map_height):
					return {
						"x": possible_room_x, "y": possible_room_y, 
						"wall_tile": wall_tile, "direction": direction,
						"tunnel_length": tunnel_length
					}
		return {}

	func _get_overlap(room: Array, room_x: int, room_y: int, map_width: int, map_height: int) -> bool:
		var room_dims = _get_room_dimensions(room)
		for x in room_dims.x:
			for y in room_dims.y:
				if room[x][y] == 0:
					if not (room_x + x >= 1 and room_x + x < map_width - 1 and
							room_y + y >= 1 and room_y + y < map_height - 1):
						return false # Out of bounds
					
					# Check 3x3 area around the tile for existing floors
					for dx in range(-1, 2):
						for dy in range(-1, 2):
							if level[room_x + x + dx][room_y + y + dy] == 0:
								return false
		return true

	func _add_room(room_x: int, room_y: int, room: Array) -> void:
		var room_dims = _get_room_dimensions(room)
		for x in room_dims.x:
			for y in room_dims.y:
				if room[x][y] == 0:
					level[room_x + x][room_y + y] = 0
		rooms.append(room)

	func _add_tunnel(wall_tile: Vector2i, direction: Vector2i, tunnel_length: int) -> void:
		var start_pos = wall_tile + direction * tunnel_length
		for i in tunnel_length + 1:
			var pos = start_pos - direction * i
			level[pos.x][pos.y] = 0
			if pos + direction == wall_tile:
				break

	func _add_shortcuts(map_width: int, map_height: int) -> void:
		astar_grid = AStarGrid2D.new()
		_recompute_path_map(map_width, map_height)

		for i in shortcut_attempts:
			var floor_pos = Vector2i.ZERO
			while true:
				var check_x = randi_range(shortcut_length + 1, map_width - shortcut_length - 2)
				var check_y = randi_range(shortcut_length + 1, map_height - shortcut_length - 2)
				if level[check_x][check_y] == 0:
					if (level[check_x - 1][check_y] == 1 or level[check_x + 1][check_y] == 1 or
						level[check_x][check_y - 1] == 1 or level[check_x][check_y + 1] == 1):
						floor_pos = Vector2i(check_x, check_y)
						break
			
			for x in range(-1, 2):
				for y in range(-1, 2):
					if x == 0 and y == 0: continue
					
					var new_pos = floor_pos + Vector2i(x, y) * shortcut_length
					if level[new_pos.x][new_pos.y] == 0:
						var path = astar_grid.get_id_path(floor_pos, new_pos)
						if path.size() > min_pathfinding_distance:
							_carve_shortcut(floor_pos, new_pos)
							_recompute_path_map(map_width, map_height)

	func _recompute_path_map(map_width: int, map_height: int) -> void:
		astar_grid.region = Rect2i(0, 0, map_width, map_height)
		astar_grid.cell_size = Vector2i(1, 1)
		astar_grid.update()
		
		for x in map_width:
			for y in map_height:
				if level[x][y] == 1:
					astar_grid.set_point_solid(Vector2i(x, y), true)

	func _carve_shortcut(p1: Vector2i, p2: Vector2i) -> void:
		if p1.x == p2.x: # Vertical
			for y in range(min(p1.y, p2.y), max(p1.y, p2.y) + 1):
				level[p1.x][y] = 0
		elif p1.y == p2.y: # Horizontal
			for x in range(min(p1.x, p2.x), max(p1.x, p2.x) + 1):
				level[x][p1.y] = 0

# ---
class CityWalls:
	var level: Array
	var room = null
	var MAX_LEAF_SIZE: int = 30
	var ROOM_MAX_SIZE: int = 16
	var ROOM_MIN_SIZE: int = 8
	var _leafs: Array
	var rooms: Array

	func generate_level(map_width: int, map_height: int) -> Array:
		level = DungeonMaker.create_grid(map_width, map_height, 0)
		_leafs = []
		rooms = []
		
		var root_leaf = Leaf.new(0, 0, map_width, map_height)
		_leafs.append(root_leaf)
		
		var split_successfully = true
		while split_successfully:
			split_successfully = false
			for l in _leafs:
				if l.child_1 == null and l.child_2 == null:
					if l.width > MAX_LEAF_SIZE or l.height > MAX_LEAF_SIZE or randf() > 0.8:
						if l.split_leaf():
							_leafs.append(l.child_1)
							_leafs.append(l.child_2)
							split_successfully = true
		
		root_leaf.create_rooms(self)
		_create_doors()
		return level

	func create_room(r: DG_Rect) -> void:
		# Build Walls
		for x in range(r.x1 + 1, r.x2):
			for y in range(r.y1 + 1, r.y2):
				level[x][y] = 1
		# Build Interior Floor
		for x in range(r.x1 + 2, r.x2 - 1):
			for y in range(r.y1 + 2, r.y2 - 1):
				level[x][y] = 0

	func _create_doors() -> void:
		for r in rooms:
			var center = r.center()
			var wall_pos = Vector2i.ZERO
			var wall_dir = ["north", "south", "east", "west"].pick_random()
			
			match wall_dir:
				"north": wall_pos = Vector2i(center.x, r.y1 + 1)
				"south": wall_pos = Vector2i(center.x, r.y2 - 1)
				"east": wall_pos = Vector2i(r.x2 - 1, center.y)
				"west": wall_pos = Vector2i(r.x1 + 1, center.y)
			
			level[wall_pos.x][wall_pos.y] = 0

	func create_hall(room1: DG_Rect, room2: DG_Rect) -> void:
		# This method just collects the rooms to create doors for later.
		if not rooms.has(room1): rooms.append(room1)
		if not rooms.has(room2): rooms.append(room2)

# ---
class MazeWithRooms:
	var level: Array
	var ROOM_MAX_SIZE: int = 13
	var ROOM_MIN_SIZE: int = 6
	var build_room_attempts: int = 100
	var allow_dead_ends: bool = false
	var winding_percent: float = 0.1
	var connection_chance: float = 0.04
	var _regions: Array
	var _current_region: int

	func generate_level(map_width: int, map_height: int) -> Array:
		var w = map_width if map_width % 2 != 0 else map_width
		var h = map_height if map_height % 2 != 0 else map_height
		level = DungeonMaker.create_grid(w, h, 1)
		_regions = DungeonMaker.create_grid(w, h, null)
		_current_region = -1

		_add_rooms(w-1, h-1)

		for y in range(1, h, 2):
			for x in range(1, w, 2):
				if level[x][y] != 1: continue
				_grow_maze(Vector2i(x,y), w, h)
		
		_connect_regions(w-1, h-1)
		
		if not allow_dead_ends:
			_remove_dead_ends(w, h)
			
		return level

	func _grow_maze(start: Vector2i, map_width: int, map_height: int) -> void:
		var cells: Array = []
		var last_direction = null
		
		_start_region()
		_carve(start)
		cells.append(start)
		
		var directions = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]

		while not cells.is_empty():
			var cell: Vector2i = cells.back()
			var unmade_cells: Array = []
			
			for direction in directions:
				if _can_carve(cell, direction, map_width, map_height):
					unmade_cells.append(direction)
			
			if not unmade_cells.is_empty():
				var direction
				if unmade_cells.has(last_direction) and randf() > winding_percent:
					direction = last_direction
				else:
					direction = unmade_cells.pick_random()
				
				_carve(cell + direction)
				var new_cell = cell + direction * 2
				_carve(new_cell)
				cells.append(new_cell)
				last_direction = direction
			else:
				cells.pop_back()
				last_direction = null

	func _add_rooms(map_width: int, map_height: int) -> void:
		var rooms: Array = []
		for i in build_room_attempts:
			var room_w = randi_range(ROOM_MIN_SIZE / 2, ROOM_MAX_SIZE / 2) * 2 + 1
			var room_h = randi_range(ROOM_MIN_SIZE / 2, ROOM_MAX_SIZE / 2) * 2 + 1
			var x = (randi_range(0, (map_width - room_w - 1) / 2)) * 2 + 1
			var y = (randi_range(0, (map_height - room_h - 1) / 2)) * 2 + 1
			
			var new_room = DG_Rect.new(x, y, room_w, room_h)
			var failed = false
			for other_room in rooms:
				if new_room.intersect(other_room):
					failed = true
					break
			
			if not failed:
				rooms.append(new_room)
				_start_region()
				_create_room(new_room)

	func _connect_regions(map_width: int, map_height: int) -> void:
		var connector_regions: Dictionary = {} # pos -> set of regions
		var directions = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]
		
		for x in range(1, map_width - 1):
			for y in range(1, map_height - 1):
				if level[x][y] != 1: continue
				
				var regions: Dictionary = {}
				for direction in directions:
					var neighbor_pos = Vector2i(x,y) + direction
					var region = _regions[neighbor_pos.x][neighbor_pos.y]
					if region != null:
						regions[region] = true
				
				if regions.size() < 2: continue
				connector_regions[Vector2i(x,y)] = regions.keys()
		
		var connectors = connector_regions.keys()
		var merged: Dictionary = {}
		var open_regions: Dictionary = {}
		for i in _current_region + 1:
			merged[i] = i
			open_regions[i] = true

		while open_regions.size() > 1:
			var connector: Vector2i = connectors.pick_random()
			_add_junction(connector)
			
			var regions_at_connector = connector_regions[connector]
			var real_regions = []
			for r in regions_at_connector:
				real_regions.append(merged[r])
			
			var dest = real_regions[0]
			var sources = real_regions.slice(1)
			
			for i in range(_current_region + 1):
				if sources.has(merged[i]):
					merged[i] = dest
			
			for s in sources:
				open_regions.erase(s)
			
			var to_be_removed: Array = []
			for pos in connectors:
				if pos.distance_to(connector) < 2:
					to_be_removed.append(pos)
					continue
				
				var pos_regions_set: Dictionary = {}
				for n in connector_regions[pos]:
					pos_regions_set[merged[n]] = true
				
				if pos_regions_set.size() > 1: continue
				
				if randf() < connection_chance:
					_add_junction(pos)
				
				to_be_removed.append(pos)
			
			for r_pos in to_be_removed:
				connectors.erase(r_pos)
				
	func _remove_dead_ends(map_width: int, map_height: int) -> void:
		var done = false
		var directions = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]
		while not done:
			done = true
			for y in range(1, map_height - 1):
				for x in range(1, map_width - 1):
					if level[x][y] == 0:
						var exits = 0
						for d in directions:
							if level[x + d.x][y + d.y] == 0:
								exits += 1
						if exits > 1: continue
						
						done = false
						level[x][y] = 1

	func _can_carve(pos: Vector2i, direction: Vector2i, map_width: int, map_height: int) -> bool:
			var check_pos = pos + direction * 2
			if not (check_pos.x > 0 and check_pos.x < map_width and check_pos.y > 0 and check_pos.y < map_height):
				return false
			return level[check_pos.x][check_pos.y] == 1

	func _start_region() -> void: _current_region += 1
	func _carve(pos: Vector2i) -> void: level[pos.x][pos.y] = 0; _regions[pos.x][pos.y] = _current_region
	func _create_room(room: DG_Rect) -> void:
		for x in range(room.x1, room.x2):
			for y in range(room.y1, room.y2):
				_carve(Vector2i(x,y))
	func _add_junction(pos: Vector2i) -> void: 
		level[pos.x][pos.y] = 0

# ---
class MessyBSPTree:
	var level: Array
	var room = null
	var MAX_LEAF_SIZE: int = 24
	var ROOM_MAX_SIZE: int = 15
	var ROOM_MIN_SIZE: int = 6
	var smooth_edges: bool = true
	var smoothing: int = 1
	var filling: int = 3
	var map_width: int
	var map_height: int

	func generate_level(width: int, height: int) -> Array:
		self.map_width = width
		self.map_height = height
		level = DungeonMaker.create_grid(width, height, 1)
		var _leafs: Array = []

		var root_leaf = Leaf.new(0, 0, width, height)
		_leafs.append(root_leaf)

		var split_successfully = true
		while split_successfully:
			split_successfully = false
			for l in _leafs:
				if l.child_1 == null and l.child_2 == null:
					if (l.width > MAX_LEAF_SIZE or l.height > MAX_LEAF_SIZE or randf() > 0.8):
						if l.split_leaf():
							_leafs.append(l.child_1)
							_leafs.append(l.child_2)
							split_successfully = true

		root_leaf.create_rooms(self)
		_clean_up_map(width, height)
		return level

	func create_room(r: DG_Rect) -> void:
		for x in range(r.x1 + 1, r.x2):
			for y in range(r.y1 + 1, r.y2):
				level[x][y] = 0

	func create_hall(room1: DG_Rect, room2: DG_Rect) -> void:
		var drunkard_pos = room2.center()
		var goal_pos = room1.center()
		
		while not (room1.x1 <= drunkard_pos.x and drunkard_pos.x <= room1.x2 and
				   room1.y1 < drunkard_pos.y and drunkard_pos.y < room1.y2):
			var north = 1.0; var south = 1.0; var east = 1.0; var west = 1.0
			var weight = 1.0
			
			if drunkard_pos.x < goal_pos.x: east += weight
			elif drunkard_pos.x > goal_pos.x: west += weight
			if drunkard_pos.y < goal_pos.y: south += weight
			elif drunkard_pos.y > goal_pos.y: north += weight
			
			var total = north + south + east + west
			north /= total; south /= total; east /= total
			
			var choice = randf()
			var delta = Vector2i.ZERO
			if choice < north: delta = Vector2i.UP
			elif choice < north + south: delta = Vector2i.DOWN
			elif choice < north + south + east: delta = Vector2i.RIGHT
			else: delta = Vector2i.LEFT
			
			var next_pos = drunkard_pos + delta
			if (next_pos.x > 0 and next_pos.x < map_width - 1 and
				next_pos.y > 0 and next_pos.y < map_height - 1):
				drunkard_pos = next_pos
				if level[drunkard_pos.x][drunkard_pos.y] == 1:
					level[drunkard_pos.x][drunkard_pos.y] = 0

	func _clean_up_map(width: int, height: int) -> void:
		if smooth_edges:
			for i in 3:
				for x in range(1, width - 1):
					for y in range(1, height - 1):
						var walls = _get_adjacent_walls_simple(x,y)
						if level[x][y] == 1 and walls <= smoothing:
							level[x][y] = 0
						if level[x][y] == 0 and walls >= filling:
							level[x][y] = 1

	func _get_adjacent_walls_simple(x: int, y: int) -> int:
		var count = 0
		if level[x][y - 1] == 1: count += 1
		if level[x][y + 1] == 1: count += 1
		if level[x - 1][y] == 1: count += 1
		if level[x + 1][y] == 1: count += 1
		return count

#=============================================================================
# ==== Main Generator API =====================================================
#=============================================================================

static var level: Array = []
static var _previous_generator

# Instances of each algorithm
static var _tunneling_algorithm = TunnelingAlgorithm.new()
static var _bsp_tree = BSPTree.new()
static var _drunkards_walk = DrunkardsWalk.new()
static var _cellular_automata = CellularAutomata.new()
static var _room_addition = RoomAddition.new()
static var _city_walls = CityWalls.new()
static var _maze_with_rooms = MazeWithRooms.new()
static var _messy_bsp_tree = MessyBSPTree.new()

static func _generate(generator, map_width: int, map_height: int) -> Array:
	_previous_generator = generator
	level = _previous_generator.generate_level(map_width, map_height)
	return level

static func generate_level_tunneling(map_width: int, map_height: int) -> Array:
	return _generate(_tunneling_algorithm, map_width, map_height)

static func generate_level_bsp(map_width: int, map_height: int) -> Array:
	return _generate(_bsp_tree, map_width, map_height)

static func generate_level_drunkards_walk(map_width: int, map_height: int) -> Array:
	return _generate(_drunkards_walk, map_width, map_height)

static func generate_level_cellular_automata(map_width: int, map_height: int) -> Array:
	return _generate(_cellular_automata, map_width, map_height)

static func generate_level_room_addition(map_width: int, map_height: int) -> Array:
	return _generate(_room_addition, map_width, map_height)
	
static func generate_level_city_walls(map_width: int, map_height: int) -> Array:
	return _generate(_city_walls, map_width, map_height)

static func generate_level_maze_with_rooms(map_width: int, map_height: int) -> Array:
	return _generate(_maze_with_rooms, map_width, map_height)

static func generate_level_messy_bsp(map_width: int, map_height: int) -> Array:
	return _generate(_messy_bsp_tree, map_width, map_height)

static func regenerate_with_previous(map_width: int, map_height: int) -> Array:
	if _previous_generator != null:
		level = _previous_generator.generate_level(map_width, map_height)
		return level
	else:
		# Default to tunneling if no previous generator
		return generate_level_tunneling(map_width, map_height)
