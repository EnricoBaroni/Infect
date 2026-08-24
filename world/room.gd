extends Node2D
class_name Room

const EnemySpawnSelector = preload("res://world/enemy_spawn_selector.gd")

enum RoomType {
	GACHA,
	COMBAT,
	BOSS
}

@onready var enemies = $Enemies
@onready var doors: Array[Door] = [
	$Door,
	$Door2,
	$Door3,
	$Door4
]
@onready var marker_2d: Marker2D = $Marker2D
@onready var spawn_points_root: Node2D = $SpawnPoints

var active := false
var enemy_templates: Array[Dictionary] = []
@export var combat_room := true
@export var room_type: RoomType = RoomType.COMBAT
@export var enemy_spawn_count := 0
@export var enemy_spawn_min_count := 0
@export var enemy_spawn_max_count := 0
@export var enemy_pool: Array[PackedScene] = []
var _room_cleared_emitted := false
var _spawn_rng := RandomNumberGenerator.new()

func _ready() -> void:
	_spawn_rng.randomize()
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
				"combat_room": combat_room,
				"room_type": room_type
			})
			if is_boss_room():
				var world_dungeon := get_parent()
				if world_dungeon != null and world_dungeon.has_method("notify_boss_room_cleared"):
					world_dungeon.notify_boss_room_cleared(self)
		open_doors()

func activate() -> void:
	active = true
	EventBus.emit_room_entered({
		"room": self,
		"room_name": name,
		"combat_room": combat_room,
		"room_type": room_type
	})

func deactivate() -> void:
	if active:
		EventBus.emit_room_exited({
			"room": self,
			"room_name": name,
			"combat_room": combat_room,
			"room_type": room_type
		})
	active = false

func is_boss_room() -> bool:
	return room_type == RoomType.BOSS

func get_room_center_position() -> Vector2:
	return marker_2d.global_position

func get_door_by_connection_role(role: Door.ConnectionRole) -> Door:
	for door in doors:
		if door.connection_role == role:
			return door
	return null

func get_forward_door() -> Door:
	return get_door_by_connection_role(Door.ConnectionRole.FORWARD)

func get_backward_door() -> Door:
	return get_door_by_connection_role(Door.ConnectionRole.BACKWARD)

func has_spawn_points() -> bool:
	return not get_spawn_point_positions().is_empty()

func get_spawn_point_positions() -> Array[Vector2]:
	var positions: Array[Vector2] = []
	for child in spawn_points_root.get_children():
		if child is Node2D:
			positions.append((child as Node2D).position)
	return positions

func set_enemy_pool(pool: Array[PackedScene]) -> void:
	enemy_pool = pool.duplicate()

func get_generation_rng() -> RandomNumberGenerator:
	var world_owner := get_parent()
	if world_owner != null and world_owner.has_method("get_generation_rng"):
		var shared_rng: RandomNumberGenerator = world_owner.get_generation_rng()
		if shared_rng is RandomNumberGenerator:
			return shared_rng
	return _spawn_rng

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

	if not combat_room:
		return

	if is_boss_room():
		_spawn_from_templates(enemy_templates)
		return

	if enemy_pool.is_empty():
		_spawn_from_templates(enemy_templates)
		return

	var selected_templates := _build_selected_enemy_templates()
	if selected_templates.is_empty():
		push_warning("No tier-eligible enemies found for room '%s' at tier %d" % [name, _resolve_current_spawn_tier()])
		return

	_spawn_from_templates(selected_templates)

func _spawn_from_templates(templates: Array[Dictionary]) -> void:
	for template in templates:
		var enemy_scene := template.get("scene", null) as PackedScene
		if enemy_scene == null:
			continue
		var template_position: Vector2 = template.get("position", Vector2.ZERO)
		var template_name: String = str(template.get("name", "Enemy"))
		var enemy: Node = enemy_scene.instantiate()

		var health_multiplier := 1.0 + (Global.difficulty_level - 1) * 0.25
		var speed_multiplier := 1.0 + (Global.difficulty_level - 1) * 0.05

		enemy.set("health_multiplier", health_multiplier)
		enemy.set("speed_multiplier", speed_multiplier)

		if enemy is Node2D:
			(enemy as Node2D).position = template_position
		enemy.name = template_name

		enemies.add_child(enemy)

func _build_selected_enemy_templates() -> Array[Dictionary]:
	var candidate_scenes: Array[PackedScene] = enemy_pool.duplicate()
	if candidate_scenes.is_empty():
		for template in enemy_templates:
			var template_scene := template.get("scene", null) as PackedScene
			if template_scene != null:
				candidate_scenes.append(template_scene)

	if candidate_scenes.is_empty():
		return []

	var tier := _resolve_current_spawn_tier()

	var spawn_count := _resolve_enemy_spawn_count()

	var selected_scenes := EnemySpawnSelector.select_weighted_scenes_for_tier(
		candidate_scenes,
		tier,
		spawn_count,
		get_generation_rng()
	)

	if selected_scenes.is_empty():
		return []

	var spawn_positions: Array[Vector2] = _build_spawn_positions(spawn_count)
	var selected_templates: Array[Dictionary] = []
	for i in selected_scenes.size():
		var scene: PackedScene = selected_scenes[i]
		var position: Vector2 = spawn_positions[i % spawn_positions.size()]
		selected_templates.append({
			"scene": scene,
			"position": position,
			"name": "Enemy_%d" % i
		})

	return selected_templates

func _resolve_current_spawn_tier() -> int:
	var world_dungeon := get_parent()
	if world_dungeon != null and world_dungeon.has_method("get_current_spawn_tier"):
		return int(world_dungeon.get_current_spawn_tier())
	return 1

func _resolve_enemy_spawn_count() -> int:
	if enemy_spawn_min_count > 0 and enemy_spawn_max_count >= enemy_spawn_min_count:
		return get_generation_rng().randi_range(enemy_spawn_min_count, enemy_spawn_max_count)

	if enemy_spawn_count > 0:
		return enemy_spawn_count

	var spawn_positions := _build_spawn_positions(1)
	if not spawn_positions.is_empty():
		return spawn_positions.size()

	return max(1, enemy_templates.size())

func _build_spawn_positions(count: int) -> Array[Vector2]:
	var positions: Array[Vector2] = get_spawn_point_positions()

	for template in enemy_templates:
		positions.append(template.get("position", Vector2.ZERO))

	if positions.is_empty():
		var center := marker_2d.position
		positions = [
			center + Vector2(-56, -32),
			center + Vector2(56, -32),
			center + Vector2(-56, 32),
			center + Vector2(56, 32)
		]

	var base_positions := positions.duplicate()
	var base_size := base_positions.size()
	while positions.size() < count:
		positions.append(base_positions[(positions.size() - base_size) % base_size])

	return positions
