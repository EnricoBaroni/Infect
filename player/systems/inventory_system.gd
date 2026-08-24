extends Node
class_name InventorySystem

signal passive_item_added(item: ItemData)
signal passive_item_removed(item: ItemData)

var passive_items: Array[ItemData] = []

var active_item: ItemData

var trinkets: Array[ItemData] = []

@onready var stat_evaluation: StatEvaluationSystem = $"../StatEvaluationSystem"

func add_passive_item(item: ItemData) -> void:
	if item == null:
		return

	passive_items.append(item)
	passive_item_added.emit(item)
	if stat_evaluation:
		stat_evaluation.recalculate()

func remove_passive_item(item: ItemData) -> void:
	if item == null:
		return

	var had_item := passive_items.has(item)
	if not had_item:
		return

	passive_items.erase(item)
	passive_item_removed.emit(item)
	if stat_evaluation:
		stat_evaluation.recalculate()

func has_passive_item(item: ItemData) -> bool:
	if item == null:
		return false

	return passive_items.has(item)

func get_last_passive_item() -> ItemData:
	if passive_items.is_empty():
		return null
	return passive_items[-1]
