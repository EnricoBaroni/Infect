extends Area2D

const BULLET_SCENE = preload("res://attacks/bullet.tscn")
const TEAR_BREAK_EFFECT = preload("res://effects/tear_break_effect.tscn")

@export var SPEED: float = 150.0
@export var DAMAGE: float = 1.0
@export var FIRE_RATE: float = 0.6
@export var MAX_DISTANCE: float = 150
@export var MOVEMENT_INHERITANCE: float = 0.4
@export var MAX_VISUAL_DROP := 4
@onready var hitbox: Hitbox = $Hitbox
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

var direction: Vector2 = Vector2.ZERO
var inherited_velocity: Vector2 = Vector2.ZERO
var distance_travelled: float = 0.0
var infection_shot := false
var custom_color: Color = Color.WHITE
var enemy_shot := false
var _destroy_emitted := false
var remaining_pierces := 0
var remaining_bounces := 0
var weapon_type := "tear"
var homing_strength := 0.0
var homing_radius := 0.0
var spectral := false
var crit_chance := 0.0
var crit_multiplier := 1.5
var knockback_multiplier := 1.0
var knockback_flat_bonus := 0.0
var explosion_radius := 0.0
var explosion_damage_multiplier := 1.0
var explosion_inherits_infection := false
var explosion_spawn_count := 0
var explosion_spawn_spread_degrees := 360.0
var explosion_spawn_damage_multiplier := 0.35
var explosion_spawn_speed_multiplier := 1.0
var explosion_spawn_range_multiplier := 0.5
var explosion_spawn_inherit_status := false
var bounce_speed_retention := 1.0
var bounce_random_angle_degrees := 0.0
var fracture_on_hit_count := 0
var fracture_spread_degrees := 26.0
var fracture_damage_multiplier := 0.5
var fracture_speed_multiplier := 1.0
var fracture_range_multiplier := 0.6
var fracture_generations := 0
var _attack_template: AttackData

func _ensure_setup_nodes() -> void:
	if hitbox == null:
		hitbox = get_node_or_null("Hitbox") as Hitbox

func _ready() -> void:
	_ensure_setup_nodes()
	modulate = custom_color
	hitbox.area_entered.connect(_on_hitbox_area_entered)
	body_entered.connect(_on_body_entered)
	EventBus.emit_projectile_spawned({
		"projectile": self,
		"enemy_shot": enemy_shot,
		"weapon_type": weapon_type,
		"infection_shot": infection_shot,
		"position": global_position,
		"direction": direction
	})
	if enemy_shot:
		hitbox.collision_layer = 8
		hitbox.collision_mask = 8
		hitbox.source_faction = "enemy"
		hitbox.source_is_projectile = true
	else:
		hitbox.source_faction = "player"
		hitbox.source_is_projectile = true
	
	if infection_shot:
		modulate = Color.GREEN
		hitbox.infection_power = 1
		hitbox.damage = 0

func setup_attack(attack_data: AttackData) -> void:
	_ensure_setup_nodes()
	direction = attack_data.direction
	inherited_velocity = attack_data.inherited_velocity
	SPEED = attack_data.speed
	DAMAGE = attack_data.damage
	MAX_DISTANCE = attack_data.max_distance
	MOVEMENT_INHERITANCE = attack_data.movement_inheritance
	infection_shot = attack_data.infection_shot
	weapon_type = attack_data.weapon_type
	homing_strength = max(0.0, attack_data.homing_strength)
	homing_radius = max(0.0, attack_data.homing_radius)
	spectral = attack_data.spectral
	crit_chance = clamp(attack_data.crit_chance, 0.0, 1.0)
	crit_multiplier = max(1.0, attack_data.crit_multiplier)
	knockback_multiplier = max(0.0, attack_data.knockback_multiplier)
	knockback_flat_bonus = attack_data.knockback_flat_bonus
	explosion_radius = max(0.0, attack_data.explosion_radius)
	explosion_damage_multiplier = max(0.0, attack_data.explosion_damage_multiplier)
	explosion_inherits_infection = attack_data.explosion_inherits_infection
	explosion_spawn_count = max(0, attack_data.explosion_spawn_count)
	explosion_spawn_spread_degrees = max(1.0, attack_data.explosion_spawn_spread_degrees)
	explosion_spawn_damage_multiplier = max(0.0, attack_data.explosion_spawn_damage_multiplier)
	explosion_spawn_speed_multiplier = max(0.0, attack_data.explosion_spawn_speed_multiplier)
	explosion_spawn_range_multiplier = max(0.0, attack_data.explosion_spawn_range_multiplier)
	explosion_spawn_inherit_status = attack_data.explosion_spawn_inherit_status
	bounce_speed_retention = clamp(attack_data.bounce_speed_retention, 0.05, 1.5)
	bounce_random_angle_degrees = clamp(attack_data.bounce_random_angle_degrees, 0.0, 180.0)
	fracture_on_hit_count = max(0, attack_data.fracture_on_hit_count)
	fracture_spread_degrees = max(1.0, attack_data.fracture_spread_degrees)
	fracture_damage_multiplier = max(0.0, attack_data.fracture_damage_multiplier)
	fracture_speed_multiplier = max(0.0, attack_data.fracture_speed_multiplier)
	fracture_range_multiplier = max(0.0, attack_data.fracture_range_multiplier)
	fracture_generations = max(0, attack_data.fracture_generations)
	_attack_template = attack_data.copy()
	remaining_pierces = max(0, attack_data.pierce_count)
	remaining_bounces = max(0, attack_data.bounce_count)

	var resolved_damage: float = DAMAGE
	var resolved_crit_chance := crit_chance
	if attack_data.crit_luck_to_full > 0.0:
		resolved_crit_chance = EventBus.evaluate_luck_proc(
			resolved_crit_chance,
			attack_data.source_luck,
			attack_data.crit_luck_to_full,
			attack_data.crit_max_chance
		)
	if randf() <= resolved_crit_chance:
		resolved_damage *= crit_multiplier

	hitbox.damage = resolved_damage
	hitbox.knockback_amount = max(0.0, hitbox.knockback_amount * knockback_multiplier + knockback_flat_bonus)
	hitbox.source_luck = attack_data.source_luck
	hitbox.status_payloads = attack_data.clone_status_payloads()

