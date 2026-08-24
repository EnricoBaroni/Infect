extends Area2D
class_name FloorTransition

var _world_dungeon: Node = null
var _used := false

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func set_world_dungeon(world_dungeon: Node) -> void:
	_world_dungeon = world_dungeon

func _on_body_entered(body: Node2D) -> void:
	if _used:
		return
	if not body.is_in_group("player"):
		return
	var collision_shape := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if collision_shape != null:
		collision_shape.set_deferred("disabled", true)

	if _world_dungeon == null:
		var parent_room := get_parent()
		if parent_room != null:
			var maybe_world := parent_room.get_parent()
			if maybe_world != null and maybe_world.has_method("advance_to_next_floor"):
				_world_dungeon = maybe_world

	if _world_dungeon != null and _world_dungeon.has_method("advance_to_next_floor"):
		_world_dungeon.advance_to_next_floor()

	queue_free()
