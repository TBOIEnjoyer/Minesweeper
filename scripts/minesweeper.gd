@icon("res://sprites/icons/flagSprite_icon.svg")
extends Node2D
class_name Board

## Main Minesweeper game script.

signal firstMine_changed(originalSquare) ## Emmited when the first mine is changed.
signal game_ended ## Emmited when the game ends (either victory or defeat).

@onready var SQUARE_SIZE = get_spriteSize() ## The original size of the square sprites (in pixels).
const SQUARE_SCENE = preload("res://scenes/square.tscn") ## Path to the square scene.
const SAFE_MARGIN = 50 # In pixels


@onready var screen_size = get_viewport().get_visible_rect().size 
@onready var screen_center = screen_size / 2 

var game_started: bool = false ## Whether the game has started (the timer is running).

var grid_rows ## The number of rows in the grid.
var grid_columns ## The number of columns in the grid.
var max_mines ## The maximum number of mines in the grid.

var minesPositions: Array ## The positions of the mines in the grid.
var squaresList: Array ## 2D Array that contains all the square instances.
var firstSquare_clicked: bool = false ## Whether the first square clicked was a mine.

func _ready():
	
	# 1. Setup nodes.
	%End_Screen.position = Vector2(0, 0)
	%End_Screen.visible = false

	# 2. Animation
	%AnimationPlayer.connect("animation_finished", Callable(self, "_on_animation_changed"))
	%AnimationPlayer.play("START")
	
	if Global.difficulty == "easy":
		setup_game(10, 10, 10)
	elif Global.difficulty == "medium":
		setup_game(20, 20, 40)
	elif Global.difficulty == "hard":
		setup_game(20, 50, 100)
	pass

func _on_timer_timeout() -> void:
	Global.time += 1
	pass # Replace with function body.

func _on_animation_changed(anim_name) -> void:
	if anim_name == "START":
		game_started = true
		%Timer.start()

## Calculates the size of the square sprites. Returns the x size (because its a square).
func get_spriteSize() -> float:
	
	var square = SQUARE_SCENE.instantiate()
	var sprite_frames = square.get_node("AnimatedSprite2D").sprite_frames
	
	var texture = sprite_frames.get_frame_texture("squares_v2", 0)
	var sprite_size: Vector2 = texture.get_size()
	
	return sprite_size.x


## It defines a Rectangle where the squares will be created. It will calculate
## if the squares can spawn with the original size and if not, they will be 
## scaled so they can fit. It returns the scaled size. 
func get_actualSquareSize() -> float:
	
	var safe_rect = Rect2(SAFE_MARGIN, SAFE_MARGIN,
					  screen_size.x - 2*SAFE_MARGIN,
					  screen_size.y - 2*SAFE_MARGIN)
	
	var max_width_per_square = safe_rect.size.x / grid_columns
	var max_height_per_square = safe_rect.size.y / grid_rows
	
	var actual_square_size = min(SQUARE_SIZE, max_height_per_square, max_width_per_square) 
	
	return actual_square_size


## Prepares the board depending of the given 'rows', 'columns' and 'maxMines', which
## defines the size of the board and number of mines.
## It has to be called everytime a new game starts.
func setup_game(rows: int, columns: int, maxMines: int) -> void:
	
	minesPositions = []
	squaresList = [] 
	
	grid_rows = rows
	grid_columns = columns
	max_mines = maxMines
	
	Global.numFlags = max_mines
	Global.time = 0
	
	game_started = false
	firstSquare_clicked = false
	
	if max_mines > (grid_rows * grid_columns):
		assert(false, "¡Error! The max_mines value is greater that the total number of squares.")
	
	# 1. Select what squares will have mines.
	generate_mines()
	
	# 2. Instantiate the square entities.
	generate_squares()
	
	# 3. Assign mines values and after that, the rest of the square's values.
	assign_values()
	


## Defines the positions of the mines depending of the 'max_mines' and the size of the board.
## It stores the positions in the 'minesPositions' Array.
func generate_mines() -> void:
	
	var possiblePositions: Array = []
	
	for row in range(grid_rows):
		for column in range(grid_columns):
			var selectedPosition = Vector2(row, column)
			possiblePositions.append(selectedPosition)
	
	possiblePositions.shuffle()
	
	for mine in range(max_mines):
		minesPositions.append(possiblePositions[mine])


## Instantiates the squares depending of how many columns and rows there are,
## the size of the squares and also the size of the screen.
func generate_squares() -> void:
	
	var actual_square_size = get_actualSquareSize()
	
	var total_width = actual_square_size * grid_columns
	var total_height = actual_square_size * grid_rows
	
	var origin = screen_center - Vector2(total_width/2, total_height/2)
	
	for row in range(grid_rows):
		var new_row = []
		
		for column in range(grid_columns):
			var new_square = SQUARE_SCENE.instantiate()
			
			var pos = origin + Vector2(column * actual_square_size, row * actual_square_size)
			new_square.global_position = pos
			new_square.scale = Vector2(actual_square_size / SQUARE_SIZE, actual_square_size / SQUARE_SIZE)
			new_square.squareID = column + (grid_columns * row)
			new_square.squareLocation = Vector2(row, column)
			connect_square_signals(new_square)
			
			new_row.append(new_square)
			
			add_child(new_square)
		
		squaresList.append(new_row)

