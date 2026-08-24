extends ReactiveEffectInstance
class_name RoomEntryHazardPulseRuntime

var _player: Player
var _radius: float = 420.0
var _damage: float = 1.0
var _apply_poison: bool = false
var _poison_duration: float = 2.0
var _poison_dps: float = 0.7
var _apply_fear: bool = false
var _fear_duration: float = 2.0
var _apply_slow: bool = false
var _slow_duration: float = 1.8
var _slow_intensity: float = 0.6
var _proc_chance: float = 1.0
var _luck_to_full: float = 0.0
var _max_proc_chance: float = 1.0

func configure(
	player: Player,
	radius: float,
	damage: float,
	apply_poison: bool,
	poison_duration: float,
	poison_dps: float,
	apply_fear: bool,
	fear_duration: float,
	apply_slow: bool,
	slow_duration: float,
	slow_intensity: float,
	proc_chance: float,
	luck_to_full: float,
	max_proc_chance: float
) -> void:
	_player = player
	_radius = max(8.0, radius)
	_damage = max(0.0, damage)
	_apply_poison = apply_poison
	_poison_duration = max(0.1, poison_duration)
	_poison_dps = max(0.0, poison_dps)
	_apply_fear = apply_fear
	_fear_duration = max(0.1, fear_duration)
	_apply_slow = apply_slow
	_slow_duration = max(0.1, slow_duration)
	_slow_intensity = clampf(slow_intensity, 0.0, 1.0)
	_proc_chance = clampf(proc_chance, 0.0, 1.0)
	_luck_to_full = maxf(0.0, luck_to_full)
	_max_proc_chance = clampf(max_proc_chance, 0.0, 1.0)

func activate() -> void:
	if not EventBus.room_entered.is_connected(_on_room_entered):
		EventBus.room_entered.connect(_on_room_entered)

func deactivate() -> void:
	if EventBus.room_entered.is_connected(_on_room_entered):
		EventBus.room_entered.disconnect(_on_room_entered)

func _on_room_entered(payload: Dictionary) -> void:
	if _player == null or not is_instance_valid(_player):
		return

	var chance := _proc_chance
	if _luck_to_full > 0.0 and _player.stats != null:
		chance = EventBus.evaluate_luck_proc(_proc_chance, _player.stats.luck, _luck_to_full, _max_proc_chance)
	if randf() > chance:
		return

	var room: Node = payload.get("room", null)
	if room == null:
		return

	var center := _player.global_position
	_apply_pulse(room, center)

func _apply_pulse(room: Node, center: Vector2) -> void:
	var pulse_hitbox := Hitbox.new()
	pulse_hitbox.damage = _damage
	pulse_hitbox.infection_power = 0
	pulse_hitbox.source_faction = "player"
	pulse_hitbox.source_luck = _player.stats.luck if (_player != null and _player.stats != null) else 0.0
	pulse_hitbox.status_payloads = _build_status_payloads()

	for node in room.find_children("*", "EnemyBase", true, false):
		if node is not EnemyBase:
			continue
		var enemy := node as EnemyBase
		if enemy == null or not is_instance_valid(enemy):
			continue
		var to_enemy := enemy.global_position - center
		if to_enemy.length() > _radius:
			continue
		pulse_hitbox.knockback_direction = to_enemy.normalized()
		pulse_hitbox.knockback_amount = 60.0
		enemy.take_hit(pulse_hitbox)

func _build_status_payloads() -> Array[StatusPayload]:
	var payloads: Array[StatusPayload] = []
	if _apply_poison:
		var poison := StatusPayload.new()
		poison.status_id = "poison"
		poison.duration = _poison_duration
		poison.magnitude = _poison_dps
		poison.tick_interval = 0.5
		poison.max_stacks = 2
		poison.stack_rule = "refresh"
		poison.visual_tint = Color(0.55, 1.0, 0.45, 1.0)
		poison.proc_chance = 1.0
		payloads.append(poison)
	if _apply_fear:
		var fear := StatusPayload.new()
		fear.status_id = "fear"
		fear.duration = _fear_duration
		fear.magnitude = 1.0
		fear.tick_interval = 0.0
		fear.max_stacks = 1
		fear.stack_rule = "refresh"
		fear.visual_tint = Color(0.95, 0.75, 1.0, 1.0)
		fear.proc_chance = 1.0
		payloads.append(fear)
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
