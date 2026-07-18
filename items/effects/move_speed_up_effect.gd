extends EffectData
class_name MoveSpeedUpEffect

@export var amount: float = 15.0

func apply_to_stats(stats: Stats) -> void:
	stats.move_speed += amount
