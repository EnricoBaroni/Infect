extends AttackEffectData
class_name HomingProjectilesEffect

@export var strength: float = 4.0
@export var radius: float = 180.0

func apply_to_attack_data(attack_data: AttackData) -> void:
	attack_data.homing_strength += max(0.0, strength)
	attack_data.homing_radius += max(0.0, radius)
