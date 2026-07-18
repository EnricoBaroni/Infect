extends ReactiveEffectInstance
class_name CompanionFormationRuntime

var _player: Player
var _source_effect: Resource
var _orbital_count: int = 0
var _orbital_radius: float = 56.0
var _orbital_speed: float = 3.2
var _orbital_contact_damage: float = 0.9
var _orbital_blocks_projectiles: bool = false
var _orbital_contact_cooldown: float = 0.35
var _follower_count: int = 0
var _follower_distance: float = 72.0
var _follower_follow_speed: float = 7.0
var _follower_contact_damage: float = 0.7
var _follower_blocks_projectiles: bool = false
var _follower_contact_cooldown: float = 0.4
var _follower_shot_interval: float = 0.0
var _follower_shot_damage: float = 0.0
var _follower_shot_speed: float = 170.0
var _follower_shot_range: float = 170.0

func configure(
	player: Player,
	source_effect: Resource,
	orbital_count: int,
	orbital_radius: float,
	orbital_speed: float,
	orbital_contact_damage: float,
	orbital_blocks_projectiles: bool,
	orbital_contact_cooldown: float,
	follower_count: int,
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
	_orbital_count = max(0, orbital_count)
	_orbital_radius = orbital_radius
	_orbital_speed = orbital_speed
	_orbital_contact_damage = orbital_contact_damage
	_orbital_blocks_projectiles = orbital_blocks_projectiles
	_orbital_contact_cooldown = orbital_contact_cooldown
	_follower_count = max(0, follower_count)
	_follower_distance = follower_distance
	_follower_follow_speed = follower_follow_speed
	_follower_contact_damage = follower_contact_damage
	_follower_blocks_projectiles = follower_blocks_projectiles
	_follower_contact_cooldown = follower_contact_cooldown
	_follower_shot_interval = follower_shot_interval
	_follower_shot_damage = follower_shot_damage
	_follower_shot_speed = follower_shot_speed
	_follower_shot_range = follower_shot_range

func activate() -> void:
	var system = _get_companion_system()
	if system == null:
		return

	system.clear_source(_source_key())
	if _orbital_count > 0:
		system.spawn_orbitals(
			_source_key(),
			_player,
			_orbital_count,
			_orbital_radius,
			_orbital_speed,
			_orbital_contact_damage,
				_orbital_blocks_projectiles,
			_orbital_contact_cooldown
		)
	if _follower_count > 0:
		system.spawn_followers(
			_source_key(),
			_player,
			_follower_count,
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

func deactivate() -> void:
	var system = _get_companion_system()
	if system == null:
		return
	system.clear_source(_source_key())

func _get_companion_system() -> CompanionSystem:
	if _player == null or not is_instance_valid(_player):
		return null
	return _player.get_node_or_null("CompanionSystem") as CompanionSystem

func _source_key() -> String:
	if _source_effect == null:
		return "companion_runtime_unknown"
	return "effect_" + str(_source_effect.get_instance_id()) + "_" + str(get_instance_id())
