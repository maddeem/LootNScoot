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
	if event.is_action_pressed("Click"):
		Player.instance.set_path(lastDisplayed)
		for cell in lastDisplayed:
			erase_cell(local_to_map(cell))

func _process(_delta: float) -> void:
	$"../CanvasLayer/Control/Label2".text = str(PathFinder.get_cell(get_global_mouse_position()))
	$"../CanvasLayer/Control/Label3".text = str(PathFinder.is_cell_blocked(get_global_mouse_position()))
	if GameTick.stepsRemaining > 0:
		return
	var mpos = get_global_mouse_position()
	var start = local_to_map(mpos)
	var end = local_to_map(Player.instance.position)
	var result : PackedVector2Array = PathFinder.calculate_path(start,end)
	if result != lastDisplayed:
		for cell in lastDisplayed:
			erase_cell(local_to_map(cell))
		for cell in result:
			set_cell(local_to_map(cell),0,Vector2i(0,0),1)
		lastDisplayed = result
