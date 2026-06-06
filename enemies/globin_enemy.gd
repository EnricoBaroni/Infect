extends EnemyBase

const FRICTION = 500

var custom_color := Color.BLACK
var health_multiplier := 1.0
var speed_multiplier := 1.0

@export var min_range: = 4
@export var max_range: = 400
@export var TRANSFORMED_ENEMY: PackedScene

@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var animation_tree: AnimationTree = $AnimationTree
@onready var playback = animation_tree.get("parameters/StateMachine/playback") as AnimationNodeStateMachinePlayback
@onready var ray_cast_2d: RayCast2D = $RayCast2D
@onready var navigation_agent_2d: NavigationAgent2D = $Marker2D/NavigationAgent2D
@onready var marker_2d: Marker2D = $Marker2D

func _ready() -> void:
	super()
	
	stats.health *= health_multiplier
	stats.max_health *= health_multiplier
	modulate = custom_color

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

func die() -> void:
	if TRANSFORMED_ENEMY:
		spawn_enemy_on_death(
		TRANSFORMED_ENEMY
		)
	super()
