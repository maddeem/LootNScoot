extends TileMapLayer
class_name FogReactiveTileMapLayer
static var instance : FogReactiveTileMapLayer
@export_node_path("DungeonGenerator") var dungeonGenerator
static var cellStatus : Array
static var currentList = {}
static var dimensions : Vector2i
enum{
	FOG_VISIBLE,
	FOG_BLACK_MASK,
	FOG_EXPLORED,
}

static func is_cell_visible(pos : Vector2) -> bool:
	var p = PathFinder.get_cell(pos)
	return cellStatus[p.x][p.y] == FOG_VISIBLE

func set_cell_custom(coords: Vector2i, source_id: int = -1, atlas_coords: Vector2i = Vector2i(-1, -1), alternative_tile: int = 0):
	if alternative_tile == 0:
		alternative_tile = cellStatus[coords.x][coords.y]
	set_cell(coords,source_id,atlas_coords,alternative_tile)

func update_tile_fog(coords : Vector2i):
	set_cell(coords, get_cell_source_id(coords),get_cell_atlas_coords(coords),cellStatus[coords.x][coords.y])

func _ready() -> void:
	dungeonGenerator = get_node(dungeonGenerator)
	instance = self
	generate()

func generate():
	var gen : DungeonGenerator = instance.dungeonGenerator
	dimensions = Vector2i(gen.width,gen.height)
	cellStatus = DungeonMaker.create_grid(gen.width + 1,gen.height + 1,FOG_BLACK_MASK)
	create_alternate_tiles(Color.BLACK,Color(0.5,0.5,0.5,1.))

static func get_circle_perimeter_points(center: Vector2i, radius: int) -> Array:
	var points: Array = []
	if radius < 0:
		return points
	if radius == 0:
		points.append(center)
		return points
	var x = radius
	var y = 0
	var error = 0
	var delta = 1 - (2 * radius)
	points.append(Vector2i(center.x + x, center.y + y))
	points.append(Vector2i(center.x + x, center.y - y))
	points.append(Vector2i(center.x - x, center.y + y))
	points.append(Vector2i(center.x - x, center.y - y))
	points.append(Vector2i(center.x + y, center.y + x))
	points.append(Vector2i(center.x + y, center.y - x))
	points.append(Vector2i(center.x - y, center.y + x))
	points.append(Vector2i(center.x - y, center.y - x))
	while x > y:
		error = delta
		if error <= 0:
			y += 1
			delta += (2 * y) + 1
		if error > 0:
			x -= 1
			delta += (-2 * x) + 1
			if error > 0 and error > (-2 * x):
				y += 1
				delta += (2 * y) + 1
		points.append(Vector2i(center.x + x, center.y + y))
		points.append(Vector2i(center.x + x, center.y - y))
		points.append(Vector2i(center.x - x, center.y + y))
		points.append(Vector2i(center.x - x, center.y - y))
		points.append(Vector2i(center.x + y, center.y + x))
		points.append(Vector2i(center.x + y, center.y - x))
		points.append(Vector2i(center.x - y, center.y + x))
		points.append(Vector2i(center.x - y, center.y - x))
	return points

static func when_lt(x : int, y : int) -> int:
	return max(sign(y - x), 0)

static func when_gt(x : int, y : int) -> int:
	return max(sign(x - y), 0)

static func _walk_line_with_callback2(p0 : Vector2i, p1 : Vector2i, condition: Callable, action : Callable) -> void:
	var dx : int = abs(p1.x - p0.x);
	var dy : int = -abs(p1.y - p0.y);
	var err : int = dx + dy;
	var sx : int = 2 * when_lt(p0.x,p1.x) -1;
	var sy : int = 2 * when_lt(p0.y,p1.y) -1;
	var walls_hit : int = 0;
	var last : int = 0;
	while true:
		walls_hit += int(condition.call(p0));
		if walls_hit >= 1 and last == walls_hit or p0==p1:
			break
		else:
			action.call(p0)
		var c : = when_gt(err * 2 - dy, dx - err * 2);
		err += c * dy + (1 - c) * dx;
		p0.x += c * sx;
		p0.y += (1 - c) * sy;
		last = walls_hit;

