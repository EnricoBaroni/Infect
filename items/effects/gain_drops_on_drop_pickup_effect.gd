extends ReactiveEffectData
class_name GainDropsOnDropPickupEffect

@export var bonus_drops: int = 1
@export var proc_chance: float = 0.5
@export var luck_to_full: float = 0.0
@export var max_proc_chance: float = 1.0

func create_runtime(player: Player) -> ReactiveEffectInstance:
	var runtime := GainDropsOnDropPickupRuntime.new()
	runtime.configure(player, bonus_drops, proc_chance, luck_to_full, max_proc_chance)
	return runtime