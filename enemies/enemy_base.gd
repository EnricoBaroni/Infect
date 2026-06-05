extends CharacterBody2D
class_name EnemyBase

# SCENES

const DROP = preload("uid://dhaw4gt67tdhp")
const HIT_EFFECT = preload("uid://ceyipwdhuape4")
const DEATH_EFFECT = preload("uid://dwdgco8qr3k4f")
const DEFAULT_ENEMY_BULLET = preload("uid://cwe1h0ebu2ech")

# STATE

var infected := false
var speed := 0.0

var move_direction := Vector2.ZERO
var move_timer := 0.0

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

# CORE

func die() -> void:
	var death_effect = DEATH_EFFECT.instantiate()
	get_tree().current_scene.add_child(death_effect)
	death_effect.global_position = global_position

	var drop = DROP.instantiate()
	get_tree().current_scene.add_child(drop)
	drop.global_position = global_position
	drop.setup(infected)

	queue_free()

func take_hit(other_hitbox: Hitbox) -> void:
	var hit_effect = HIT_EFFECT.instantiate()
	get_tree().current_scene.add_child(hit_effect)
	hit_effect.global_position = center.global_position

	if other_hitbox.infection_power > 0:
		infect()
		return

	stats.health -= other_hitbox.damage
	on_hit(other_hitbox)

func infect() -> void:
	if infected:
		return

	infected = true
	modulate = Color.GREEN

	on_infected()

# HOOKS

func on_hit(other_hitbox: Hitbox) -> void:
	velocity = other_hitbox.knockback_direction * other_hitbox.knockback_amount

	if has_method("play_hit_animation"):
		play_hit_animation()

func on_infected() -> void:
	pass

func play_hit_animation() -> void:
	pass

# HELPERS

func get_room():
	return get_parent().get_parent()

func get_player() -> Player:
	return get_tree().get_first_node_in_group("player")

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

# MOVEMENT

func chase_player() -> void:
	var player = get_player()

	if player is Player:
		var target_position = get_chase_target_position()

		velocity = global_position.direction_to(target_position) * speed
		face_direction(velocity)
	else:
		velocity = Vector2.ZERO

	move_and_slide()

func flee_player() -> void:
	var player = get_player()

	if player is Player:
		velocity = player.global_position.direction_to(global_position) * speed
		face_direction(velocity)
	else:
		velocity = Vector2.ZERO

	move_and_slide()

func charge_towards_player(multiplier: float = 3.0) -> void:
	var direction = get_direction_to_player()

	velocity = direction * speed * multiplier

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

	face_direction(velocity)

	move_and_slide()

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
