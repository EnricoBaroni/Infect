extends Node2D
class_name WorldDungeon

const FLOOR_TRANSITION_SCENE = preload("res://world/floor_transition.tscn")
const ENEMY_SCENES_PATH := "res://enemies"

@export var max_spawn_tier := 5
@export var base_floor_difficulty := 1
@export var floor_transition_scene: PackedScene = FLOOR_TRANSITION_SCENE
@export var boss_room_path: NodePath = ^"Room3"
@export var gacha_room_path: NodePath = ^"Room5"

@onready var starting_room: Room = $Room1
@onready var drops_label: Label = $CanvasLayer/StatsUI/DropsLabel
@onready var rooms: Array[Room] = [
	$Room1,
	$Room2,
	$Room3,
	$Room4,
	$Room5
]

var _enemy_roster: Array[PackedScene] = []
var _active_floor_transition: Node = null
var _generation_rng := RandomNumberGenerator.new()

func _ready() -> void:
	_generation_rng.randomize()
	_sync_progression_state_on_load()
	_enemy_roster = _discover_enemy_roster()
	_configure_combat_room_enemy_pools()
	respawn_all_enemies()
	var initial_room := _get_gacha_room()
	if initial_room == null:
		initial_room = starting_room
	_activate_room(initial_room)
	_move_player_and_camera_to_room(initial_room)

func _process(_delta: float) -> void:
	drops_label.text = str(Global.drops)

func respawn_all_enemies() -> void:
	for room in rooms:
		room.respawn_enemies()

func get_current_spawn_tier() -> int:
	return clampi(Global.floor_number, 1, max_spawn_tier)

func get_generation_rng() -> RandomNumberGenerator:
	return _generation_rng

func notify_boss_room_cleared(room: Room) -> void:
	if room == null:
		return
	var boss_room := _get_boss_room()
	if boss_room == null or room != boss_room:
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

	_clear_floor_transition()
	respawn_all_enemies()

	for room in rooms:
		room.deactivate()

	var gacha_room := _get_gacha_room()
	if gacha_room == null:
		_activate_room(starting_room)
		return

	_activate_room(gacha_room)
	_move_player_and_camera_to_room(gacha_room)

func _sync_progression_state_on_load() -> void:
	Global.floor_number = max(1, Global.floor_number)
	Global.difficulty_level = max(base_floor_difficulty, Global.floor_number, Global.difficulty_level)

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
		var scene_path := ENEMY_SCENES_PATH + "/" + file_name
		var scene := load(scene_path) as PackedScene
		if scene != null:
			discovered.append(scene)

	return discovered

func _configure_combat_room_enemy_pools() -> void:
	if _enemy_roster.is_empty():
		return
	for room in rooms:
		if room == null:
			continue
		if not room.combat_room:
			continue
		if room.is_boss_room():
			continue
		room.set_enemy_pool(_enemy_roster)

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

func _clear_floor_transition() -> void:
	if _active_floor_transition != null and is_instance_valid(_active_floor_transition):
		_active_floor_transition.queue_free()
	_active_floor_transition = null

func _activate_room(room: Room) -> void:
	if room == null:
		return
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

func _get_boss_room() -> Room:
	if boss_room_path == NodePath(""):
		return null
	return get_node_or_null(boss_room_path) as Room

func _get_gacha_room() -> Room:
	if gacha_room_path == NodePath(""):
		return null
	return get_node_or_null(gacha_room_path) as Room
