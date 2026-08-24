extends ReactiveEffectData
class_name RoomEntryHazardPulseEffect

@export var radius: float = 420.0
@export var damage: float = 1.0
@export var apply_poison: bool = false
@export var poison_duration: float = 2.0
@export var poison_dps: float = 0.7
@export var apply_fear: bool = false
@export var fear_duration: float = 2.0
@export var apply_slow: bool = false
@export var slow_duration: float = 1.8
@export var slow_intensity: float = 0.6
@export var proc_chance: float = 1.0
@export var luck_to_full: float = 0.0
@export var max_proc_chance: float = 1.0

func create_runtime(player: Player) -> ReactiveEffectInstance:
	var runtime := RoomEntryHazardPulseRuntime.new()
	runtime.configure(
		player,
		radius,
		damage,
		apply_poison,
		poison_duration,
		poison_dps,
		apply_fear,
		fear_duration,
		apply_slow,
		slow_duration,
		slow_intensity,
		proc_chance,
		luck_to_full,
		max_proc_chance
	)
	return runtime