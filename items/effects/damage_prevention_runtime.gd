extends ReactiveEffectInstance
class_name DamagePreventionRuntime

var _player: Player
var _charges_per_room := 0
var _charges_remaining := 0
var _reset_on_room_enter := false
var _full_block := true
var _reduction_multiplier := 0.0
var _flat_reduction := 0.0
var _proc_chance := 1.0
var _proc_luck_to_full := 0.0
var _proc_max_chance := 1.0
var _only_if_lethal := false

func configure(
	player: Player,
	charges_per_room: int,
	reset_on_room_enter: bool,
	full_block: bool,
	reduction_multiplier: float,
	flat_reduction: float,
	proc_chance: float,
	proc_luck_to_full: float,
	proc_max_chance: float,
	only_if_lethal: bool
) -> void:
	_player = player
	_charges_per_room = max(0, charges_per_room)
	_charges_remaining = _charges_per_room
	_reset_on_room_enter = reset_on_room_enter
	_full_block = full_block
	_reduction_multiplier = clampf(reduction_multiplier, 0.0, 1.0)
	_flat_reduction = maxf(0.0, flat_reduction)
	_proc_chance = clampf(proc_chance, 0.0, 1.0)
	_proc_luck_to_full = maxf(0.0, proc_luck_to_full)
	_proc_max_chance = clampf(proc_max_chance, 0.0, 1.0)
	_only_if_lethal = only_if_lethal

func activate() -> void:
	if not EventBus.player_damage_preprocess.is_connected(_on_player_damage_preprocess):
		EventBus.player_damage_preprocess.connect(_on_player_damage_preprocess)
	if _reset_on_room_enter and not EventBus.room_entered.is_connected(_on_room_entered):
		EventBus.room_entered.connect(_on_room_entered)

func deactivate() -> void:
	if EventBus.player_damage_preprocess.is_connected(_on_player_damage_preprocess):
		EventBus.player_damage_preprocess.disconnect(_on_player_damage_preprocess)
	if EventBus.room_entered.is_connected(_on_room_entered):
		EventBus.room_entered.disconnect(_on_room_entered)

func _on_room_entered(_payload: Dictionary) -> void:
	if _charges_per_room > 0:
		_charges_remaining = _charges_per_room

func _on_player_damage_preprocess(payload: Dictionary) -> void:
	if _player == null or not is_instance_valid(_player):
		return
	if payload.get("player", null) != _player:
		return

	var damage := float(payload.get("damage", 0.0))
	if damage <= 0.0:
		return
	if _only_if_lethal:
		if _player.stats == null:
			return
		if damage < _player.stats.health:
			return

	if _charges_per_room > 0 and _charges_remaining <= 0:
		return

	var final_proc_chance := _proc_chance
	if _proc_luck_to_full > 0.0 and _player.stats != null:
		final_proc_chance = EventBus.evaluate_luck_proc(
			_proc_chance,
			_player.stats.luck,
			_proc_luck_to_full,
			_proc_max_chance
		)
	if randf() > final_proc_chance:
		return

	if _charges_per_room > 0:
		_charges_remaining = max(0, _charges_remaining - 1)

	if _full_block:
		payload["damage"] = 0.0
		return

	var reduced := maxf(0.0, damage * (1.0 - _reduction_multiplier) - _flat_reduction)
	payload["damage"] = reduced