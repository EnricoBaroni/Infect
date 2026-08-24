extends ReactiveEffectInstance
class_name GainDropsOnRoomClearRuntime

var _player: Player
var _flat_drops: int = 1
var _bonus_if_combat_room: int = 0
var _proc_chance: float = 1.0
var _luck_to_full: float = 0.0
var _max_proc_chance: float = 1.0

func configure(player: Player, flat_drops: int, bonus_if_combat_room: int, proc_chance: float, luck_to_full: float, max_proc_chance: float) -> void:
	_player = player
	_flat_drops = max(0, flat_drops)
	_bonus_if_combat_room = max(0, bonus_if_combat_room)
	_proc_chance = clampf(proc_chance, 0.0, 1.0)
	_luck_to_full = maxf(0.0, luck_to_full)
	_max_proc_chance = clampf(max_proc_chance, 0.0, 1.0)

func activate() -> void:
	if not EventBus.room_cleared.is_connected(_on_room_cleared):
		EventBus.room_cleared.connect(_on_room_cleared)

func deactivate() -> void:
	if EventBus.room_cleared.is_connected(_on_room_cleared):
		EventBus.room_cleared.disconnect(_on_room_cleared)

func _on_room_cleared(payload: Dictionary) -> void:
	if _player == null or not is_instance_valid(_player):
		return

	if not evaluate_proc(_proc_chance, _player, _luck_to_full, _max_proc_chance):
		return

	var payout := _flat_drops
	if bool(payload.get("combat_room", true)):
		payout += _bonus_if_combat_room
	Global.drops += max(0, payout)