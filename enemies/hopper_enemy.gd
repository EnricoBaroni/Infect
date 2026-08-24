extends EnemyBase

const FRICTION = 500

var custom_color := Color.PINK
var health_multiplier := 1.0
var speed_multiplier := 1.0

# Spawn tier metadata — based on Isaac Leaper (Caves/Catacombs through Depths, Chapter 2+)
@export var spawn_tier_min: int = 2
@export var spawn_tier_max: int = 4
@export var spawn_weight: int = 6

@export var min_range: float = 4.0
@export var max_range: float = 80.0
