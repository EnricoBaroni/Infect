extends Area2D

@export var cost := 1
const UPGRADE_PICKUP = preload("uid://tq8rii0lj6x1")

var player_inside := false

@onready var press_e: Label = $PressE

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	press_e.visible = false
	press_e.text = "Press E to\n" + "DIFFICULTY +1"

func _process(_delta: float) -> void:
	if not player_inside:
		return
	if Input.is_action_just_pressed("interact"):
		use_machine()

func use_machine() -> void:
	Global.difficulty_level += 1
	press_e.text = "DIFFICULTY " + str(Global.difficulty_level)

func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	player_inside = true
	press_e.visible = true
	press_e.text = "Press E to\nDIFFICULTY +1\n (" + str(Global.difficulty_level) + ")"

func _on_body_exited(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	player_inside = false
	press_e.visible = false
