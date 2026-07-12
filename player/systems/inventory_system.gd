extends Node
class_name InventorySystem

var passive_items: Array[ItemData] = []

var active_item: ItemData

var trinkets: Array[ItemData] = []

@onready var stat_evaluation: StatEvaluationSystem = $"../StatEvaluationSystem"

func add_passive_item(item: ItemData) -> void:
	passive_items.append(item)
	if stat_evaluation:
		stat_evaluation.recalculate()

func remove_passive_item(item: ItemData) -> void:
	passive_items.erase(item)
	if stat_evaluation:
		stat_evaluation.recalculate()

func has_passive_item(item: ItemData) -> bool:
	return passive_items.has(item)

func get_last_passive_item() -> ItemData:
	if passive_items.is_empty():
		return null
	return passive_items[-1]
