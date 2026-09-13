class_name State
extends Node

var _fsm_name: String

func _init(fsm_name: String) -> void:
	_fsm_name = fsm_name

signal _transition_signal(from: State, to: String, fsm_id: String)

func _request_transition(to: String) -> void:
	_transition_signal.emit(self, to, _fsm_name)

func enter() -> void:
	pass

func exit() -> void:
	pass

func process(delta_time: float) -> void:
	pass

func physics_process(delta_time: float) -> void:
	pass
