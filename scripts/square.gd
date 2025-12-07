@icon("res://sprites/icons/square_icon.svg")
extends Area2D
class_name Square 

## Square script. It contains all the functions and variables related to each square in the board.

signal check_all_non_mine_squares ## This signal is emitted when a square is revealed, to check if all non-mine squares are revealed.
signal mine_exploded ## This signal is emitted when a mine explodes.
signal wrongFlags_detected ## This signal is emitted when wrong flags are detected around a square.
signal change_firstMine(mine) ## This signal is emitted when the first square is clicked and it has a mine, to change its position.

enum Frames {
	MINE = 9, ## Frame 9 = Mine
	MINE_EXPLODED = 10, ## Frame 10 = Mine exploded
	COVERED = 11, ## Frame 11 = Covered square
	WRONG_FLAG = 12 ## Frame 12 = Wrong flag
}

@onready var board: Board = get_parent() ## Reference to the board node.

var squareID: int ## Unique ID for each square.
var squareLocation: Vector2 ## Location of the square in the grid (row, column).
var squareValue: int = 0 ## Value of the square (-1 = mine, 0-8 = number of mines around).
var is_shown: bool = false ## Indicates if the square is revealed or not.
var is_mine: bool = false ## Indicates if the square is a mine or not.
var has_flag: bool = false ## Indicates if the square has a flag or not.
var neighboursAround: Array = [] ## List of neighbour squares around this square.
var minesAround: Array = [] ## List of mines around this square.

func _ready():
	var particles_material = %ExplosionParticles.process_material.duplicate()
	particles_material.scale_max *= scale.x
	particles_material.scale_min *= scale.x
	%ExplosionParticles.process_material = particles_material
	
	%AnimatedSprite2D.frame = Frames.COVERED 
	board.firstMine_changed.connect(_on_firstMine_changed)


## When the first mine is changed, if this square is the original square (the one that was clicked), 
## it reveals itself.
func _on_firstMine_changed(originalSquare: Square) -> void:
	if self == originalSquare:
		reveal_squares()
		emit_signal("check_all_non_mine_squares")

## Input event function to handle mouse clicks on the square.
func _on_input_event(_viewport, event, _shape_idx) -> void:
	if board.game_started:
		if event is InputEventMouseButton and event.pressed:
			
			%ButtonPlayer.play()
			
			if event.button_index == MOUSE_BUTTON_LEFT and !has_flag:
				if is_shown and squareValue > 0:
					reveal_non_mine_squares()
				else:
					if is_mine and !is_shown:
						
						if !board.firstSquare_clicked:
							emit_signal("change_firstMine", self)
							return
						
						%AnimatedSprite2D.frame = Frames.MINE_EXPLODED 
						is_shown = true
						explosion()
						emit_signal("mine_exploded")
					else:
						board.firstSquare_clicked = true
						reveal_squares()
						
			
			if event.button_index == MOUSE_BUTTON_RIGHT:
				assign_flag()


## Reveals only the current square, changing its sprite based on whether it's a mine or not.
func _reveal_square():
	
	if is_shown:
		return
	else:
		is_shown = true
			
		if squareValue != -1:
			%AnimatedSprite2D.frame = squareValue
		else:
			%AnimatedSprite2D.frame = Frames.MINE 
			
			if Global.game_result == Global.Result.DEFEAT:
				explosion()
		
		emit_signal("check_all_non_mine_squares")



## Reveals the square and if that square is not a mine, it will reveal all the squares
## connected whose value is 0.
func reveal_squares() -> void:
	
	if is_shown:
		return
	else:
		
		var queue: Array = []
		queue.append(self)
		
		while queue.size() > 0:
			var currentSquare: Square = queue.pop_front()
			
			if currentSquare.is_shown:
				continue
			else:
				
				currentSquare._reveal_square()
				
				if currentSquare.squareValue == 0 and board.game_started:
					for neighbour: Square in currentSquare.neighboursAround:
						if !neighbour.is_shown and !neighbour.has_flag:
							queue.append(neighbour)
	



## Assigns or removes a flag from the square.
func assign_flag() -> void:
	
	if %AnimationPlayer.is_playing():
		return
	
	if !is_shown:
		if !has_flag:
			Global.numFlags -= 1
			has_flag = true
			%AnimationPlayer.play("assign_flag")
			
			
		else:
			Global.numFlags += 1
			has_flag = false
			%AnimationPlayer.play_backwards("assign_flag")
			

## The function checks all the squares around. If all the mines that are around are flagged correctly,
## it will return true. Otherwise, will return false. Also if the function detects a square that is flagged
## and it doesn't have a mine, it will mark the wrong flags and send a "game_over".
func check_neighbour_flags() -> bool:
	
	var are_minesAround_flagged = true
	
	if check_wrongFlags():
		emit_signal("wrongFlags_detected")
		return false
	
	for mine in minesAround:
		if mine.has_flag == false:
			are_minesAround_flagged = false
			break
	
	return are_minesAround_flagged

## It returns true if it finds a square that is flagged and it doesn't have a flag. Also changes those
## flag's sprites into a red square with the square (Frame 12)
func check_wrongFlags() -> bool:
	
	var has_wrongFlags = false
	
	for square in neighboursAround:
		if !square.is_mine and square.has_flag:
			has_wrongFlags = true
			square.get_node("AnimatedSprite2D").frame = Frames.WRONG_FLAG
			square.is_shown = true
	
	return has_wrongFlags


## It would first check all the squares around. If the mines around are correctly flagged, this function
## will call reveal_square() to reveal all the non_mine squares.  
func reveal_non_mine_squares() -> void:
	
	if check_neighbour_flags() == true:
		for neighbour in neighboursAround:
			if !neighbour.is_mine and !neighbour.is_shown:
				neighbour.reveal_squares()
	pass


## Updates the square value based on the mines around it.
func updateValue() -> void:
	
	if is_mine:
		squareValue = -1
		return
	
	minesAround.clear()
	neighboursAround.clear()
	squareValue = 0
	
	var row = int(squareLocation.x)
	var col = int(squareLocation.y)
	
	for dy in range(-1, 2):
		for dx in range(-1, 2):
					
			if dx == 0 and dy == 0:
				continue
					
			var ny = row + dy
			var nx = col + dx
					
			if ny >= 0 and ny < board.grid_rows and nx >= 0 and nx < board.grid_columns:
						
				neighboursAround.append(board.squaresList[ny][nx])
						
				if board.squaresList[ny][nx].is_mine and !is_mine:
					squareValue += 1
					minesAround.append(board.squaresList[ny][nx])


## Activates the explosion particles.
func explosion() -> void:
	%ExplosionParticles.restart()
