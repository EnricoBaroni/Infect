extends ReactiveEffectInstance
class_name StatRampOnDamageRuntime

var _player: Player
var _damage_per_hit: float = 0.0
var _speed_per_hit: float = 0.0
var _fire_rate_reduction_per_hit: float = 0.0
var _max_stacks: int = 8
var _reset_on_room_exit: bool = false
var _current_stacks: int = 0
var _stat_eval: StatEvaluationSystem = null

func configure(
	player: Player,
	damage_per_hit: float,
	speed_per_hit: float,
	fire_rate_reduction_per_hit: float,
	max_stacks: int,
	reset_on_room_exit: bool
) -> void:
	_player = player
	_damage_per_hit = maxf(0.0, damage_per_hit)
	_speed_per_hit = maxf(0.0, speed_per_hit)
	_fire_rate_reduction_per_hit = maxf(0.0, fire_rate_reduction_per_hit)
	_max_stacks = max(1, max_stacks)
	_reset_on_room_exit = reset_on_room_exit

func activate() -> void:
	if not EventBus.player_damaged.is_connected(_on_player_damaged):
		EventBus.player_damaged.connect(_on_player_damaged)
	if _reset_on_room_exit and not EventBus.room_exited.is_connected(_on_room_exited):
		EventBus.room_exited.connect(_on_room_exited)
	_stat_eval = _find_stat_eval()
	if _stat_eval != null:
		_stat_eval.register_post_recalculate_applier(_apply_ramp_bonus)

func deactivate() -> void:
	if EventBus.player_damaged.is_connected(_on_player_damaged):
		EventBus.player_damaged.disconnect(_on_player_damaged)
	if EventBus.room_exited.is_connected(_on_room_exited):
		EventBus.room_exited.disconnect(_on_room_exited)
	if _stat_eval != null:
		_stat_eval.unregister_post_recalculate_applier(_apply_ramp_bonus)
	_current_stacks = 0

func _find_stat_eval() -> StatEvaluationSystem:
	if _player == null or not is_instance_valid(_player):
		return null
	return _player.get_node_or_null("StatEvaluationSystem") as StatEvaluationSystem

func _on_player_damaged(payload: Dictionary) -> void:
	if _player == null or not is_instance_valid(_player):
		return
	if payload.get("player", null) != _player:
		return
	if _current_stacks >= _max_stacks:
		return
	_current_stacks = min(_current_stacks + 1, _max_stacks)
	if _stat_eval != null:
		_stat_eval.recalculate()

func _on_room_exited(_payload: Dictionary) -> void:
	if _current_stacks > 0:
		_current_stacks = 0
		if _stat_eval != null:
			_stat_eval.recalculate()

func _apply_ramp_bonus(stats: Stats) -> void:
	if _current_stacks <= 0:
		return
	stats.damage += _damage_per_hit * float(_current_stacks)
	stats.move_speed += _speed_per_hit * float(_current_stacks)
	if _fire_rate_reduction_per_hit > 0.0:
		stats.fire_rate = max(0.05, stats.fire_rate - _fire_rate_reduction_per_hit * float(_current_stacks))
