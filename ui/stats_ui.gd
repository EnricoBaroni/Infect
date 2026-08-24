extends Control

const STAT_FEEDBACK_DURATION := 1.2

@export var player_stats: Stats

@onready var empty_hearts: TextureRect = $EmptyHearts
@onready var full_hearts: TextureRect = $FullHearts
@onready var damage_label: Label = $DamageLabel
@onready var fire_rate_label: Label = $FireRateLabel
@onready var speed_label: Label = $SpeedLabel
@onready var range_label: Label = $RangeLabel
@onready var luck_label: Label = $LuckLabel
@onready var drops_label: Label = $DropsLabel
@onready var damage_delta_label: Label = $DamageDeltaLabel
@onready var fire_rate_delta_label: Label = $FireRateDeltaLabel
@onready var speed_delta_label: Label = $SpeedDeltaLabel
@onready var range_delta_label: Label = $RangeDeltaLabel
@onready var luck_delta_label: Label = $LuckDeltaLabel
@onready var item_panel: PanelContainer = $ItemAcquisitionPanel
@onready var item_name_label: Label = $ItemAcquisitionPanel/VBoxContainer/ItemNameLabel
@onready var item_description_label: Label = $ItemAcquisitionPanel/VBoxContainer/ItemDescriptionLabel
@onready var item_effects_label: Label = $ItemAcquisitionPanel/VBoxContainer/ItemEffectsLabel
@onready var item_hide_timer: Timer = $ItemAcquisitionHideTimer

var _last_damage: float = INF
var _last_fire_rate: float = INF
var _last_speed: float = INF
var _last_range: float = INF
var _last_luck: float = INF
var _delta_expiry_by_label: Dictionary = {}

func _ready() -> void:
	_bind_event_bus()
	item_panel.visible = false
	item_hide_timer.one_shot = true
	item_hide_timer.timeout.connect(_hide_item_panel)
	bind_player_stats()

func _bind_event_bus() -> void:
	if not EventBus.item_collected.is_connected(_on_item_collected):
		EventBus.item_collected.connect(_on_item_collected)

func bind_player_stats() -> void:
	var player_node: Player = get_tree().get_first_node_in_group("player") as Player
	if player_node and player_node.stats:
		player_stats = player_node.stats

	if player_stats == null:
		return

	if not player_stats.max_health_changed.is_connected(set_empty_hearts):
		player_stats.max_health_changed.connect(set_empty_hearts)
	if not player_stats.health_changed.is_connected(set_full_hearts):
		player_stats.health_changed.connect(set_full_hearts)
	set_empty_hearts(player_stats.max_health)
	set_full_hearts(player_stats.health)
	_capture_baseline_stats()

func set_empty_hearts(value: float) -> void:
	empty_hearts.size.x = value * 15.0

func set_full_hearts(value: float) -> void:
	full_hearts.size.x = value * 15.0

func _process(_delta: float) -> void:
	if player_stats == null:
		bind_player_stats()
		if player_stats == null:
			return

	_update_stat_display()
	_update_stat_feedback()
	drops_label.text = "🧪 " + str(Global.drops)
	_update_delta_visibility()

func _update_stat_display() -> void:
	damage_label.text = "⚔ " + _format_stat(player_stats.damage)
	fire_rate_label.text = "🔥 " + _format_stat(player_stats.fire_rate)
	speed_label.text = "👟 " + _format_stat(player_stats.move_speed)
	range_label.text = "🏹 " + _format_stat(player_stats.range)
	luck_label.text = "🍀 " + _format_stat(player_stats.luck)

func _capture_baseline_stats() -> void:
	_last_damage = player_stats.damage
	_last_fire_rate = player_stats.fire_rate
	_last_speed = player_stats.move_speed
	_last_range = player_stats.range
	_last_luck = player_stats.luck

