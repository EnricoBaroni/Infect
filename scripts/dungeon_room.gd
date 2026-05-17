extends Node2D

func _ready() -> void:
	$PlayerDetector.body_entered.connect(_on_player_detector_body_entered)

func _on_player_detector_body_entered(body: Node2D) -> void:
	Events.room_entered.emit(self)
