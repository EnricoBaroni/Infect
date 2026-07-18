extends ReactiveEffectInstance
class_name MapRevealRuntime

var _reveal_map := false
var _reveal_room_types := false
var _reveal_secret_walls := false
var _reveal_secret_rooms := false
var _reveal_treasure_rooms := false
var _reveal_boss_rooms := false

func configure(
	reveal_map: bool,
	reveal_room_types: bool,
	reveal_secret_walls: bool,
	reveal_secret_rooms: bool,
	reveal_treasure_rooms: bool,
	reveal_boss_rooms: bool
) -> void:
	_reveal_map = reveal_map
	_reveal_room_types = reveal_room_types
	_reveal_secret_walls = reveal_secret_walls
	_reveal_secret_rooms = reveal_secret_rooms
	_reveal_treasure_rooms = reveal_treasure_rooms
	_reveal_boss_rooms = reveal_boss_rooms

func activate() -> void:
	Global.adjust_map_intel(
		1 if _reveal_map else 0,
		1 if _reveal_room_types else 0,
		1 if _reveal_secret_walls else 0,
		1 if _reveal_secret_rooms else 0,
		1 if _reveal_treasure_rooms else 0,
		1 if _reveal_boss_rooms else 0
	)

func deactivate() -> void:
	Global.adjust_map_intel(
		-1 if _reveal_map else 0,
		-1 if _reveal_room_types else 0,
		-1 if _reveal_secret_walls else 0,
		-1 if _reveal_secret_rooms else 0,
		-1 if _reveal_treasure_rooms else 0,
		-1 if _reveal_boss_rooms else 0
	)