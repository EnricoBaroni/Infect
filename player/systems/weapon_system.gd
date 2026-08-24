extends Node
class_name WeaponSystem

@onready var fire_rate_timer: Timer = $"../FireRate"
@onready var shoot_marker: Marker2D = $"../ShootMarker"
@onready var attack_evaluation: AttackEvaluationSystem = $"../AttackEvaluationSystem"
@onready var projectile_system: ProjectileSystem = $"../ProjectileSystem"

var _charge_active := false
var _charge_elapsed := 0.0
var _charge_direction := Vector2.RIGHT
var _charge_infection_mode := false
var _cadence_shot_count: int = 0

func try_fire(
	attack_vector: Vector2,
	infection_mode: bool,
	stats: Stats,
	current_velocity: Vector2,
	bullet_scene: PackedScene,
	delta: float
) -> void:
	if stats == null:
		return
	if bullet_scene == null:
		return
	if fire_rate_timer == null:
		return

	var has_input := attack_vector != Vector2.ZERO
	if has_input:
		_charge_direction = attack_vector
		_charge_infection_mode = infection_mode

	var attack_data := AttackData.new()
	attack_data.weapon_type = "tear"
	attack_data.direction = _charge_direction if _charge_direction != Vector2.ZERO else Vector2.RIGHT
	attack_data.damage = stats.damage
	attack_data.speed = stats.bullet_speed
	attack_data.max_distance = stats.range
	attack_data.movement_inheritance = 0.4
	attack_data.source_luck = stats.luck

	var perpendicular_velocity := current_velocity - attack_data.direction * current_velocity.dot(attack_data.direction)
	attack_data.inherited_velocity = perpendicular_velocity
	attack_data.infection_shot = _charge_infection_mode

	if attack_evaluation:
		attack_evaluation.apply_to_attack_data(attack_data)

	if not attack_data.charge_enabled:
		_charge_active = false
		_charge_elapsed = 0.0
		if not has_input:
			return
		if attack_data.continuous_fire:
			if not fire_rate_timer.is_stopped():
				return
			_emit_attack(attack_data, bullet_scene, attack_data.continuous_tick_rate)
			return
		if not fire_rate_timer.is_stopped():
			return
		_emit_attack(attack_data, bullet_scene, stats.fire_rate)
		return

	if has_input:
		if not _charge_active:
			if not fire_rate_timer.is_stopped():
				return
			_charge_active = true
			_charge_elapsed = 0.0
			_charge_infection_mode = infection_mode
			return

		_charge_elapsed += max(0.0, delta)
		return

	if not _charge_active:
		return

	var charged_attack = attack_data.copy()
	charged_attack.infection_shot = _charge_infection_mode
	_apply_charge_scaling(charged_attack)
	_emit_attack(charged_attack, bullet_scene, stats.fire_rate)
	_charge_active = false
	_charge_elapsed = 0.0

func _apply_charge_scaling(attack_data: AttackData) -> void:
	if attack_data == null:
		return

	var min_time: float = max(0.01, attack_data.charge_min_time)
	var max_time: float = max(min_time, attack_data.charge_max_time)
	var ratio: float = clampf((_charge_elapsed - min_time) / max(0.001, max_time - min_time), 0.0, 1.0)

	var damage_scale: float = lerpf(attack_data.charge_damage_scale_min, attack_data.charge_damage_scale_max, ratio)
	var speed_scale: float = lerpf(attack_data.charge_speed_scale_min, attack_data.charge_speed_scale_max, ratio)
	var range_scale: float = lerpf(attack_data.charge_range_scale_min, attack_data.charge_range_scale_max, ratio)
	var size_scale: float = lerpf(attack_data.charge_size_scale_min, attack_data.charge_size_scale_max, ratio)

	attack_data.damage *= max(0.0, damage_scale)
	attack_data.speed *= max(0.0, speed_scale)
	attack_data.max_distance *= max(0.0, range_scale)
	attack_data.beam_segment_count = max(1, int(round(float(attack_data.beam_segment_count) * size_scale)))
	attack_data.ring_max_radius = max(8.0, attack_data.ring_max_radius * size_scale)
	attack_data.blade_outbound_distance = max(16.0, attack_data.blade_outbound_distance * size_scale)
	attack_data.blade_spin_speed *= max(0.0, size_scale)
	attack_data.lob_burst_count = max(1, int(round(float(attack_data.lob_burst_count) * size_scale)))

	var split_bonus_f: float = lerpf(float(attack_data.charge_split_min), float(attack_data.charge_split_max), ratio)
	attack_data.split_count += max(0, int(round(split_bonus_f)))

func _emit_attack(attack_data: AttackData, bullet_scene: PackedScene, cooldown: float) -> void:
	if projectile_system:
		projectile_system.spawn_projectile(
			attack_data,
			bullet_scene,
			shoot_marker.global_position
		)
	else:
		var bullet_instance = bullet_scene.instantiate()
		bullet_instance.global_position = shoot_marker.global_position
		bullet_instance.setup_attack(attack_data)
		get_tree().current_scene.add_child(bullet_instance)

	fire_rate_timer.start(max(0.01, cooldown))
	_process_cadence(attack_data, bullet_scene)

func _process_cadence(attack_data: AttackData, bullet_scene: PackedScene) -> void:
	if attack_data.cadence_interval <= 0:
		_cadence_shot_count = 0
		return
	_cadence_shot_count += 1
	if _cadence_shot_count >= attack_data.cadence_interval:
		_cadence_shot_count = 0
		_fire_cadence_shot(attack_data, bullet_scene)

func _fire_cadence_shot(base_attack: AttackData, bullet_scene: PackedScene) -> void:
	if projectile_system == null:
		return
	var cadence_data := base_attack.copy()
	cadence_data.cadence_interval = 0
	cadence_data.split_count += max(0, cadence_data.cadence_shot_split_bonus)
	cadence_data.damage *= max(0.0, cadence_data.cadence_shot_damage_multiplier)
	cadence_data.explosion_radius += max(0.0, cadence_data.cadence_shot_explosion_radius)
	projectile_system.spawn_projectile(cadence_data, bullet_scene, shoot_marker.global_position)
