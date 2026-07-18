extends CharacterBody2D
class_name EnemyBase

# SCENES

const DROP = preload("uid://dhaw4gt67tdhp")
const HIT_EFFECT = preload("uid://ceyipwdhuape4")
const DEATH_EFFECT = preload("uid://dwdgco8qr3k4f")
const DEFAULT_ENEMY_BULLET = preload("uid://cwe1h0ebu2ech")

# STATE

const INFECTION_MULTIPLIER = 1.5
var infection_state: InfectionState = InfectionState.new()
var infected := false
var speed := 0.0

var move_direction := Vector2.ZERO
var move_timer := 0.0
var charging := false
var charge_direction := Vector2.ZERO
var jump_timer := 0.0
var _status_states: Dictionary[String, Dictionary] = {}
var _status_runtime_timer: Timer

# DATA

@export var stats: Stats

# NODES

@onready var hurtbox: Hurtbox = $Hurtbox
@onready var center: Marker2D = $Center

# LIFECYCLE

func _ready() -> void:
	stats = stats.duplicate()
	hurtbox.hurt.connect(take_hit.call_deferred)
	stats.no_health.connect(die)
	_status_runtime_timer = Timer.new()
	_status_runtime_timer.name = "StatusRuntimeTimer"
	_status_runtime_timer.wait_time = 0.1
	_status_runtime_timer.one_shot = false
	_status_runtime_timer.autostart = true
	add_child(_status_runtime_timer)
	_status_runtime_timer.timeout.connect(_on_status_runtime_tick)
	EventBus.emit_enemy_spawned({
		"enemy": self,
		"enemy_name": name,
		"position": global_position
	})

# CORE

func die() -> void:
	EventBus.emit_enemy_killed({
		"enemy": self,
		"enemy_name": name,
		"infected": infected,
		"position": global_position
	})

	var death_effect = DEATH_EFFECT.instantiate()
	get_tree().current_scene.add_child(death_effect)
	death_effect.global_position = global_position

	var drop = DROP.instantiate()
	get_tree().current_scene.add_child(drop)
	drop.global_position = global_position
	drop.setup(infected)

	queue_free()

func spawn_enemy_on_death(
	enemy_scene: PackedScene
) -> void:

	if not enemy_scene:
		return

	var enemy := enemy_scene.instantiate() as Node2D
	if enemy == null:
		return

	enemy.global_position = global_position

	get_parent().add_child(enemy)

func take_hit(other_hitbox: Hitbox) -> void:
	var hit_effect = HIT_EFFECT.instantiate()
	get_tree().current_scene.add_child(hit_effect)
	hit_effect.global_position = center.global_position
	if not can_take_damage():
		return

	_apply_status_payloads(other_hitbox.status_payloads, other_hitbox.source_luck)

	if other_hitbox.infection_power > 0:
		infect()

	if other_hitbox.damage > 0:
		stats.health -= other_hitbox.damage
		if other_hitbox.source_faction == "player":
			var enemy_hit_payload := {
				"enemy": self,
				"enemy_name": name,
				"infected": infected,
				"position": global_position,
				"damage": other_hitbox.damage,
				"source_hitbox": other_hitbox
			}
			EventBus.emit_enemy_hit(enemy_hit_payload)
			if other_hitbox.source_is_projectile:
				EventBus.emit_projectile_hit(enemy_hit_payload)
		on_hit(other_hitbox)

func infect() -> void:
	if infection_state.is_infected:
		return

	infection_state.is_infected = true
	infected = infection_state.is_infected
	modulate = Color.GREEN
	speed = stats.move_speed * INFECTION_MULTIPLIER

	on_infected()
	_recalculate_status_visual()

# HOOKS

func on_hit(other_hitbox: Hitbox) -> void:
	velocity = other_hitbox.knockback_direction * other_hitbox.knockback_amount

	if has_method("play_hit_animation"):
		play_hit_animation()

func on_infected() -> void:
	pass

func can_take_damage() -> bool:
	return true

