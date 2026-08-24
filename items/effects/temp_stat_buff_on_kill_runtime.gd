extends ReactiveEffectInstance
class_name TempStatBuffOnKillRuntime

var _player: Player
var _damage_bonus: float = 0.0
var _speed_bonus: float = 0.0
var _fire_rate_reduction: float = 0.0
var _buff_duration: float = 3.0
var _only_infected: bool = false

var _buff_active := false
var _buff_timer: SceneTreeTimer = null
var _stat_eval: StatEvaluationSystem = null

func configure(
	player: Player,
	damage_bonus: float,
	speed_bonus: float,
	fire_rate_reduction: float,
	buff_duration: float,
	only_infected_kills: bool
) -> void:
	_player = player
	_damage_bonus = maxf(0.0, damage_bonus)
	_speed_bonus = maxf(0.0, speed_bonus)
	_fire_rate_reduction = maxf(0.0, fire_rate_reduction)
	_buff_duration = maxf(0.1, buff_duration)
	_only_infected = only_infected_kills

func activate() -> void:
	if not EventBus.enemy_killed.is_connected(_on_enemy_killed):
		EventBus.enemy_killed.connect(_on_enemy_killed)
	_stat_eval = _find_stat_eval()
	if _stat_eval != null:
		_stat_eval.register_post_recalculate_applier(_apply_buff_bonus)

func deactivate() -> void:
	if EventBus.enemy_killed.is_connected(_on_enemy_killed):
		EventBus.enemy_killed.disconnect(_on_enemy_killed)
	if _stat_eval != null:
		_stat_eval.unregister_post_recalculate_applier(_apply_buff_bonus)
	_buff_active = false

func _find_stat_eval() -> StatEvaluationSystem:
	if _player == null or not is_instance_valid(_player):
		return null
	return _player.get_node_or_null("StatEvaluationSystem") as StatEvaluationSystem

func _on_enemy_killed(payload: Dictionary) -> void:
	if _player == null or not is_instance_valid(_player):
		return
	var was_infected: bool = payload.get("infected", false)
	if _only_infected and not was_infected:
		return
	_refresh_buff()

func _refresh_buff() -> void:
	_buff_active = true
	if _player == null or not is_instance_valid(_player):
		return
	if _stat_eval != null:
		_stat_eval.recalculate()
	_buff_timer = _player.get_tree().create_timer(_buff_duration)
	_buff_timer.timeout.connect(_on_buff_expired, CONNECT_ONE_SHOT)

func _on_buff_expired() -> void:
	_buff_active = false
	if _stat_eval != null:
		_stat_eval.recalculate()

func _apply_buff_bonus(stats: Stats) -> void:
	if not _buff_active:
		return
	stats.damage += _damage_bonus
	stats.move_speed += _speed_bonus
	if _fire_rate_reduction > 0.0:
		stats.fire_rate = max(0.05, stats.fire_rate - _fire_rate_reduction)
