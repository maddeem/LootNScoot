extends Node
class_name DungeonGenerator

@export var width := 80
@export var height := 80
@export_node_path("TileMapLayer") var level1
var open_cell := PackedVector2Array()

func _ready():
	var lvl1 : TileMapLayer = get_node(level1)
	randomize()
	var grid = DungeonMaker.generate_level_city_walls(width, height)
	for y in range(height):
		for x in range(width):
			if y == height - 1 or x == 0:
				lvl1.set_cell(Vector2i(x,y),0,Vector2i(0,0),1)
				continue
			if grid[x][y] == 1 or x == height - 1 or y == 0:
				lvl1.set_cell(Vector2i(x,y),0,Vector2i(0,0))
			else:
				open_cell.append(lvl1.map_to_local(Vector2i(x,y)))
				lvl1.set_cell(Vector2i(x,y),0,Vector2i(randi_range(1,3),0))

func get_random_open_cell() -> Vector2:
	return open_cell[randi_range(0, open_cell.size() - 1)]
