extends EffectData
class_name RangeUpEffect

@export var amount: float = 25.0

func apply_to_stats(stats: Stats) -> void:
	stats.range += amount
