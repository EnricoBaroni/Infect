extends EffectData
class_name LuckUpEffect

@export var amount: float = 1.0

func apply_to_stats(stats: Stats) -> void:
	stats.luck += amount