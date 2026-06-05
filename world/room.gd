extends Node2D

@onready var enemies = $Enemies
@onready var doors := [
	$Door,
	$Door2,
	$Door3,
	$Door4
]

var active := false
@export var combat_room := true

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

func close_doors():
	for door in doors:
		door.close()

func has_enemies() -> bool:
	return enemies.get_child_count() > 0
