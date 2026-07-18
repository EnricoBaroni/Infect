extends AttackEffectData
class_name KnockbackModifierEffect

@export var knockback_multiplier: float = 1.25
@export var knockback_flat_bonus: float = 0.0

func apply_to_attack_data(attack_data: AttackData) -> void:
	attack_data.knockback_multiplier *= max(0.0, knockback_multiplier)
	attack_data.knockback_flat_bonus += knockback_flat_bonus
