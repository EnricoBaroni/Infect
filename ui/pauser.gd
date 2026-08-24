extends Node

@onready var pause_audio_stream_player_2d: AudioStreamPlayer2D = $PauseAudioStreamPlayer2D
@onready var unpause_audio_stream_player_2d: AudioStreamPlayer2D = $UnpauseAudioStreamPlayer2D

func _process(delta: float) -> void:
	if Global.is_dead:
		return
	if Input.is_action_just_pressed("ui_cancel"):
		var is_paused = get_tree().paused
		if is_paused: unpause_audio_stream_player_2d.play()
		else: pause_audio_stream_player_2d.play()		
		get_tree().paused = not get_tree().paused
