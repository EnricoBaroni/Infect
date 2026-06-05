extends Node2D

@onready var starting_room = $Room1
@onready var drops_label: Label = $CanvasLayer/StatsUI/DropsLabel
@onready var rooms = [
	$Room1,
	$Room2,
	$Room3,
	$Room4,
	$Room5
]

func _ready():
	starting_room.activate()

func _process(_delta):
	drops_label.text = str(Global.drops)

func respawn_all_enemies():
	for room in rooms:
		room.respawn_enemies()
