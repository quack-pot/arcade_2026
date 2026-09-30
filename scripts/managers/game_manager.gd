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

@onready
var timer: float = game_delay_time

@onready
var fade_player: AnimationPlayer = $Control/FadeRect/AnimationPlayer

func _process(delta: float) -> void:
	timer -= delta
	
	if timer > 0.0:
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
				-1.0,
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
