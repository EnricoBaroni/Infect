extends ReactiveEffectInstance
class_name SpawnCompanionsOnKillRuntime

var _player: Player
var _source_effect: Resource
var _companion_type: String = "orbital"
var _spawn_per_kill: int = 1
var _max_companions: int = 8
var _reset_on_room_enter: bool = true
var _active_companions: int = 0

var _orbital_radius: float = 56.0
var _orbital_speed: float = 3.4
var _orbital_contact_damage: float = 0.8
var _orbital_blocks_projectiles: bool = false
var _orbital_contact_cooldown: float = 0.35

var _follower_distance: float = 72.0
var _follower_follow_speed: float = 7.0
var _follower_contact_damage: float = 0.65
var _follower_blocks_projectiles: bool = false
var _follower_contact_cooldown: float = 0.4
var _follower_shot_interval: float = 0.0
var _follower_shot_damage: float = 0.0
var _follower_shot_speed: float = 170.0
var _follower_shot_range: float = 170.0

func configure(
	player: Player,
	source_effect: Resource,
	companion_type: String,
	spawn_per_kill: int,
	max_companions: int,
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
	_spawn_per_kill = max(0, spawn_per_kill)
	_max_companions = max(0, max_companions)
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
	if not EventBus.enemy_killed.is_connected(_on_enemy_killed):
		EventBus.enemy_killed.connect(_on_enemy_killed)
	if _reset_on_room_enter and not EventBus.room_entered.is_connected(_on_room_entered):
		EventBus.room_entered.connect(_on_room_entered)
	_refresh_companions()

func deactivate() -> void:
	if EventBus.enemy_killed.is_connected(_on_enemy_killed):
		EventBus.enemy_killed.disconnect(_on_enemy_killed)
	if EventBus.room_entered.is_connected(_on_room_entered):
		EventBus.room_entered.disconnect(_on_room_entered)
	var system := _get_companion_system()
	if system != null:
		system.clear_source(_source_key())

func _on_enemy_killed(_payload: Dictionary) -> void:
	if _player == null or not is_instance_valid(_player):
		return
	if _spawn_per_kill <= 0:
		return
	if _max_companions <= 0:
		return
	_active_companions = min(_max_companions, _active_companions + _spawn_per_kill)
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

	if _companion_type == "follower":
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
		return

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

func _get_companion_system() -> CompanionSystem:
	if _player == null or not is_instance_valid(_player):
		return null
	return _player.get_node_or_null("CompanionSystem") as CompanionSystem

func _source_key() -> String:
	if _source_effect == null:
		return "spawn_companions_runtime_" + str(get_instance_id())
	return "spawn_companions_effect_" + str(_source_effect.get_instance_id()) + "_" + str(get_instance_id())