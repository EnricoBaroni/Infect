extends Node2D
class_name RemoteOrb

@onready var hitbox: Hitbox = $Hitbox

var _control_direction: Vector2 = Vector2.RIGHT
var _velocity: Vector2 = Vector2.ZERO
var _speed: float = 120.0
var _turn_rate: float = 5.0
var _lifetime: float = 5.0
var _age: float = 0.0
var _damage: float = 1.0
var _infection_shot: bool = false
var _contact_cooldown: float = 0.12
var _cooldowns_by_enemy: Dictionary[int, float] = {}

func setup_orb(attack_data: AttackData) -> void:
	_speed = max(1.0, attack_data.remote_speed)
	_turn_rate = max(0.1, attack_data.remote_turn_rate)
	_lifetime = max(0.2, attack_data.remote_lifetime)
	_contact_cooldown = max(0.03, attack_data.remote_contact_cooldown)
	_control_direction = attack_data.direction.normalized()
	if _control_direction == Vector2.ZERO:
		_control_direction = Vector2.RIGHT
	if _velocity == Vector2.ZERO:
		_velocity = _control_direction * _speed

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
	hitbox.knockback_amount = max(50.0, hitbox.knockback_amount * max(0.0, attack_data.knockback_multiplier) + attack_data.knockback_flat_bonus)
	hitbox.source_faction = "player"
	hitbox.source_is_projectile = true
	hitbox.source_luck = attack_data.source_luck
	hitbox.status_payloads = attack_data.clone_status_payloads()
	hitbox.infection_power = 0
	if _infection_shot:
		modulate = Color.GREEN
		hitbox.damage = 0
		hitbox.infection_power = 1

func set_control_direction(new_direction: Vector2) -> void:
	if new_direction == Vector2.ZERO:
		return
	_control_direction = new_direction.normalized()

func _ready() -> void:
	EventBus.emit_projectile_spawned({
		"projectile": self,
		"projectile_kind": "remote_orb",
		"infection_shot": _infection_shot,
		"position": global_position
	})

func _physics_process(delta: float) -> void:
	_age += delta
	if _age >= _lifetime:
		queue_free()
		return

	var current_direction = _velocity.normalized()
	if current_direction == Vector2.ZERO:
		current_direction = _control_direction
	current_direction = current_direction.lerp(_control_direction, clamp(_turn_rate * delta, 0.0, 1.0)).normalized()
	_velocity = current_direction * _speed
	global_position += _velocity * delta

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

		hitbox.knockback_direction = (_velocity.normalized())
		enemy.take_hit(hitbox)
		_cooldowns_by_enemy[enemy_id] = _contact_cooldown

func _exit_tree() -> void:
	EventBus.emit_projectile_destroyed({
		"projectile": self,
		"projectile_kind": "remote_orb",
		"infection_shot": _infection_shot,
		"position": global_position
	})
