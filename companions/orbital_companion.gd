extends Node2D
class_name OrbitalCompanion

@onready var hitbox: Hitbox = $Hitbox

var _player: Player
var _orbit_radius := 60.0
var _angular_speed := 3.4
var _angle := 0.0
var _damage := 0.8
var _blocks_projectiles := false
var _contact_cooldown := 0.35
var _cooldowns_by_enemy: Dictionary[int, float] = {}

func configure(
	player: Player,
	orbit_radius: float,
	angular_speed: float,
	damage: float,
	blocks_projectiles: bool,
	contact_cooldown: float,
	initial_angle: float
) -> void:
	_player = player
	_orbit_radius = max(12.0, orbit_radius)
	_angular_speed = angular_speed
	_damage = max(0.0, damage)
	_blocks_projectiles = blocks_projectiles
	_contact_cooldown = max(0.05, contact_cooldown)
	_angle = initial_angle

func _ready() -> void:
	hitbox.damage = _damage
	hitbox.knockback_amount = 80.0

func _physics_process(delta: float) -> void:
	if _player == null or not is_instance_valid(_player):
		queue_free()
		return

	_angle += _angular_speed * delta
	global_position = _player.global_position + Vector2.RIGHT.rotated(_angle) * _orbit_radius
	_apply_contact_damage(delta)
	if _blocks_projectiles:
		_block_enemy_projectiles()

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
