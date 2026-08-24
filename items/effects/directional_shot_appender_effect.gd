extends AttackEffectData
class_name DirectionalShotAppenderEffect

@export var angle_offsets_degrees: Array[float] = [180.0]

func apply_to_attack_data(attack_data: AttackData) -> void:
	for angle in angle_offsets_degrees:
		attack_data.appended_shot_offsets.append(angle)
