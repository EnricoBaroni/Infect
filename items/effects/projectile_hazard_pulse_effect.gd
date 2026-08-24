extends ReactiveEffectData
class_name ProjectileHazardPulseEffect

@export var radius: float = 46.0
@export var damage: float = 0.45
@export var apply_poison: bool = false
@export var poison_duration: float = 2.5
@export var poison_dps: float = 0.6
@export var apply_slow: bool = false
@export var slow_duration: float = 1.6
@export var slow_intensity: float = 0.6
@export var trigger_chance: float = 1.0
@export var luck_to_full: float = 0.0
@export var max_trigger_chance: float = 1.0

func create_runtime(player: Player) -> ReactiveEffectInstance:
	var runtime := ProjectileHazardPulseRuntime.new()
	runtime.configure(
		player,
		radius,
		damage,
		apply_poison,
		poison_duration,
		poison_dps,
		apply_slow,
		slow_duration,
		slow_intensity,
		trigger_chance,
		luck_to_full,
		max_trigger_chance
	)
	return runtime