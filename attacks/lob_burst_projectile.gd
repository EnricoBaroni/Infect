extends Area2D
class_name LobBurstProjectile

@onready var hitbox: Hitbox = $Hitbox

var _velocity: Vector2 = Vector2.ZERO
var _gravity: float = 420.0
var _max_distance: float = 150.0
var _distance_travelled: float = 0.0
var _burst_count: int = 6
var _burst_spread_degrees: float = 360.0
var _burst_speed_multiplier: float = 0.65
var _burst_damage_multiplier: float = 0.5
var _burst_inherit_status: bool = true
var _infection_shot: bool = false
var _source_attack: AttackData
var _bullet_scene: PackedScene

func _ensure_setup_nodes() -> void:
	if hitbox == null:
		hitbox = get_node_or_null("Hitbox") as Hitbox

func setup_lob(attack_data: AttackData, bullet_scene: PackedScene) -> void:
	_ensure_setup_nodes()
	_source_attack = attack_data.copy()
	_source_attack.weapon_type = "tear"
	_bullet_scene = bullet_scene
	var direction = attack_data.direction.normalized()
	if direction == Vector2.ZERO:
		direction = Vector2.RIGHT
	_velocity = direction * max(1.0, attack_data.speed)
	_gravity = max(0.0, attack_data.lob_gravity)
	_max_distance = max(8.0, attack_data.max_distance)
	_burst_count = max(1, attack_data.lob_burst_count)
	_burst_spread_degrees = max(1.0, attack_data.lob_burst_spread_degrees)
	_burst_speed_multiplier = max(0.0, attack_data.lob_burst_speed_multiplier)
	_burst_damage_multiplier = max(0.0, attack_data.lob_burst_damage_multiplier)
	_burst_inherit_status = attack_data.lob_burst_inherit_status
	_infection_shot = attack_data.infection_shot

	var resolved_damage = attack_data.damage
	var crit_chance := clampf(attack_data.crit_chance, 0.0, 1.0)
	if attack_data.crit_luck_to_full > 0.0:
		crit_chance = EventBus.evaluate_luck_proc(
			crit_chance,
			attack_data.source_luck,
			attack_data.crit_luck_to_full,
			attack_data.crit_max_chance
		)
	if randf() <= crit_chance:
		resolved_damage *= max(1.0, attack_data.crit_multiplier)

	hitbox.damage = resolved_damage
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
	_ensure_setup_nodes()
	body_entered.connect(_on_body_entered)
	hitbox.area_entered.connect(_on_hitbox_area_entered)
	EventBus.emit_projectile_spawned({
		"projectile": self,
		"projectile_kind": "lob_burst",
		"infection_shot": _infection_shot,
		"position": global_position
	})

func _physics_process(delta: float) -> void:
	_velocity += Vector2.DOWN * _gravity * delta
	var movement = _velocity * delta
	global_position += movement
	_distance_travelled += movement.length()
	if _distance_travelled >= _max_distance:
		_burst_and_dispose()

func _on_body_entered(_body: Node2D) -> void:
	_burst_and_dispose()

func _on_hitbox_area_entered(area: Area2D) -> void:
	if area is not Hurtbox:
		return
	_burst_and_dispose()

func _burst_and_dispose() -> void:
	if is_queued_for_deletion():
		return
	_spawn_fragments()
	queue_free()

func _spawn_fragments() -> void:
	if _bullet_scene == null:
		return

	var base_direction = _source_attack.direction.normalized()
	if base_direction == Vector2.ZERO:
		base_direction = Vector2.RIGHT

	var full_circle = _burst_spread_degrees >= 359.0
	var count = max(1, _burst_count)
	var start_angle = 0.0
	var step = 0.0
	if full_circle:
		step = TAU / float(count)
	else:
		step = deg_to_rad(_burst_spread_degrees) / float(max(1, count - 1))
		start_angle = -deg_to_rad(_burst_spread_degrees) * 0.5

	for index in count:
		var angle_offset = start_angle + step * float(index)
		var direction = base_direction.rotated(angle_offset).normalized()
		var fragment_data = _source_attack.copy()
		fragment_data.weapon_type = "tear"
		fragment_data.direction = direction
		fragment_data.speed = max(1.0, _source_attack.speed * _burst_speed_multiplier)
		fragment_data.damage = _source_attack.damage * _burst_damage_multiplier
		fragment_data.max_distance = max(8.0, _source_attack.max_distance * 0.55)
		if not _burst_inherit_status:
			fragment_data.status_payloads = []

		var bullet_instance = _bullet_scene.instantiate()
		bullet_instance.global_position = global_position
		bullet_instance.setup_attack(fragment_data)
		get_tree().current_scene.add_child(bullet_instance)

func _exit_tree() -> void:
	EventBus.emit_projectile_destroyed({
		"projectile": self,
		"projectile_kind": "lob_burst",
		"infection_shot": _infection_shot,
		"position": global_position,
		"distance_travelled": _distance_travelled
	})
