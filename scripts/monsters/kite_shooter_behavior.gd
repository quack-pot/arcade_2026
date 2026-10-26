class_name KiteShooterBehavior
extends GhostBehavior
## Keeps a comfortable distance from every player and throws fireballs at them.
## States: KITE (reposition, fire timer counts down) -> WINDUP (stand still, face
## the target, then throw) -> KITE ...

enum State { KITE, WINDUP }

signal windup_started(target: Node3D)
signal fired

@export_group("Kiting")
## Ideal distance from each player.
@export var preferred_distance: float = 12.0
## No penalty while within preferred_distance +/- this.
@export var tolerance: float = 2.0
## Being too close is worse than being too far.
@export var too_close_weight: float = 2.0
## Penalty per unit of travel, to avoid pointless long runs.
@export var travel_penalty: float = 0.1
## Points sampled on a ring around each player, and around the ghost itself.
@export var ring_samples_per_player: int = 5
@export var local_samples: int = 5
@export var local_sample_radius: float = 6.0

@export_group("Shooting")
@export var fireball_scene: PackedScene
@export var fire_interval_min: float = 1.0
@export var fire_interval_max: float = 1.5
## Only throws at players closer than this.
@export var shoot_range: float = 20.0
## Stands still and faces the target this long before throwing.
@export var windup_time: float = 0.25
@export var windup_turn_speed: float = 12.0
@export var spawn_height: float = 0.8
@export var spawn_forward_offset: float = 0.8

var state: State = State.KITE

var _state_time: float = 0.0
var _fire_cooldown: float = 0.0
var _windup_target: Node3D = null


func _init() -> void:
	think_interval = 0.5 # reposition more often than the default


func setup(p_ghost: Ghost) -> void:
	super(p_ghost)
	_fire_cooldown = randf_range(fire_interval_min, fire_interval_max)


# --- GhostBehavior overrides -------------------------------------------------

func physics_update(delta: float) -> void:
	match state:
		State.KITE:
			_fire_cooldown -= delta
			if _fire_cooldown <= 0.0:
				var target := _pick_shoot_target()
				if target:
					_begin_windup(target)
				else:
					_fire_cooldown = 0.25 # nobody in range; check again soon
		State.WINDUP:
			_state_time += delta
			if not is_instance_valid(_windup_target) or _is_stunned(_windup_target):
				_end_windup(0.5)
				return
			_face(_windup_target.global_position, delta)
			if _state_time >= windup_time:
				_fire(_windup_target)


func choose_target(player_positions: Array[Vector3]) -> Vector3:
	if state == State.WINDUP or player_positions.is_empty():
		return ghost.global_position # stand still

	# Staying put is always a candidate, which gives the ghost some hysteresis.
	var best_point := ghost.global_position
	var best_score := _score(best_point, player_positions)

	for point in _build_candidates(player_positions):
		var s := _score(point, player_positions)
		if s > best_score:
			best_score = s
			best_point = point
	return best_point


func get_next_think_delay() -> float:
	if state == State.WINDUP:
		return 0.1
	return super()


# --- Kiting ------------------------------------------------------------------

func _build_candidates(player_positions: Array[Vector3]) -> Array[Vector3]:
	var raw: Array[Vector3] = []

	# Ring around each player at the preferred distance.
	for p in player_positions:
		for i in ring_samples_per_player:
			raw.append(p + _random_flat_dir() * preferred_distance)

	# Nearby points around the ghost.
	for i in local_samples:
		raw.append(ghost.global_position + _random_flat_dir() * randf_range(1.0, local_sample_radius))

	var snapped: Array[Vector3] = []
	for point in raw:
		snapped.append(ghost.snap_to_navmesh(point))
	return snapped


## Higher is better. Zero deviation = inside the comfort band for every player.
func _score(point: Vector3, player_positions: Array[Vector3]) -> float:
	var deviation := 0.0
	var near_edge := preferred_distance - tolerance
	var far_edge := preferred_distance + tolerance
	for p in player_positions:
		var d := _flat_distance(point, p)
		if d < near_edge:
			deviation += (near_edge - d) * too_close_weight
		elif d > far_edge:
			deviation += d - far_edge
	var travel := _flat_distance(point, ghost.global_position)
	return -deviation - travel * travel_penalty


# --- Shooting ----------------------------------------------------------------

func _pick_shoot_target() -> Node3D:
	var valid: Array[Node3D] = []
	for p in ghost.get_players():
		if not _is_stunned(p) \
				and _flat_distance(ghost.global_position, p.global_position) <= shoot_range:
			valid.append(p)
	return valid.pick_random() if not valid.is_empty() else null


func _begin_windup(target: Node3D) -> void:
	state = State.WINDUP
	_state_time = 0.0
	_windup_target = target
	ghost.request_rethink() # stops movement right away
	windup_started.emit(target)


func _end_windup(next_cooldown: float) -> void:
	state = State.KITE
	_windup_target = null
	_fire_cooldown = next_cooldown
	ghost.request_rethink()


func _fire(target: Node3D) -> void:
	if fireball_scene:
		var dir := target.global_position - ghost.global_position
		dir.y = 0.0
		if dir.length_squared() < 0.0001:
			dir = -ghost.global_basis.z
		dir = dir.normalized()

		var fireball := fireball_scene.instantiate() as Fireball
		ghost.get_parent().add_child(fireball)
		var spawn_pos := ghost.global_position + Vector3.UP * spawn_height + dir * spawn_forward_offset
		fireball.launch(spawn_pos, dir)
	fired.emit()
	_end_windup(randf_range(fire_interval_min, fire_interval_max))


func _face(world_pos: Vector3, delta: float) -> void:
	var dir := world_pos - ghost.global_position
	dir.y = 0.0
	if dir.length_squared() > 0.0001:
		ghost.rotation.y = lerp_angle(ghost.rotation.y, atan2(-dir.x, -dir.z), windup_turn_speed * delta)


# --- Helpers -----------------------------------------------------------------

func _is_stunned(player: Node3D) -> bool:
	return "is_stunned" in player and player.is_stunned


func _random_flat_dir() -> Vector3:
	var angle := randf() * TAU
	return Vector3(cos(angle), 0.0, sin(angle))


func _flat_distance(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()
