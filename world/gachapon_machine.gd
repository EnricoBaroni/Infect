extends Area2D

@export var cost := 1
const UPGRADE_PICKUP = preload("uid://tq8rii0lj6x1")
const PASSIVE_ITEMS_PATH := "res://items/data"

var passive_item_pool: Array[ItemData] = []
var pending_item: ItemData = null
var player_inside := false

@onready var press_e: Label = $PressE
@onready var item_name: Label = $ItemName
@onready var item_description: RichTextLabel = $ItemDescription
@onready var item_stats: Label = $ItemStats
@onready var color_rect: ColorRect = $ColorRect

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
	item_name.visible = false
	item_description.visible = false
	item_stats.visible = false
	color_rect.visible = false

func _process(_delta: float) -> void:
	if not player_inside:
		return
	_update_prompt_text()
	if pending_item != null:
		if Input.is_action_just_pressed("interact"):
			reroll_pending_item()
			return
		if Input.is_action_just_pressed("interact2"):
			take_pending_item()
			return
	else:
		if Input.is_action_just_pressed("interact"):
			use_machine()

func use_machine() -> void:
	if pending_item != null:
		return
	print("USE MACHINE")
	var effective_cost := Global.get_effective_shop_cost(cost)
	if Global.drops < effective_cost:
		print("NOT ENOUGH DROPS")
		return
	if passive_item_pool.is_empty():
		print("NO ITEMS IN POOL")
		return

	Global.drops -= effective_cost
	var item_data := _take_random_item_data().duplicate()
	pending_item = item_data
	print("Pending item:", pending_item.name)
	item_name.text = pending_item.name
	item_description.text = pending_item.description	
	
	item_stats.text = _build_stats_text(pending_item)
	item_stats.visible = item_stats.text != ""
	await get_tree().process_frame
	var stats_lines := item_stats.text.count("\n") + 1 if item_stats.text != "" else 0
	color_rect.size.y = 70 + (stats_lines * 10)

	item_name.visible = true
	item_description.visible = true
	item_stats.visible = true
	color_rect.visible = true
	_update_prompt_text()
	EventBus.emit_shop_purchase({
		"shop_node": self,
		"shop_name": name,
		"cost": effective_cost,
		"remaining_drops": Global.drops,
		"item_id": pending_item.id,
		"item_name": pending_item.name
	})
	print("PURCHASE")

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
			passive_item_pool.append(loaded_resource)

func _on_body_entered(body: Node2D) -> void:
	if body.name != "Player":
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
	if body.name != "Player":
		return
	player_inside = false
	press_e.visible = false

func _update_prompt_text() -> void:
	if pending_item != null:
		press_e.text = "[Q] Take    [E] Reroll"
	else:
		press_e.text = "Press E\n" + str(Global.get_effective_shop_cost(cost)) + " 🧪"

func take_pending_item() -> void:
	var player := get_tree().get_first_node_in_group("player") as Player
	if player == null:
		return
	EventBus.emit_item_collected({
		"item": pending_item,
		"item_id": pending_item.id,
		"item_name": pending_item.name,
		"position": global_position
	})
	player.inventory.add_passive_item(pending_item)
	pending_item = null
	item_name.visible = false
	item_description.visible = false
	item_stats.visible = false
	color_rect.visible = false
	_update_prompt_text()

func reroll_pending_item() -> void:
	if pending_item == null:
		return

	var effective_cost := Global.get_effective_shop_cost(cost)

	if Global.drops < effective_cost:
		print("NOT ENOUGH DROPS")
		return

	Global.drops -= effective_cost

	if passive_item_pool.is_empty():
		print("NO ITEMS LEFT TO REROLL")
		return

	pending_item = _take_random_item_data().duplicate()

	item_name.text = pending_item.name
	item_description.text = pending_item.description
	item_stats.text = _build_stats_text(pending_item)
	item_stats.visible = item_stats.text != ""

	await get_tree().process_frame
	var stats_lines := item_stats.text.count("\n") + 1 if item_stats.text != "" else 0
	color_rect.size.y = 70 + (stats_lines * 10)
	
	_update_prompt_text()

	EventBus.emit_shop_purchase({
		"shop_node": self,
		"shop_name": name,
		"cost": effective_cost,
		"remaining_drops": Global.drops,
		"item_id": pending_item.id,
		"item_name": pending_item.name
	})
func _build_stats_text(item: ItemData) -> String:
	var lines: Array[String] = []

	for effect in item.effects:
		if effect is DamageUpEffect:
			lines.append("%+.1f Damage" % effect.amount)

		elif effect is HealthUpEffect:
			lines.append("%+.0f Health" % effect.amount)

		elif effect is MoveSpeedUpEffect:
			lines.append("%+.2f Speed" % effect.amount)

		elif effect is BulletSpeedUpEffect:
			lines.append("%+.2f Bullet Speed" % effect.amount)

		elif effect is FireRateUpEffect:
			lines.append("%+.2f Fire Rate" % effect.amount)

		elif effect is RangeUpEffect:
			lines.append("%+.0f Range" % effect.amount)

		elif effect is LuckUpEffect:
			lines.append("%+.0f Luck" % effect.amount)

		elif effect is SplitShotsEffect:
			lines.append("%+d Split Shots" % effect.extra_shots)

		elif effect is ChanceSplitShotsEffect:
			lines.append("%d%% Split Chance" % int(effect.proc_chance * 100.0))

		elif effect is PiercingProjectilesEffect:
			lines.append("%+d Pierce" % effect.extra_pierces)

		elif effect is BouncyProjectilesEffect:
			lines.append("%+d Bounce" % effect.extra_bounces)

		elif effect is HomingProjectilesEffect:
			lines.append("Homing")

		elif effect is ExplosiveProjectilesEffect:
			lines.append("Explosive")

		elif effect is BeamLengthUpEffect:
			lines.append("%+d Beam Segments" % effect.extra_segments)

	return "\n".join(lines)
