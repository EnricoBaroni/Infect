extends AttackEffectData
class_name SplitShotsEffect

@export var extra_shots: int = 1
@export var spread_degrees: float = 12.0

func apply_to_attack_data(attack_data: AttackData) -> void:
	attack_data.split_count += max(0, extra_shots)
	attack_data.split_spread_degrees = max(1.0, attack_data.split_spread_degrees + spread_degrees)
