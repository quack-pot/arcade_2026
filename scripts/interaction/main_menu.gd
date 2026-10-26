extends Node

@export_group("Fade Animation")
@export var transition_wait_time: float = 1.5
@export var transition_speed_scale: float = 10.0
@export var fade_player: AnimationPlayer = null

@export_group("Monster Animation")
@export var monster_spawn_time: float = 8.0
@export var monster_spawn_delay: float = 2.0
@export var spawn_points: Array[Node3D] = []

const DRIFT_MONSTER = preload("res://entities/decorative/monster_drift.scn")

var loading_game: bool = false
var next_spawns: Array[Node3D] = []
@onready var monster_spawn_timer: float = monster_spawn_time - monster_spawn_delay

func _process(delta: float) -> void:
	monster_spawn_timer += delta
	
	if monster_spawn_timer >= monster_spawn_time:
		monster_spawn_timer -= monster_spawn_time
		
		if next_spawns.is_empty():
			next_spawns = spawn_points.duplicate()
			next_spawns.shuffle()
		
		var spawn = next_spawns.pop_front()
		
		var monster = DRIFT_MONSTER.instantiate() as Node3D
		
		spawn.add_child(monster)
		monster.position = Vector3.ZERO
		monster.rotation = Vector3.ZERO

func _input(event: InputEvent) -> void:
	if loading_game:
		return
	
	var is_start_event: bool = !event.is_action("WhiteLeft") && !event.is_action("WhiteRight")
	if is_start_event:
		return
	
	loading_game = true
	if fade_player != null:
		fade_player.play(
			"scene_fade_in",
			-1,
			-absf(transition_speed_scale),
			true
		)
	
	await get_tree().create_timer(transition_wait_time).timeout
	get_tree().change_scene_to_file("res://scenes/game.tscn")
