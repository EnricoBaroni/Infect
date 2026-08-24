extends CanvasLayer

# DeathScreen — shown when the player dies.
# Freezes gameplay via get_tree().paused. Stays usable because process_mode = ALWAYS.
# Restarting resets all Global run state then reloads the current scene.
#
# Extension points for future Isaac-like death summary:
#   - Add exported fields to the _payload dict emitted by EventBus.player_died
#     (floor_number, items collected, killer, etc.) — these arrive here as _last_death_payload.
#   - Add Label nodes for floor, build, killer and populate them in _on_player_died().
#   - No structural changes to the freeze/restart flow are required.

var _last_death_payload: Dictionary = {}

func _ready() -> void:
	hide()
	EventBus.player_died.connect(_on_player_died)
	$CenterContainer/VBoxContainer/RestartButton.pressed.connect(_on_restart_pressed)

func _on_player_died(payload: Dictionary) -> void:
	_last_death_payload = payload
	Global.is_dead = true
	show()
	get_tree().paused = true

func _on_restart_pressed() -> void:
	get_tree().paused = false
	Global.reset_run_state()
	get_tree().reload_current_scene()
