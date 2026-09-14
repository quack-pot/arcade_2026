class_name StateMachine
extends Node

var _active_state: State
var _states: Dictionary[String, State]

func _init(
	states: Dictionary[String, State],
	initial_state_key: String,
) -> void:
	_states = states
	
	for key in _states:
		_states[key].transition_signal.connect(_on_transition)
	
	_active_state = _states.get(initial_state_key)
	assert(_active_state != null, "Initial state does not exist with key!")
	
	_active_state.enter()

func _process(delta: float) -> void:
	_active_state.process(delta)

func _physics_process(delta: float) -> void:
	_active_state.physics_process(delta)

func _on_transition(from: State, to: String) -> void:
	var next_state: State = _states.get(to)
	assert(next_state != null, "Next state does not exist with key!")
	
	_active_state.exit()
	_active_state = next_state
	_active_state.enter()
