class_name Hitbox extends Area2D

@export var damage: float = 1.0
@export var infection_power := 0
@export var knockback_amount: float = 100.0
@export var knockback_direction: Vector2
@export var source_faction := "neutral"
@export var source_is_projectile := false
@export var source_luck := 0.0
var status_payloads: Array[StatusPayload] = []
