extends StatusAttackEffect
class_name FearStatusEffect

@export var duration: float = 2.5
@export var intensity: float = 1.0
@export var max_stacks: int = 1
@export var stack_rule: String = "refresh"
@export var visual_tint: Color = Color(0.95, 0.75, 1.0, 1.0)
@export var proc_chance: float = 1.0
@export var proc_luck_to_full: float = 0.0
@export var proc_max_chance: float = 1.0

func apply_to_attack_data(attack_data: AttackData) -> void:
	_append_status_payload(
		attack_data,
		"fear",
		duration,
		intensity,
		0.0,
		max_stacks,
		stack_rule,
		visual_tint,
		proc_chance,
		proc_luck_to_full,
		proc_max_chance
	)
