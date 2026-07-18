extends EnemyBase

const FRICTION = 500
const CLOSED_COLOR = Color.SADDLE_BROWN
const OPEN_COLOR = Color.RED

var custom_color := Color.SADDLE_BROWN
var health_multiplier := 1.0
var speed_multiplier := 1.0
var opened := false

@export var min_range: float = 4.0
@export var max_range: float = 80.0

@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var animation_tree: AnimationTree = $AnimationTree
@onready var playback: AnimationNodeStateMachinePlayback = animation_tree.get("parameters/StateMachine/playback") as AnimationNodeStateMachinePlayback
@onready var ray_cast_2d: RayCast2D = $RayCast2D
@onready var navigation_agent_2d: NavigationAgent2D = $Marker2D/NavigationAgent2D
@onready var marker_2d: Marker2D = $Marker2D
@onready var attack_timer: Timer = $AttackTimer
@onready var state_timer: Timer = $StateTimer

func _ready() -> void:
	super()
	state_timer.timeout.connect(toggle_state)
	state_timer.start(2.0)
	attack_timer.timeout.connect(start_attack)
	attack_timer.start()
	modulate = custom_color
	
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
		"WanderState":
			velocity = Vector2.ZERO
			move_and_slide()
		"HitState":
			velocity = velocity.move_toward(Vector2.ZERO, FRICTION * delta)
			move_and_slide()

func start_attack() -> void:
	var room = get_room()
	if not room.active:
		return
	if not can_see_player(
	ray_cast_2d,
	min_range,
	max_range
):
		return
	var player = get_player()
	if not player:
		return
	shoot_at_player()

func on_infected() -> void:
	super()
	attack_timer.wait_time *= 0.5

func get_bullet_color() -> Color:
	return custom_color

func toggle_state() -> void:
	opened = !opened

	if opened:
		modulate = OPEN_COLOR
	else:
		modulate = CLOSED_COLOR
	state_timer.start(2.0)
func can_take_damage() -> bool:
	return opened
