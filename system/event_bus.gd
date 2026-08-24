extends Node
class_name EventBusNode

signal player_damaged(payload: Dictionary)
signal player_damage_preprocess(payload: Dictionary)
signal enemy_killed(payload: Dictionary)
signal enemy_died(payload: Dictionary)
signal enemy_hit(payload: Dictionary)
signal projectile_hit(payload: Dictionary)
signal room_entered(payload: Dictionary)
signal room_exited(payload: Dictionary)
signal room_cleared(payload: Dictionary)
signal projectile_spawned(payload: Dictionary)
signal projectile_destroyed(payload: Dictionary)
signal item_collected(payload: Dictionary)
signal enemy_spawned(payload: Dictionary)
signal boss_killed(payload: Dictionary)
signal player_died(payload: Dictionary)

# Infrastructure hooks for room/shop/curse/luck families.
signal shop_opened(payload: Dictionary)
signal shop_purchase(payload: Dictionary)
signal shop_restocked(payload: Dictionary)
signal curse_changed(payload: Dictionary)
signal drop_collected(payload: Dictionary)

func emit_player_damaged(payload: Dictionary) -> void:
	player_damaged.emit(payload)

func emit_player_damage_preprocess(payload: Dictionary) -> void:
	player_damage_preprocess.emit(payload)

func emit_enemy_killed(payload: Dictionary) -> void:
	enemy_killed.emit(payload)
	enemy_died.emit(payload)

func emit_enemy_hit(payload: Dictionary) -> void:
	enemy_hit.emit(payload)

func emit_projectile_hit(payload: Dictionary) -> void:
	projectile_hit.emit(payload)

func emit_room_entered(payload: Dictionary) -> void:
	room_entered.emit(payload)

func emit_room_exited(payload: Dictionary) -> void:
	room_exited.emit(payload)

func emit_room_cleared(payload: Dictionary) -> void:
	room_cleared.emit(payload)

func emit_projectile_spawned(payload: Dictionary) -> void:
	projectile_spawned.emit(payload)

func emit_projectile_destroyed(payload: Dictionary) -> void:
	projectile_destroyed.emit(payload)

func emit_item_collected(payload: Dictionary) -> void:
	item_collected.emit(payload)

func emit_enemy_spawned(payload: Dictionary) -> void:
	enemy_spawned.emit(payload)

func emit_boss_killed(payload: Dictionary) -> void:
	boss_killed.emit(payload)

func emit_player_died(payload: Dictionary) -> void:
	player_died.emit(payload)

func emit_shop_opened(payload: Dictionary) -> void:
	shop_opened.emit(payload)

func emit_shop_purchase(payload: Dictionary) -> void:
	shop_purchase.emit(payload)

func emit_shop_restocked(payload: Dictionary) -> void:
	shop_restocked.emit(payload)

func emit_curse_changed(payload: Dictionary) -> void:
	curse_changed.emit(payload)

func emit_drop_collected(payload: Dictionary) -> void:
	drop_collected.emit(payload)

func evaluate_luck_proc(base_chance: float, luck: float, luck_to_full: float = 10.0, max_chance: float = 1.0) -> float:
	if luck_to_full <= 0.0:
		return clampf(base_chance, 0.0, max_chance)
	var luck_ratio := clampf(luck / luck_to_full, 0.0, 1.0)
	var proc_chance := lerpf(base_chance, max_chance, luck_ratio)
	return clampf(proc_chance, 0.0, max_chance)
