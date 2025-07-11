extends Node2D
class_name Player
static var instance : Player
@onready var sprite = $Sprite2D
var moveHandler : ActionPoints
var currentPath := PackedVector2Array()
@export var stat : StatHolder
@onready var startPos := position
@onready var nextPos := position
static var endPos : Vector2

func moveTo(end : Vector2):
	startPos = nextPos
	var list = PackedVector2Array()
	PathFinder.set_cell_blocked(nextPos,false)
	if PathFinder.is_cell_blocked(end):
		currentPath.clear()
		nextPos = startPos
		list.append(startPos)
		PathFinder.set_cell_blocked(nextPos,true)
	else:
		list.append(end)
		nextPos = end
		if nextPos != startPos:
			sprite.frame = Math.get_sprite_direction(startPos,nextPos)
		PathFinder.set_cell_blocked(nextPos,true)
		currentPath.remove_at(0)
	FogReactiveTileMapLayer.update_fog(PathFinder.get_cell(nextPos), stat.sight_range.get_total())
	PathFinder.update_flow_field(list)

func step():
	if currentPath.size() > 0:
		moveTo(currentPath[0]) 

func process(time : float):
	position = lerp(startPos,nextPos,ease(time,-1.6))

func incTick():
	if currentPath.size() > 0:
		GameTick.push_forward(1/stat.speed.get_total())

func _ready():
	instance = self
	moveHandler = ActionPoints.new(stat.speed.get_total,step,process,0)
	GameTick.instance.pushNext.connect(incTick)
	FogReactiveTileMapLayer.update_fog(PathFinder.get_cell(nextPos), stat.sight_range.get_total())

func set_path(path : PackedVector2Array) -> void:
	if currentPath.size() == 0 and path.size() > 0 and PathFinder.is_cell_blocked(path[0]) == false:
		currentPath = path
		endPos = currentPath[currentPath.size()-1]
		GameTick.push_forward(1/stat.speed.get_total())

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("Skip") and GameTick.doingNothing:
		var list = PackedVector2Array()
		nextPos = position
		startPos = position
		list.append(position)
		PathFinder.update_flow_field(list)
		PathFinder.set_cell_blocked(nextPos,false)
		GameTick.push_forward(1.0)
