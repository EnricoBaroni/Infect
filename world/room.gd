extends Node2D

@onready var enemies = $Enemies
@onready var doors := [
	$Door,
	$Door2,
	$Door3,
	$Door4
]

var active := false
var enemy_templates := []
@export var combat_room := true

func _ready():
	for enemy in enemies.get_children():
		enemy_templates.append({
			"scene": load(enemy.scene_file_path),
			"position": enemy.position,
			"name": enemy.name
		})

func _process(_delta):
	if not combat_room:
		open_doors()
		return
	if has_enemies():
		close_doors()
	else:
		open_doors()

func activate():
	active = true

func deactivate():
	active = false

func open_doors():
	for door in doors:
		if door.has_destination():
			door.open()
		else:
			door.close()

func close_doors():
	for door in doors:
		door.close()

func has_enemies() -> bool:
	return enemies.get_child_count() > 0

func respawn_enemies():
	for enemy in enemies.get_children():
		enemy.queue_free()
		
	for template in enemy_templates:
		var enemy = template["scene"].instantiate()
		
		var health_multiplier = 1.0 + (Global.difficulty_level - 1) * 0.25
		var speed_multiplier = 1.0 + (Global.difficulty_level - 1) * 0.05

		enemy.health_multiplier = health_multiplier
		enemy.speed_multiplier = speed_multiplier
		
		enemy.position = template["position"]
		enemy.name = template["name"]
		
		enemies.add_child(enemy)
