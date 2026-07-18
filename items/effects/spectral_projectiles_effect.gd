extends AttackEffectData
class_name SpectralProjectilesEffect

func apply_to_attack_data(attack_data: AttackData) -> void:
	attack_data.spectral = true
