extends Node2D
class_name ExpandingRing

@onready var sprite: Sprite2D = $Sprite2D
@onready var hitbox: Hitbox = $Hitbox
@onready var hitbox_shape: CollisionShape2D = $Hitbox/CollisionShape2D

var _radius: float = 8.0
var _expand_rate: float = 180.0
var _max_radius: float = 84.0
var _lifetime: float = 0.6
var _age: float = 0.0
var _damage: float = 1.0
var _infection_shot: bool = false
var _contact_cooldown: float = 0.15
var _cooldowns_by_enemy: Dictionary[int, float] = {}

func setup_ring(attack_data: AttackData) -> void:
	_expand_rate = max(1.0, attack_data.ring_expand_rate)
	_max_radius = max(8.0, attack_data.ring_max_radius)
	_lifetime = max(0.05, attack_data.ring_lifetime)
	_contact_cooldown = max(0.03, attack_data.ring_contact_cooldown)
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
	hitbox.knockback_amount = max(40.0, hitbox.knockback_amount * max(0.0, attack_data.knockback_multiplier) + attack_data.knockback_flat_bonus)
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
	_update_shape_radius(_radius)
	EventBus.emit_projectile_spawned({
		"projectile": self,
		"projectile_kind": "expanding_ring",
		"infection_shot": _infection_shot,
		"position": global_position
	})

func _physics_process(delta: float) -> void:
	_age += delta
	_radius = min(_max_radius, _radius + _expand_rate * delta)
	_update_shape_radius(_radius)
	_apply_contact_damage(delta)

	if _age >= _lifetime:
		queue_free()

func _update_shape_radius(new_radius: float) -> void:
	if hitbox_shape == null:
		return
	var shape: CircleShape2D = hitbox_shape.shape as CircleShape2D
	if shape != null:
		shape.radius = new_radius

	var visual_scale = new_radius / 16.0
	sprite.scale = Vector2(visual_scale, visual_scale)

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
		"projectile_kind": "expanding_ring",
		"infection_shot": _infection_shot,
		"position": global_position
	})
