extends EffectData
class_name FireRateUpEffect

@export var amount: float = 0.08
@export var min_fire_rate: float = 0.05

func apply_to_stats(stats: Stats) -> void:
	# Lower fire_rate means shorter cooldown between shots.
	stats.fire_rate = max(min_fire_rate, stats.fire_rate - amount)
