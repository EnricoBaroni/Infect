extends Node2D

@onready var area_2d: Area2D = $Area2D
@onready var marker_2d: Marker2D = $Marker2D
@export var tp_position: String
@export var enabled: bool = false

func _on_area_2d_body_entered(body: Node2D) -> void:
	if enabled == false: return
	if Global.recently_moved:
		await get_tree().create_timer(0.3).timeout

		if body not in area_2d.get_overlapping_bodies():
			return
	if not tp_position:
		return
	move_body_to(body, marker_2d.global_position)
	move_camera_to(get_tree().current_scene.get_node(tp_position).get_node("Marker2D").global_position)
	
	var current_room = get_parent()
	current_room.deactivate()

	var destination_room = get_tree().current_scene.get_node(tp_position)
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
		print("❌ Cámara no encontrada.")

func _start_move_cooldown():
	Global.recently_moved = true
	await get_tree().create_timer(0.3).timeout
	Global.recently_moved = false

func open():
	enabled = true
	modulate = Color.WHITE

func close():
	enabled = false
	modulate = Color.BLACK
