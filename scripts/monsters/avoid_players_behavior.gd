class_name AvoidPlayersBehavior
extends GhostBehavior
## Ghost that tries to stay as far from every player as possible.
##
## Each think tick it builds candidate points, snaps them to the navmesh,
## scores them, and heads for the best one.

## How far from a player (or the midpoint) to project candidates.
@export var max_flee_distance: float = 15.0
## Extra candidates scattered around the ghost itself so it always has nearby options.
@export var local_samples: int = 6

@export_group("Heuristic")
## Reward for the distance to the NEAREST player (keeps it away from both).
@export var min_distance_weight: float = 1.0
## Reward for total distance to all players.
@export var sum_distance_weight: float = 0.25
## Penalty per unit the ghost must travel (prevents long dashes past a player).
@export var travel_penalty: float = 0.15


func choose_target(player_positions: Array[Vector3]) -> Vector3:
	if player_positions.is_empty():
		return ghost.global_position

	var candidates := _build_candidates(player_positions)
	var best_point := ghost.global_position
	var best_score := -INF
	for point in candidates:
		var score := _score(point, player_positions)
		if score > best_score:
			best_score = score
			best_point = point
	return best_point


func _build_candidates(player_positions: Array[Vector3]) -> Array[Vector3]:
	var raw: Array[Vector3] = []

	# 1. A random-direction point at max distance from each player.
	for p in player_positions:
		raw.append(p + _random_flat_dir() * max_flee_distance)

	# 2. The midpoint between players, plus a random far point projected from it.
	var midpoint := Vector3.ZERO
	for p in player_positions:
		midpoint += p
	midpoint /= player_positions.size()
	raw.append(midpoint)
	raw.append(midpoint + _random_flat_dir() * max_flee_distance)

	# 3. Scattered points around the ghost.
	for i in local_samples:
		raw.append(ghost.global_position + _random_flat_dir() * randf_range(0.3, 1.0) * max_flee_distance)

	var snapped_to: Array[Vector3] = []
	for point in raw:
		snapped_to.append(ghost.snap_to_navmesh(point))
	return snapped_to


func _score(point: Vector3, player_positions: Array[Vector3]) -> float:
	var nearest := INF
	var total := 0.0
	for p in player_positions:
		var d := _flat_distance(point, p)
		nearest = minf(nearest, d)
		total += d
	var travel := _flat_distance(point, ghost.global_position)
	return nearest * min_distance_weight + total * sum_distance_weight - travel * travel_penalty


func _random_flat_dir() -> Vector3:
	var angle := randf() * TAU
	return Vector3(cos(angle), 0.0, sin(angle))


## Distance on the XZ plane only (the game is top-down).
func _flat_distance(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()
