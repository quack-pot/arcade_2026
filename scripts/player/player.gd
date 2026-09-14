class_name Player
extends Node

var state_machine: StateMachine

@export var player_id: int = 1

const PLAYER_IDLE_STATE: String = "Idle"
const PLAYER_RUN_STATE: String = "Run"
const PLAYER_STUN_STATE: String = "Stun"

func _ready() -> void:
	await owner.ready
	
	state_machine = StateMachine.new({
		PLAYER_IDLE_STATE: IdleState.new(),
		PLAYER_RUN_STATE: RunState.new(),
		PLAYER_STUN_STATE: StunState.new(),
	}, PLAYER_IDLE_STATE)
