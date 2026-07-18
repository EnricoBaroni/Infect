extends Node
class_name EffectRuntimeSystem

@onready var inventory: InventorySystem = $"../InventorySystem"

var _active_instances_by_item: Dictionary = {}

func _ready() -> void:
	if inventory == null:
		return

	inventory.passive_item_added.connect(_on_passive_item_added)
	inventory.passive_item_removed.connect(_on_passive_item_removed)

	for item in inventory.passive_items:
		_register_item(item)

func _exit_tree() -> void:
	if inventory != null:
		if inventory.passive_item_added.is_connected(_on_passive_item_added):
			inventory.passive_item_added.disconnect(_on_passive_item_added)
		if inventory.passive_item_removed.is_connected(_on_passive_item_removed):
			inventory.passive_item_removed.disconnect(_on_passive_item_removed)

	for item: ItemData in _active_instances_by_item.keys():
		var instances: Array[ReactiveEffectInstance] = _active_instances_by_item[item]
		for instance in instances:
			if instance == null:
				continue
			instance.deactivate()

	_active_instances_by_item.clear()

func _on_passive_item_added(item: ItemData) -> void:
	_register_item(item)

func _on_passive_item_removed(item: ItemData) -> void:
	_unregister_item(item)

func _register_item(item: ItemData) -> void:
	if item == null:
		return

	var instances: Array[ReactiveEffectInstance] = []
	for effect in item.effects:
		if effect == null:
			continue
		if effect is not ReactiveEffectData:
			continue
		var owner_player := get_parent() as Player
		if owner_player == null:
			continue

		var reactive_effect: ReactiveEffectData = effect as ReactiveEffectData
		var runtime_instance: ReactiveEffectInstance = reactive_effect.create_runtime(owner_player)
		if runtime_instance == null:
			continue

		runtime_instance.activate()
		instances.append(runtime_instance)

	if not instances.is_empty():
		_active_instances_by_item[item] = instances

func _unregister_item(item: ItemData) -> void:
	if item == null:
		return
	if not _active_instances_by_item.has(item):
		return

	var instances: Array[ReactiveEffectInstance] = _active_instances_by_item[item]
	for instance in instances:
		if instance == null:
			continue
		instance.deactivate()

	_active_instances_by_item.erase(item)
