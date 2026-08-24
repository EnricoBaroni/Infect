extends AttackEffectData
class_name CadenceShotEffect

@export var every_n_shots: int = 3
@export var bonus_split: int = 0
@export var bonus_damage_multiplier: float = 2.0
@export var bonus_explosion_radius: float = 0.0

func apply_to_attack_data(attack_data: AttackData) -> void:
	var clamped_interval: int = maxi(1, every_n_shots)
	if attack_data.cadence_interval == 0:
		attack_data.cadence_interval = clamped_interval
	else:
		attack_data.cadence_interval = min(attack_data.cadence_interval, clamped_interval)
	attack_data.cadence_shot_split_bonus += max(0, bonus_split)
	attack_data.cadence_shot_damage_multiplier *= max(0.0, bonus_damage_multiplier)
	attack_data.cadence_shot_explosion_radius += max(0.0, bonus_explosion_radius)
