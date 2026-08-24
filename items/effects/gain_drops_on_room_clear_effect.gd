extends ReactiveEffectData
class_name GainDropsOnRoomClearEffect

@export var flat_drops: int = 1
@export var bonus_if_combat_room: int = 0
@export var proc_chance: float = 1.0
@export var luck_to_full: float = 0.0
@export var max_proc_chance: float = 1.0

func create_runtime(player: Player) -> ReactiveEffectInstance:
	var runtime := GainDropsOnRoomClearRuntime.new()
	runtime.configure(player, flat_drops, bonus_if_combat_room, proc_chance, luck_to_full, max_proc_chance)
	return runtime