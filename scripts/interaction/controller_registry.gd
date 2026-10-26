extends Node

var controller_ids: Array[int] = [-1, -1]

func set_controller_id(player: GameManager.PlayerId, id: int) -> void:
	if player >= len(controller_ids):
		push_warning("Player ID out of bounds:", player)
	
	controller_ids[player] = id

func get_controller_id(player: GameManager.PlayerId) -> int:
	if player >= len(controller_ids):
		push_warning("Player ID out of bounds:", player)
		return -1
	
	return controller_ids[player]
