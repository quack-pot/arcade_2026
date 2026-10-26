class_name ChargeBehavior
extends GhostBehavior
## Wanders the arena for a while, then charges a random player and stuns them on contact.
## States: WANDER -> CHARGE -> RECOVER -> WANDER ...

signal state_changed(new_state: State)

enum State { WANDER, CHARGE, RECOVER }

@export_group("Wander")
@export var wander_time_min: float = 3.0
@export var wander_time_max: float = 6.0
@export var wander_min_distance: float = 8.0
@export var wander_max_distance: float = 12.0

@export_group("Charge")
## Multiplies the ghost's move_speed while charging.
@export var charge_speed_multiplier: float = 2.1
## How often the path to the (moving) player is refreshed.
@export var charge_repath_interval: float = 0.15
## Flat (XZ) distance at which the charge counts as contact.
@export var contact_distance: float = 1.275
## Gives up and goes back to wandering if contact isn't made in this long.
@export var charge_timeout: float = 8.0
@export var stun_duration: float = 2.5

@export_group("Recover")
## The ghost stands still for this long after a hit, so it can't stun-lock.
@export var recover_time: float = 1.5

var state: State = State.WANDER

var _state_time: float = 0.0
var _wander_duration: float = 0.0
var _charge_target: Node3D = null


func setup(p_ghost: Ghost) -> void:
	super(p_ghost)
	_enter_state(State.WANDER)


# --- GhostBehavior overrides -------------------------------------------------

func physics_update(delta: float) -> void:
	_state_time += delta
	match state:
		State.WANDER:
			if _state_time >= _wander_duration:
				_start_charge()
		State.CHARGE:
			_update_charge()
		State.RECOVER:
			if _state_time >= recover_time:
				_enter_state(State.WANDER)


func choose_target(_player_positions: Array[Vector3]) -> Vector3:
	match state:
		State.WANDER:
			return _pick_wander_point()
		State.CHARGE:
			if is_instance_valid(_charge_target):
				return ghost.snap_to_navmesh(_charge_target.global_position)
	return ghost.global_position # RECOVER (or no target): stand still


func get_next_think_delay() -> float:
	match state:
		State.CHARGE:
			return charge_repath_interval
		State.RECOVER:
			return 0.25
	return super()


func get_speed_multiplier() -> float:
	return charge_speed_multiplier if state == State.CHARGE else 1.0


func on_target_reached() -> void:
	# Keep wandering instead of idling at the end of each path.
	if state == State.WANDER:
		ghost.request_rethink()


# --- State handling ----------------------------------------------------------

func _enter_state(new_state: State) -> void:
	state = new_state
	_state_time = 0.0
	if new_state == State.WANDER:
		_wander_duration = randf_range(wander_time_min, wander_time_max)
		_charge_target = null
	ghost.request_rethink()
	state_changed.emit(new_state)


func _start_charge() -> void:
	var target := _pick_charge_target()
	if target == null:
		# Nobody to chase right now; wander a little longer.
		_wander_duration = _state_time + 1.0
		return
	_charge_target = target
	_enter_state(State.CHARGE)


func _update_charge() -> void:
	if not is_instance_valid(_charge_target) or _is_stunned(_charge_target):
		var next := _pick_charge_target()
		if next == null:
			_enter_state(State.WANDER) # everyone is stunned
			return
		_charge_target = next # keep charging; the timeout keeps counting

	if _flat_distance(ghost.global_position, _charge_target.global_position) <= contact_distance:
		_hit(_charge_target)
	elif _state_time >= charge_timeout:
		_enter_state(State.WANDER)


func _hit(player: Node3D) -> void:
	if player.has_method("stun"):
		player.stun(stun_duration)
	_enter_state(State.RECOVER)


# --- Helpers -----------------------------------------------------------------

func _pick_charge_target() -> Node3D:
	var candidates: Array[Node3D] = []
	for p in ghost.get_players():
		if not _is_stunned(p):
			candidates.append(p)
	return candidates.pick_random() if not candidates.is_empty() else null

func _pick_wander_point() -> Vector3:
	var angle := randf() * TAU
	var dist := randf_range(wander_min_distance, wander_max_distance)
	var point := ghost.global_position + Vector3(cos(angle), 0.0, sin(angle)) * dist
	return ghost.snap_to_navmesh(point)


func _is_stunned(player: Node3D) -> bool:
	return "is_stunned" in player and player.is_stunned


func _flat_distance(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()
