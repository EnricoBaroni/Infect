extends Node
class_name CompanionSystem

const ORBITAL_SCENE = preload("res://companions/orbital_companion.tscn")
const FOLLOWER_SCENE = preload("res://companions/passive_follower.tscn")

var _companions_by_source: Dictionary = {}

func clear_source(source_key: String) -> void:
	if source_key == "":
		return
	if not _companions_by_source.has(source_key):
		return

	var companions: Array[Node2D] = _companions_by_source[source_key]
	for companion: Node2D in companions:
		if companion == null:
			continue
		if is_instance_valid(companion):
			companion.queue_free()

	_companions_by_source.erase(source_key)

func spawn_orbitals(
	source_key: String,
	player: Player,
	count: int,
	radius: float,
	angular_speed: float,
	damage: float,
	blocks_projectiles: bool,
	contact_cooldown: float
) -> void:
	if source_key == "":
		return
	if player == null:
		return
	if count <= 0:
		return
	if ORBITAL_SCENE == null:
		return

	var root = get_tree().current_scene
	if root == null:
		return

	if not _companions_by_source.has(source_key):
		var new_companions: Array[Node2D] = []
		_companions_by_source[source_key] = new_companions

	var companions: Array[Node2D] = _companions_by_source[source_key]
	for idx in count:
		var orbital: OrbitalCompanion = ORBITAL_SCENE.instantiate() as OrbitalCompanion
		if orbital == null:
			continue
		orbital.configure(
			player,
			radius,
			angular_speed,
			damage,
			blocks_projectiles,
			contact_cooldown,
			float(idx) / float(max(1, count)) * TAU
		)
		root.add_child(orbital)
		companions.append(orbital)

func spawn_followers(
	source_key: String,
	player: Player,
	count: int,
	follow_distance: float,
	follow_speed: float,
	damage: float,
	blocks_projectiles: bool,
	contact_cooldown: float,
	shot_interval: float,
	shot_damage: float,
	shot_speed: float,
	shot_range: float
) -> void:
	if source_key == "":
		return
	if player == null:
		return
	if count <= 0:
		return
	if FOLLOWER_SCENE == null:
		return

	var root = get_tree().current_scene
	if root == null:
		return

	if not _companions_by_source.has(source_key):
		var new_companions: Array[Node2D] = []
		_companions_by_source[source_key] = new_companions

	var companions: Array[Node2D] = _companions_by_source[source_key]
	for idx in count:
		var follower: PassiveFollower = FOLLOWER_SCENE.instantiate() as PassiveFollower
		if follower == null:
			continue
		follower.configure(
			player,
			idx,
			count,
			follow_distance,
			follow_speed,
			damage,
			blocks_projectiles,
			contact_cooldown,
			shot_interval,
			shot_damage,
			shot_speed,
			shot_range
		)
		root.add_child(follower)
		companions.append(follower)

func _exit_tree() -> void:
	for source_key in _companions_by_source.keys():
		clear_source(source_key)