func _physics_process(delta: float) -> void:
	_apply_homing(delta)

	var movement: Vector2 = (direction * SPEED + inherited_velocity * MOVEMENT_INHERITANCE) * delta
	global_position += movement
	
	hitbox.knockback_direction = direction.normalized()
	
	distance_travelled += movement.length()
	var progress: float = clamp(distance_travelled / MAX_DISTANCE, 0.0, 1.0)
	sprite.position.y = pow(progress, 4.0) * MAX_VISUAL_DROP
	if distance_travelled >= MAX_DISTANCE:
		_dispose()

func get_fire_rate() -> float:
	return FIRE_RATE

func _on_body_entered(body: Node2D) -> void:
	if spectral:
		return

	if remaining_bounces > 0:
		remaining_bounces -= 1
		var reflected_direction: Vector2 = -direction.normalized()
		if bounce_random_angle_degrees > 0.0:
			var random_angle: float = deg_to_rad(randf_range(-bounce_random_angle_degrees, bounce_random_angle_degrees))
			reflected_direction = reflected_direction.rotated(random_angle)
		direction = reflected_direction.normalized()
		SPEED *= bounce_speed_retention
		global_position += direction.normalized() * 4.0
		return

	_trigger_explosion_at(global_position)

	_dispose()

func _on_hitbox_area_entered(area: Area2D) -> void:
	if area is not Hurtbox: return
	if remaining_pierces > 0:
		remaining_pierces -= 1
		return

	_spawn_fracture_projectiles(global_position)

	_trigger_explosion_at(global_position)
	_dispose()

func _spawn_fracture_projectiles(origin: Vector2) -> void:
	if BULLET_SCENE == null:
		return
	if _attack_template == null:
		return
	if fracture_on_hit_count <= 0:
		return
	if fracture_generations <= 0:
		return

	var base_direction := direction.normalized()
	if base_direction == Vector2.ZERO:
		base_direction = Vector2.RIGHT

	var fragment_count := fracture_on_hit_count
	var start_angle := -fracture_spread_degrees * 0.5
	var step := 0.0
	if fragment_count > 1:
		step = fracture_spread_degrees / float(fragment_count - 1)

	for idx in fragment_count:
		var angle_offset := deg_to_rad(start_angle + step * float(idx))
		var fragment_data := _attack_template.copy()
		fragment_data.direction = base_direction.rotated(angle_offset)
		fragment_data.damage = hitbox.damage * fracture_damage_multiplier
		fragment_data.speed *= fracture_speed_multiplier
		fragment_data.max_distance *= fracture_range_multiplier
		fragment_data.weapon_type = "tear"
		fragment_data.split_count = 0
		fragment_data.chance_split_count = 0
		fragment_data.fracture_generations = fracture_generations - 1

		var fragment: Area2D = BULLET_SCENE.instantiate()
		fragment.global_position = origin
		fragment.setup_attack(fragment_data)
		get_tree().current_scene.add_child(fragment)

