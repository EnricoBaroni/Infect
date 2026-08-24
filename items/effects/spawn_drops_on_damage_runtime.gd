extends ReactiveEffectInstance
class_name SpawnDropsOnDamageRuntime

var _player: Player
var _drops_on_damage: int = 1
var _proc_chance: float = 1.0
var _luck_to_full: float = 0.0
var _max_proc_chance: float = 1.0

func configure(player: Player, drops_on_damage: int, proc_chance: float, luck_to_full: float, max_proc_chance: float) -> void:
	_player = player
	_drops_on_damage = max(0, drops_on_damage)
	_proc_chance = clampf(proc_chance, 0.0, 1.0)
	_luck_to_full = max(0.0, luck_to_full)
	_max_proc_chance = clampf(max_proc_chance, 0.0, 1.0)

func activate() -> void:
	if not EventBus.player_damaged.is_connected(_on_player_damaged):
		EventBus.player_damaged.connect(_on_player_damaged)

func deactivate() -> void:
	if EventBus.player_damaged.is_connected(_on_player_damaged):
		EventBus.player_damaged.disconnect(_on_player_damaged)

func _on_player_damaged(payload: Dictionary) -> void:
	if _player == null or not is_instance_valid(_player):
		return
	if payload.get("player") != _player:
		return
	if not evaluate_proc(_proc_chance, _player, _luck_to_full, _max_proc_chance):
		return

	Global.drops += _drops_on_damage