func _update_stat_feedback() -> void:
	_check_stat_change("damage", player_stats.damage, _last_damage, damage_delta_label)
	_check_stat_change("fire_rate", player_stats.fire_rate, _last_fire_rate, fire_rate_delta_label)
	_check_stat_change("speed", player_stats.move_speed, _last_speed, speed_delta_label)
	_check_stat_change("range", player_stats.range, _last_range, range_delta_label)
	_check_stat_change("luck", player_stats.luck, _last_luck, luck_delta_label)

func _check_stat_change(key: String, current_value: float, previous_value: float, label: Label) -> void:
	if is_inf(previous_value):
		_set_delta_label(label, "", false)
		_delta_expiry_by_label[key] = 0.0
		return

	if is_equal_approx(current_value, previous_value):
		return

	var delta: float = current_value - previous_value
	_set_delta_label(label, _format_delta(delta), delta >= 0.0)
	_delta_expiry_by_label[key] = Time.get_ticks_msec() / 1000.0 + STAT_FEEDBACK_DURATION

	match key:
		"damage":
			_last_damage = current_value
		"fire_rate":
			_last_fire_rate = current_value
		"speed":
			_last_speed = current_value
		"range":
			_last_range = current_value
		"luck":
			_last_luck = current_value

func _update_delta_visibility() -> void:
	var now: float = Time.get_ticks_msec() / 1000.0
	_update_delta_label_visibility("damage", damage_delta_label, now)
	_update_delta_label_visibility("fire_rate", fire_rate_delta_label, now)
	_update_delta_label_visibility("speed", speed_delta_label, now)
	_update_delta_label_visibility("range", range_delta_label, now)
	_update_delta_label_visibility("luck", luck_delta_label, now)

func _update_delta_label_visibility(key: String, label: Label, now: float) -> void:
	var expiry: float = _delta_expiry_by_label.get(key, 0.0)
	if expiry > 0.0 and now <= expiry:
		label.visible = true
	else:
		label.visible = false

func _set_delta_label(label: Label, text: String, positive: bool) -> void:
	label.text = text
	label.visible = text != ""
	label.add_theme_color_override("font_color", Color(0.4, 1.0, 0.4) if positive else Color(1.0, 0.45, 0.45))

func _format_delta(delta: float) -> String:
	return "%+.2f" % delta

func _format_stat(value: float) -> String:
	if absf(value - roundf(value)) < 0.001:
		return str(int(roundf(value)))
	return "%0.2f" % value

func _on_item_collected(payload: Dictionary) -> void:
	var item: ItemData = payload.get("item", null)
	if item == null:
		return

	item_name_label.text = item.name if item.name != "" else str(item.id)
	item_description_label.text = item.description if item.description != "" else "No description."
	item_effects_label.text = _build_stats_text(item)
	item_panel.visible = true
	item_hide_timer.start(2.8)

func _hide_item_panel() -> void:
	item_panel.visible = false

func _build_stats_text(item: ItemData) -> String:
	var lines: Array[String] = []
	for effect in item.effects:
		if effect == null:
			continue
		var effect_line: String = _describe_effect(effect)
		if effect_line != "":
			lines.append(effect_line)

	if lines.is_empty():
		return item.description if item.description != "" else "Item acquired."

	return "\n".join(lines)

func _describe_effect(effect: EffectData) -> String:
	var effect_class_name := effect.get_class()
	match effect_class_name:
		"DamageUpEffect":
			return "+Damage"
		"HealthUpEffect":
			return "+Health"
		"MoveSpeedUpEffect":
			return "+Speed"
		"FireRateUpEffect":
			return "+Fire Rate"
		"RangeUpEffect":
			return "+Range"
		"LuckUpEffect":
			return "+Luck"
		"PiercingProjectilesEffect":
			return "+Pierce"
		"HomingProjectilesEffect":
			return "Homing"
		"ExplosiveProjectilesEffect":
			return "Explosive"
		"SplitShotsEffect":
			return "Split Shots"
		"DirectionalShotAppenderEffect":
			return "Additional shots"
		"CadenceShotEffect":
			return "Cadence shots"
		_:
			return ""
