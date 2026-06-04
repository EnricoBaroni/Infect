extends CharacterBody2D

const DROP = preload("uid://dhaw4gt67tdhp")
const HIT_EFFECT = preload("uid://ceyipwdhuape4")
const DEATH_EFFECT = preload("uid://dwdgco8qr3k4f")

const BASE_SPEED = 8
const INFECTION_MULTIPLIER = 1.2
const FRICTION = 500

var infected := false
var speed := BASE_SPEED
var move_direction := Vector2.ZERO
var move_timer := 0.0
var custom_color := Color.CYAN

@export var stats: Stats
@export var BULLET: PackedScene

@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var animation_tree: AnimationTree = $AnimationTree
@onready var playback = animation_tree.get("parameters/StateMachine/playback") as AnimationNodeStateMachinePlayback
@onready var hurtbox: Hurtbox = $Hurtbox
@onready var center: Marker2D = $Center
@onready var attack_timer: Timer = $AttackTimer

func _ready() -> void:
	stats = stats.duplicate()
	hurtbox.hurt.connect(take_hit.call_deferred)
	stats.no_health.connect(die)
	attack_timer.timeout.connect(start_attack)
	attack_timer.start(randf_range(0.3, 1.0))
	modulate = custom_color
	speed = BASE_SPEED * randf_range(0.9, 1.3)

func _physics_process(delta: float) -> void:
	var room = get_room()
	if not room.active:
		return
	var state = playback.get_current_node()
	match state:
		"WanderState":
			wander(delta)
		"HitState":
			velocity = velocity.move_toward(Vector2.ZERO, FRICTION * delta)
			move_and_slide()

func wander(delta: float) -> void:
	move_timer -= delta
	if move_timer <= 0:
		move_timer = randf_range(1.0, 2.0)
		move_direction = Vector2(
			randf_range(-1.0, 1.0),
			randf_range(-1.0, 1.0)
		).normalized()
	velocity = move_direction * speed
	if velocity.x != 0:
		sprite_2d.scale.x = sign(velocity.x)
	move_and_slide()

func start_attack() -> void:
	var room = get_room()
	if not room.active:
		return
	attack_timer.start(randf_range(1.0, 3.0))
	shoot_cross()
	if infected:
		shoot_diagonals()

func shoot_cross() -> void:
	spawn_bullet(Vector2.UP)
	spawn_bullet(Vector2.DOWN)
	spawn_bullet(Vector2.LEFT)
	spawn_bullet(Vector2.RIGHT)

func shoot_diagonals() -> void:
	spawn_bullet(Vector2(1, 1).normalized())
	spawn_bullet(Vector2(1, -1).normalized())
	spawn_bullet(Vector2(-1, 1).normalized())
	spawn_bullet(Vector2(-1, -1).normalized())

func spawn_bullet(direction: Vector2) -> void:
	print("RAPPER SHOOT")
	var bullet = BULLET.instantiate()
	bullet.enemy_shot = true
	bullet.custom_color = custom_color
	bullet.global_position = global_position
	bullet.direction = direction
	get_tree().current_scene.add_child(bullet)

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
	velocity = other_hitbox.knockback_direction * other_hitbox.knockback_amount
	playback.start("HitState")

func infect() -> void:
	if infected:
		return
	infected = true
	modulate = Color.GREEN
	speed = BASE_SPEED * INFECTION_MULTIPLIER

func get_room():
	return get_parent().get_parent()
