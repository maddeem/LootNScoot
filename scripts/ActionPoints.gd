class_name ActionPoints
extends RefCounted

static var priority_buckets : Dictionary = {}
static var priorities : Array
static var maxTurn : int
var current_points : float = 0
var get_points : Callable
var step_func : Callable
var interpolate
var turns : int
var canInterp : bool
var queue_priority : int = 0
var bucket_index : int  # Track position within bucket for removal

func _init(getPoints : Callable, step : Callable, interp = null, priority : int = 1):
	get_points = getPoints
	step_func = step
	interpolate = interp
	queue_priority = priority
	
	# Create bucket if it doesn't exist
	if not priority_buckets.has(priority):
		priority_buckets[priority] = []
		priorities = priority_buckets.keys()
		priorities.sort()
	
	# Add to appropriate bucket
	var bucket = priority_buckets[priority]
	bucket.append(self)
	bucket_index = bucket.size() - 1
	self.unreference()

static func start_new_turn():
	# Process each priority bucket in order
	for priority in priorities:
		var bucket = priority_buckets[priority]
		for obj in bucket:
			obj.canInterp = obj.turns > 0
			if obj.canInterp == false:
				continue
			obj.turns -= 1
			obj.step_func.call()

static func interpolateTurn(delta : float):
	# Process all buckets for interpolation
	for priority in priority_buckets.keys():
		var bucket = priority_buckets[priority]
		for obj in bucket:
			if obj != null and obj.canInterp and obj.interpolate != null:
				obj.interpolate.call(delta)

static func update(mult : float) -> int:
	maxTurn = 0
	# Process all buckets for updates
	for priority in priority_buckets.keys():
		var bucket = priority_buckets[priority]
		for obj in bucket:
			if obj != null:
				obj.current_points += obj.get_points.call() * mult
				obj.turns += floor(obj.current_points)
				obj.current_points -= obj.turns
				maxTurn = max(obj.turns, maxTurn)
	return maxTurn

func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		# Remove from bucket using swap-and-pop
		var bucket = priority_buckets[queue_priority]
		var last_obj = bucket.pop_back()
		
		# If we're not removing the last element, swap it into our position
		if last_obj != null and last_obj != self:
			last_obj.bucket_index = bucket_index
			bucket[bucket_index] = last_obj
		
		# Clean up empty buckets to keep dictionary tidy
		if bucket.is_empty():
			priority_buckets.erase(queue_priority)
			priorities = priority_buckets.keys()
			priorities.sort()

func extend_turn(amount):
	turns += amount
	GameTick.stepsRemaining = max(GameTick.stepsRemaining, turns)
