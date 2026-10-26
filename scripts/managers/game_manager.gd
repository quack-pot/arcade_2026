class_name GameManager
extends Node

signal play_started
signal play_ended

@export var game_play_time: float = 45
@export var game_delay_time: float = 5
@export var game_summary_time: float = 5
@export var game_fade_out_time: float = 2

enum PlayerId { PLAYER_1, PLAYER_2, PLAYER_COUNT }
enum GameState { DELAY, PLAY, SUMMARY, FADE_OUT }

var scores: Array[int] = [0, 0]
var state: GameState = GameState.DELAY

@onready var timer: float = game_delay_time
@onready var fade_player: AnimationPlayer = $Control/FadeRect/AnimationPlayer

@onready var p1_score_text: Label = $Control/P1/VBoxContainer/Label
@onready var p2_score_text: Label = $Control/P2/VBoxContainer/Label

@onready var p1_time_text: Label = $Control/P1/VBoxContainer/Label3
@onready var p2_time_text: Label = $Control/P2/VBoxContainer/Label3

@onready var results_container: Control = $Control/Results

@onready var highscore_text: Label = $Control/Results/VBoxContainer/Highscore
@onready var results_text: Label = $Control/Results/VBoxContainer/ResultText
@onready var player_status_text: Label = $Control/Results/VBoxContainer/PlayerStatus

@onready var camera: Camera3D = $Camera3D

@export var spawn_time: float = 1.5
@export var initial_spawn_count: int = 6
@onready var spawn_timer: float = spawn_time * initial_spawn_count

const MONSTERS: Array[PackedScene] = [
	preload("res://entities/monsters/demon.scn"),
	preload("res://entities/monsters/angel_cyclops.scn"),
	preload("res://entities/monsters/skull.scn"),
	preload("res://entities/monsters/spectre.scn")
]

func _ready() -> void:
	var time_text: String = "Time: %ds" % int(game_play_time)
	p1_time_text.text = time_text
	p2_time_text.text = time_text

func spawn_ghost(scene: PackedScene) -> Ghost:
	var ghost := scene.instantiate() as Ghost
	add_child(ghost) # must be in the tree before setting global_position
	
	var nav_map: RID = camera.get_world_3d().navigation_map
	var landing_spot := NavigationServer3D.map_get_random_point(nav_map, 1, true)
	ghost.global_position = landing_spot + Vector3.UP * (camera.global_position.y + 5.0 - landing_spot.y)
	return ghost

func _process(delta: float) -> void:
	timer = maxf(0.0, timer - delta)
	
	if state == GameState.PLAY:
		var time_text: String = "Time: %ds" % int(timer)
		p1_time_text.text = time_text
		p2_time_text.text = time_text
		
		spawn_timer += delta
		if spawn_timer >= spawn_time:
			spawn_timer -= spawn_time
			spawn_ghost(MONSTERS.pick_random())
	
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
			
			results_container.visible = true
			
			var p1_score: int = scores[PlayerId.PLAYER_1]
			var p2_score: int = scores[PlayerId.PLAYER_2]
			if p1_score > p2_score:
				player_status_text.add_theme_color_override("font_color", "#dd5959")
				player_status_text.add_theme_color_override("font_outline_color", "#860505")
				player_status_text.text = "Player 1 Wins!"
			elif p2_score > p1_score:
				player_status_text.add_theme_color_override("font_color", "#38b6ff")
				player_status_text.add_theme_color_override("font_outline_color", "#1800ad")
				player_status_text.text = "Player 2 Wins!"
			else:
				player_status_text.add_theme_color_override("font_color", "#d9d9d9")
				player_status_text.add_theme_color_override("font_outline_color", "#20122b")
				player_status_text.text = "Draw!"
			
			var max_score: int = maxi(p1_score, p2_score)
			var highscore: int = HighScoreManager.get_highscore()
			highscore_text.text = "High score: %d" % maxi(highscore, max_score)
			
			if HighScoreManager.get_highscore() < max_score:
				HighScoreManager.save_highscore(max_score)
				results_text.text = "New High Score"
		
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
	p1_score_text.text = "Score: %d" % scores[GameManager.PlayerId.PLAYER_1]
func _on_player_2_score_changed(player_id: GameManager.PlayerId, addition: int) -> void:
	increment_score(player_id, addition)
	p2_score_text.text = "Score: %d" % scores[GameManager.PlayerId.PLAYER_2]
