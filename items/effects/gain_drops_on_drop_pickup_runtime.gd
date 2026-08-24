extends ReactiveEffectInstance
class_name GainDropsOnDropPickupRuntime

var _player: Player
var _bonus_drops: int = 1
var _proc_chance: float = 0.5
var _luck_to_full: float = 0.0
var _max_proc_chance: float = 1.0

func configure(player: Player, bonus_drops: int, proc_chance: float, luck_to_full: float, max_proc_chance: float) -> void:
	_player = player
	_bonus_drops = max(0, bonus_drops)
	_proc_chance = clampf(proc_chance, 0.0, 1.0)
	_luck_to_full = max(0.0, luck_to_full)
	_max_proc_chance = clampf(max_proc_chance, 0.0, 1.0)

func activate() -> void:
	if not EventBus.drop_collected.is_connected(_on_drop_collected):
		EventBus.drop_collected.connect(_on_drop_collected)

func deactivate() -> void:
	if EventBus.drop_collected.is_connected(_on_drop_collected):
		EventBus.drop_collected.disconnect(_on_drop_collected)

func _on_drop_collected(payload: Dictionary) -> void:
	if _player == null or not is_instance_valid(_player):
		return
	if payload.get("player") != _player:
		return
	if not evaluate_proc(_proc_chance, _player, _luck_to_full, _max_proc_chance):
		return

	Global.drops += _bonus_drops