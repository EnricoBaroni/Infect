extends ReactiveEffectInstance
class_name GainDropsOnKillRuntime

var _player: Player
var _drops_per_kill: int = 1
var _infected_bonus: int = 0
var _proc_chance: float = 1.0
var _luck_to_full: float = 0.0
var _max_proc_chance: float = 1.0

func configure(player: Player, drops_per_kill: int, infected_bonus: int, proc_chance: float, luck_to_full: float, max_proc_chance: float) -> void:
	_player = player
	_drops_per_kill = max(0, drops_per_kill)
	_infected_bonus = max(0, infected_bonus)
	_proc_chance = clampf(proc_chance, 0.0, 1.0)
	_luck_to_full = max(0.0, luck_to_full)
	_max_proc_chance = clampf(max_proc_chance, 0.0, 1.0)

func activate() -> void:
	if not EventBus.enemy_killed.is_connected(_on_enemy_killed):
		EventBus.enemy_killed.connect(_on_enemy_killed)

func deactivate() -> void:
	if EventBus.enemy_killed.is_connected(_on_enemy_killed):
		EventBus.enemy_killed.disconnect(_on_enemy_killed)

func _on_enemy_killed(payload: Dictionary) -> void:
	if _player == null or not is_instance_valid(_player):
		return
	if not evaluate_proc(_proc_chance, _player, _luck_to_full, _max_proc_chance):
		return

	var payout := _drops_per_kill
	if payload.get("infected", false):
		payout += _infected_bonus

	Global.drops += max(0, payout)