func play_hit_animation() -> void:
	pass

# HELPERS

func get_room() -> Room:
	return get_parent().get_parent() as Room

func get_player() -> Player:
	return get_tree().get_first_node_in_group("player") as Player

func face_direction(direction: Vector2) -> void:
	if not has_node("Sprite2D"):
		return

	var sprite = get_node("Sprite2D")

	if direction.x != 0:
		sprite.scale.x = sign(direction.x)

func get_direction_to_player() -> Vector2:
	var player = get_player()

	if player is Player:
		return global_position.direction_to(player.global_position)

	return Vector2.ZERO

func get_chase_target_position() -> Vector2:
	var player = get_player()

	if player is Player:
		return player.global_position

	return global_position

# CONDITIONS

func is_player_in_range(min_range: float, max_range: float) -> bool:
	var player = get_player()

	if player is Player:
		var distance = global_position.distance_to(player.global_position)
		return distance < max_range and distance > min_range

	return false

func has_line_of_sight(
	raycast: RayCast2D,
	min_range: float,
	max_range: float
) -> bool:
	if not is_player_in_range(min_range, max_range):
		return false

	var player = get_player()

	if not player:
		return false

	raycast.target_position = player.global_position - global_position
	raycast.force_raycast_update()

	return not raycast.is_colliding()

func can_see_player(
	raycast: RayCast2D,
	min_range: float,
	max_range: float
) -> bool:
	return has_line_of_sight(
		raycast,
		min_range,
		max_range
	)

# MOVEMENT

func get_navigation_chase_target_position(
	navigation_agent: NavigationAgent2D
) -> Vector2:

	var player = get_player()

	if player is Player:
		navigation_agent.target_position = player.global_position
		return navigation_agent.get_next_path_position()

	return global_position

func chase_player() -> void:
	var player = get_player()

	if player is Player:
		var direction = get_direction_to_player()
		direction = _apply_behavior_statuses(direction)

		velocity = direction * _get_effective_speed()
		face_direction(velocity)
	else:
		velocity = Vector2.ZERO

	move_and_slide()

func chase_player_with_navigation(
	navigation_agent: NavigationAgent2D
) -> void:
	if _is_status_active("fear") or _is_status_active("charm"):
		flee_player()
		return

	var target_position = get_navigation_chase_target_position(
		navigation_agent
	)

	velocity = global_position.direction_to(
		target_position
	) * _get_effective_speed()
	velocity = _apply_behavior_statuses(velocity)

	face_direction(velocity)

	move_and_slide()

func flee_player() -> void:
	var player = get_player()

	if player is Player:
		velocity = player.global_position.direction_to(global_position) * _get_effective_speed()
		face_direction(velocity)
	else:
		velocity = Vector2.ZERO

	move_and_slide()

func charge_towards_player(multiplier: float = 3.0) -> void:
	var direction = get_direction_to_player()
	direction = _apply_behavior_statuses(direction)

	velocity = direction * _get_effective_speed() * multiplier

	face_direction(velocity)

	move_and_slide()

func is_aligned_with_player(threshold: float = 8.0) -> bool:
	var player = get_player()

	if not player:
		return false

	var offset = player.global_position - global_position

	return (
		abs(offset.x) < threshold
		or abs(offset.y) < threshold
	)

func wander(delta: float) -> void:
	move_timer -= delta

	if move_timer <= 0:
		move_timer = randf_range(1.0, 2.0)

		move_direction = Vector2(
			randf_range(-1.0, 1.0),
			randf_range(-1.0, 1.0)
		).normalized()

	velocity = move_direction * speed
	if _is_status_active("fear") or _is_status_active("charm"):
		velocity = get_direction_to_player() * -1.0 * _get_effective_speed()
	else:
		velocity = move_direction * _get_effective_speed()
	velocity = _apply_behavior_statuses(velocity)

	face_direction(velocity)

	move_and_slide()

