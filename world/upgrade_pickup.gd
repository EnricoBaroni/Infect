extends Area2D

enum UpgradeType {
	DAMAGE,
	HEALTH,
	SPEED,
	FIRE_RATE,
	RANGE
}

@export var upgrade_type := UpgradeType.DAMAGE

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	update_sprite()

func update_sprite() -> void:
	match upgrade_type:
		UpgradeType.DAMAGE:
			$Sprite2D.frame = 0

		UpgradeType.HEALTH:
			$Sprite2D.frame = 1

		UpgradeType.SPEED:
			$Sprite2D.frame = 2

		UpgradeType.FIRE_RATE:
			$Sprite2D.frame = 3

		UpgradeType.RANGE:
			$Sprite2D.frame = 4

func _on_body_entered(body: Node2D) -> void:
	print("UPGRADE TYPE:", upgrade_type)

	if body.name != "Player":
		return

	var stats = body.stats

	match upgrade_type:
		UpgradeType.DAMAGE:
			print("DAMAGE")
			stats.damage += 0.5

		UpgradeType.HEALTH:
			print("HEALTH")
			stats.max_health += 1
			stats.health += 1

		UpgradeType.SPEED:
			print("SPEED")
			stats.move_speed += 10

		UpgradeType.FIRE_RATE:
			print("FIRE RATE")
			stats.fire_rate = max(0.1, stats.fire_rate - 0.05)

		UpgradeType.RANGE:
			print("RANGE")
			stats.range += 25

	queue_free()
