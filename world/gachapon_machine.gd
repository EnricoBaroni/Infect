extends Area2D

@export var cost := 1
const UPGRADE_PICKUP = preload("uid://tq8rii0lj6x1")

var player_inside := false

@onready var press_e: Label = $PressE

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	press_e.visible = false
	press_e.text = "Press E\n" + str(cost) + " 🧪"

func _process(_delta: float) -> void:
	if not player_inside:
		return
	if Input.is_action_just_pressed("interact"):
		use_machine()

func use_machine() -> void:
	print("USE MACHINE")
	if Global.drops < cost:
		print("NOT ENOUGH DROPS")
		return
	Global.drops -= cost
	var pickup = UPGRADE_PICKUP.instantiate()
	var item_data := preload("res://items/data/sad_onion.tres").duplicate()
	pickup.item_data = item_data
	pickup.upgrade_type = 0
	get_tree().current_scene.add_child(pickup)
	pickup.global_position = global_position + Vector2(48, 0)
	print("PURCHASE")

func _on_body_entered(body: Node2D) -> void:
	if body.name != "Player":
		return
	player_inside = true
	press_e.visible = true

func _on_body_exited(body: Node2D) -> void:
	if body.name != "Player":
		return
	player_inside = false
	press_e.visible = false
