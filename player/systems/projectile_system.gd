extends Node
class_name ProjectileSystem

const WEAPON_TYPE_TEAR := "tear"
const WEAPON_TYPE_SEGMENTED_BEAM := "segmented_beam"
const WEAPON_TYPE_RETURNING_BLADE := "returning_blade"
const WEAPON_TYPE_EXPANDING_RING := "expanding_ring"
const WEAPON_TYPE_REMOTE_ORB := "remote_orb"
const WEAPON_TYPE_ORBIT_SHOT := "orbit_shot"
const WEAPON_TYPE_LOB_BURST := "lob_burst"
const WEAPON_TYPE_ELASTIC_RICOCHET := "elastic_ricochet"
const BEAM_SEGMENT_SCENE = preload("res://attacks/beam_segment.tscn")
const RETURNING_BLADE_SCENE = preload("res://attacks/returning_blade.tscn")
const EXPANDING_RING_SCENE = preload("res://attacks/expanding_ring.tscn")
const REMOTE_ORB_SCENE = preload("res://attacks/remote_orb.tscn")
const ORBIT_SHOT_SCENE = preload("res://attacks/orbit_shot.tscn")
const LOB_BURST_SCENE = preload("res://attacks/lob_burst_projectile.tscn")

var _active_remote_orb: RemoteOrb

func spawn_projectile(
	attack_data: AttackData,
	bullet_scene: PackedScene,
	spawn_position: Vector2
) -> void:
	if attack_data == null:
		return

	match attack_data.weapon_type:
		WEAPON_TYPE_SEGMENTED_BEAM:
			_spawn_segmented_beam(attack_data, spawn_position)
		WEAPON_TYPE_RETURNING_BLADE:
			_spawn_returning_blade(attack_data, spawn_position)
		WEAPON_TYPE_EXPANDING_RING:
			_spawn_expanding_ring(attack_data, spawn_position)
		WEAPON_TYPE_REMOTE_ORB:
			_spawn_remote_orb(attack_data, spawn_position)
		WEAPON_TYPE_ORBIT_SHOT:
			_spawn_orbit_shot(attack_data, spawn_position)
		WEAPON_TYPE_LOB_BURST:
			_spawn_lob_burst(attack_data, bullet_scene, spawn_position)
		WEAPON_TYPE_ELASTIC_RICOCHET:
			_spawn_elastic_ricochet(attack_data, bullet_scene, spawn_position)
		_:
			_spawn_tear_projectile(attack_data, bullet_scene, spawn_position)

func _spawn_tear_projectile(
	attack_data: AttackData,
	bullet_scene: PackedScene,
	spawn_position: Vector2
) -> void:
	if bullet_scene == null:
		return

	for direction in _build_attack_directions(attack_data):
		var split_attack_data: AttackData = _clone_attack_data(attack_data)
		split_attack_data.direction = direction

		var bullet_instance := bullet_scene.instantiate()
		get_tree().current_scene.add_child(bullet_instance)
		bullet_instance.setup_attack(split_attack_data)
		bullet_instance.global_position = spawn_position

func _spawn_segmented_beam(
	attack_data: AttackData,
	spawn_position: Vector2
) -> void:
	if BEAM_SEGMENT_SCENE == null:
		return

	var direction = attack_data.direction.normalized()
	if direction == Vector2.ZERO:
		return

	var segment_count = max(1, attack_data.beam_segment_count)
	var spacing = max(1.0, attack_data.beam_segment_spacing)

	for index in segment_count:
		var segment = BEAM_SEGMENT_SCENE.instantiate()
		get_tree().current_scene.add_child(segment)

		segment.global_position = spawn_position + direction * spacing * float(index + 1)
		segment.rotation = direction.angle()
		segment.setup_segment(attack_data, index)

func _spawn_returning_blade(attack_data: AttackData, spawn_position: Vector2) -> void:
	if RETURNING_BLADE_SCENE == null:
		return

	var player: Player = get_parent() as Player
	if player == null:
		return
	for direction in _build_attack_directions(attack_data):
		var blade_data: AttackData = _clone_attack_data(attack_data)
		blade_data.direction = direction
		var blade = RETURNING_BLADE_SCENE.instantiate()
		get_tree().current_scene.add_child(blade)
		blade.global_position = spawn_position
		blade.setup_blade(player, blade_data)

func _spawn_expanding_ring(attack_data: AttackData, spawn_position: Vector2) -> void:
	if EXPANDING_RING_SCENE == null:
		return

	var ring = EXPANDING_RING_SCENE.instantiate()
	ring.global_position = spawn_position
	ring.setup_ring(attack_data)
	get_tree().current_scene.add_child(ring)

