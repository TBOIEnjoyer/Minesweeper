extends Node

## Global script to store variables and functions used across multiple scenes.

const DIFFICULTIES: Array = ["easy", "medium", "hard"] ## Possible difficulties.
const BEST_TIME_PATHFILE = "user://highscore.json" ## Path to the best times file.

enum Result {VICTORY, DEFEAT}

var difficulty: String = "easy" ## Current difficulty of the game.
var game_result: int ## Current game result ("¡Victory!" or "Defeat").
var numFlags: int = 0 ## Number of flags in the current game.
var time: int = 0 ## Current time in seconds.
var bestTimes: Dictionary = { ## Best times for each difficulty.
	"easy": 0,
	"medium": 0,
	"hard": 0
}

func _ready():
	load_bestTime()

## Loads the best times from the highscores text file. If the file does not exist, 
## it uses default values.
func load_bestTime() -> void:
	if !FileAccess.file_exists(BEST_TIME_PATHFILE):
		return
	
	var file = FileAccess.open(BEST_TIME_PATHFILE, FileAccess.READ)
	var json_text = file.get_as_text()
	
	var result = JSON.parse_string(json_text)
	if result == null:
		push_warning("Error loading JSON, using default values.")
	
	bestTimes = result

## Saves the current time as the best time for the current difficulty.
func save_bestTime() -> void:
	
	# 1. Update the "bestTimes" dictionary.
	for bestTime_difficulty in bestTimes:
		if bestTime_difficulty == difficulty:
			bestTimes[bestTime_difficulty] = time
			break
	
	# 2. Update the highscores text file.
	var file = FileAccess.open(BEST_TIME_PATHFILE, FileAccess.WRITE)
	var json_text = JSON.stringify(bestTimes, "\t")
	file.store_line(json_text)

## Erases the best times file.
func erase_bestTimes() -> void:
	DirAccess.remove_absolute(BEST_TIME_PATHFILE)
	pass

## Makes all the childs of the given node that can take input in some way unable to take it, 
## changing the "mouse_filter" property. The childs need to be inside the global group
## "Interactive".
func lock_inputs(parent: Object) -> void:
	for child in parent.get_children():
		if child.is_in_group("Interactive"):
			child.mouse_filter = Control.MOUSE_FILTER_IGNORE
		
		if child.get_child_count() > 0:
			lock_inputs(child)
	pass

## Makes all the childs of the given node that can take input in some way able to take it, 
## changing the "mouse_filter" property. The childs need to be inside the global group
## "Interactive".
func unlock_inputs(parent: Object) -> void:
	for child in parent.get_children():
		if child.is_in_group("Interactive"):
			child.mouse_filter = Control.MOUSE_FILTER_STOP
		
		if child.get_child_count() > 0:
			unlock_inputs(child)
	pass
