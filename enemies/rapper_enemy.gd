extends EnemyBase

const FRICTION = 500

var health_multiplier := 1.0
var speed_multiplier := 1.0

# Spawn tier metadata — no direct Isaac equivalent; original design
# Cross + diagonal (when infected) pattern + highest HP in roster → design decision: Tier 3
@export var spawn_tier_min: int = 3
@export var spawn_tier_max: int = 0
@export var spawn_weight: int = 4

@export var BULLET: PackedScene

@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var animation_tree: AnimationTree = $AnimationTree
@onready var playback: AnimationNodeStateMachinePlayback = animation_tree.get("parameters/StateMachine/playback") as AnimationNodeStateMachinePlayback
@onready var attack_timer: Timer = $AttackTimer

func _ready() -> void:
	super()
	attack_timer.timeout.connect(start_attack)
	attack_timer.start(randf_range(0.3, 1.0))
	stats.health *= health_multiplier
	stats.max_health *= health_multiplier

	speed = stats.move_speed * randf_range(0.9, 1.1)
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

func start_attack() -> void:
	var room = get_room()
	if not room.active:
		return
	attack_timer.start(randf_range(1.0, 3.0))
	shoot_cross()
	if infected:
		shoot_diagonals()

func get_bullet_scene() -> PackedScene:
	return BULLET
