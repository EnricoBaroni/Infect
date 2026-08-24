extends AttackEffectData
class_name ChargeShotEffect

@export var charge_enabled: bool = true
@export var charge_min_time: float = 0.1
@export var charge_max_time: float = 1.0
@export var charge_damage_scale_min: float = 0.7
@export var charge_damage_scale_max: float = 1.8
@export var charge_speed_scale_min: float = 0.9
@export var charge_speed_scale_max: float = 1.1
@export var charge_range_scale_min: float = 0.9
@export var charge_range_scale_max: float = 1.25
@export var charge_split_min: int = 0
@export var charge_split_max: int = 0
@export var charge_size_scale_min: float = 0.9
@export var charge_size_scale_max: float = 1.5

func apply_to_attack_data(attack_data: AttackData) -> void:
	attack_data.charge_enabled = charge_enabled
	attack_data.charge_min_time = max(0.01, charge_min_time)
	attack_data.charge_max_time = max(attack_data.charge_min_time, charge_max_time)
	attack_data.charge_damage_scale_min = max(0.0, charge_damage_scale_min)
	attack_data.charge_damage_scale_max = max(attack_data.charge_damage_scale_min, charge_damage_scale_max)
	attack_data.charge_speed_scale_min = max(0.0, charge_speed_scale_min)
	attack_data.charge_speed_scale_max = max(attack_data.charge_speed_scale_min, charge_speed_scale_max)
	attack_data.charge_range_scale_min = max(0.0, charge_range_scale_min)
	attack_data.charge_range_scale_max = max(attack_data.charge_range_scale_min, charge_range_scale_max)
	attack_data.charge_split_min = max(0, charge_split_min)
	attack_data.charge_split_max = max(attack_data.charge_split_min, charge_split_max)
	attack_data.charge_size_scale_min = max(0.1, charge_size_scale_min)
	attack_data.charge_size_scale_max = max(attack_data.charge_size_scale_min, charge_size_scale_max)