extends EnemyBase

const BASE_SPEED = 30
const INFECTION_MULTIPLIER = 1.5
const FRICTION = 500

var speed := BASE_SPEED
var custom_color := Color.YELLOW
var health_multiplier := 1.0
var speed_multiplier := 1.0

@export var min_range: = 4
@export var max_range: = 80
@export var BULLET: PackedScene

@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var animation_tree: AnimationTree = $AnimationTree
@onready var playback = animation_tree.get("parameters/StateMachine/playback") as AnimationNodeStateMachinePlayback
@onready var ray_cast_2d: RayCast2D = $RayCast2D
@onready var navigation_agent_2d: NavigationAgent2D = $Marker2D/NavigationAgent2D
@onready var marker_2d: Marker2D = $Marker2D
@onready var attack_timer: Timer = $AttackTimer

func _ready() -> void:
	super()
	attack_timer.timeout.connect(start_attack)
	attack_timer.start()
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
		"IdleState": pass
		"ChaseState":
			velocity = Vector2.ZERO
			move_and_slide()
		"HitState":
			velocity = velocity.move_toward(Vector2.ZERO, FRICTION * delta)
			move_and_slide()

func start_attack() -> void:
	var room = get_room()
	if not room.active:
		return
	if not can_see_player():
		return
	var player = get_player()
	if not player:
		return
	var direction = global_position.direction_to(player.global_position)
	print("shooting ", direction)
	spawn_bullet(direction)

func spawn_bullet(direction: Vector2) -> void:
	var bullet = BULLET.instantiate()

	bullet.enemy_shot = true
	bullet.custom_color = custom_color

	bullet.global_position = global_position
	bullet.direction = direction

	get_tree().current_scene.add_child(bullet)

func play_hit_animation() -> void:
	playback.start("HitState")

func on_infected() -> void:
	attack_timer.wait_time *= 0.5

func can_see_player() -> bool:
	if not is_player_in_range(min_range, max_range): return false
	var player: = get_player()
	ray_cast_2d.target_position = player.global_position - global_position
	ray_cast_2d.force_raycast_update()
	var has_los_to_player: = not ray_cast_2d.is_colliding()
	return has_los_to_player
