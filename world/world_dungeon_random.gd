extends Node2D
class_name WorldDungeonRandom

const FLOOR_TRANSITION_SCENE = preload("res://world/floor_transition.tscn")
const DEFAULT_COMBAT_TEMPLATE = preload("res://world/templates/combat_room_template_01.tscn")
const DEFAULT_GACHA_TEMPLATE = preload("res://world/templates/gacha_room_template.tscn")
const DEFAULT_BOSS_TEMPLATE = preload("res://world/templates/boss_room_template.tscn")
const ENEMY_SCENES_PATH := "res://enemies"
const STANDARD_ROOM_WIDTH := 352.0
const STANDARD_ROOM_HEIGHT := 216.0

@export var combat_rooms_per_floor := 4
@export var room_spacing := Vector2(STANDARD_ROOM_WIDTH, 0)
@export var start_position := Vector2.ZERO
@export var max_spawn_tier := 5
@export var base_floor_difficulty := 1

@export var gacha_room_template: PackedScene = DEFAULT_GACHA_TEMPLATE
@export var combat_room_templates: Array[PackedScene] = [DEFAULT_COMBAT_TEMPLATE]
@export var boss_room_template: PackedScene = DEFAULT_BOSS_TEMPLATE
@export var floor_transition_scene: PackedScene = FLOOR_TRANSITION_SCENE

@onready var drops_label: Label = $CanvasLayer/StatsUI/DropsLabel

var _spawn_rng := RandomNumberGenerator.new()
var _enemy_roster: Array[PackedScene] = []
var _generated_rooms: Array[Room] = []
var _active_floor_transition: Node = null

func _ready() -> void:
	_spawn_rng.randomize()
	_sync_progression_state_on_load()
	_enemy_roster = _discover_enemy_roster()
	_generate_floor()

func _process(_delta: float) -> void:
	drops_label.text = str(Global.drops)

func get_current_spawn_tier() -> int:
	return clampi(Global.floor_number, 1, max_spawn_tier)

func get_generation_rng() -> RandomNumberGenerator:
	return _spawn_rng

func notify_boss_room_cleared(room: Room) -> void:
	if room == null or not room.is_boss_room():
		return
	if _active_floor_transition != null and is_instance_valid(_active_floor_transition):
		return

	EventBus.emit_boss_killed({
		"room": room,
		"room_name": room.name,
		"floor_number": Global.floor_number,
		"spawn_tier": get_current_spawn_tier()
	})

	_spawn_floor_transition_in_room(room)

func advance_to_next_floor() -> void:
	Global.floor_number += 1
	Global.difficulty_level = max(base_floor_difficulty, Global.floor_number)
	_generate_floor()

func _sync_progression_state_on_load() -> void:
	Global.floor_number = max(1, Global.floor_number)
	Global.difficulty_level = max(base_floor_difficulty, Global.floor_number, Global.difficulty_level)

func _generate_floor() -> void:
	_clear_floor_transition()
	_clear_generated_rooms()

	var room_sequence := _build_room_sequence()
	if room_sequence.is_empty():
		return

	for index in room_sequence.size():
		var room_scene := room_sequence[index]
		if room_scene == null:
			continue
		var room_instance := room_scene.instantiate() as Room
		if room_instance == null:
			continue

		_add_room_metadata(room_instance, index, room_sequence.size())
		room_instance.position = start_position + room_spacing * index
		add_child(room_instance)
		_generated_rooms.append(room_instance)

	_connect_linear_room_doors(_generated_rooms)
	_configure_enemy_generation(_generated_rooms)

	for room in _generated_rooms:
		room.respawn_enemies()

	var gacha_room := _get_gacha_room()
	if gacha_room != null:
		_activate_room(gacha_room)
		_move_player_and_camera_to_room(gacha_room)

func _build_room_sequence() -> Array[PackedScene]:
	var sequence: Array[PackedScene] = []
	sequence.append(gacha_room_template if gacha_room_template != null else DEFAULT_GACHA_TEMPLATE)

	var combat_count := max(1, combat_rooms_per_floor)
	for i in combat_count:
		sequence.append(_pick_random_combat_template())

	sequence.append(boss_room_template if boss_room_template != null else DEFAULT_BOSS_TEMPLATE)
	return sequence

