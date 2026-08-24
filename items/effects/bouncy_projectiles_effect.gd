extends AttackEffectData
class_name BouncyProjectilesEffect

@export var extra_bounces: int = 1

func apply_to_attack_data(attack_data: AttackData) -> void:
	attack_data.bounce_count += max(0, extra_bounces)
