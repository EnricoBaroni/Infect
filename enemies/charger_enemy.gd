extends EnemyBase

const BASE_SPEED = 20
const INFECTION_MULTIPLIER = 1.5
const FRICTION = 500

var custom_color := Color.PURPLE
var health_multiplier := 1.0
var speed_multiplier := 1.0
var charging := false
var charge_direction := Vector2.ZERO

@export var min_range: = 4
@export var max_range: = 80

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
		"WanderState":
			if charging:
				charge()
				return
			if is_aligned_with_player():
				charging = true
				charge_direction = get_direction_to_player().round()
				return
			wander(delta)
		"HitState":
			velocity = velocity.move_toward(Vector2.ZERO, FRICTION * delta)
			move_and_slide()

func start_attack() -> void:
	pass

func on_infected() -> void:
	attack_timer.wait_time *= 0.5

func can_see_player() -> bool:
	return has_line_of_sight(
		ray_cast_2d,
		min_range,
		max_range
	)

func get_bullet_color() -> Color:
	return custom_color

func charge() -> void:
	velocity = charge_direction * speed * 3.0
	face_direction(velocity)
	move_and_slide()
	if is_hitting_wall():
		charging = false

func is_hitting_wall() -> bool:
	return get_slide_collision_count() > 0