func make_cell_visible(pos: Vector2i):
	pos.x = clampi(pos.x,0,dimensions.x)
	pos.y = clampi(pos.y,0,dimensions.y)
	if currentList.has(pos):
		return
	currentList[pos] = true
	cellStatus[pos.x][pos.y] = FOG_VISIBLE
	update_tile_fog(pos)

static func update_fog(center: Vector2i, radius: int) -> void:
	var perimeter_points = get_circle_perimeter_points(center, radius)
	for pos in currentList.keys():
		cellStatus[pos.x][pos.y] = FOG_EXPLORED
		instance.update_tile_fog(pos)
	currentList.clear()
	for target_point in perimeter_points:
		_walk_line_with_callback2(center, target_point, PathFinder.is_los_blocked, instance.make_cell_visible)

func create_alternate_tiles(color1 : Color, color2 : Color):
	for source_id in range(tile_set.get_source_count()):
		var source = tile_set.get_source(source_id)
		if source is TileSetAtlasSource:
			process_atlas_source(source as TileSetAtlasSource, source_id, color1)
			process_atlas_source(source as TileSetAtlasSource, source_id, color2)

func find_custom_data_layer(layer_name: String) -> int:
	for i in range(tile_set.get_custom_data_layers_count()):
		if tile_set.get_custom_data_layer_name(i) == layer_name:
			return i
	return -1

func process_atlas_source(atlas_source: TileSetAtlasSource, _source_id: int, color1 : Color):
	for i in range(atlas_source.get_tiles_count()):
		var atlas_coords = atlas_source.get_tile_id(i)
		var next_alt_id1 = atlas_source.get_next_alternative_tile_id(atlas_coords)
		atlas_source.create_alternative_tile(atlas_coords, next_alt_id1)
		var original_tile_data = atlas_source.get_tile_data(atlas_coords, 0)
		var alt_tile_data1 = atlas_source.get_tile_data(atlas_coords, next_alt_id1)
		alt_tile_data1.modulate = color1
		copy_tile_data_properties(original_tile_data, alt_tile_data1)

func copy_tile_data_properties(source_data: TileData, target_data: TileData):
	# Copy transform properties
	target_data.flip_h = source_data.flip_h
	target_data.flip_v = source_data.flip_v
	target_data.transpose = source_data.transpose
	target_data.z_index = source_data.z_index
	target_data.texture_origin = source_data.texture_origin
	target_data.y_sort_origin = source_data.y_sort_origin
	
	# Copy physics layers (collision)
	#var collisionPolygonCount = source_data.get_collision_polygons_count(0)
	#for physics_layer in range(collisionPolygonCount):
		#if source_data.get_collision_polygon_points(0, physics_layer).size() > 0:
			#target_data.set_collision_polygon_points(0, physics_layer, 
				#source_data.get_collision_polygon_points(0, physics_layer))
	#
	## Copy navigation data
	#for nav_layer in range(16):  # Godot supports up to 16 navigation layers
		#var nav_polygon = source_data.get_navigation_polygon(nav_layer)
		#if nav_polygon:
			#target_data.set_navigation_polygon(nav_layer, nav_polygon)
	#
	## Copy occlusion data
	#for occlusion_layer in range(16):  # Godot supports up to 16 occlusion layers
		#var occluder = source_data.get_occluder(occlusion_layer)
		#if occluder:
			#target_data.set_occluder(occlusion_layer, occluder)
	
	# Copy terrain data
	#target_data.terrain = source_data.terrain
	
	# Copy probability
	target_data.probability = source_data.probability
	
	for i in range(tile_set.get_custom_data_layers_count()):
		var custom_data = source_data.get_custom_data_by_layer_id(i)
		target_data.set_custom_data_by_layer_id(i, custom_data)
