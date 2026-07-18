extends Area2D

const BULLET_SCENE = preload("res://attacks/bullet.tscn")

@onready var hitbox: Hitbox = $Hitbox
@onready var life_timer: Timer = $LifeTimer

var _destroy_emitted := false
var _infection_shot := false
var _explosion_radius := 0.0
var _explosion_damage_multiplier := 1.0
var _explosion_inherits_infection := false
var _explosion_spawn_count := 0
var _explosion_spawn_spread_degrees := 360.0
var _explosion_spawn_damage_multiplier := 0.35
var _explosion_spawn_speed_multiplier := 1.0
var _explosion_spawn_range_multiplier := 0.5
var _explosion_spawn_inherit_status := false
var _attack_template: AttackData

func _ready() -> void:
	if not life_timer.timeout.is_connected(_on_life_timer_timeout):
		life_timer.timeout.connect(_on_life_timer_timeout)
	if not hitbox.area_entered.is_connected(_on_hitbox_area_entered):
		hitbox.area_entered.connect(_on_hitbox_area_entered)

	EventBus.emit_projectile_spawned({
		"projectile": self,
		"projectile_kind": "beam_segment",
		"infection_shot": _infection_shot,
		"position": global_position
	})

func setup_segment(attack_data: AttackData, segment_index: int) -> void:
	_infection_shot = attack_data.infection_shot
	var crit_chance = clampf(attack_data.crit_chance, 0.0, 1.0)
	var crit_multiplier = max(1.0, attack_data.crit_multiplier)
	if attack_data.crit_luck_to_full > 0.0:
		crit_chance = EventBus.evaluate_luck_proc(
			crit_chance,
			attack_data.source_luck,
			attack_data.crit_luck_to_full,
			attack_data.crit_max_chance
		)
	var resolved_damage = attack_data.damage
	if randf() <= crit_chance:
		resolved_damage *= crit_multiplier

	hitbox.damage = resolved_damage
	hitbox.knockback_amount = max(0.0, hitbox.knockback_amount * max(0.0, attack_data.knockback_multiplier) + attack_data.knockback_flat_bonus)
	hitbox.source_faction = "player"
	hitbox.source_is_projectile = true
	hitbox.source_luck = attack_data.source_luck
	hitbox.infection_power = 0
	hitbox.status_payloads = attack_data.clone_status_payloads()
	_explosion_radius = max(0.0, attack_data.explosion_radius)
	_explosion_damage_multiplier = max(0.0, attack_data.explosion_damage_multiplier)
	_explosion_inherits_infection = attack_data.explosion_inherits_infection
	_explosion_spawn_count = max(0, attack_data.explosion_spawn_count)
	_explosion_spawn_spread_degrees = max(1.0, attack_data.explosion_spawn_spread_degrees)
	_explosion_spawn_damage_multiplier = max(0.0, attack_data.explosion_spawn_damage_multiplier)
	_explosion_spawn_speed_multiplier = max(0.0, attack_data.explosion_spawn_speed_multiplier)
	_explosion_spawn_range_multiplier = max(0.0, attack_data.explosion_spawn_range_multiplier)
	_explosion_spawn_inherit_status = attack_data.explosion_spawn_inherit_status
	_attack_template = attack_data.copy()

	if _infection_shot:
		modulate = Color.GREEN
		hitbox.infection_power = 1
		hitbox.damage = 0

	var visual_scale = clamp(1.0 - segment_index * 0.04, 0.6, 1.0)
	scale = Vector2(1.5 * visual_scale, 0.75)

	life_timer.wait_time = attack_data.beam_segment_duration
	life_timer.start()

func _on_life_timer_timeout() -> void:
	_dispose()

func _on_hitbox_area_entered(area: Area2D) -> void:
	if area is not Hurtbox:
		return
	_trigger_explosion_at(global_position)

func _trigger_explosion_at(center_position: Vector2) -> void:
	if _explosion_radius <= 0.0:
		return

	var root = get_tree().current_scene
	if root == null:
		return

	var explosion_hitbox := Hitbox.new()
	explosion_hitbox.damage = hitbox.damage * _explosion_damage_multiplier
	explosion_hitbox.infection_power = 0
	explosion_hitbox.source_faction = hitbox.source_faction
	explosion_hitbox.source_luck = hitbox.source_luck
	explosion_hitbox.status_payloads = []
	for payload in hitbox.status_payloads:
		if payload == null:
			continue
		explosion_hitbox.status_payloads.append(payload.copy())
	if _infection_shot:
		explosion_hitbox.damage = 0
		if _explosion_inherits_infection:
			explosion_hitbox.infection_power = 1

	for node in root.find_children("*", "EnemyBase", true, false):
		if node is not EnemyBase:
			continue

		var enemy := node as EnemyBase
		if enemy == null or not is_instance_valid(enemy):
			continue

		var to_enemy = enemy.global_position - center_position
		if to_enemy.length() > _explosion_radius:
			continue

		explosion_hitbox.knockback_direction = to_enemy.normalized()
		explosion_hitbox.knockback_amount = 140.0
		enemy.take_hit(explosion_hitbox)

	_spawn_explosion_projectiles(center_position)

func _spawn_explosion_projectiles(origin: Vector2) -> void:
	if BULLET_SCENE == null:
		return
	if _attack_template == null:
		return
	if _explosion_spawn_count <= 0:
		return

	var base_direction := Vector2.RIGHT.rotated(rotation)
	if base_direction == Vector2.ZERO:
		base_direction = Vector2.RIGHT

	var full_circle := _explosion_spawn_spread_degrees >= 359.0
	var count: int = maxi(1, _explosion_spawn_count)
	var step := 0.0
	var start_angle := 0.0
	if full_circle:
		step = TAU / float(count)
	else:
		step = deg_to_rad(_explosion_spawn_spread_degrees) / float(max(1, count - 1))
		start_angle = -deg_to_rad(_explosion_spawn_spread_degrees) * 0.5

	for index in count:
		var angle_offset := start_angle + step * float(index)
		var shard_data := _attack_template.copy()
		shard_data.weapon_type = "tear"
		shard_data.direction = base_direction.rotated(angle_offset).normalized()
		shard_data.damage = max(0.0, hitbox.damage * _explosion_spawn_damage_multiplier)
		shard_data.speed = max(1.0, _attack_template.speed * _explosion_spawn_speed_multiplier)
		shard_data.max_distance = max(8.0, _attack_template.max_distance * _explosion_spawn_range_multiplier)
		shard_data.explosion_radius = 0.0
		shard_data.explosion_spawn_count = 0
		shard_data.split_count = 0
		shard_data.chance_split_count = 0
		shard_data.fracture_on_hit_count = 0
		if not _explosion_spawn_inherit_status:
			shard_data.status_payloads = []

		var shard = BULLET_SCENE.instantiate()
		shard.global_position = origin
		shard.setup_attack(shard_data)
		get_tree().current_scene.add_child(shard)

func _dispose() -> void:
	if is_queued_for_deletion():
		return

	if not _destroy_emitted:
		_destroy_emitted = true
		EventBus.emit_projectile_destroyed({
			"projectile": self,
			"projectile_kind": "beam_segment",
			"infection_shot": _infection_shot,
			"position": global_position
		})

	queue_free()
