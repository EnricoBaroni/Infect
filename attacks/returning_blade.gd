extends Node2D
class_name ReturningBlade

@onready var hitbox: Hitbox = $Hitbox

var _player: Player
var _direction: Vector2 = Vector2.RIGHT
var _start_position: Vector2 = Vector2.ZERO
var _speed: float = 180.0
var _outbound_distance: float = 72.0
var _return_speed: float = 260.0
var _spin_speed: float = 16.0
var _damage: float = 1.0
var _infection_shot: bool = false
var _contact_cooldown: float = 0.2
var _returning: bool = false
var _cooldowns_by_enemy: Dictionary[int, float] = {}

func _ensure_setup_nodes() -> void:
	if hitbox == null:
		hitbox = get_node_or_null("Hitbox") as Hitbox

func setup_blade(player: Player, attack_data: AttackData) -> void:
	_ensure_setup_nodes()
	_player = player
	_direction = attack_data.direction.normalized()
	if _direction == Vector2.ZERO:
		_direction = Vector2.RIGHT
	_start_position = global_position
	_speed = max(1.0, attack_data.speed)
	_outbound_distance = max(12.0, attack_data.blade_outbound_distance)
	_return_speed = max(1.0, attack_data.blade_return_speed)
	_spin_speed = attack_data.blade_spin_speed
	_contact_cooldown = max(0.03, attack_data.blade_contact_cooldown)
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
	hitbox.knockback_amount = max(60.0, hitbox.knockback_amount * max(0.0, attack_data.knockback_multiplier) + attack_data.knockback_flat_bonus)
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
	_ensure_setup_nodes()
	EventBus.emit_projectile_spawned({
		"projectile": self,
		"projectile_kind": "returning_blade",
		"infection_shot": _infection_shot,
		"position": global_position
	})

func _physics_process(delta: float) -> void:
	rotation += _spin_speed * delta
	if _returning:
		_step_return(delta)
	else:
		_step_outbound(delta)
	_apply_contact_damage(delta)

func _step_outbound(delta: float) -> void:
	global_position += _direction * _speed * delta
	if global_position.distance_to(_start_position) >= _outbound_distance:
		_returning = true

func _step_return(delta: float) -> void:
	if _player == null or not is_instance_valid(_player):
		queue_free()
		return

	var to_player = _player.global_position - global_position
	if to_player.length() <= 12.0:
		queue_free()
		return

	global_position += to_player.normalized() * _return_speed * delta

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

		var enemy_id: int = enemy.get_instance_id()
		if _cooldowns_by_enemy.get(enemy_id, 0.0) > 0.0:
			continue

		var to_enemy = enemy.global_position - global_position
		hitbox.knockback_direction = to_enemy.normalized()
		enemy.take_hit(hitbox)
		_cooldowns_by_enemy[enemy_id] = _contact_cooldown

func _exit_tree() -> void:
	EventBus.emit_projectile_destroyed({
		"projectile": self,
		"projectile_kind": "returning_blade",
		"infection_shot": _infection_shot,
		"position": global_position
	})
