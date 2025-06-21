extends Node
class_name GameTick
const INTERP_TIME := 0.2
static var currentDelta := 0.0
static var stepsRemaining := 0
static var instance : GameTick

signal delta_update( delta : float)
signal step_update
signal start
static func push_forward( amount : int) ->void:
	if stepsRemaining == 0 and amount > 0:
		instance.start.emit()
	stepsRemaining += amount

static func attach( process : Callable, step : Callable, startOfStep = null):
	instance.step_update.connect(step)
	instance.delta_update.connect(process)
	if startOfStep is Callable:
		instance.start.connect(startOfStep)

func _process(delta: float) -> void:
	if stepsRemaining <= 0:
		return
	currentDelta = currentDelta + delta
	if currentDelta >= INTERP_TIME:
		stepsRemaining -= 1
		step_update.emit()
		currentDelta -= INTERP_TIME
	delta_update.emit(currentDelta/INTERP_TIME)

func _ready():
	instance = self
