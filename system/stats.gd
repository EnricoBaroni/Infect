class_name Stats extends Resource

@export var health: = 1 :
	set(value):
		var previous_health = health
		health = value
		if health != previous_health: health_changed.emit(health)
		if health <= 0: no_health.emit()

@export var max_health := 1:
	set(value):
		var previous_max_health = max_health
		max_health = value
		if max_health != previous_max_health:
			max_health_changed.emit(max_health)
@export var move_speed := 100.0
@export var damage := 1.0
@export var fire_rate := 0.6
@export var bullet_speed := 150.0
@export var range := 150.0

signal health_changed()
signal max_health_changed()
signal no_health()