## Connects all the signals from the Square Object to the game.
func connect_square_signals(square) -> void:
	
	square.check_all_non_mine_squares.connect(_on_check_all_non_mine_squares)
	square.mine_exploded.connect(_on_mine_exploded)
	square.wrongFlags_detected.connect(_on_wrongFlags_detected)
	square.change_firstMine.connect(_on_change_firstMine)

## Assigns values for each square inside the 'squaresValues' Array. First, gives a mine value to the
## positions defined in 'mines_list' and then gives each other square a value depending of how many mines have
## around it.
func assign_values() -> void:
	
	# 1. Give a mine value to the correct positions.
	
	for minePosition in minesPositions:
		
		var row = int(minePosition.x)
		var column = int(minePosition.y)
		
		squaresList[row][column].is_mine = true
	
	# 2. Gives a value to the rest of the squares depending of how many mines have around it.
	
	for row in range(grid_rows):
		for col in range(grid_columns):
			
			var square = squaresList[row][col]
			
			square.updateValue()
	
	pass


## When a mine is clicked, it explodes and sends a signal calling this functions.
## Sends a 'game-over' signal.
func _on_mine_exploded() -> void:
	
	Global.game_result = Global.Result.DEFEAT
	emit_signal("game_ended")
	pass


## Everytime a square is clicked, it sends a signal calling this function. This function
## checks if all the non-mine squares are revealed. If true, it reveals the mines that
## aren't flagged and then it ends the game sending a 'victory' signal.
func _on_check_all_non_mine_squares() -> void:
	
	if !game_started:
		return
	
	var are_all_nonMine_squares_revealed = true
	
	# 1. Checks all the non-mine squares.
	for row in squaresList:
		for square in row:
			if !square.is_shown and !square.is_mine:
				are_all_nonMine_squares_revealed = false
				break
	
	# 2. If true, sends a victory signal and sets the user as a winner.
	if are_all_nonMine_squares_revealed:
		Global.game_result = Global.Result.VICTORY
		emit_signal("game_ended")
	
	pass


## When the first clicked square is a mine, this function is called to change
## the mine to another square that is not a mine.
func _on_change_firstMine(mine) -> void:
	
	firstSquare_clicked = true
	
	var selectedRow
	var selectedColumn
	var selectedPosition
	
	while true:
		
		selectedRow = randi_range(0, grid_rows - 1)
		selectedColumn = randi_range(0, grid_columns - 1)
		selectedPosition = Vector2(selectedRow, selectedColumn)
		
		if selectedPosition not in minesPositions:
			minesPositions.erase(mine.squareLocation)
			minesPositions.append(selectedPosition)
			
			# 1. Erase all data and calculate new value from the mine.
			mine.is_mine = false
			mine.updateValue()
			
			# 2. Give new data to the new mine.
			squaresList[selectedPosition.x][selectedPosition.y].is_mine = true
			squaresList[selectedPosition.x][selectedPosition.y].updateValue()
			
			# 3. Update neighbours
			for neighbour in mine.neighboursAround:
				neighbour.updateValue()
			
			for neighbour in squaresList[selectedPosition.x][selectedPosition.y].neighboursAround:
				neighbour.updateValue()
			
			emit_signal("firstMine_changed", mine)
			break


## When you press a revealed square with a value greater than 0, if you have placed
## all the flags you can around it but you have placed some wrong flags, this function is called.
func _on_wrongFlags_detected() -> void:
	Global.game_result = Global.Result.DEFEAT
	emit_signal("game_ended")

## Called when the game ends (either victory or defeat).
func _on_gameEnded() -> void:
	
	game_started = false
	%Timer.stop()
	
	if Global.game_result == Global.Result.DEFEAT:
		%ExplosionPlayer.play()
		%MusicPlayer.stop()
	
	# 1. Reveals all the squares (doesnt change the sprite of the exploded mine)
	await reveal_allSquares()
	
	# 2. Stops the music slowly if the player has won.
	
	if Global.game_result == Global.Result.VICTORY:
		var tween = get_tree().create_tween()
		tween.tween_property(%MusicPlayer, "volume_db", -60.0, 2)
	
	await get_tree().create_timer(3).timeout
	
	# 3. Instantiate the End Screen 
	%End_Screen.show_screen()


## Reveals all the squares in the board with a small delay between each row.
func reveal_allSquares() -> void:
	
	for row in squaresList:
		for square: Square in row:
			
			if !square.is_shown and ((square.is_mine and !square.has_flag) or !square.is_mine):
				if !square.is_mine and square.has_flag:
					square.get_node("AnimationPlayer").stop()
					square.assign_flag()
					
				square._reveal_square()
				
				
		await get_tree().create_timer(0.05).timeout
