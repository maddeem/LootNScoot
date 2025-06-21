extends Node2D
class_name Enemy
@onready var Sprite = $Sprite2D
@onready var startPos : Vector2 = position
@onready var nextPos : Vector2 = position

func _update_facing(from : Vector2,to : Vector2):
	Sprite.frame = Math.get_sprite_direction(from,to)

func move():
	startPos = position
	PathFinder.set_cell_blocked(nextPos,false)
	nextPos = PathFinder.get_flow_field(position)
	if nextPos != startPos:
		_update_facing(startPos,nextPos)
	PathFinder.set_cell_blocked(nextPos,true)

func step():
	startPos = position
	if GameTick.stepsRemaining == 0:
		return
	move()

func process(time : float):
	position = lerp(startPos,nextPos,time)

func _ready():
	GameTick.attach(process,step,move)
