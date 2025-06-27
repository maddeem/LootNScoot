extends Node2D
class_name Enemy
@onready var Sprite = $Sprite2D
@export var stat : StatHolder
@onready var startPos : Vector2 = position
@onready var nextPos : Vector2 = position
var moveHandler : ActionPoints
static var position2Enemy = {}

func _update_facing(from : Vector2,to : Vector2):
	Sprite.frame = Math.get_sprite_direction(from,to)

func step():
	startPos = nextPos
	PathFinder.set_cell_blocked(nextPos,false)
	position2Enemy.erase(PathFinder.get_cell(nextPos))
	nextPos = PathFinder.get_flow_field(position)
	if nextPos != startPos:
		_update_facing(startPos,nextPos)
	PathFinder.set_cell_blocked(nextPos,true)
	position2Enemy[PathFinder.get_cell(nextPos)] = self

func interp_turn(time: float) -> void:
	position = lerp(startPos,nextPos,ease(time,2.0))

func _ready() -> void:
	moveHandler = ActionPoints.new(stat.speed.get_total,step,interp_turn)
	PathFinder.set_cell_blocked(startPos,true)
	position2Enemy[PathFinder.get_cell(nextPos)] = self
	
func _exit_tree() -> void:
	position2Enemy.erase(PathFinder.get_cell(nextPos))
	PathFinder.set_cell_blocked(nextPos,false)
