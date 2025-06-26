class_name ActionPoints
extends RefCounted

static var selfList : Array[ActionPoints] = []
static var maxTurn : int
var current_points : float = 0
var get_points : Callable
var step_func : Callable
var interpolate
var turns : int
var canInterp : bool

func _init(getPoints : Callable,step : Callable, interp = null):
	selfList.append(self)
	get_points = getPoints
	step_func = step
	interpolate = interp
	self.unreference()

static func start_new_turn():
	var i = 0
	var size = selfList.size() - 1
	while i < size:
		var obj = selfList[i]
		if obj == null:
			selfList[i] = selfList.pop_back()
			size -= 1
			if i >= size:
				break
		else:
			i += 1
			obj.canInterp = obj.turns > 0
			if obj.canInterp == false:
				continue
			obj.turns -= 1
			obj.step_func.call()
			
static func interpolateTurn(delta : float):
	var i = 0
	var size = selfList.size() - 1
	while i < size:
		var obj = selfList[i]
		if obj == null:
			selfList[i] = selfList.pop_back()
			size -= 1
			if i >= size:
				break
		else:
			if obj.canInterp and obj.interpolate != null:
				obj.interpolate.call(delta)
			i += 1

static func update(mult : float) -> int:
	maxTurn = 0
	var i = 0
	var size = selfList.size() - 1
	while i < size:
		var obj = selfList[i]
		if obj == null:
			selfList[i] = selfList.pop_back()
			size -= 1
			if i >= size:
				break
		else:
			obj.current_points += obj.get_points.call() * mult
			obj.turns += floor(obj.current_points)
			obj.current_points -= obj.turns
			maxTurn = max(obj.turns, maxTurn)
			i += 1
	return maxTurn

func extend_turn(amount):
	turns += amount
	GameTick.stepsRemaining = max(GameTick.stepsRemaining, turns)
