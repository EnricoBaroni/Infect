extends ReactiveEffectData
class_name CompanionFormationEffect

@export var orbital_count: int = 0
@export var orbital_radius: float = 56.0
@export var orbital_speed: float = 3.2
@export var orbital_contact_damage: float = 0.9
@export var orbital_contact_cooldown: float = 0.35
@export var orbital_blocks_projectiles: bool = false

@export var follower_count: int = 0
@export var follower_distance: float = 72.0
@export var follower_follow_speed: float = 7.0
@export var follower_contact_damage: float = 0.7
@export var follower_contact_cooldown: float = 0.4
@export var follower_blocks_projectiles: bool = false
@export var follower_shot_interval: float = 0.0
@export var follower_shot_damage: float = 0.0
@export var follower_shot_speed: float = 170.0
@export var follower_shot_range: float = 170.0

func create_runtime(player: Player) -> ReactiveEffectInstance:
	var runtime := CompanionFormationRuntime.new()
	runtime.configure(
		player,
		self,
		orbital_count,
		orbital_radius,
		orbital_speed,
		orbital_contact_damage,
		orbital_blocks_projectiles,
		orbital_contact_cooldown,
		follower_count,
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
