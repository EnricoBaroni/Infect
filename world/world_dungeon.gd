extends Node2D

@onready var starting_room = $Room1
@onready var drops_label: Label = $CanvasLayer/StatsUI/DropsLabel

func _ready():
	starting_room.activate()

func _process(_delta):
	drops_label.text = str(Global.drops)
