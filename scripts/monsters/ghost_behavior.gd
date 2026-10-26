class_name GhostBehavior
extends Node
## Base class for ghost AI. Add a subclass as a child of a Ghost.
## Override choose_target() to decide where the ghost wants to go.

## Seconds between target re-evaluations.
@export var think_interval: float = 1.0
## Random +/- seconds added to the interval so ghosts don't all think in lockstep.
@export var think_jitter: float = 0.25

var ghost: Ghost


func setup(p_ghost: Ghost) -> void:
	ghost = p_ghost


## Return the world-space position the ghost should navigate toward.
## player_positions contains one entry per active player.
func choose_target(_player_positions: Array[Vector3]) -> Vector3:
	return ghost.global_position


## Called once each time the ghost finishes its current path.
func on_target_reached() -> void:
	pass


func get_next_think_delay() -> float:
	return maxf(0.05, think_interval + randf_range(-think_jitter, think_jitter))


## Called every physics frame by the Ghost. Use for timers/state transitions.
func physics_update(_delta: float) -> void:
	pass


## Multiplies the ghost's move_speed (e.g. charging).
func get_speed_multiplier() -> float:
	return 1.0
