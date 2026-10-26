class_name Ghost
extends CharacterBody3D
## Owns movement, navmesh pathing, and the think timer.
## All decision-making is delegated to a GhostBehavior child node.
##
## Scene layout:
##   Ghost (CharacterBody3D, this script)
##   ├─ CollisionShape3D
##   ├─ NavigationAgent3D
##   ├─ (mesh / model)
##   └─ AvoidPlayersBehavior (or any GhostBehavior subclass)

@export var move_speed: float = 3.0
@export var turn_speed: float = 8.0
## Players are found through this group unless a provider is set.
@export var player_group: StringName = &"players"

@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D

@export var point_value: int = 100

signal landed

@export_group("Spawn")
## If true, the ghost falls under gravity and its AI stays off until it touches the floor.
@export var fall_from_above: bool = true
@export var gravity: float = 15.0
@export var max_fall_speed: float = 40.0

var is_falling: bool = false

var is_captured: bool = false

var behavior: GhostBehavior

var _think_timer: float = 0.0
var _nav_ready: bool = false
var _arrival_reported: bool = false


func _ready() -> void:
	for child in get_children():
		if child is GhostBehavior:
			behavior = child
			break
	assert(behavior != null, "Ghost needs a GhostBehavior child node.")
	behavior.setup(self)
	is_falling = fall_from_above
	_setup_navigation.call_deferred()


func _setup_navigation() -> void:
	# The navigation map is empty until the first physics frame has synced.
	await get_tree().physics_frame
	_nav_ready = true
	_think_timer = 0.0 # think immediately


func _physics_process(delta: float) -> void:
	if is_falling:
		_fall(delta)
		return
	
	if not _nav_ready:
		return
	
	behavior.physics_update(delta)
	
	_think_timer -= delta
	if _think_timer <= 0.0:
		_think()

	_move(delta)


func _think() -> void:
	var target := behavior.choose_target(get_player_positions())
	nav_agent.target_position = target
	_arrival_reported = false
	_think_timer = behavior.get_next_think_delay()


## Forces a re-evaluation on the next physics frame (e.g. after being scared).
func request_rethink() -> void:
	_think_timer = 0.0


func _move(delta: float) -> void:
	if nav_agent.is_navigation_finished():
		if not _arrival_reported:
			_arrival_reported = true
			behavior.on_target_reached()
		velocity = Vector3.ZERO
		move_and_slide()
		return

	var next_pos := nav_agent.get_next_path_position()
	var dir := next_pos - global_position
	dir.y = 0.0
	if dir.length_squared() > 0.0001:
		dir = dir.normalized()
		velocity = dir * move_speed * behavior.get_speed_multiplier()
		# Godot's forward is -Z.
		rotation.y = lerp_angle(rotation.y, atan2(-dir.x, -dir.z), turn_speed * delta)
	else:
		velocity = Vector3.ZERO
	move_and_slide()

func get_players() -> Array[Node3D]:
	var result: Array[Node3D] = []
	for p in get_tree().get_nodes_in_group(player_group):
		if p is Node3D:
			result.append(p)
	return result

func get_player_positions() -> Array[Vector3]:
	var result: Array[Vector3] = []
	for p in get_tree().get_nodes_in_group(player_group):
		if p is Node3D:
			result.append(p.global_position)
	return result


## Snaps a point onto the navmesh this ghost navigates on.
func snap_to_navmesh(point: Vector3) -> Vector3:
	return NavigationServer3D.map_get_closest_point(nav_agent.get_navigation_map(), point)

## Called by a player's suction. Stops all AI/movement and collisions.
func begin_capture() -> void:
	if is_captured:
		return
	is_captured = true
	velocity = Vector3.ZERO
	collision_layer = 0
	collision_mask = 0
	process_mode = Node.PROCESS_MODE_DISABLED # also disables the behavior child

func _fall(delta: float) -> void:
	velocity.x = 0.0
	velocity.z = 0.0
	velocity.y = maxf(velocity.y - gravity * delta, -max_fall_speed)
	move_and_slide()
	if is_on_floor():
		is_falling = false
		velocity = Vector3.ZERO
		_think_timer = 0.0 # start thinking right away
		landed.emit()
