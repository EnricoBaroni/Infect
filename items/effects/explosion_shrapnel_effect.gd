extends AttackEffectData
class_name ExplosionShrapnelEffect

@export var shard_count: int = 8
@export var spread_degrees: float = 360.0
@export var damage_multiplier: float = 0.35
@export var speed_multiplier: float = 1.0
@export var range_multiplier: float = 0.5
@export var inherit_status_payloads: bool = false

func apply_to_attack_data(attack_data: AttackData) -> void:
	attack_data.explosion_spawn_count += max(0, shard_count)
	attack_data.explosion_spawn_spread_degrees = max(1.0, spread_degrees)
	attack_data.explosion_spawn_damage_multiplier = max(0.0, damage_multiplier)
	attack_data.explosion_spawn_speed_multiplier = max(0.0, speed_multiplier)
	attack_data.explosion_spawn_range_multiplier = max(0.0, range_multiplier)
	if inherit_status_payloads:
		attack_data.explosion_spawn_inherit_status = true