extends StatusAttackEffect
class_name BurnStatusEffect

@export var duration: float = 2.2
@export var damage_per_second: float = 1.0
@export var tick_interval: float = 0.4
@export var max_stacks: int = 3
@export var stack_rule: String = "refresh"
@export var visual_tint: Color = Color(1.0, 0.62, 0.42, 1.0)
@export var proc_chance: float = 1.0
@export var proc_luck_to_full: float = 0.0
@export var proc_max_chance: float = 1.0

func apply_to_attack_data(attack_data: AttackData) -> void:
	_append_status_payload(
		attack_data,
		"burn",
		duration,
		damage_per_second,
		tick_interval,
		max_stacks,
		stack_rule,
		visual_tint,
		proc_chance,
		proc_luck_to_full,
		proc_max_chance
	)
