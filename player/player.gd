class_name Player extends CharacterBody2D

const SPEED = 100
@export var BULLET: PackedScene
@export var stats: Stats

var input_vector: = Vector2.ZERO
var attack_vector: = Vector2.ZERO

@onready var body_animation_tree: AnimationTree = $Body/BodyAnimationTree
@onready var head_animation_tree: AnimationTree = $Head/HeadAnimationTree
@onready var fire_rate: Timer = $FireRate
@onready var shoot_marker: Marker2D = $ShootMarker
@onready var hurtbox: Hurtbox = $Hurtbox
@onready var blink_animation_player: AnimationPlayer = $BlinkAnimationPlayer
@onready var hurt_audio_stream_player: AudioStreamPlayer2D = $HurtAudioStreamPlayer


@onready var body_playback = body_animation_tree.get("parameters/StateMachine/playback") as AnimationNodeStateMachinePlayback
@onready var head_playback = head_animation_tree.get("parameters/StateMachine/playback") as AnimationNodeStateMachinePlayback

func _ready() -> void:
	hurtbox.hurt.connect(take_hit.call_deferred)
	stats.no_health.connect(die)

func _physics_process(delta: float) -> void:
	var bodyState = body_playback.get_current_node()
	match bodyState:
		"MoveState": move_state(delta)
	var headState = head_playback.get_current_node()
	match headState:
		"AttackState": attack_state(delta)
	
	velocity = input_vector * SPEED
	move_and_slide()

func die() -> void:
	hide()
	remove_from_group("player")
	process_mode = Node.PROCESS_MODE_DISABLED

func take_hit(other_hitbox: Hitbox) -> void:
	hurt_audio_stream_player.play()
	stats.health -= other_hitbox.damage
	blink_animation_player.play("blink")

func move_state(delta: float) -> void:
	input_vector = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if input_vector != Vector2.ZERO:
		var move_direction_vector: = Vector2(input_vector.x, -input_vector.y)
		update_blend_positions(move_direction_vector, "Body")

func attack_state(delta: float) -> void:
	attack_vector = Input.get_vector("attack_left", "attack_right", "attack_up", "attack_down")
	if attack_vector != Vector2.ZERO:
		var attack_direction_vector: = Vector2(attack_vector.x, -attack_vector.y)
		update_blend_positions(attack_direction_vector, "Head")
		if fire_rate.is_stopped():
			shoot(attack_direction_vector)

func shoot(direction_vector: Vector2) -> void:
	var bullet_instance = BULLET.instantiate()
	bullet_instance.global_position = shoot_marker.global_position
	bullet_instance.direction = attack_vector
	fire_rate.start(bullet_instance.get_fire_rate())
	get_tree().current_scene.add_child(bullet_instance)

func update_blend_positions(direction_vector: Vector2, type: String) -> void:
	match type:
		"Body":
			body_animation_tree.set("parameters/StateMachine/MoveState/StandState/blend_position", direction_vector)
			body_animation_tree.set("parameters/StateMachine/MoveState/RunState/blend_position", direction_vector)
		"Head":
			head_animation_tree.set("parameters/StateMachine/AttackState/StandState/blend_position", direction_vector)
			head_animation_tree.set("parameters/StateMachine/AttackState/AttackState/blend_position", direction_vector)
