extends Node2D
class_name PathFinder
static var instance : PathFinder
static var astar = AStarGrid2D.new()
@onready var space_state = get_world_2d().direct_space_state
@export_node_path("DungeonGenerator") var dungeonGenerator
@export_node_path("MouseTracker") var mouseTracker
@export_node_path("TileMapLayer") var floorTiles

func _ready() -> void:
	instance = self
	mouseTracker = get_node(mouseTracker)
	dungeonGenerator = get_node(dungeonGenerator)
	floorTiles = get_node(floorTiles)
	astar.cell_shape = AStarGrid2D.CELL_SHAPE_ISOMETRIC_RIGHT
	astar.cell_size = mouseTracker.tile_set.tile_size
	astar.region = Rect2i(0, 0, dungeonGenerator.width, dungeonGenerator.height)
	astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_AT_LEAST_ONE_WALKABLE
	astar.update()
	await get_tree().create_timer(0.01).timeout
	for cell : Vector2i in floorTiles.get_used_cells():
		var data : TileData = floorTiles.get_cell_tile_data(cell)
		var closed = data.get_custom_data("PathBlock")
		astar.set_point_solid(cell,closed)

static func calculate_path(start : Vector2i, end : Vector2i) -> PackedVector2Array:
	if not astar.is_in_boundsv(start) or not astar.is_in_boundsv(end):
		return PackedVector2Array()
	var result = astar.get_point_path(end,start,true)
	if result.is_empty() == false:
		result.remove_at(0)
	return result

static func set_cell_blocked(pos : Vector2, state : bool) -> void:
	var cell = instance.floorTiles.local_to_map(pos)
	if astar.is_in_boundsv(cell) == false:
		return
	var weight = astar.get_point_weight_scale(cell)
	if state:
		astar.set_point_weight_scale(cell,weight + 100)
	else:
		astar.set_point_weight_scale(cell,max(1,weight - 100))

static func is_cell_blocked(pos) -> bool:
	var cell = instance.floorTiles.local_to_map(pos)
	if astar.is_in_boundsv(cell) == false:
		return true
	return astar.get_point_weight_scale(cell) > 1

const neighbors = [Vector2i(0, 1), Vector2i(0, -1), Vector2i(1, 0), Vector2i(-1, 0),
						Vector2i(1, 1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(-1, -1)]
						
static func get_enemies_in_range(pos : Vector2, range : int) -> Array[Enemy]:
	var visited  = {}
	var listCur : Array[Vector2i] = []
	var listNext : Array[Vector2i] = []
	var tiles : TileMapLayer = instance.floorTiles
	var distance = 0
	var list : Array[Enemy] = []
	listNext.append(tiles.local_to_map(pos))
	while listNext.size() > 0 and distance != range:
		listCur = listNext.duplicate()
		listNext = []
		for v in listCur:
			for n in neighbors:
				var vec = n + v
				var idx = vec.x * 1e7 + vec.y
				if visited.has(idx):
					continue
				visited[idx] = true
				listNext.append(vec)
				if Enemy.position2Enemy.has(vec):
					list.append(Enemy.position2Enemy[vec])
		distance += 1
	return list

static var cellData = {}
static func update_flow_field(startList : PackedVector2Array) -> void:
	var visited  = {}
	var listCur : Array[Vector2i] = []
	var listNext : Array[Vector2i] = []
	var tiles : TileMapLayer = instance.floorTiles
	var distance = 0
	cellData = {}
	for pos in startList:
		listNext.append(tiles.local_to_map(pos))
	while listNext.size() > 0:
		listCur = listNext.duplicate()
		listNext = []
		for v in listCur:
			for n in neighbors:
				var vec = n + v
				var idx = vec.x * 1e7 + vec.y
				var data : TileData = tiles.get_cell_tile_data(vec)
				if data == null or visited.has(idx):
					continue
				visited[idx] = true
				var open = data.get_custom_data("PathBlock") == false
				if open:
					cellData[idx] = distance
					listNext.append(vec)
		distance += 1

static func get_flow_field(pos : Vector2) -> Vector2:
	var tiles : TileMapLayer = instance.floorTiles
	var pos2 = tiles.local_to_map(pos)
	var idx = pos2.x * 1e7 + pos2.y
	if cellData.has(idx) == false:
		return pos
	var dist = cellData[idx]
	var directRouteList = []
	var exploreList = []
	for n in neighbors:
		var vec = pos2 + n
		idx = vec.x * 1e7 + vec.y
		if cellData.has(idx) == false or astar.get_point_weight_scale(vec) > 1:
			continue
		var d = cellData[idx]
		if d == dist:
			exploreList.append(vec)
		if d < dist:
			directRouteList.append(vec)
	var size = directRouteList.size()
	var size2 = exploreList.size()
	if size > 0:
		return tiles.map_to_local(directRouteList[randi_range(0,size-1)])
	elif size2 > 0:
		return tiles.map_to_local(exploreList[randi_range(0,size2-1)])
	return pos

static func get_flow_field2(pos: Vector2) -> Vector2i:
	var tiles : TileMapLayer = instance.floorTiles
	pos = tiles.local_to_map(pos)
	var idx = pos.x * 1e7 + pos.y
	if cellData.has(idx) == false:
		return Vector2.ZERO
	return cellData[idx]

static func get_cell(pos:Vector2) -> Vector2i:
	var tiles : TileMapLayer = instance.floorTiles
	return tiles.local_to_map(pos)
