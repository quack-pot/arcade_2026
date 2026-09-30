extends Node

var high_score: int = 0
const SAVE_PATH: String = "user://highscore.save"

func _ready() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
		
		if file:
			high_score = file.get_32()

func get_highscore() -> int:
	return high_score

func save_highscore(new_high_score: int) -> void:
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	
	if file:
		file.store_32(new_high_score)
	
	high_score = new_high_score
