class_name GameManager
extends Node

signal play_started
signal play_ended

@export var game_play_time: float = 30
@export var game_delay_time: float = 5
@export var game_summary_time: float = 5
@export var game_fade_out_time: float = 2

enum PlayerId { PLAYER_1, PLAYER_2, PLAYER_COUNT }
enum GameState { DELAY, PLAY, SUMMARY, FADE_OUT }

var scores: Array[int] = [0, 0]
var state: GameState = GameState.DELAY

@onready var timer: float = game_delay_time
@onready var fade_player: AnimationPlayer = $Control/FadeRect/AnimationPlayer

@onready var camera: Camera3D = $Camera3D

@export var spawn_time: float = 2.5
@export var initial_spawn_count: int = 4
@onready var spawn_timer: float = spawn_time * initial_spawn_count

const MONSTERS: Array[PackedScene] = [
	preload("res://entities/monsters/demon.scn"),
	preload("res://entities/monsters/angel_cyclops.scn"),
	preload("res://entities/monsters/skull.scn"),
	preload("res://entities/monsters/spectre.scn")
]

func spawn_ghost(scene: PackedScene) -> Ghost:
	var ghost := scene.instantiate() as Ghost
	add_child(ghost) # must be in the tree before setting global_position
	
	var nav_map: RID = camera.get_world_3d().navigation_map
	var landing_spot := NavigationServer3D.map_get_random_point(nav_map, 1, true)
	ghost.global_position = landing_spot + Vector3.UP * (camera.global_position.y + 5.0 - landing_spot.y)
	return ghost

func _process(delta: float) -> void:
	timer -= delta
	
	if timer > 0.0:
		if state == GameState.PLAY:
			spawn_timer += delta
			if spawn_timer >= spawn_time:
				spawn_timer -= spawn_time
				spawn_ghost(MONSTERS.pick_random())
		return
	
	match state:
		GameState.DELAY:
			state = GameState.PLAY
			timer = game_play_time
			play_started.emit()
		
		GameState.PLAY:
			state = GameState.SUMMARY
			timer = game_summary_time
			play_ended.emit()
			
			var p1_score: int = scores[PlayerId.PLAYER_1]
			var p2_score: int = scores[PlayerId.PLAYER_2]
			if p1_score > p2_score:
				pass # TODO: Declare P1 Wins
			elif p2_score > p1_score:
				pass # TODO: Declare P2 Wins
			else:
				pass # TODO: Declare Draw
			
			var max_score: int = maxi(p1_score, p2_score)
			if HighScoreManager.get_highscore() < max_score:
				HighScoreManager.save_highscore(max_score)
				pass # TODO: Declare new high score!
		
		GameState.SUMMARY:
			state = GameState.FADE_OUT
			timer = game_fade_out_time
			fade_player.play(
				"scene_fade_in",
				-1,
				-10.0,
				true
			)
		
		GameState.FADE_OUT:
			get_tree().change_scene_to_file("res://scenes/main_menu.scn")

func increment_score(player: PlayerId, score: int) -> void:
	if state != GameState.PLAY:
		return
	
	if player >= PlayerId.PLAYER_COUNT:
		push_warning("Unknown player id:", player)
		return
	
	scores[player] += score


func _on_player_1_score_changed(player_id: GameManager.PlayerId, addition: int) -> void:
	increment_score(player_id, addition)
func _on_player_2_score_changed(player_id: GameManager.PlayerId, addition: int) -> void:
	increment_score(player_id, addition)
