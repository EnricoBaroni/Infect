extends ReactiveEffectData
class_name MapRevealEffect

@export var reveal_map: bool = false
@export var reveal_room_types: bool = false
@export var reveal_secret_walls: bool = false
@export var reveal_secret_rooms: bool = false
@export var reveal_treasure_rooms: bool = false
@export var reveal_boss_rooms: bool = false

func create_runtime(_player: Player) -> ReactiveEffectInstance:
	var runtime := MapRevealRuntime.new()
	runtime.configure(
		reveal_map,
		reveal_room_types,
		reveal_secret_walls,
		reveal_secret_rooms,
		reveal_treasure_rooms,
		reveal_boss_rooms
	)
	return runtime