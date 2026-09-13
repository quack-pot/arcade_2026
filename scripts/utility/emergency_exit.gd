extends Node

func _input(event: InputEvent) -> void:
	if event.is_action("Escape", true):
		get_tree().change_scene_to_file("res://scenes/main_menu.scn")
	elif event.is_action("Restart", true):
		get_tree().reload_current_scene()
