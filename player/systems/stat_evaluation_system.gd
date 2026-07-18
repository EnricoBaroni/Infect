extends Node
class_name StatEvaluationSystem

@export var base_stats: Stats

@export var current_stats: Stats

@onready var inventory: InventorySystem = $"../InventorySystem"

var _initialized := false

func _ready() -> void:
	if base_stats != null and current_stats != null:
		recalculate()

func recalculate() -> void:
	if base_stats == null or current_stats == null:
		return

	var previous_health := current_stats.health

	_reset_stats_from_base()
	_apply_passive_item_effects()
	_restore_runtime_health(previous_health)

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
