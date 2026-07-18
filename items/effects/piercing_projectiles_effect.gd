extends AttackEffectData
class_name PiercingProjectilesEffect

@export var extra_pierces: int = 1

func apply_to_attack_data(attack_data: AttackData) -> void:
	attack_data.pierce_count += max(0, extra_pierces)
