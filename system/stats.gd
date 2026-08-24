class_name Stats extends Resource

var _health: float = 1.0
var _max_health: float = 1.0

@export var health: float:
	get:
		return _health
	set(value):
		var previous_health: float = _health
		_health = value
		if _health != previous_health:
			health_changed.emit(_health)
		if _health <= 0.0:
			no_health.emit()

@export var max_health: float:
	get:
		return _max_health
	set(value):
		var previous_max_health: float = _max_health
		_max_health = value
		if _max_health != previous_max_health:
			max_health_changed.emit(_max_health)
@export var move_speed := 100.0
@export var damage := 1.0
@export var fire_rate := 0.6
@export var bullet_speed := 150.0
@export var range := 150.0
@export var luck := 0.0

signal health_changed(value: float)
signal max_health_changed(value: float)
signal no_health()
