extends EffectData
class_name DamageUpEffect

@export var amount: float = 0.5

func apply_to_stats(stats: Stats) -> void:
	stats.damage += amount
