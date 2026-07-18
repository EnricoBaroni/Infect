extends Node2D
class_name PassiveFollower

@onready var hitbox: Hitbox = $Hitbox

var _player: Player
var _slot := 0
var _total := 1
var _follow_distance := 72.0
var _follow_speed := 6.0
var _damage := 0.65
var _blocks_projectiles := false
var _contact_cooldown := 0.45
var _shot_interval := 0.0
var _shot_damage := 0.0
var _shot_speed := 170.0
var _shot_range := 170.0
var _shot_timer := 0.0
var _cooldowns_by_enemy: Dictionary[int, float] = {}

func configure(
	player: Player,
	slot: int,
	total: int,
	follow_distance: float,
	follow_speed: float,
	damage: float,
	blocks_projectiles: bool,
	contact_cooldown: float,
	shot_interval: float,
	shot_damage: float,
	shot_speed: float,
	shot_range: float
) -> void:
	_player = player
	_slot = max(0, slot)
	_total = max(1, total)
	_follow_distance = max(20.0, follow_distance)
	_follow_speed = max(1.0, follow_speed)
	_damage = max(0.0, damage)
	_blocks_projectiles = blocks_projectiles
	_contact_cooldown = max(0.05, contact_cooldown)
	_shot_interval = max(0.0, shot_interval)
	_shot_damage = max(0.0, shot_damage)
	_shot_speed = max(10.0, shot_speed)
	_shot_range = max(20.0, shot_range)
	_shot_timer = randf_range(0.0, _shot_interval)

func _ready() -> void:
	hitbox.damage = _damage
	hitbox.knockback_amount = 65.0

func _physics_process(delta: float) -> void:
	if _player == null or not is_instance_valid(_player):
		queue_free()
		return

	var spread = 0.35
	var center = float(_total - 1) * 0.5
	var offset_angle = (float(_slot) - center) * spread
	var desired = _player.global_position + Vector2(-_follow_distance, 0).rotated(offset_angle)
	global_position = global_position.lerp(desired, clamp(_follow_speed * delta, 0.0, 1.0))

	_apply_contact_damage(delta)
	if _blocks_projectiles:
		_block_enemy_projectiles()
	_update_shooting(delta)

func _apply_contact_damage(delta: float) -> void:
	var expired_enemy_ids: Array[int] = []
	for enemy_id: int in _cooldowns_by_enemy.keys():
		var remaining: float = _cooldowns_by_enemy[enemy_id] - delta
		if remaining <= 0.0:
			expired_enemy_ids.append(enemy_id)
			continue
		_cooldowns_by_enemy[enemy_id] = remaining
	for enemy_id: int in expired_enemy_ids:
		_cooldowns_by_enemy.erase(enemy_id)

	for area in hitbox.get_overlapping_areas():
		if area is not Hurtbox:
			continue

		var enemy_node: Node = area.get_parent()
		if enemy_node is not EnemyBase:
			continue
		var enemy := enemy_node as EnemyBase
		if enemy == null or not is_instance_valid(enemy):
			continue

		var enemy_id = enemy.get_instance_id()
		if _cooldowns_by_enemy.get(enemy_id, 0.0) > 0.0:
			continue

		var to_enemy = enemy.global_position - global_position
		hitbox.knockback_direction = to_enemy.normalized()
		enemy.take_hit(hitbox)
		_cooldowns_by_enemy[enemy_id] = _contact_cooldown

func _block_enemy_projectiles() -> void:
	for area in hitbox.get_overlapping_areas():
		if area == null or not is_instance_valid(area):
			continue
		if not area.has_method("queue_free"):
			continue
		if not (area is Area2D):
			continue
		if not (area.has_meta("enemy_shot") and bool(area.get_meta("enemy_shot"))):
			continue
		area.call_deferred("queue_free")

func _update_shooting(delta: float) -> void:
	if _shot_interval <= 0.0 or _shot_damage <= 0.0:
		return

	_shot_timer -= delta
	if _shot_timer > 0.0:
		return

	var target := _find_nearest_enemy()
	if target == null:
		_shot_timer = 0.05
		return

	var player_projectile_system: ProjectileSystem = _player.get_node_or_null("ProjectileSystem") as ProjectileSystem
	if player_projectile_system == null:
		_shot_timer = _shot_interval
		return

	if _player.BULLET == null:
		_shot_timer = _shot_interval
		return

	var attack_data := AttackData.new()
	attack_data.direction = global_position.direction_to(target.global_position)
	attack_data.damage = _shot_damage
	attack_data.speed = _shot_speed
	attack_data.max_distance = _shot_range
	attack_data.movement_inheritance = 0.0
	attack_data.infection_shot = false
	attack_data.weapon_type = "tear"
	if _player.stats:
		attack_data.source_luck = _player.stats.luck

	player_projectile_system.spawn_projectile(attack_data, _player.BULLET, global_position)
	_shot_timer = _shot_interval

func _find_nearest_enemy() -> EnemyBase:
	var root = get_tree().current_scene
	if root == null:
		return null

	var nearest: EnemyBase = null
	var nearest_distance := _shot_range
	for node in root.find_children("*", "EnemyBase", true, false):
		if node is not EnemyBase:
			continue
		var enemy := node as EnemyBase
		if enemy == null or not is_instance_valid(enemy):
			continue
		var distance := global_position.distance_to(enemy.global_position)
		if distance <= nearest_distance:
			nearest_distance = distance
			nearest = enemy

	return nearest
