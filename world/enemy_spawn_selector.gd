extends RefCounted
class_name EnemySpawnSelector

static var _metadata_cache: Dictionary = {}

static func select_weighted_scenes_for_tier(
	candidate_scenes: Array[PackedScene],
	tier: int,
	count: int,
	rng: RandomNumberGenerator = null
) -> Array[PackedScene]:
	var resolved_count: int = max(0, count)
	if resolved_count <= 0:
		return []

	var weighted_entries := _build_weighted_entries(candidate_scenes, tier)
	if weighted_entries.is_empty():
		return []

	var random := rng
	if random == null:
		random = RandomNumberGenerator.new()
		random.randomize()

	var selected: Array[PackedScene] = []
	for i in resolved_count:
		var pick := _pick_weighted_entry(weighted_entries, random)
		if pick != null:
			selected.append(pick)
	return selected

static func _build_weighted_entries(candidate_scenes: Array[PackedScene], tier: int) -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	for scene in candidate_scenes:
		if scene == null:
			continue
		var metadata := _get_scene_metadata(scene)
		if metadata.is_empty():
			continue
		if not _is_scene_eligible_for_tier(metadata, tier):
			continue
		var weight: int = int(metadata.get("spawn_weight", 1))
		if weight <= 0:
			continue
		entries.append({
			"scene": scene,
			"weight": weight
		})
	return entries

static func _pick_weighted_entry(weighted_entries: Array[Dictionary], rng: RandomNumberGenerator) -> PackedScene:
	var total_weight := 0
	for entry in weighted_entries:
		total_weight += int(entry.get("weight", 0))

	if total_weight <= 0:
		return null

	var roll := rng.randi_range(1, total_weight)
	var running := 0
	for entry in weighted_entries:
		running += int(entry.get("weight", 0))
		if roll <= running:
			return entry.get("scene") as PackedScene

	return weighted_entries.back().get("scene") as PackedScene

static func _get_scene_metadata(scene: PackedScene) -> Dictionary:
	var scene_key := scene.resource_path
	if scene_key == "":
		scene_key = str(scene)

	if _metadata_cache.has(scene_key):
		return _metadata_cache[scene_key] as Dictionary

	var enemy := scene.instantiate()
	if enemy == null:
		_metadata_cache[scene_key] = {}
		return {}

	var metadata := {
		"spawn_tier_min": int(enemy.get("spawn_tier_min") if enemy.get("spawn_tier_min") != null else 1),
		"spawn_tier_max": int(enemy.get("spawn_tier_max") if enemy.get("spawn_tier_max") != null else 0),
		"spawn_weight": int(enemy.get("spawn_weight") if enemy.get("spawn_weight") != null else 1)
	}
	enemy.free()

	_metadata_cache[scene_key] = metadata
	return metadata

static func _is_scene_eligible_for_tier(metadata: Dictionary, tier: int) -> bool:
	var min_tier: int = max(1, int(metadata.get("spawn_tier_min", 1)))
	var max_tier := int(metadata.get("spawn_tier_max", 0))
	if tier < min_tier:
		return false
	if max_tier > 0 and tier > max_tier:
		return false
	return true
