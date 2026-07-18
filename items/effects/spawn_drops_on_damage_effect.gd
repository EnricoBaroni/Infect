extends ReactiveEffectData
class_name SpawnDropsOnDamageEffect

@export var drops_on_damage: int = 1
@export var proc_chance: float = 1.0
@export var luck_to_full: float = 0.0
@export var max_proc_chance: float = 1.0

func create_runtime(player: Player) -> ReactiveEffectInstance:
	var runtime := SpawnDropsOnDamageRuntime.new()
	runtime.configure(player, drops_on_damage, proc_chance, luck_to_full, max_proc_chance)
	return runtime
