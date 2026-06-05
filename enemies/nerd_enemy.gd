extends CharacterBody2D

const DROP = preload("uid://dhaw4gt67tdhp")
const HIT_EFFECT = preload("uid://ceyipwdhuape4")
const DEATH_EFFECT = preload("uid://dwdgco8qr3k4f")
const BASE_SPEED = 30
const INFECTION_MULTIPLIER = 1.5
const FRICTION = 500

var infected := false
var speed := BASE_SPEED
var custom_color := Color.YELLOW
var health_multiplier := 1.0
var speed_multiplier := 1.0

@export var min_range: = 4
@export var max_range: = 80
@export var stats: Stats
@export var BULLET: PackedScene

@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var animation_tree: AnimationTree = $AnimationTree
@onready var playback = animation_tree.get("parameters/StateMachine/playback") as AnimationNodeStateMachinePlayback
@onready var ray_cast_2d: RayCast2D = $RayCast2D
@onready var hurtbox: Hurtbox = $Hurtbox
@onready var center: Marker2D = $Center
@onready var navigation_agent_2d: NavigationAgent2D = $Marker2D/NavigationAgent2D
@onready var marker_2d: Marker2D = $Marker2D
@onready var attack_timer: Timer = $AttackTimer

func _ready() -> void:
	stats = stats.duplicate()
	hurtbox.hurt.connect(take_hit.call_deferred)
	stats.no_health.connect(die)
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
	attack_timer.wait_time *= 0.5

func get_room():
	return get_parent().get_parent()

func get_player() -> Player:
	return get_tree().get_first_node_in_group("player")

func is_player_in_range() -> bool:
	var result = false
	var player: = get_player()
	if player is Player:
		var distance_to_player = global_position.distance_to(player.global_position)
		if distance_to_player < max_range and distance_to_player > min_range: 
			result = true
	return result
	
func can_see_player() -> bool:
	if not is_player_in_range(): return false
	var player: = get_player()
	ray_cast_2d.target_position = player.global_position - global_position
	ray_cast_2d.force_raycast_update()
	var has_los_to_player: = not ray_cast_2d.is_colliding()
	return has_los_to_player
