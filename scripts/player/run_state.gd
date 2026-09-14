class_name RunState
extends State

func enter() -> void:
	pass

func exit() -> void:
	pass

func process(delta_time: float) -> void:
	var move: Vector2 = Input.get_vector("Left", "Right", "Down", "Up")

func physics_process(delta_time: float) -> void:
	pass
