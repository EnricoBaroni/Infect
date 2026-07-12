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
var custom_color: Color = Color.WHITE
var enemy_shot := false

func _ready() -> void:
	modulate = custom_color
	hitbox.area_entered.connect(_on_hitbox_area_entered)
	body_entered.connect(_on_body_entered)
	if enemy_shot:
		hitbox.collision_layer = 8
		hitbox.collision_mask = 8
	
	if infection_shot:
		modulate = Color.GREEN
		hitbox.infection_power = 1
		hitbox.damage = 0

func setup_attack(attack_data: AttackData) -> void:
	direction = attack_data.direction
	inherited_velocity = attack_data.inherited_velocity
	SPEED = attack_data.speed
	DAMAGE = attack_data.damage
	MAX_DISTANCE = attack_data.max_distance
	MOVEMENT_INHERITANCE = attack_data.movement_inheritance
	infection_shot = attack_data.infection_shot
	hitbox.damage = DAMAGE

func _physics_process(delta: float) -> void:
	var movement = (direction * SPEED + inherited_velocity * MOVEMENT_INHERITANCE) * delta
	global_position += movement
	
	hitbox.knockback_direction = direction.normalized()
	
	distance_travelled += movement.length()
	if distance_travelled >= MAX_DISTANCE:
		queue_free()

func get_fire_rate() -> float:
	return FIRE_RATE

func _on_body_entered(body: Node2D) -> void:
	queue_free()

func _on_hitbox_area_entered(area: Area2D) -> void:
	if area is not Hurtbox: return
	queue_free()
