extends ReactiveEffectData
class_name StatRampOnKillEffect

@export var damage_per_kill: float = 0.0
@export var speed_per_kill: float = 0.0
@export var fire_rate_reduction_per_kill: float = 0.0
@export var only_infected_kills: bool = false
@export var max_stacks: int = 10
@export var reset_on_room_exit: bool = false

func create_runtime(player: Player) -> ReactiveEffectInstance:
	var runtime := StatRampOnKillRuntime.new()
	runtime.configure(
		player,
		damage_per_kill,
		speed_per_kill,
		fire_rate_reduction_per_kill,
		only_infected_kills,
		max_stacks,
		reset_on_room_exit
	)
	return runtime
