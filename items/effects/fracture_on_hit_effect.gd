extends AttackEffectData
class_name FractureOnHitEffect

@export var fragment_count: int = 2
@export var spread_degrees: float = 28.0
@export var damage_multiplier: float = 0.5
@export var speed_multiplier: float = 1.0
@export var range_multiplier: float = 0.6
@export var generations: int = 1

func apply_to_attack_data(attack_data: AttackData) -> void:
	attack_data.fracture_on_hit_count += max(0, fragment_count)
	attack_data.fracture_spread_degrees = max(attack_data.fracture_spread_degrees, max(1.0, spread_degrees))
	attack_data.fracture_damage_multiplier = max(attack_data.fracture_damage_multiplier, max(0.0, damage_multiplier))
	attack_data.fracture_speed_multiplier = max(attack_data.fracture_speed_multiplier, max(0.0, speed_multiplier))
	attack_data.fracture_range_multiplier = max(attack_data.fracture_range_multiplier, max(0.0, range_multiplier))
	attack_data.fracture_generations = max(attack_data.fracture_generations, max(0, generations))