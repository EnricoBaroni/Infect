extends Control

@export var player_stats: Stats

@onready var empty_hearts: TextureRect = $EmptyHearts
@onready var full_hearts: TextureRect = $FullHearts
@onready var damage_label: Label = $DamageLabel
@onready var fire_rate_label: Label = $FireRateLabel
@onready var speed_label: Label = $SpeedLabel
@onready var range_label: Label = $RangeLabel
@onready var drops_label: Label = $DropsLabel
@onready var damage_delta: Label = $DamageDelta
@onready var fire_rate_delta: Label = $FireRateDelta
@onready var speed_delta: Label = $SpeedDelta
@onready var range_delta: Label = $RangeDelta
@onready var luck_label: Label = $LuckLabel
@onready var luck_delta: Label = $LuckDelta

var previous_damage := 0.0
var previous_fire_rate := 0.0
var previous_speed := 0.0
var previous_range := 0.0
var previous_luck := 0.0

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
	previous_damage = player_stats.damage
	previous_fire_rate = player_stats.fire_rate
	previous_speed = player_stats.move_speed
	previous_range = player_stats.range
	previous_luck = player_stats.luck

func _process(_delta: float) -> void:
	if player_stats == null:
		bind_player_stats()
		if player_stats == null:
			return

	damage_label.text = "⚔ " + str(player_stats.damage)
	fire_rate_label.text = "🔥 " + str(player_stats.fire_rate)
	speed_label.text = "👟 " + str(player_stats.move_speed)
	range_label.text = "🏹 " + str(player_stats.range)
	luck_label.text = "🍀 " + str(player_stats.luck)
	drops_label.text = "🧪 " + str(Global.drops)
	_update_delta(damage_delta, player_stats.damage - previous_damage)
	_update_delta(fire_rate_delta, previous_fire_rate - player_stats.fire_rate)
	_update_delta(speed_delta, player_stats.move_speed - previous_speed)
	_update_delta(range_delta, player_stats.range - previous_range)
	_update_delta(luck_delta, player_stats.luck - previous_luck)

	previous_damage = player_stats.damage
	previous_fire_rate = player_stats.fire_rate
	previous_speed = player_stats.move_speed
	previous_range = player_stats.range
	previous_luck = player_stats.luck

func set_empty_hearts(value: float) -> void:
	empty_hearts.size.x = value * 15.0
	
func set_full_hearts(value: float) -> void:
	full_hearts.size.x = value * 15.0

func _update_delta(label: Label, delta: float) -> void:
	if is_zero_approx(delta):
		return

	label.visible = true
	label.text = "%+.2f" % delta

	if delta > 0:
		label.modulate = Color.LIME_GREEN
	else:
		label.modulate = Color.RED

	await get_tree().create_timer(1.2).timeout

	label.visible = false
