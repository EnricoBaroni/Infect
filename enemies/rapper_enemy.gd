extends EnemyBase

const BASE_SPEED = 8
const INFECTION_MULTIPLIER = 1.2
const FRICTION = 500

var speed := BASE_SPEED
var move_direction := Vector2.ZERO
var move_timer := 0.0
var custom_color := Color.CYAN
var health_multiplier := 1.0
var speed_multiplier := 1.0

@export var BULLET: PackedScene

@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var animation_tree: AnimationTree = $AnimationTree
@onready var playback = animation_tree.get("parameters/StateMachine/playback") as AnimationNodeStateMachinePlayback
@onready var attack_timer: Timer = $AttackTimer

func _ready() -> void:
	super()
	attack_timer.timeout.connect(start_attack)
	attack_timer.start(randf_range(0.3, 1.0))
	modulate = custom_color
	stats.health *= health_multiplier
	stats.max_health *= health_multiplier

	speed = BASE_SPEED * randf_range(0.9, 1.1)
	speed *= speed_multiplier

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

func play_hit_animation() -> void:
	playback.start("HitState")

func on_infected() -> void:
	speed = BASE_SPEED * INFECTION_MULTIPLIER
