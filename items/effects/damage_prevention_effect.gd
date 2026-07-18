extends ReactiveEffectData
class_name DamagePreventionEffect

@export var charges_per_room: int = 0
@export var reset_on_room_enter: bool = false
@export var full_block: bool = true
@export var reduction_multiplier: float = 0.0
@export var flat_reduction: float = 0.0
@export var proc_chance: float = 1.0
@export var proc_luck_to_full: float = 0.0
@export var proc_max_chance: float = 1.0
@export var only_if_lethal: bool = false

func create_runtime(player: Player) -> ReactiveEffectInstance:
	var runtime := DamagePreventionRuntime.new()
	runtime.configure(
		player,
		charges_per_room,
		reset_on_room_enter,
		full_block,
		reduction_multiplier,
		flat_reduction,
		proc_chance,
		proc_luck_to_full,
		proc_max_chance,
		only_if_lethal
	)
	return runtime