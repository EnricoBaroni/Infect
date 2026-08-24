extends ReactiveEffectInstance
class_name AbstractCompanionSpawnerRuntime

## Base class for reactive effects that spawn companions.
## Provides common companion lifecycle management and spawning logic.
## Subclasses must implement activate/deactivate for event-specific subscriptions.

var _player: Player
var _source_effect: Resource
var _companion_type: String = "orbital"
var _spawn_count: int = 1
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

func activate() -> void:
	# Subclasses override to subscribe to events and call _setup_room_reset_if_needed()
	pass

func deactivate() -> void:
	# Disconnect room_entered if it was subscribed
	if EventBus.room_entered.is_connected(_on_room_entered):
		EventBus.room_entered.disconnect(_on_room_entered)
	# Clean up companions
	var system := _get_companion_system()
	if system != null:
		system.clear_source(_source_key())

## Call this from subclass activate() if room reset is needed.
func _setup_room_reset_if_needed() -> void:
	if _reset_on_room_enter and not EventBus.room_entered.is_connected(_on_room_entered):
		EventBus.room_entered.connect(_on_room_entered)
	_refresh_companions()

## Increment active companions by delta and refresh display.
func _spawn_delta(delta: int) -> void:
	_active_companions = min(_max_companions, _active_companions + delta)
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
