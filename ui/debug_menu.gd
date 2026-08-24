extends CanvasLayer

const ITEMS_PATH := "res://items/data"

var _panel: Panel
var _items_container: VBoxContainer
var _status_label: Label

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 100
	_build_ui()
	_panel.visible = false
	_load_items()

func _input(event: InputEvent) -> void:
	if Global.is_dead:
		return
	if event is InputEventKey and event.keycode == KEY_F1 and event.pressed and not event.echo:
		_panel.visible = not _panel.visible
		get_viewport().set_input_as_handled()

func _build_ui() -> void:
	_panel = Panel.new()
	_panel.custom_minimum_size = Vector2(360, 0)
	_panel.size = Vector2(360, 620)
	_panel.position = Vector2(8, 8)
	add_child(_panel)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	_panel.add_child(margin)

	var vbox := VBoxContainer.new()
	margin.add_child(vbox)

	var title := Label.new()
	title.text = "DEBUG MENU  [F1 toggle]"
	vbox.add_child(title)

	vbox.add_child(HSeparator.new())

	var drops_row := HBoxContainer.new()
	vbox.add_child(drops_row)

	var drops_label := Label.new()
	drops_label.text = "Economy:"
	drops_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	drops_row.add_child(drops_label)

	var give_drops_btn := Button.new()
	give_drops_btn.text = "+ 10 Drops"
	give_drops_btn.pressed.connect(_on_give_drops_pressed)
	drops_row.add_child(give_drops_btn)

	vbox.add_child(HSeparator.new())

	_status_label = Label.new()
	_status_label.text = "Items: (loading...)"
	vbox.add_child(_status_label)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.custom_minimum_size = Vector2(0, 450)
	vbox.add_child(scroll)

	_items_container = VBoxContainer.new()
	_items_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_items_container)

func _load_items() -> void:
	var dir := DirAccess.open(ITEMS_PATH)
	if dir == null:
		_status_label.text = "Items: (error — path not found)"
		return

	var file_names: PackedStringArray = []
	dir.list_dir_begin()
	while true:
		var file_name := dir.get_next()
		if file_name == "":
			break
		if dir.current_is_dir():
			continue
		if file_name.get_extension() != "tres":
			continue
		file_names.append(file_name)
	dir.list_dir_end()
	file_names.sort()

	var count := 0
	for file_name in file_names:
		var path := ITEMS_PATH + "/" + file_name
		var resource := load(path)
		if not (resource is ItemData):
			continue
		var item_data := resource as ItemData
		var btn := Button.new()
		btn.text = item_data.name if item_data.name != "" else file_name
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.tooltip_text = item_data.description
		btn.pressed.connect(_on_give_item_pressed.bind(item_data))
		_items_container.add_child(btn)
		count += 1

	_status_label.text = "Items (%d) — click to give:" % count

func _on_give_drops_pressed() -> void:
	Global.drops += 10

func _on_give_item_pressed(item_data: ItemData) -> void:
	var player := _get_player()
	if player == null:
		push_warning("DebugMenu: Player not found in group 'player'")
		return
	if player.inventory == null:
		push_warning("DebugMenu: Player inventory is null")
		return
	player.inventory.add_passive_item(item_data.duplicate())

func _get_player() -> Player:
	var players := get_tree().get_nodes_in_group("player")
	if players.is_empty():
		return null
	return players[0] as Player
