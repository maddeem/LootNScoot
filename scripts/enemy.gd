extends Node2D
class_name Enemy
const DEATH_MATERIAL = preload("res://materials/DeathMaterial.tres")
@onready var Sprite : Sprite2D = $Sprite2D
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
	visible = FogReactiveTileMapLayer.is_cell_visible(nextPos)

func interp_turn(time: float) -> void:
	position = lerp(startPos,nextPos,ease(time,-1.6))

func _ready() -> void:
	moveHandler = ActionPoints.new(stat.speed.get_total,step,interp_turn)
	PathFinder.set_cell_blocked(startPos,true)
	position2Enemy[PathFinder.get_cell(nextPos)] = self
	visible = FogReactiveTileMapLayer.is_cell_visible(nextPos)

func _death_interp(t : float):
	Sprite.material.set_shader_parameter("animation_time",t)

func destroy():
	position2Enemy.erase(PathFinder.get_cell(nextPos))
	PathFinder.set_cell_blocked(nextPos,false)
	Sprite.material = DEATH_MATERIAL.duplicate()
	#Sprite.material.set_shader_parameter("slice_angle",randf_range(0,TAU))
	moveHandler = null
	Preloader.remove_script_from_children(self)
	var tween = create_tween()
	tween.tween_method(_death_interp,0.0,1.0,GameTick.INTERP_TIME).set_ease(Tween.EASE_OUT)
	tween.tween_callback(queue_free)
