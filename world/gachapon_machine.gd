extends Area2D

@export var cost := 1
@export var pool_tag: String = "gacha"  # Filter items by this pool tag. Set to "infection_gacha" for the Infection Gacha machine.
const UPGRADE_PICKUP = preload("uid://tq8rii0lj6x1")
const PASSIVE_ITEMS_PATH := "res://items/data"

var passive_item_pool: Array[ItemData] = []
var player_inside := false

@onready var press_e: Label = $PressE

func _ready() -> void:
	_refresh_passive_item_pool()
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	press_e.visible = false
	_update_prompt_text()
	EventBus.emit_shop_restocked({
		"shop_node": self,
		"shop_name": name,
		"pool_size": passive_item_pool.size()
	})

func _process(_delta: float) -> void:
	if not player_inside:
		return
	_update_prompt_text()
	if Input.is_action_just_pressed("interact"):
		use_machine()

func use_machine() -> void:
	var effective_cost := Global.get_effective_shop_cost(cost)
	if Global.drops < effective_cost:
		return
	if passive_item_pool.is_empty():
		return

	Global.drops -= effective_cost
	var pickup = UPGRADE_PICKUP.instantiate()
	var item_data := _take_random_item_data().duplicate()
	pickup.item_data = item_data
	pickup.upgrade_type = 0
	get_tree().current_scene.add_child(pickup)
	pickup.global_position = global_position + Vector2(48, 0)
	_update_prompt_text()
	EventBus.emit_shop_purchase({
		"shop_node": self,
		"shop_name": name,
		"cost": effective_cost,
		"remaining_drops": Global.drops,
		"item_id": item_data.id,
		"item_name": item_data.name
	})

func _take_random_item_data() -> ItemData:
	var index := randi() % passive_item_pool.size()
	var selected: ItemData = passive_item_pool[index]
	if not Global.has_shop_infinite_restock():
		passive_item_pool.remove_at(index)
	return selected

func _refresh_passive_item_pool() -> void:
	passive_item_pool.clear()

	var dir := DirAccess.open(PASSIVE_ITEMS_PATH)
	if dir == null:
		return

	var file_names: PackedStringArray = []
	dir.list_dir_begin()
	while true:
		var file_name := dir.get_next()
		if file_name == "":
			break
		if dir.current_is_dir():
			continue
		if file_name.get_extension() != "tres":
			continue
		file_names.append(file_name)
	dir.list_dir_end()

	file_names.sort()

	for file_name in file_names:
		var path := PASSIVE_ITEMS_PATH + "/" + file_name
		var loaded_resource := load(path)
		if loaded_resource is ItemData:
			var item := loaded_resource as ItemData
			if item.pool_tags.has(pool_tag):
				passive_item_pool.append(item)

func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	player_inside = true
	press_e.visible = true
	_update_prompt_text()
	EventBus.emit_shop_opened({
		"shop_node": self,
		"shop_name": name,
		"cost": Global.get_effective_shop_cost(cost),
		"pool_size": passive_item_pool.size()
	})

func _on_body_exited(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	player_inside = false
	press_e.visible = false

func _update_prompt_text() -> void:
	press_e.text = "Press E\n" + str(Global.get_effective_shop_cost(cost)) + " 🧪"
