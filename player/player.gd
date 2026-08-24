class_name Player extends CharacterBody2D

const SPEED = 100
const EFFECT_RUNTIME_SYSTEM_SCRIPT = preload("res://player/systems/effect_runtime_system.gd")
const ATTACK_EVALUATION_SYSTEM_SCRIPT = preload("res://player/systems/attack_evaluation_system.gd")
const PROJECTILE_SYSTEM_SCRIPT = preload("res://player/systems/projectile_system.gd")
const WEAPON_SYSTEM_SCRIPT = preload("res://player/systems/weapon_system.gd")
const COMPANION_SYSTEM_SCRIPT = preload("res://player/systems/companion_system.gd")
const MUTANT_SPIDER_ITEM = preload("res://items/data/mutant_spider.tres")
@export var BULLET: PackedScene
@export var stats: Stats

var input_vector: Vector2 = Vector2.ZERO
var attack_vector: Vector2 = Vector2.ZERO
var infection_mode := false

@onready var body_animation_tree: AnimationTree = $Body/BodyAnimationTree
@onready var head_animation_tree: AnimationTree = $Head/HeadAnimationTree
@onready var fire_rate: Timer = $FireRate
@onready var shoot_marker: Marker2D = $ShootMarker
@onready var hurtbox: Hurtbox = $Hurtbox
@onready var blink_animation_player: AnimationPlayer = $BlinkAnimationPlayer
@onready var hurt_audio_stream_player: AudioStreamPlayer2D = $HurtAudioStreamPlayer
@onready var inventory: InventorySystem = $InventorySystem
@onready var stat_evaluation: StatEvaluationSystem = $StatEvaluationSystem
@onready var weapon_system: WeaponSystem = get_node_or_null("WeaponSystem")

@onready var body_playback: AnimationNodeStateMachinePlayback = body_animation_tree.get("parameters/StateMachine/playback") as AnimationNodeStateMachinePlayback
@onready var head_playback: AnimationNodeStateMachinePlayback = head_animation_tree.get("parameters/StateMachine/playback") as AnimationNodeStateMachinePlayback

func _ready() -> void:
	_ensure_companion_system()
	_ensure_effect_runtime_system()
	_ensure_attack_evaluation_system()
	_ensure_projectile_system()
	_ensure_weapon_system()
	weapon_system = get_node_or_null("WeaponSystem")

	if stat_evaluation:
		if stat_evaluation.current_stats:
			stats = stat_evaluation.current_stats
		elif stat_evaluation.base_stats:
			stats = stat_evaluation.base_stats
		stat_evaluation.recalculate()

	if stats == null:
		return

	if Global.start_with_mutant_spider and not inventory.has_passive_item(MUTANT_SPIDER_ITEM):
		inventory.add_passive_item(MUTANT_SPIDER_ITEM.duplicate())
		Global.start_with_mutant_spider = false

	hurtbox.hurt.connect(take_hit.call_deferred)
	stats.no_health.connect(die)

func _physics_process(delta: float) -> void:
	if stats == null:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	var bodyState: StringName = body_playback.get_current_node()
	match bodyState:
		"MoveState": move_state(delta)
	var headState: StringName = head_playback.get_current_node()
	match headState:
		"AttackState": attack_state(delta)
	
	infection_mode = Input.is_action_pressed("infection_mode")
	velocity = input_vector * stats.move_speed
	move_and_slide()

func die() -> void:
	hide()
	remove_from_group("player")
	EventBus.emit_player_died({
		"player": self,
		"floor_number": Global.floor_number,
		"position": global_position,
	})
	# Gameplay is frozen by DeathScreen._on_player_died via the signal above.

func take_hit(other_hitbox: Hitbox) -> void:
	var preprocess_payload := {
		"player": self,
		"source": other_hitbox,
		"damage": other_hitbox.damage,
		"position": global_position
	}
	EventBus.emit_player_damage_preprocess(preprocess_payload)
	var resolved_damage: float = maxf(0.0, float(preprocess_payload.get("damage", other_hitbox.damage)))
	if resolved_damage <= 0.0:
		return

	hurt_audio_stream_player.play()
	stats.health -= resolved_damage
	EventBus.emit_player_damaged({
		"player": self,
		"source": other_hitbox,
		"damage": resolved_damage,
		"current_health": stats.health,
		"max_health": stats.max_health,
		"position": global_position
	})
	blink_animation_player.play("blink")

func _ensure_effect_runtime_system() -> void:
	if has_node("EffectRuntimeSystem"):
		return

	var effect_runtime_system: Node = EFFECT_RUNTIME_SYSTEM_SCRIPT.new()
	effect_runtime_system.name = "EffectRuntimeSystem"
	add_child(effect_runtime_system)

func _ensure_companion_system() -> void:
	if has_node("CompanionSystem"):
		return

	var companion_system: Node = COMPANION_SYSTEM_SCRIPT.new()
	companion_system.name = "CompanionSystem"
	add_child(companion_system)

func _ensure_weapon_system() -> void:
	if has_node("WeaponSystem"):
		return

	var new_weapon_system: Node = WEAPON_SYSTEM_SCRIPT.new()
	new_weapon_system.name = "WeaponSystem"
	add_child(new_weapon_system)

func _ensure_attack_evaluation_system() -> void:
	if has_node("AttackEvaluationSystem"):
		return

	var new_attack_evaluation_system: Node = ATTACK_EVALUATION_SYSTEM_SCRIPT.new()
	new_attack_evaluation_system.name = "AttackEvaluationSystem"
	add_child(new_attack_evaluation_system)

func _ensure_projectile_system() -> void:
	if has_node("ProjectileSystem"):
		return

	var new_projectile_system: Node = PROJECTILE_SYSTEM_SCRIPT.new()
	new_projectile_system.name = "ProjectileSystem"
	add_child(new_projectile_system)

func move_state(delta: float) -> void:
	input_vector = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if input_vector != Vector2.ZERO:
		var move_direction_vector: Vector2 = Vector2(input_vector.x, -input_vector.y)
		update_blend_positions(move_direction_vector, "Body")

func attack_state(delta: float) -> void:
	attack_vector = Input.get_vector("attack_left", "attack_right", "attack_up", "attack_down")
	if attack_vector != Vector2.ZERO:
		var attack_direction_vector: Vector2 = Vector2(attack_vector.x, -attack_vector.y)
		update_blend_positions(attack_direction_vector, "Head")
	if weapon_system:
		weapon_system.try_fire(
			attack_vector,
			infection_mode,
			stats,
			velocity,
			BULLET,
			delta
		)

func update_blend_positions(direction_vector: Vector2, type: String) -> void:
	match type:
		"Body":
			body_animation_tree.set("parameters/StateMachine/MoveState/StandState/blend_position", direction_vector)
			body_animation_tree.set("parameters/StateMachine/MoveState/RunState/blend_position", direction_vector)
		"Head":
			head_animation_tree.set("parameters/StateMachine/AttackState/StandState/blend_position", direction_vector)
			head_animation_tree.set("parameters/StateMachine/AttackState/AttackState/blend_position", direction_vector)
