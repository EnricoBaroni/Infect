extends Area2D

@onready var marker_2d: Marker2D = $Marker2D


func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	body.global_position = marker_2d.global_position
	Events.room_changed.emit(marker_2d.global_position)
