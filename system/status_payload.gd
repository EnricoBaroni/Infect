class_name StatusPayload extends RefCounted

var status_id: String = ""
var duration: float = 0.0
var magnitude: float = 0.0
var tick_interval: float = 0.0
var max_stacks: int = 1
var stack_rule: String = "refresh"
var visual_tint: Color = Color.WHITE
var proc_chance: float = 1.0
var proc_luck_to_full: float = 0.0
var proc_max_chance: float = 1.0

func copy() -> StatusPayload:
	var cloned := StatusPayload.new()
	cloned.status_id = status_id
	cloned.duration = duration
	cloned.magnitude = magnitude
	cloned.tick_interval = tick_interval
	cloned.max_stacks = max_stacks
	cloned.stack_rule = stack_rule
	cloned.visual_tint = visual_tint
	cloned.proc_chance = proc_chance
	cloned.proc_luck_to_full = proc_luck_to_full
	cloned.proc_max_chance = proc_max_chance
	return cloned
