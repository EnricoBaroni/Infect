extends EffectData
class_name StatMultiplierEffect

@export var damage_multiplier: float = 1.0
@export var move_speed_multiplier: float = 1.0
@export var fire_rate_multiplier: float = 1.0
@export var bullet_speed_multiplier: float = 1.0
@export var range_multiplier: float = 1.0
@export var max_health_multiplier: float = 1.0

func apply_to_stats(stats: Stats) -> void:
	if damage_multiplier != 1.0:
		stats.damage *= max(0.0, damage_multiplier)
	if move_speed_multiplier != 1.0:
		stats.move_speed *= max(0.0, move_speed_multiplier)
	if fire_rate_multiplier != 1.0:
		stats.fire_rate *= max(0.01, fire_rate_multiplier)
	if bullet_speed_multiplier != 1.0:
		stats.bullet_speed *= max(0.0, bullet_speed_multiplier)
	if range_multiplier != 1.0:
		stats.range *= max(0.0, range_multiplier)
	if max_health_multiplier != 1.0:
		stats.max_health *= max(0.0, max_health_multiplier)
