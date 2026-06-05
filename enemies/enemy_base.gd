extends CharacterBody2D
class_name EnemyBase

const DROP = preload("uid://dhaw4gt67tdhp")
const HIT_EFFECT = preload("uid://ceyipwdhuape4")
const DEATH_EFFECT = preload("uid://dwdgco8qr3k4f")

var infected := false

@export var stats: Stats

@onready var hurtbox: Hurtbox = $Hurtbox
@onready var center: Marker2D = $Center

func _ready() -> void:
	stats = stats.duplicate()
	hurtbox.hurt.connect(take_hit.call_deferred)
	stats.no_health.connect(die)

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
	on_hit(other_hitbox)

func infect() -> void:
	if infected:
		return
	infected = true
	modulate = Color.GREEN
	on_infected()

func on_infected() -> void:
	pass

func get_room():
	return get_parent().get_parent()

func get_player() -> Player:
	return get_tree().get_first_node_in_group("player")

func on_hit(other_hitbox: Hitbox) -> void:
	velocity = other_hitbox.knockback_direction * other_hitbox.knockback_amount
	if has_method("play_hit_animation"):
		play_hit_animation()

func play_hit_animation() -> void:
	pass

func is_player_in_range(min_range: float, max_range: float) -> bool:
	var player = get_player()

	if player is Player:
		var distance = global_position.distance_to(player.global_position)
		return distance < max_range and distance > min_range

	return false