func jump_randomly(delta: float) -> void:
	jump_timer -= delta
	if jump_timer > 0:
		velocity = Vector2.ZERO
		move_and_slide()
		return
	jump_timer = 1
	move_direction = Vector2(
		randf_range(-1.0, 1.0),
		randf_range(-1.0, 1.0)
	).normalized()
	velocity = move_direction * _get_effective_speed() * 50.0
	face_direction(velocity)
	move_and_slide()

func charge() -> void:
	var direction = charge_direction
	direction = _apply_behavior_statuses(direction)
	velocity = direction * _get_effective_speed() * 3.0
	face_direction(velocity)
	move_and_slide()
	if is_hitting_wall():
		charging = false

func _apply_behavior_statuses(direction: Vector2) -> Vector2:
	var adjusted := direction
	if _is_status_active("fear") or _is_status_active("charm"):
		adjusted = adjusted * -1.0
	if _is_status_active("confusion"):
		var confusion_state: Dictionary = _status_states["confusion"]
		var wobble := clampf(float(confusion_state.get("magnitude", 0.45)), 0.0, 1.0)
		adjusted = adjusted.rotated(randf_range(-PI, PI) * wobble)
	return adjusted

func _on_status_runtime_tick() -> void:
	if _status_states.is_empty():
		return

	var delta := _status_runtime_timer.wait_time
	var changed := false
	var expired_statuses: Array[String] = []
	for status_id: String in _status_states.keys():
		var state: Dictionary = _status_states[status_id]
		state["remaining"] = float(state["remaining"]) - delta
		state["tick_elapsed"] = float(state["tick_elapsed"]) + delta

		if float(state["tick_interval"]) > 0.0:
			while float(state["tick_elapsed"]) >= float(state["tick_interval"]):
				state["tick_elapsed"] = float(state["tick_elapsed"]) - float(state["tick_interval"])
				_apply_status_tick(status_id, state)

		if float(state["remaining"]) <= 0.0:
			expired_statuses.append(status_id)
			changed = true

	for status_id: String in expired_statuses:
		_status_states.erase(status_id)

	if changed:
		_recalculate_status_visual()

func _apply_status_payloads(payloads: Array[StatusPayload], source_luck: float = 0.0) -> void:
	if payloads.is_empty():
		return

	var changed := false
	for payload in payloads:
		if payload == null:
			continue
		if payload.duration <= 0.0:
			continue
		if payload.status_id == "":
			continue
		var proc := clampf(payload.proc_chance, 0.0, 1.0)
		if payload.proc_luck_to_full > 0.0:
			proc = EventBus.evaluate_luck_proc(proc, source_luck, payload.proc_luck_to_full, payload.proc_max_chance)
		if randf() > proc:
			continue

		if not _status_states.has(payload.status_id):
			var created_state: Dictionary = {
				"remaining": payload.duration,
				"stacks": 1,
				"max_stacks": payload.max_stacks,
				"stack_rule": payload.stack_rule,
				"magnitude": payload.magnitude,
				"tick_interval": payload.tick_interval,
				"tick_elapsed": 0.0,
				"visual_tint": payload.visual_tint
			}
			_status_states[payload.status_id] = created_state
			changed = true
			continue

		var state: Dictionary = _status_states[payload.status_id]

		state["max_stacks"] = max(int(state["max_stacks"]), payload.max_stacks)
		state["tick_interval"] = payload.tick_interval
		state["visual_tint"] = payload.visual_tint

		match payload.stack_rule:
			"stack_duration":
				state["remaining"] = float(state["remaining"]) + payload.duration
				state["stacks"] = min(int(state["max_stacks"]), int(state["stacks"]) + 1)
				state["magnitude"] = max(float(state["magnitude"]), payload.magnitude)
			"replace_stronger":
				if payload.magnitude >= float(state["magnitude"]):
					state["magnitude"] = payload.magnitude
					state["remaining"] = payload.duration
				state["stacks"] = min(int(state["max_stacks"]), int(state["stacks"]) + 1)
			_:
				state["remaining"] = max(float(state["remaining"]), payload.duration)
				state["stacks"] = min(int(state["max_stacks"]), int(state["stacks"]) + 1)
				state["magnitude"] = max(float(state["magnitude"]), payload.magnitude)

		changed = true

	if changed:
		_recalculate_status_visual()

