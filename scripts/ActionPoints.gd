class_name ActionPoints
extends RefCounted

static var selfList : Array[ActionPoints] = []
static var maxTurn : int
var current_points : float = 0
var get_points : Callable
var step_func : Callable
var interpolate : Callable
var turns : int
var canInterp : bool

func _init(getPoints : Callable,step : Callable, interp : Callable):
	selfList.append(self)
	get_points = getPoints
	step_func = step
	interpolate = interp
	self.unreference()

static func start_new_turn():
	for obj in selfList:
		obj.canInterp = obj.turns > 0
		if obj.canInterp == false:
			continue
		obj.turns -= 1
		obj.step_func.call()
		if GameTick.stepsRemaining == 0:
			return

static func interpolateTurn(delta : float):
	for obj in selfList:
		if obj.canInterp:
			obj.interpolate.call(delta)

func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		selfList.erase(self)

static func update(mult : float) -> int:
	maxTurn = 0
	for obj in selfList:
		obj.current_points += obj.get_points.call() * mult
		obj.turns = floor(obj.current_points)
		obj.current_points -= obj.turns
		maxTurn = max(obj.turns,maxTurn)
	return maxTurn
