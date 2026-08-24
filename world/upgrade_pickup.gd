extends Area2D

enum UpgradeType {
	DAMAGE,
	HEALTH,
	SPEED,
	FIRE_RATE,
	RANGE
}

@export var upgrade_type := UpgradeType.DAMAGE
@export var item_data: ItemData

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	update_sprite()

func _get_item_id() -> String:
	if item_data and item_data.id != "":
		return item_data.id

	match upgrade_type:
		UpgradeType.DAMAGE:
			return "damage"
		UpgradeType.HEALTH:
			return "health"
		UpgradeType.SPEED:
			return "speed"
		UpgradeType.FIRE_RATE:
			return "fire_rate"
		UpgradeType.RANGE:
			return "range"

	return "damage"

func update_sprite() -> void:
	match _get_item_id():
		"damage":
			$Sprite2D.frame = 0
		"health":
			$Sprite2D.frame = 1
		"speed":
			$Sprite2D.frame = 2
		"fire_rate":
			$Sprite2D.frame = 3
		"range":
			$Sprite2D.frame = 4
		_:
			$Sprite2D.frame = 0

func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return

	if not item_data:
		queue_free()
		return

	EventBus.emit_item_collected({
		"item": item_data,
		"item_id": item_data.id,
		"item_name": item_data.name,
		"position": global_position
	})

	body.inventory.add_passive_item(item_data)
	queue_free()
