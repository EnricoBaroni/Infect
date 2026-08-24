extends ReactiveEffectData
class_name TempStatBuffOnKillEffect

@export var damage_bonus: float = 0.0
@export var speed_bonus: float = 0.0
@export var fire_rate_reduction: float = 0.0
@export var buff_duration: float = 3.0
@export var only_infected_kills: bool = false

func create_runtime(player: Player) -> ReactiveEffectInstance:
	var runtime := TempStatBuffOnKillRuntime.new()
	runtime.configure(
		player,
		damage_bonus,
		speed_bonus,
		fire_rate_reduction,
		buff_duration,
		only_infected_kills
	)
	return runtime
