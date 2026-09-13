class_name StateMachine
extends Node

var active_state: State
var states: Dictionary[String, State] = {}

func _ready() -> void:
	await owner.ready
	
	active_state.enter()

func _process(delta: float) -> void:
	active_state.process(delta)

func _physics_process(delta: float) -> void:
	active_state.physics_process(delta)