func _apply_status_tick(status_id: String, state: Dictionary) -> void:
	if not can_take_damage():
		return

	var stacks = max(1, int(state["stacks"]))
	var magnitude = max(0.0, float(state["magnitude"]))
	var tick_interval = max(0.01, float(state["tick_interval"]))
	var tick_damage := 0.0
	match status_id:
		"poison":
			tick_damage = magnitude * float(stacks) * tick_interval
		"burn":
			tick_damage = magnitude * (1.0 + 0.25 * float(stacks - 1)) * tick_interval
		"bleed":
			tick_damage = magnitude * (1.0 + 0.2 * float(stacks - 1)) * tick_interval
		_:
			tick_damage = 0.0

	if tick_damage > 0.0:
		stats.health -= tick_damage

func _get_effective_speed() -> float:
	var effective = speed
	if _status_states.has("freeze"):
		var freeze_state: Dictionary = _status_states["freeze"]
		effective *= clamp(float(freeze_state["magnitude"]), 0.0, 1.0)
	if _status_states.has("slow"):
		var slow_state: Dictionary = _status_states["slow"]
		effective *= clamp(float(slow_state["magnitude"]), 0.0, 1.0)
	return effective

func _is_status_active(status_id: String) -> bool:
	return _status_states.has(status_id)

func _recalculate_status_visual() -> void:
	var tint = Color(1, 1, 1, 1)
	if infected:
		tint = Color(0.65, 1.0, 0.65, 1.0)

	for state_data: Dictionary in _status_states.values():
		var visual_tint: Color = state_data["visual_tint"] as Color
		tint.r = clamp((tint.r + visual_tint.r) * 0.5, 0.0, 1.0)
		tint.g = clamp((tint.g + visual_tint.g) * 0.5, 0.0, 1.0)
		tint.b = clamp((tint.b + visual_tint.b) * 0.5, 0.0, 1.0)

	modulate = tint

func start_charge() -> void:
	charging = true
	charge_direction = get_direction_to_player().round()

func is_hitting_wall() -> bool:
	return get_slide_collision_count() > 0

# ATTACK INFRASTRUCTURE

func spawn_enemy_bullet(
	direction: Vector2,
	bullet_scene: PackedScene,
	color: Color
) -> void:
	var bullet = bullet_scene.instantiate()

	bullet.enemy_shot = true
	bullet.custom_color = color

	bullet.global_position = global_position
	bullet.direction = direction

	get_tree().current_scene.add_child(bullet)

func get_bullet_scene() -> PackedScene:
	return DEFAULT_ENEMY_BULLET

func get_bullet_color() -> Color:
	return Color.WHITE

# ATTACKS

func shoot_at_player() -> void:
	spawn_enemy_bullet(
		get_direction_to_player(),
		get_bullet_scene(),
		get_bullet_color()
	)

func shoot_cross() -> void:
	spawn_enemy_bullet(Vector2.UP, get_bullet_scene(), get_bullet_color())
	spawn_enemy_bullet(Vector2.DOWN, get_bullet_scene(), get_bullet_color())
	spawn_enemy_bullet(Vector2.LEFT, get_bullet_scene(), get_bullet_color())
	spawn_enemy_bullet(Vector2.RIGHT, get_bullet_scene(), get_bullet_color())

func shoot_diagonals() -> void:
	spawn_enemy_bullet(Vector2(1, 1).normalized(), get_bullet_scene(), get_bullet_color())
	spawn_enemy_bullet(Vector2(1, -1).normalized(), get_bullet_scene(), get_bullet_color())
	spawn_enemy_bullet(Vector2(-1, 1).normalized(), get_bullet_scene(), get_bullet_color())
	spawn_enemy_bullet(Vector2(-1, -1).normalized(), get_bullet_scene(), get_bullet_color())
