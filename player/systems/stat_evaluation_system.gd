extends Node
class_name StatEvaluationSystem

@export var base_stats: Stats

@export var current_stats: Stats

@onready var inventory: InventorySystem = $"../InventorySystem"

func _ready() -> void:
	if base_stats != null and current_stats != null:
		recalculate()

func recalculate() -> void:
	if base_stats == null or current_stats == null:
		return

	current_stats.health = base_stats.health
	current_stats.max_health = base_stats.max_health
	current_stats.move_speed = base_stats.move_speed
	current_stats.damage = base_stats.damage
	current_stats.fire_rate = base_stats.fire_rate
	current_stats.range = base_stats.range
	current_stats.health = min(current_stats.health, current_stats.max_health)

	if inventory == null:
		return

	for item in inventory.passive_items:
		if item == null:
			continue
		for effect in item.effects:
			if effect == null:
				continue
			effect.apply_to_stats(current_stats)
