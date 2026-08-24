extends EnemyBase

const FRICTION = 500

var health_multiplier := 1.0
var speed_multiplier := 1.0
# Spawn tier metadata — based on Isaac Hopper (Basement/Cellar through all floors)
@export var spawn_tier_min: int = 1   # Floor must be >= this to include this enemy in spawn pool
@export var spawn_tier_max: int = 0   # 0 = no upper limit
@export var spawn_weight: int = 10    # Relative probability when eligible

@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var animation_tree: AnimationTree = $AnimationTree
@onready var playback: AnimationNodeStateMachinePlayback = animation_tree.get("parameters/StateMachine/playback") as AnimationNodeStateMachinePlayback
@onready var ray_cast_2d: RayCast2D = $RayCast2D
@onready var navigation_agent_2d: NavigationAgent2D = $Marker2D/NavigationAgent2D
@onready var marker_2d: Marker2D = $Marker2D

func _ready() -> void:
	super()
	
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
		"IdleState": pass
		"ChaseState":
			chase_player()
		"HitState":
			velocity = velocity.move_toward(Vector2.ZERO, FRICTION * delta)
			move_and_slide()
