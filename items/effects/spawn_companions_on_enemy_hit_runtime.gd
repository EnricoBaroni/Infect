extends AbstractCompanionSpawnerRuntime
class_name SpawnCompanionsOnEnemyHitRuntime

var _proc_chance: float = 0.12
var _luck_to_full: float = 0.0
var _max_proc_chance: float = 1.0

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
	_setup_room_reset_if_needed()

func _on_enemy_hit(_payload: Dictionary) -> void:
	if _player == null or not is_instance_valid(_player):
		return
	if _spawn_count <= 0:
		return
	if _max_companions <= 0:
		return

	if not evaluate_proc(_proc_chance, _player, _luck_to_full, _max_proc_chance):
		return

	_spawn_delta(_spawn_count)

func deactivate() -> void:
	if EventBus.enemy_hit.is_connected(_on_enemy_hit):
		EventBus.enemy_hit.disconnect(_on_enemy_hit)
	super.deactivate()
