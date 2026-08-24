extends Node
class_name StatEvaluationSystem

@export var base_stats: Stats

@export var current_stats: Stats

@onready var inventory: InventorySystem = $"../InventorySystem"

var _initialized := false
var _post_recalculate_appliers: Array[Callable] = []

signal stats_recalculated

func _ready() -> void:
	if base_stats != null and current_stats != null:
		recalculate()

func register_post_recalculate_applier(applier: Callable) -> void:
	if not _post_recalculate_appliers.has(applier):
		_post_recalculate_appliers.append(applier)

func unregister_post_recalculate_applier(applier: Callable) -> void:
	_post_recalculate_appliers.erase(applier)

func recalculate() -> void:
	if base_stats == null or current_stats == null:
		return

	var previous_health := current_stats.health

	_reset_stats_from_base()
	_apply_passive_item_effects()
	_apply_post_recalculate_appliers()
	_restore_runtime_health(previous_health)
	stats_recalculated.emit()

func _apply_post_recalculate_appliers() -> void:
	for applier in _post_recalculate_appliers:
		if applier.is_valid():
			applier.call(current_stats)


func _reset_stats_from_base() -> void:
	current_stats.max_health = base_stats.max_health
	current_stats.move_speed = base_stats.move_speed
	current_stats.damage = base_stats.damage
	current_stats.fire_rate = base_stats.fire_rate
	current_stats.bullet_speed = base_stats.bullet_speed
	current_stats.range = base_stats.range
	current_stats.luck = base_stats.luck

func _apply_passive_item_effects() -> void:
	if inventory == null:
		return

	for item in inventory.passive_items:
		if item == null:
			continue
		for effect in item.effects:
			if effect == null:
				continue
			effect.apply_to_stats(current_stats)

func _restore_runtime_health(previous_health: float) -> void:
	if not _initialized:
		current_stats.health = min(base_stats.health, current_stats.max_health)
		_initialized = true
		return

	current_stats.health = clamp(previous_health, 0.0, current_stats.max_health)
