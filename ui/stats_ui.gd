extends Control

@export var player_stats: Stats

@onready var empty_hearts: TextureRect = $EmptyHearts
@onready var full_hearts: TextureRect = $FullHearts
@onready var damage_label: Label = $DamageLabel
@onready var fire_rate_label: Label = $FireRateLabel
@onready var speed_label: Label = $SpeedLabel
@onready var range_label: Label = $RangeLabel
@onready var drops_label: Label = $DropsLabel

func _ready() -> void:
	bind_player_stats()

func bind_player_stats() -> void:
	var player_node: Player = get_tree().get_first_node_in_group("player") as Player
	if player_node and player_node.stats:
		player_stats = player_node.stats

	if player_stats == null:
		return

	player_stats.max_health_changed.connect(set_empty_hearts)
	player_stats.health_changed.connect(set_full_hearts)
	set_empty_hearts(player_stats.max_health)
	set_full_hearts(player_stats.health)

func _process(_delta: float) -> void:
	if player_stats == null:
		bind_player_stats()
		if player_stats == null:
			return

	damage_label.text = "⚔ " + str(player_stats.damage)
	fire_rate_label.text = "🔥 " + str(player_stats.fire_rate)
	speed_label.text = "👟 " + str(player_stats.move_speed)
	range_label.text = "🏹 " + str(player_stats.range)
	drops_label.text = "🧪 " + str(Global.drops)

func set_empty_hearts(value: float) -> void:
	empty_hearts.size.x = value * 15.0
	
func set_full_hearts(value: float) -> void:
	full_hearts.size.x = value * 15.0
