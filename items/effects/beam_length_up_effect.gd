extends AttackEffectData
class_name BeamLengthUpEffect

@export var extra_segments: int = 2
@export var extra_duration: float = 0.03

func apply_to_attack_data(attack_data: AttackData) -> void:
	attack_data.beam_segment_count += max(0, extra_segments)
	attack_data.beam_segment_duration += max(0.0, extra_duration)
