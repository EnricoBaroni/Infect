extends EffectData
class_name BulletSpeedUpEffect

@export var amount: float = 20.0

func apply_to_stats(stats: Stats) -> void:
	stats.bullet_speed += amount
