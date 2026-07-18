extends ReactiveEffectData
class_name GainDropsOnEnemyHitEffect

@export var drops_per_hit: int = 1
@export var infected_bonus: int = 0
@export var proc_chance: float = 0.2
@export var luck_to_full: float = 0.0
@export var max_proc_chance: float = 1.0

func create_runtime(player: Player) -> ReactiveEffectInstance:
	var runtime := GainDropsOnEnemyHitRuntime.new()
	runtime.configure(player, drops_per_hit, infected_bonus, proc_chance, luck_to_full, max_proc_chance)
	return runtime