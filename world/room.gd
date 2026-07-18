extends Node2D
class_name Room

@onready var enemies = $Enemies
@onready var doors: Array[Door] = [
	$Door,
	$Door2,
	$Door3,
	$Door4
]

var active := false
var enemy_templates: Array[Dictionary] = []
@export var combat_room := true
var _room_cleared_emitted := false

func _ready() -> void:
	for enemy: Node in enemies.get_children():
		if enemy.scene_file_path == "":
			continue
		var enemy_scene := load(enemy.scene_file_path) as PackedScene
		if enemy_scene == null:
			continue
		var enemy_position: Vector2 = Vector2.ZERO
		if enemy is Node2D:
			enemy_position = (enemy as Node2D).position
		var enemy_name: String = enemy.name
		enemy_templates.append({
			"scene": enemy_scene,
			"position": enemy_position,
			"name": enemy_name
		})

func _process(_delta: float) -> void:
	if not combat_room:
		open_doors()
		return
	if has_enemies():
		_room_cleared_emitted = false
		close_doors()
	else:
		if active and not _room_cleared_emitted:
			_room_cleared_emitted = true
			EventBus.emit_room_cleared({
				"room": self,
				"room_name": name,
				"combat_room": combat_room
			})
		open_doors()

func activate() -> void:
	active = true
	EventBus.emit_room_entered({
		"room": self,
		"room_name": name,
		"combat_room": combat_room
	})

func deactivate() -> void:
	if active:
		EventBus.emit_room_exited({
			"room": self,
			"room_name": name,
			"combat_room": combat_room
		})
	active = false

func open_doors() -> void:
	for door: Door in doors:
		if door.has_destination():
			door.open()
		else:
			door.close()

func close_doors() -> void:
	for door: Door in doors:
		door.close()

func has_enemies() -> bool:
	return enemies.get_child_count() > 0

func respawn_enemies() -> void:
	_room_cleared_emitted = false
	for enemy: Node in enemies.get_children():
		enemy.queue_free()
		
	for template: Dictionary in enemy_templates:
		var enemy_scene := template.get("scene", null) as PackedScene
		if enemy_scene == null:
			continue
		var template_position: Vector2 = template.get("position", Vector2.ZERO)
		var template_name: String = str(template.get("name", "Enemy"))
		var enemy: Node = enemy_scene.instantiate()
		
		var health_multiplier = 1.0 + (Global.difficulty_level - 1) * 0.25
		var speed_multiplier = 1.0 + (Global.difficulty_level - 1) * 0.05

		enemy.set("health_multiplier", health_multiplier)
		enemy.set("speed_multiplier", speed_multiplier)
		
		if enemy is Node2D:
			(enemy as Node2D).position = template_position
		enemy.name = template_name
		
		enemies.add_child(enemy)
