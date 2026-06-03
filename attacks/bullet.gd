extends Area2D

@export var SPEED: float = 150.0
@export var DAMAGE: float = 1.0
@export var FIRE_RATE: float = 0.6
@export var MAX_DISTANCE: float = 150
@export var MOVEMENT_INHERITANCE: float = 0.4
@onready var hitbox: Hitbox = $Hitbox

var direction: Vector2 = Vector2.ZERO
var inherited_velocity: Vector2 = Vector2.ZERO
var distance_travelled: float = 0.0
var infection_shot := false

func _ready() -> void:
	area_entered.connect(_on_area_entered)
	if infection_shot:
		modulate = Color.GREEN
		hitbox.infection_power = 1
		hitbox.damage = 0

func _physics_process(delta: float) -> void:
	var movement = (direction * SPEED + inherited_velocity * MOVEMENT_INHERITANCE) * delta
	global_position += movement
	
	hitbox.knockback_direction = direction.normalized()
	
	distance_travelled += movement.length()
	if distance_travelled >= MAX_DISTANCE:
		queue_free()

func get_fire_rate() -> float:
	return FIRE_RATE

func _on_area_entered(area_2d: Area2D) -> void:
	print("area enter")
	if area_2d is not Hurtbox: return
	queue_free()
