extends ReactiveEffectData
class_name SpawnCompanionsOnPlayerDamagedEffect

@export var companion_type: String = "orbital"
@export var spawn_count: int = 1
@export var max_companions: int = 6
@export var proc_chance: float = 1.0
@export var luck_to_full: float = 0.0
@export var max_proc_chance: float = 1.0
@export var reset_on_room_enter: bool = true

@export var orbital_radius: float = 58.0
@export var orbital_speed: float = 3.8
@export var orbital_contact_damage: float = 1.0
@export var orbital_blocks_projectiles: bool = true
@export var orbital_contact_cooldown: float = 0.22

@export var follower_distance: float = 78.0
@export var follower_follow_speed: float = 7.0
@export var follower_contact_damage: float = 0.7
@export var follower_blocks_projectiles: bool = false
@export var follower_contact_cooldown: float = 0.3
@export var follower_shot_interval: float = 0.0
@export var follower_shot_damage: float = 0.0
@export var follower_shot_speed: float = 180.0
@export var follower_shot_range: float = 180.0

func create_runtime(player: Player) -> ReactiveEffectInstance:
	var runtime := SpawnCompanionsOnPlayerDamagedRuntime.new()
	runtime.configure(
		player,
		self,
		companion_type,
		spawn_count,
		max_companions,
		proc_chance,
		luck_to_full,
		max_proc_chance,
		reset_on_room_enter,
		orbital_radius,
		orbital_speed,
		orbital_contact_damage,
		orbital_blocks_projectiles,
		orbital_contact_cooldown,
		follower_distance,
		follower_follow_speed,
		follower_contact_damage,
		follower_blocks_projectiles,
		follower_contact_cooldown,
		follower_shot_interval,
		follower_shot_damage,
		follower_shot_speed,
		follower_shot_range
	)
	return runtime