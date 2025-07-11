extends TileMapLayer
class_name MouseTracker
static var instance : MouseTracker
func _ready() -> void:
	instance = self

static func cord2Grid(cord : Vector2) -> Vector2i:
	return instance.local_to_map(cord)

static func Grid2Cord(cord : Vector2i) -> Vector2:
	return instance.map_to_local(cord)

var lastDisplayed : PackedVector2Array

func _input(event: InputEvent):
	if event.is_action_pressed("Click") and GameTick.doingNothing:
		Player.instance.set_path(lastDisplayed.duplicate())
		for cell in lastDisplayed:
			erase_cell(local_to_map(cell))
		lastDisplayed.clear()

func _process(_delta: float) -> void:
	$"../CanvasLayer/Control/Label2".text = str(PathFinder.get_cell(get_global_mouse_position()))
	$"../CanvasLayer/Control/Label3".text = str(PathFinder.is_cell_blocked(get_global_mouse_position()))
	$"../CanvasLayer/Control/Label".text = str(Engine.get_frames_per_second())
	if GameTick.doingNothing == false:
		return
	var mpos = get_global_mouse_position()
	var start = local_to_map(mpos)
	var end = local_to_map(Player.instance.position)
	var result : PackedVector2Array = PathFinder.calculate_path(start,end)
	var list = PackedVector2Array()
	if result != lastDisplayed:
		for cell in lastDisplayed:
			erase_cell(local_to_map(cell))
		for cell in result:
			if FogReactiveTileMapLayer.is_cell_explored(cell):
				list.append(cell)
				set_cell(local_to_map(cell),0,Vector2i(0,0),1)
			else:
				break
		result = list
		lastDisplayed = result
