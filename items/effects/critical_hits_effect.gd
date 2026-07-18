extends AttackEffectData
class_name CriticalHitsEffect

@export var extra_crit_chance: float = 0.12
@export var extra_crit_multiplier: float = 0.4
@export var luck_to_full: float = 0.0
@export var max_crit_chance: float = 1.0

func apply_to_attack_data(attack_data: AttackData) -> void:
	attack_data.crit_chance += max(0.0, extra_crit_chance)
	attack_data.crit_multiplier += max(0.0, extra_crit_multiplier)
	attack_data.crit_luck_to_full = max(attack_data.crit_luck_to_full, max(0.0, luck_to_full))
	attack_data.crit_max_chance = max(attack_data.crit_max_chance, clampf(max_crit_chance, 0.0, 1.0))
