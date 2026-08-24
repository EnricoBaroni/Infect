extends ReactiveEffectInstance
class_name ProjectileHazardPulseRuntime

var _player: Player
var _radius: float = 46.0
var _damage: float = 0.45
var _apply_poison: bool = false
var _poison_duration: float = 2.5
var _poison_dps: float = 0.6
var _apply_slow: bool = false
var _slow_duration: float = 1.6
var _slow_intensity: float = 0.6
var _trigger_chance: float = 1.0
var _luck_to_full: float = 0.0
var _max_trigger_chance: float = 1.0

func configure(
	player: Player,
	radius: float,
	damage: float,
	apply_poison: bool,
	poison_duration: float,
	poison_dps: float,
	apply_slow: bool,
	slow_duration: float,
	slow_intensity: float,
	trigger_chance: float,
	luck_to_full: float,
	max_trigger_chance: float
) -> void:
	_player = player
	_radius = max(8.0, radius)
	_damage = max(0.0, damage)
	_apply_poison = apply_poison
	_poison_duration = max(0.1, poison_duration)
	_poison_dps = max(0.0, poison_dps)
	_apply_slow = apply_slow
	_slow_duration = max(0.1, slow_duration)
	_slow_intensity = clampf(slow_intensity, 0.0, 1.0)
	_trigger_chance = clampf(trigger_chance, 0.0, 1.0)
	_luck_to_full = maxf(0.0, luck_to_full)
	_max_trigger_chance = clampf(max_trigger_chance, 0.0, 1.0)

func activate() -> void:
	if not EventBus.projectile_destroyed.is_connected(_on_projectile_destroyed):
		EventBus.projectile_destroyed.connect(_on_projectile_destroyed)

func deactivate() -> void:
	if EventBus.projectile_destroyed.is_connected(_on_projectile_destroyed):
		EventBus.projectile_destroyed.disconnect(_on_projectile_destroyed)

func _on_projectile_destroyed(payload: Dictionary) -> void:
	if _player == null or not is_instance_valid(_player):
		return
	if bool(payload.get("enemy_shot", false)):
		return
	if not payload.has("position"):
		return

	var chance := _trigger_chance
	if _luck_to_full > 0.0 and _player != null and _player.stats != null:
		chance = EventBus.evaluate_luck_proc(
			_trigger_chance,
			_player.stats.luck,
			_luck_to_full,
			_max_trigger_chance
		)
	if randf() > chance:
		return

	var center: Vector2 = payload["position"]
	_apply_hazard(center)

func _apply_hazard(center: Vector2) -> void:
	if _player == null or not is_instance_valid(_player):
		return

	var root: Node = _player.get_tree().current_scene
	if root == null:
		return

	var hazard_hitbox := Hitbox.new()
	hazard_hitbox.damage = _damage
	hazard_hitbox.infection_power = 0
	hazard_hitbox.source_faction = "player"
	hazard_hitbox.source_luck = _player.stats.luck if (_player != null and _player.stats != null) else 0.0
	hazard_hitbox.status_payloads = _build_status_payloads()

	for node in root.find_children("*", "EnemyBase", true, false):
		if node is not EnemyBase:
			continue
		var enemy := node as EnemyBase
		if enemy == null or not is_instance_valid(enemy):
			continue
		var to_enemy := enemy.global_position - center
		if to_enemy.length() > _radius:
			continue
		hazard_hitbox.knockback_direction = to_enemy.normalized()
		hazard_hitbox.knockback_amount = 30.0
		enemy.take_hit(hazard_hitbox)

func _build_status_payloads() -> Array[StatusPayload]:
	var payloads: Array[StatusPayload] = []
	if _apply_poison:
		var poison := StatusPayload.new()
		poison.status_id = "poison"
		poison.duration = _poison_duration
		poison.magnitude = _poison_dps
		poison.tick_interval = 0.5
		poison.max_stacks = 3
		poison.stack_rule = "refresh"
		poison.visual_tint = Color(0.55, 1.0, 0.45, 1.0)
		poison.proc_chance = 1.0
		payloads.append(poison)
	if _apply_slow:
		var slow := StatusPayload.new()
		slow.status_id = "slow"
		slow.duration = _slow_duration
		slow.magnitude = _slow_intensity
		slow.tick_interval = 0.0
		slow.max_stacks = 1
		slow.stack_rule = "refresh"
		slow.visual_tint = Color(0.7, 0.85, 1.0, 1.0)
		slow.proc_chance = 1.0
		payloads.append(slow)
	return payloads
