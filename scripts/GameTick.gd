extends Node
class_name GameTick
const INTERP_TIME := 0.2
static var currentDelta := 0.0
static var stepsRemaining : int
static var stepsLast : int
static var instance : GameTick
static var doingNothing := true

signal pushNext
signal turnEnded

static func push_forward(mult : float = 1.0) ->void:
	doingNothing = false
	stepsRemaining = ActionPoints.update(mult)
	ActionPoints.start_new_turn()

func _process(delta: float) -> void:
	if stepsRemaining <= 0:
		doingNothing = true
		if stepsRemaining != stepsLast:
			pushNext.emit()
		return
	currentDelta = currentDelta + delta
	if currentDelta >= INTERP_TIME:
		stepsLast = stepsRemaining
		stepsRemaining -= 1
		ActionPoints.start_new_turn()
		currentDelta -= INTERP_TIME
	if currentDelta + delta >= INTERP_TIME:
		ActionPoints.interpolateTurn(1.0)
		turnEnded.emit()
	else:
		ActionPoints.interpolateTurn(currentDelta/INTERP_TIME)

func _ready():
	instance = self
