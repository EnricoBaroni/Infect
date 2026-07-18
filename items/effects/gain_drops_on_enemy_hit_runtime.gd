extends ReactiveEffectInstance
class_name GainDropsOnEnemyHitRuntime

var _player: Player
var _drops_per_hit: int = 1
var _infected_bonus: int = 0
var _proc_chance: float = 0.2
var _luck_to_full: float = 0.0
var _max_proc_chance: float = 1.0

func configure(player: Player, drops_per_hit: int, infected_bonus: int, proc_chance: float, luck_to_full: float, max_proc_chance: float) -> void:
	_player = player
	_drops_per_hit = max(0, drops_per_hit)
	_infected_bonus = max(0, infected_bonus)
	_proc_chance = clampf(proc_chance, 0.0, 1.0)
	_luck_to_full = max(0.0, luck_to_full)
	_max_proc_chance = clampf(max_proc_chance, 0.0, 1.0)

func activate() -> void:
	if not EventBus.enemy_hit.is_connected(_on_enemy_hit):
		EventBus.enemy_hit.connect(_on_enemy_hit)

func deactivate() -> void:
	if EventBus.enemy_hit.is_connected(_on_enemy_hit):
		EventBus.enemy_hit.disconnect(_on_enemy_hit)

func _on_enemy_hit(payload: Dictionary) -> void:
	if _player == null or not is_instance_valid(_player):
		return
	var proc := _proc_chance
	if _luck_to_full > 0.0 and _player.stats != null:
		proc = EventBus.evaluate_luck_proc(proc, _player.stats.luck, _luck_to_full, _max_proc_chance)
	if randf() > proc:
		return

	var payout := _drops_per_hit
	if payload.get("infected", false):
		payout += _infected_bonus
	Global.drops += max(0, payout)