extends StaticBody2D

@export var GRASS_EFFECT: PackedScene

@onready var hurtbox: Hurtbox = $Hurtbox

func _ready() -> void:
	hurtbox.hurt.connect(_on_hurt)

func _on_hurt(other_hitbox: Hitbox) -> void:
	if other_hitbox.source_faction != "player":
		return

	var grass_effect_instance = GRASS_EFFECT.instantiate()
	grass_effect_instance.global_position = global_position
	get_tree().current_scene.add_child(grass_effect_instance)
	queue_free()
