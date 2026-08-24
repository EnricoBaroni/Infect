extends AttackEffectData
class_name ExplosiveProjectilesEffect

@export var explosion_radius: float = 34.0
@export var extra_explosion_damage_multiplier: float = 0.5
@export var inherit_infection: bool = false

func apply_to_attack_data(attack_data: AttackData) -> void:
	attack_data.explosion_radius += max(0.0, explosion_radius)
	attack_data.explosion_damage_multiplier += max(0.0, extra_explosion_damage_multiplier)
	if inherit_infection:
		attack_data.explosion_inherits_infection = true
