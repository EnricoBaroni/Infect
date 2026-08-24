extends AttackEffectData
class_name ChanceSplitShotsEffect

@export var extra_shots: int = 2
@export var spread_degrees: float = 24.0
@export var proc_chance: float = 0.25
@export var luck_to_full: float = 0.0
@export var max_proc_chance: float = 1.0

func apply_to_attack_data(attack_data: AttackData) -> void:
	attack_data.chance_split_count += max(0, extra_shots)
	attack_data.chance_split_spread_degrees = max(
		attack_data.chance_split_spread_degrees,
		max(1.0, spread_degrees)
	)
	var clamped_chance := clampf(proc_chance, 0.0, 1.0)
	attack_data.chance_split_chance = 1.0 - ((1.0 - attack_data.chance_split_chance) * (1.0 - clamped_chance))
	attack_data.chance_split_luck_to_full = max(attack_data.chance_split_luck_to_full, max(0.0, luck_to_full))
	attack_data.chance_split_max_chance = max(attack_data.chance_split_max_chance, clampf(max_proc_chance, 0.0, 1.0))