func _spawn_remote_orb(attack_data: AttackData, spawn_position: Vector2) -> void:
	if is_instance_valid(_active_remote_orb):
		_active_remote_orb.setup_orb(attack_data)
		_active_remote_orb.set_control_direction(attack_data.direction)
		return

	if REMOTE_ORB_SCENE == null:
		return

	var orb: RemoteOrb = REMOTE_ORB_SCENE.instantiate() as RemoteOrb
	if orb == null:
		return

	orb.global_position = spawn_position
	orb.setup_orb(attack_data)
	get_tree().current_scene.add_child(orb)
	_active_remote_orb = orb

func _spawn_orbit_shot(attack_data: AttackData, spawn_position: Vector2) -> void:
	if ORBIT_SHOT_SCENE == null:
		return

	var player: Player = get_parent() as Player
	if player == null:
		return
	for direction in _build_attack_directions(attack_data):
		var orbit_data: AttackData = _clone_attack_data(attack_data)
		orbit_data.direction = direction
		var orbit_shot = ORBIT_SHOT_SCENE.instantiate()
		orbit_shot.global_position = spawn_position
		orbit_shot.setup_orbit(player, orbit_data)
		get_tree().current_scene.add_child(orbit_shot)

func _spawn_lob_burst(attack_data: AttackData, bullet_scene: PackedScene, spawn_position: Vector2) -> void:
	if LOB_BURST_SCENE == null:
		return

	for direction in _build_attack_directions(attack_data):
		var lob_data: AttackData = _clone_attack_data(attack_data)
		lob_data.direction = direction
		var lob_projectile = LOB_BURST_SCENE.instantiate()
		lob_projectile.global_position = spawn_position
		lob_projectile.setup_lob(lob_data, bullet_scene)
		get_tree().current_scene.add_child(lob_projectile)

func _spawn_elastic_ricochet(attack_data: AttackData, bullet_scene: PackedScene, spawn_position: Vector2) -> void:
	if bullet_scene == null:
		return

	for direction in _build_attack_directions(attack_data):
		var elastic_data: AttackData = _clone_attack_data(attack_data)
		elastic_data.direction = direction
		elastic_data.weapon_type = WEAPON_TYPE_TEAR
		elastic_data.bounce_count = max(
			elastic_data.bounce_count + elastic_data.elastic_bonus_bounces,
			elastic_data.elastic_min_bounces
		)
		elastic_data.bounce_speed_retention = elastic_data.elastic_speed_retention
		elastic_data.bounce_random_angle_degrees = elastic_data.elastic_random_angle_degrees

		var bullet_instance = bullet_scene.instantiate()
		get_tree().current_scene.add_child(bullet_instance)
		bullet_instance.setup_attack(elastic_data)
		bullet_instance.global_position = spawn_position

func _build_split_directions(base_direction: Vector2, split_count: int, spread_degrees: float) -> Array[Vector2]:
	var directions: Array[Vector2] = []
	var normalized_base = base_direction.normalized()
	if normalized_base == Vector2.ZERO:
		normalized_base = Vector2.RIGHT

	directions.append(normalized_base)

	var total_split = max(0, split_count)
	if total_split == 0:
		return directions

	var total_shots = total_split + 1
	var half = float(total_shots - 1) / 2.0
	for idx in total_split:
		var slot = float(idx + 1)
		var angle_offset = deg_to_rad((slot - half) * spread_degrees)
		directions.append(normalized_base.rotated(angle_offset))

	return directions

func _build_attack_directions(attack_data: AttackData) -> Array[Vector2]:
	if attack_data == null:
		return [Vector2.RIGHT]

	var spread := attack_data.split_spread_degrees
	var total_split: int = attack_data.split_count

	if attack_data.chance_split_count > 0:
		var chance := clampf(attack_data.chance_split_chance, 0.0, 1.0)
		if attack_data.chance_split_luck_to_full > 0.0:
			chance = EventBus.evaluate_luck_proc(
				chance,
				attack_data.source_luck,
				attack_data.chance_split_luck_to_full,
				attack_data.chance_split_max_chance
			)
		if randf() <= chance:
			total_split += attack_data.chance_split_count
			spread = max(spread, attack_data.chance_split_spread_degrees)

	return _build_split_directions(attack_data.direction, total_split, spread)

func _clone_attack_data(source: AttackData) -> AttackData:
	return source.copy()
