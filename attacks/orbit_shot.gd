extends Node2D
class_name OrbitShot

@onready var hitbox: Hitbox = $Hitbox

var _player: Player
var _angle: float = 0.0
var _radius: float = 64.0
var _angular_speed: float = 3.5
var _duration: float = 2.0
var _radial_drift: float = 8.0
var _age: float = 0.0
var _damage: float = 1.0
var _infection_shot: bool = false
var _contact_cooldown: float = 0.16
var _cooldowns_by_enemy: Dictionary[int, float] = {}

func setup_orbit(player: Player, attack_data: AttackData) -> void:
	_player = player
	var direction = attack_data.direction.normalized()
	if direction == Vector2.ZERO:
		direction = Vector2.RIGHT
	_angle = direction.angle()
	_radius = max(8.0, attack_data.orbit_radius)
	_angular_speed = attack_data.orbit_angular_speed
	_duration = max(0.05, attack_data.orbit_duration)
	_radial_drift = attack_data.orbit_radial_drift
	_contact_cooldown = max(0.03, attack_data.orbit_contact_cooldown)

	_infection_shot = attack_data.infection_shot
	_damage = attack_data.damage
	var crit_chance := clampf(attack_data.crit_chance, 0.0, 1.0)
	if attack_data.crit_luck_to_full > 0.0:
		crit_chance = EventBus.evaluate_luck_proc(
			crit_chance,
			attack_data.source_luck,
			attack_data.crit_luck_to_full,
			attack_data.crit_max_chance
		)
	if randf() <= crit_chance:
		_damage *= max(1.0, attack_data.crit_multiplier)

	hitbox.damage = _damage
	hitbox.knockback_amount = max(45.0, hitbox.knockback_amount * max(0.0, attack_data.knockback_multiplier) + attack_data.knockback_flat_bonus)
	hitbox.source_faction = "player"
	hitbox.source_is_projectile = true
	hitbox.source_luck = attack_data.source_luck
	hitbox.status_payloads = attack_data.clone_status_payloads()
	hitbox.infection_power = 0
	if _infection_shot:
		modulate = Color.GREEN
		hitbox.damage = 0
		hitbox.infection_power = 1

func _ready() -> void:
	EventBus.emit_projectile_spawned({
		"projectile": self,
		"projectile_kind": "orbit_shot",
		"infection_shot": _infection_shot,
		"position": global_position
	})

func _physics_process(delta: float) -> void:
	if _player == null or not is_instance_valid(_player):
		queue_free()
		return

	_age += delta
	if _age >= _duration:
		queue_free()
		return

	_angle += _angular_speed * delta
	_radius = max(0.0, _radius + _radial_drift * delta)
	global_position = _player.global_position + Vector2.RIGHT.rotated(_angle) * _radius
	_apply_contact_damage(delta)

func _apply_contact_damage(delta: float) -> void:
	for enemy_id: int in _cooldowns_by_enemy.keys():
		_cooldowns_by_enemy[enemy_id] = _cooldowns_by_enemy[enemy_id] - delta

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

		hitbox.knockback_direction = (enemy.global_position - global_position).normalized()
		enemy.take_hit(hitbox)
		_cooldowns_by_enemy[enemy_id] = _contact_cooldown

func _exit_tree() -> void:
	EventBus.emit_projectile_destroyed({
		"projectile": self,
		"projectile_kind": "orbit_shot",
		"infection_shot": _infection_shot,
		"position": global_position
	})