func _pick_random_combat_template() -> PackedScene:
	var templates := combat_room_templates
	if templates.is_empty():
		return DEFAULT_COMBAT_TEMPLATE
	var index := _spawn_rng.randi_range(0, templates.size() - 1)
	return templates[index]

func _add_room_metadata(room: Room, index: int, total_rooms: int) -> void:
	var room_name := "Floor_%02d_Room_%02d" % [Global.floor_number, index]
	room.name = room_name

	if index == 0:
		room.room_type = Room.RoomType.GACHA
		room.combat_room = false
		return

	if index == total_rooms - 1:
		room.room_type = Room.RoomType.BOSS
		room.combat_room = true
		return

	room.room_type = Room.RoomType.COMBAT
	room.combat_room = true

func _connect_linear_room_doors(rooms: Array[Room]) -> void:
	for room in rooms:
		_clear_room_door_destinations(room)

	for index in rooms.size() - 1:
		var current_room := rooms[index]
		var next_room := rooms[index + 1]
		_set_room_door_destination(current_room.get_forward_door(), next_room.name)
		_set_room_door_destination(next_room.get_backward_door(), current_room.name)

func _clear_room_door_destinations(room: Room) -> void:
	for door in room.doors:
		door.tp_position = ""
		door.close()

func _set_room_door_destination(door: Door, destination_room_name: String) -> void:
	if door == null:
		return
	door.tp_position = destination_room_name

func _configure_enemy_generation(rooms: Array[Room]) -> void:
	if _enemy_roster.is_empty():
		return
	for room in rooms:
		if not room.combat_room:
			continue
		if room.is_boss_room():
			continue
		room.set_enemy_pool(_enemy_roster)

func _discover_enemy_roster() -> Array[PackedScene]:
	var discovered: Array[PackedScene] = []
	var dir := DirAccess.open(ENEMY_SCENES_PATH)
	if dir == null:
		return discovered

	var file_names: PackedStringArray = []
	dir.list_dir_begin()
	while true:
		var file_name := dir.get_next()
		if file_name == "":
			break
		if dir.current_is_dir():
			continue
		if not file_name.ends_with("_enemy.tscn"):
			continue
		file_names.append(file_name)
	dir.list_dir_end()

	file_names.sort()
	for file_name in file_names:
		var path := ENEMY_SCENES_PATH + "/" + file_name
		var scene := load(path) as PackedScene
		if scene != null:
			discovered.append(scene)

	return discovered

func _spawn_floor_transition_in_room(room: Room) -> void:
	if floor_transition_scene == null:
		return
	var transition_instance := floor_transition_scene.instantiate()
	if transition_instance == null:
		return
	if transition_instance.has_method("set_world_dungeon"):
		transition_instance.set_world_dungeon(self)
	room.add_child(transition_instance)
	if transition_instance is Node2D:
		(transition_instance as Node2D).global_position = room.get_room_center_position()
	_active_floor_transition = transition_instance

func _clear_generated_rooms() -> void:
	for room in _generated_rooms:
		if room != null and is_instance_valid(room):
			remove_child(room)
			room.queue_free()
	_generated_rooms.clear()

func _clear_floor_transition() -> void:
	if _active_floor_transition != null and is_instance_valid(_active_floor_transition):
		_active_floor_transition.queue_free()
	_active_floor_transition = null

func _get_gacha_room() -> Room:
	if _generated_rooms.is_empty():
		return null
	return _generated_rooms[0]

func _activate_room(room: Room) -> void:
	for candidate in _generated_rooms:
		candidate.deactivate()
	room.activate()

func _move_player_and_camera_to_room(room: Room) -> void:
	var room_center := room.get_room_center_position()
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player == null:
		player = get_node_or_null("Player") as Node2D
	if player != null:
		player.global_position = room_center

	var camera := get_node_or_null("Camera2D") as Camera2D
	if camera != null:
		camera.position = room_center

	Global.recently_moved = true
	await get_tree().create_timer(0.3).timeout
	Global.recently_moved = false
