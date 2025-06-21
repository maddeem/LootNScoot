extends Node2D
class_name Player
static var instance : Player
@export var stat_health: Stat
@export var stat_speed: Stat
@onready var Sprite = $Sprite2D
var currentPath := PackedVector2Array()
var startPos : Vector2
var nextPos : Vector2
static var endPos : Vector2

func _update_facing(from : Vector2,to : Vector2):
	Sprite.frame = Math.get_sprite_direction(from,to)

func moveTo(end : Vector2):
	if end == position:
		return
	PathFinder.set_cell_blocked(nextPos,false)
	startPos = position
	nextPos = end
	_update_facing(startPos,nextPos)
	PathFinder.set_cell_blocked(nextPos,true)
	var list = PackedVector2Array()
	list.append(nextPos)
	PathFinder.update_flow_field(list)

func step():
	currentPath.remove_at(0)
	if currentPath.size() > 0:
		if PathFinder.is_cell_blocked(currentPath[0]) and currentPath[0] != position:
			GameTick.stepsRemaining = 0
			currentPath.clear()
			return
		moveTo(currentPath[0])

func process(time : float):
	if currentPath.size() > 0:
		position = lerp(startPos,currentPath[0],time)

func _ready():
	instance = self
	GameTick.attach(process,step)


func set_path(path : PackedVector2Array) -> void:
	if currentPath.size() == 0 and path.size() > 0:
		currentPath = path
		moveTo(currentPath[0])
		endPos = currentPath[currentPath.size()-1]
		GameTick.push_forward(path.size())

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("Skip"):
		moveTo(position)
		GameTick.push_forward(1)