func _trigger_explosion_at(center_position: Vector2) -> void:
	if explosion_radius <= 0.0:
		return

	var root: Node = get_tree().current_scene
	if root == null:
		return

	var explosion_hitbox := Hitbox.new()
	explosion_hitbox.damage = hitbox.damage * explosion_damage_multiplier
	explosion_hitbox.infection_power = 0
	explosion_hitbox.source_faction = hitbox.source_faction
	explosion_hitbox.source_luck = hitbox.source_luck
	explosion_hitbox.status_payloads = []
	for payload in hitbox.status_payloads:
		if payload == null:
			continue
		explosion_hitbox.status_payloads.append(payload.copy())
	if infection_shot:
		explosion_hitbox.damage = 0
		if explosion_inherits_infection:
			explosion_hitbox.infection_power = 1

	for node in root.find_children("*", "EnemyBase", true, false):
		if node is not EnemyBase:
			continue

		var enemy := node as EnemyBase
		if enemy == null or not is_instance_valid(enemy):
			continue

		var to_enemy: Vector2 = enemy.global_position - center_position
		if to_enemy.length() > explosion_radius:
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
	if explosion_spawn_count <= 0:
		return

	var base_direction := direction.normalized()
	if base_direction == Vector2.ZERO:
		base_direction = Vector2.RIGHT

	var full_circle := explosion_spawn_spread_degrees >= 359.0
	var count: int = max(1, explosion_spawn_count)
	var step: float = 0.0
	var start_angle: float = 0.0
	if full_circle:
		step = TAU / float(count)
	else:
		step = deg_to_rad(explosion_spawn_spread_degrees) / float(max(1, count - 1))
		start_angle = -deg_to_rad(explosion_spawn_spread_degrees) * 0.5

	for index in count:
		var angle_offset := start_angle + step * float(index)
		var shard_data := _attack_template.copy()
		shard_data.weapon_type = "tear"
		shard_data.direction = base_direction.rotated(angle_offset).normalized()
		shard_data.damage = max(0.0, hitbox.damage * explosion_spawn_damage_multiplier)
		shard_data.speed = max(1.0, _attack_template.speed * explosion_spawn_speed_multiplier)
		shard_data.max_distance = max(8.0, _attack_template.max_distance * explosion_spawn_range_multiplier)
		shard_data.explosion_radius = 0.0
		shard_data.explosion_spawn_count = 0
		shard_data.split_count = 0
		shard_data.chance_split_count = 0
		shard_data.fracture_on_hit_count = 0
		if not explosion_spawn_inherit_status:
			shard_data.status_payloads = []

		var shard: Area2D = BULLET_SCENE.instantiate()
		shard.global_position = origin
		shard.setup_attack(shard_data)
		get_tree().current_scene.add_child(shard)

func _apply_homing(delta: float) -> void:
	if enemy_shot:
		return
	if homing_strength <= 0.0 or homing_radius <= 0.0:
		return

	var target := _find_homing_target()
	if target == null:
		return

	var desired_direction: Vector2 = global_position.direction_to(target.global_position)
	if desired_direction == Vector2.ZERO:
		return

	var current_direction: Vector2 = direction.normalized()
	if current_direction == Vector2.ZERO:
		current_direction = desired_direction

	var steer_factor: float = clamp(homing_strength * delta, 0.0, 1.0)
	direction = current_direction.lerp(desired_direction, steer_factor).normalized()

func _find_homing_target() -> EnemyBase:
	var root: Node = get_tree().current_scene
	if root == null:
		return null

	var best_target: EnemyBase = null
	var best_distance := homing_radius
	var baited_target: EnemyBase = null
	var baited_distance := INF

	for node in root.find_children("*", "EnemyBase", true, false):
		if node is not EnemyBase:
			continue

		var enemy := node as EnemyBase
		if enemy == null or not is_instance_valid(enemy):
			continue

		var distance: float = global_position.distance_to(enemy.global_position)
		if distance > homing_radius:
			continue

		if enemy.is_baited():
			if distance < baited_distance:
				baited_distance = distance
				baited_target = enemy
		elif distance < best_distance:
			best_distance = distance
			best_target = enemy

	return baited_target if baited_target != null else best_target

func _dispose() -> void:
	if is_queued_for_deletion():
		return

	if not _destroy_emitted:
		_destroy_emitted = true
		EventBus.emit_projectile_destroyed({
			"projectile": self,
			"enemy_shot": enemy_shot,
			"weapon_type": weapon_type,
			"infection_shot": infection_shot,
			"position": global_position,
			"distance_travelled": distance_travelled
		})
	_spawn_break_effect()

	queue_free()

func _spawn_break_effect() -> void:
	var effect = TEAR_BREAK_EFFECT.instantiate()
	effect.global_position = global_position
	get_tree().current_scene.add_child(effect)
