extends Node2D

@onready var starting_room = $Room1

func _ready():
	starting_room.activate()
