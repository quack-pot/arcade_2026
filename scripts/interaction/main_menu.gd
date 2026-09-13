extends Node

@export var transition_wait_time: float = 1.5
@export var transition_speed_scale: float = 10.0
@export var fade_player: AnimationPlayer = null

var loading_game: bool = false

func _input(event: InputEvent) -> void:
	if loading_game:
		return
	
	var is_start_event: bool = !event.is_action("WhiteLeft") && !event.is_action("WhiteRight")
	if is_start_event:
		return
	
	loading_game = true
	if fade_player != null:
		fade_player.play(
			"scene_fade_in",
			-1,
			-absf(transition_speed_scale),
			true
		)
	
	await get_tree().create_timer(transition_wait_time).timeout
	get_tree().change_scene_to_file("res://scenes/game.tscn")
