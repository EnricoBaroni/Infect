extends Node2D
class_name Door

enum ConnectionRole {
	NONE,
	FORWARD,
	BACKWARD
}

@onready var transition_area: Area2D = $TransitionArea
@onready var marker_2d: Marker2D = $Marker2D
@onready var blocker_shape: CollisionPolygon2D = $BlockerBody/CollisionPolygon2D
@export var tp_position: String
@export var enabled: bool = false
@export var connection_role: ConnectionRole = ConnectionRole.NONE

func _ready() -> void:
	if blocker_shape:
		blocker_shape.disabled = enabled

func _on_transition_area_body_entered(body: Node2D) -> void:
	if enabled == false: return
	if Global.recently_moved:
		await get_tree().create_timer(0.3).timeout

		if body not in transition_area.get_overlapping_bodies():
			return
	if not tp_position:
		return
	var destination_room := get_tree().current_scene.get_node_or_null(tp_position) as Room
	if destination_room == null:
		return
	move_body_to(body, marker_2d.global_position)
	var dest_marker := destination_room.get_node_or_null("Marker2D") as Marker2D
	if dest_marker != null:
		move_camera_to(dest_marker.global_position)

	var current_room := get_parent() as Room
	if current_room == null:
		return
	current_room.deactivate()
	destination_room.activate()
	_start_move_cooldown()

func has_destination() -> bool:
	return tp_position != ""

func move_body_to(body: Node2D, pos:Vector2):
	body.global_position = pos

func move_camera_to(pos: Vector2):
	var camera = get_tree().current_scene.get_node("Camera2D")
	if camera:
		var tween := get_tree().create_tween()
		tween.tween_property(camera, "position", pos, 0.3).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)
	else:
		push_warning("Door: Camera2D not found in current scene.")
func _start_move_cooldown():
	Global.recently_moved = true
	await get_tree().create_timer(0.3).timeout
	Global.recently_moved = false

func open():
	enabled = true
	modulate = Color.WHITE
	if blocker_shape:
		blocker_shape.disabled = true

func close():
	enabled = false
	modulate = Color.BLACK
	if blocker_shape:
		blocker_shape.disabled = false
