extends ReactiveEffectInstance
class_name SpawnCompanionsOnEnemyHitRuntime

var _player: Player
var _source_effect: Resource
var _companion_type: String = "follower"
var _spawn_count: int = 1
var _max_companions: int = 8
var _proc_chance: float = 0.12
var _luck_to_full: float = 0.0
var _max_proc_chance: float = 1.0
var _reset_on_room_enter: bool = true
var _active_companions: int = 0

var _orbital_radius: float = 56.0
var _orbital_speed: float = 3.4
var _orbital_contact_damage: float = 0.75
var _orbital_blocks_projectiles: bool = false
var _orbital_contact_cooldown: float = 0.3

var _follower_distance: float = 72.0
var _follower_follow_speed: float = 7.0
var _follower_contact_damage: float = 0.65
var _follower_blocks_projectiles: bool = false
var _follower_contact_cooldown: float = 0.35
var _follower_shot_interval: float = 0.0
var _follower_shot_damage: float = 0.0
var _follower_shot_speed: float = 170.0
var _follower_shot_range: float = 170.0

func configure(
	player: Player,
	source_effect: Resource,
	companion_type: String,
	spawn_count: int,
	max_companions: int,
	proc_chance: float,
	luck_to_full: float,
	max_proc_chance: float,
	reset_on_room_enter: bool,
	orbital_radius: float,
	orbital_speed: float,
	orbital_contact_damage: float,
	orbital_blocks_projectiles: bool,
	orbital_contact_cooldown: float,
	follower_distance: float,
	follower_follow_speed: float,
	follower_contact_damage: float,
	follower_blocks_projectiles: bool,
	follower_contact_cooldown: float,
	follower_shot_interval: float,
	follower_shot_damage: float,
	follower_shot_speed: float,
	follower_shot_range: float
) -> void:
	_player = player
	_source_effect = source_effect
	_companion_type = companion_type
	_spawn_count = max(0, spawn_count)
	_max_companions = max(0, max_companions)
	_proc_chance = clampf(proc_chance, 0.0, 1.0)
	_luck_to_full = maxf(0.0, luck_to_full)
	_max_proc_chance = clampf(max_proc_chance, 0.0, 1.0)
	_reset_on_room_enter = reset_on_room_enter
	_orbital_radius = max(12.0, orbital_radius)
	_orbital_speed = orbital_speed
	_orbital_contact_damage = max(0.0, orbital_contact_damage)
	_orbital_blocks_projectiles = orbital_blocks_projectiles
	_orbital_contact_cooldown = max(0.05, orbital_contact_cooldown)
	_follower_distance = max(20.0, follower_distance)
	_follower_follow_speed = max(1.0, follower_follow_speed)
	_follower_contact_damage = max(0.0, follower_contact_damage)
	_follower_blocks_projectiles = follower_blocks_projectiles
	_follower_contact_cooldown = max(0.05, follower_contact_cooldown)
	_follower_shot_interval = max(0.0, follower_shot_interval)
	_follower_shot_damage = max(0.0, follower_shot_damage)
	_follower_shot_speed = max(10.0, follower_shot_speed)
	_follower_shot_range = max(20.0, follower_shot_range)

func activate() -> void:
	if not EventBus.enemy_hit.is_connected(_on_enemy_hit):
		EventBus.enemy_hit.connect(_on_enemy_hit)
	if _reset_on_room_enter and not EventBus.room_entered.is_connected(_on_room_entered):
		EventBus.room_entered.connect(_on_room_entered)
	_refresh_companions()

func deactivate() -> void:
	if EventBus.enemy_hit.is_connected(_on_enemy_hit):
		EventBus.enemy_hit.disconnect(_on_enemy_hit)
	if EventBus.room_entered.is_connected(_on_room_entered):
		EventBus.room_entered.disconnect(_on_room_entered)
	var system := _get_companion_system()
	if system != null:
		system.clear_source(_source_key())

func _on_enemy_hit(_payload: Dictionary) -> void:
	if _player == null or not is_instance_valid(_player):
		return
	if _spawn_count <= 0:
		return
	if _max_companions <= 0:
		return

	var proc := _proc_chance
	if _luck_to_full > 0.0 and _player.stats != null:
		proc = EventBus.evaluate_luck_proc(proc, _player.stats.luck, _luck_to_full, _max_proc_chance)
	if randf() > proc:
		return

	_active_companions = min(_max_companions, _active_companions + _spawn_count)
	_refresh_companions()

func _on_room_entered(_payload: Dictionary) -> void:
	_active_companions = 0
	_refresh_companions()

func _refresh_companions() -> void:
	var system := _get_companion_system()
	if system == null:
		return

	system.clear_source(_source_key())
	if _active_companions <= 0:
		return

	if _companion_type == "orbital":
		system.spawn_orbitals(
			_source_key(),
			_player,
			_active_companions,
			_orbital_radius,
			_orbital_speed,
			_orbital_contact_damage,
			_orbital_blocks_projectiles,
			_orbital_contact_cooldown
		)
		return

	system.spawn_followers(
		_source_key(),
		_player,
		_active_companions,
		_follower_distance,
		_follower_follow_speed,
		_follower_contact_damage,
		_follower_blocks_projectiles,
		_follower_contact_cooldown,
		_follower_shot_interval,
		_follower_shot_damage,
		_follower_shot_speed,
		_follower_shot_range
	)

func _get_companion_system() -> CompanionSystem:
	if _player == null or not is_instance_valid(_player):
		return null
	return _player.get_node_or_null("CompanionSystem") as CompanionSystem

func _source_key() -> String:
	if _source_effect == null:
		return "spawn_on_hit_runtime_" + str(get_instance_id())
	return "spawn_on_hit_effect_" + str(_source_effect.get_instance_id()) + "_" + str(get_instance_id())