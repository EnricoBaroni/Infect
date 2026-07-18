extends EffectData
class_name HealthUpEffect

@export var amount: float = 1.0

func apply_to_stats(stats: Stats) -> void:
	stats.max_health += max(0.0, amount)