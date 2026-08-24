extends ReactiveEffectData
class_name StatRampOnDamageEffect

@export var damage_per_hit: float = 0.0
@export var speed_per_hit: float = 0.0
@export var fire_rate_reduction_per_hit: float = 0.0
@export var max_stacks: int = 8
@export var reset_on_room_exit: bool = false

func create_runtime(player: Player) -> ReactiveEffectInstance:
	var runtime := StatRampOnDamageRuntime.new()
	runtime.configure(
		player,
		damage_per_hit,
		speed_per_hit,
		fire_rate_reduction_per_hit,
		max_stacks,
		reset_on_room_exit
	)
	return runtime
