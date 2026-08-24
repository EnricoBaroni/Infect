extends Area2D

var infected_drop := false

func _ready() -> void:
	body_entered.connect(_on_body_entered)

	$Timer.timeout.connect(queue_free)
	$AnimationPlayer.play("blink")

func setup(is_infected: bool) -> void:
	infected_drop = is_infected

	if infected_drop:
		$Sprite2D.frame = 2
	else:
		$Sprite2D.frame = 0

func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return

	if infected_drop:
		Global.drops += 2
	else:
		Global.drops += 1

	EventBus.emit_drop_collected({
		"drop": self,
		"infected": infected_drop,
		"value": 2 if infected_drop else 1,
		"player": body,
		"position": global_position
	})

	queue_free()
