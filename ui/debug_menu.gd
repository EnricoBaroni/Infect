extends CanvasLayer

const ITEMS_PATH := "res://items/data"

var _panel: Panel
var _search_input: LineEdit
var _items_container: VBoxContainer
var _status_label: Label
var _tooltip_panel: PanelContainer
var _tooltip_label: Label
var _item_buttons: Array[Button] = []

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 100
	_build_ui()
	_build_tooltip()
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
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.05, 0.05, 0.05, 0.85)
	_panel.add_theme_stylebox_override("panel", panel_style)
	_panel.custom_minimum_size = Vector2(304, 196)
	_panel.size = Vector2(304, 196)
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
	title.add_theme_font_size_override("font_size", 12)
	vbox.add_child(title)

	vbox.add_child(HSeparator.new())

	var drops_row := HBoxContainer.new()
	vbox.add_child(drops_row)

	var drops_label := Label.new()
	drops_label.text = "Economy:"
	drops_label.add_theme_font_size_override("font_size", 9)
	drops_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	drops_row.add_child(drops_label)

	var give_drops_btn := Button.new()
	give_drops_btn.text = "+ 10 Drops"
	give_drops_btn.add_theme_font_size_override("font_size", 9)
	give_drops_btn.pressed.connect(_on_give_drops_pressed)
	drops_row.add_child(give_drops_btn)

	var tk_btn := Button.new()
	tk_btn.text = "T.Keeper"
	tk_btn.add_theme_font_size_override("font_size", 9)
	tk_btn.pressed.connect(_on_t_keeper_pressed)
	drops_row.add_child(tk_btn)

	var restart_btn := Button.new()
	restart_btn.text = "Restart Run"
	restart_btn.add_theme_font_size_override("font_size", 9)
	restart_btn.pressed.connect(_on_restart_run_pressed)
	drops_row.add_child(restart_btn)

	vbox.add_child(HSeparator.new())

	_status_label = Label.new()
	_status_label.text = "Items: (loading...)"
	_status_label.add_theme_font_size_override("font_size", 9)
	vbox.add_child(_status_label)

	_search_input = LineEdit.new()
	_search_input.placeholder_text = "Search items..."
	_search_input.text_changed.connect(_on_search_text_changed)
	vbox.add_child(_search_input)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)

	_items_container = VBoxContainer.new()
	_items_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_items_container)

func _build_tooltip() -> void:
	_tooltip_panel = PanelContainer.new()
	var tooltip_style := StyleBoxFlat.new()
	tooltip_style.bg_color = Color(0.03, 0.03, 0.03, 0.92)
	_tooltip_panel.add_theme_stylebox_override("panel", tooltip_style)
	_tooltip_panel.visible = false
	_tooltip_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tooltip_panel.z_index = 1000
	add_child(_tooltip_panel)

	_tooltip_label = Label.new()
	_tooltip_label.add_theme_font_size_override("font_size", 8)
	_tooltip_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_tooltip_label.custom_minimum_size = Vector2(90, 0)
	_tooltip_label.size = Vector2(120, 0)

	_tooltip_panel.add_child(_tooltip_label)

func _load_items() -> void:
	for button in _item_buttons:
		button.queue_free()
	_item_buttons.clear()

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
		btn.add_theme_font_size_override("font_size", 8)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.set_meta("item_name", item_data.name.to_lower())
		btn.mouse_entered.connect(_on_item_mouse_entered.bind(item_data))
		btn.mouse_exited.connect(_on_item_mouse_exited)
		btn.pressed.connect(_on_give_item_pressed.bind(item_data))
		_items_container.add_child(btn)
		_item_buttons.append(btn)
		count += 1

	_status_label.text = "Items (%d) — click to give:" % count
	_apply_item_filter(_search_input.text if _search_input else "")

func _on_give_drops_pressed() -> void:
	Global.drops += 10

func _on_t_keeper_pressed() -> void:
	Global.reset_run_state()
	Global.start_with_mutant_spider = true
	get_tree().reload_current_scene()

func _on_restart_run_pressed() -> void:
	get_tree().paused = false
	Global.reset_run_state()
	get_tree().reload_current_scene()

func _on_search_text_changed(new_text: String) -> void:
	_apply_item_filter(new_text)

func _apply_item_filter(filter_text: String) -> void:
	var needle := filter_text.strip_edges().to_lower()
	for button in _item_buttons:
		var visible := true
		if needle != "":
			var item_name := String(button.get_meta("item_name", button.text)).to_lower()
			visible = item_name.find(needle) != -1
		button.visible = visible
		if not visible and button.has_focus():
			button.release_focus()

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

func _on_item_mouse_entered(item_data: ItemData) -> void:
	_tooltip_label.text = item_data.description if item_data.description != "" else "No description."
	_tooltip_panel.visible = true
	_update_tooltip_position()

func _on_item_mouse_exited() -> void:
	_tooltip_panel.visible = false

func _update_tooltip_position() -> void:
	var viewport_size := get_viewport().get_visible_rect().size
	var mouse_position := get_viewport().get_mouse_position()

	_tooltip_panel.reset_size()

	var tooltip_size := _tooltip_panel.size
	var position := mouse_position + Vector2(6, 6)

	if position.x + tooltip_size.x > viewport_size.x:
		position.x = mouse_position.x - tooltip_size.x - 6

	if position.y + tooltip_size.y > viewport_size.y:
		position.y = mouse_position.y - tooltip_size.y - 6

	position.x = clampf(position.x, 0.0, viewport_size.x - tooltip_size.x)
	position.y = clampf(position.y, 0.0, viewport_size.y - tooltip_size.y)

	_tooltip_panel.position = position
