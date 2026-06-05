extends Control

@export var player_stats: Stats

@onready var empty_hearts: TextureRect = $EmptyHearts
@onready var full_hearts: TextureRect = $FullHearts
@onready var damage_label = $DamageLabel
@onready var fire_rate_label = $FireRateLabel
@onready var speed_label = $SpeedLabel
@onready var range_label = $RangeLabel
@onready var drops_label = $DropsLabel

func _ready() -> void:
	player_stats.max_health_changed.connect(set_empty_hearts)
	player_stats.health_changed.connect(set_full_hearts)
	set_empty_hearts(player_stats.max_health)
	set_full_hearts(player_stats.health)

func _process(_delta):
	damage_label.text = "⚔ " + str(player_stats.damage)
	fire_rate_label.text = "🔥 " + str(player_stats.fire_rate)
	speed_label.text = "👟 " + str(player_stats.move_speed)
	range_label.text = "🏹 " + str(player_stats.range)
	drops_label.text = "🧪 " + str(Global.drops)

func set_empty_hearts(value: int) -> void:
	empty_hearts.size.x = value * 15
	
func set_full_hearts(value: int) -> void:
	full_hearts.size.x = value * 15
