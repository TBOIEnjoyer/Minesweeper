extends Control

## End screen script.

const DIFFICULTY_SCREEN = preload("res://scenes/difficulty_screen.tscn") ## Path to the difficulty selection screen.
const MENU_SCREEN = preload("res://scenes/menu.tscn") ## Path to the main menu screen.

var is_newRecord: bool = false # Whether the player achieved a new record.
var choosen_option: String = "" # The option chosen by the player (either "retry" or "menu").

## Show the end screen with results.
func show_screen():
	# 1. If time is lower than bestTime, save the highscore.
	if (Global.time < Global.bestTimes[Global.difficulty] or Global.bestTimes[Global.difficulty] == 0) and Global.game_result == Global.Result.VICTORY:
		is_newRecord = true
		await Global.save_bestTime()
	
	%DifficultyLabel.text = "Difficulty: " + str(Global.difficulty.capitalize())
	%TimeLabel.text = "Time: " + str(Global.time) + " seconds"
	
	
	if Global.bestTimes[Global.difficulty] == 0:
		%BestTimeLabel.text = "Best time: None"
	else:
		%BestTimeLabel.text = "Best time: " + str(Global.bestTimes[Global.difficulty])
		if is_newRecord:
			%BestTimeLabel.text += " seconds (¡New Record!)"
		else:
			%BestTimeLabel.text += " seconds"
		
	if Global.game_result == Global.Result.VICTORY:
		%AnimationPlayer.play("show_results_victory")
	else:
		%AnimationPlayer.play("show_results_defeat")


func _on_retry_button_pressed():
	%AnimationPlayer.play("close_screen")
	%ButtonPlayer.play()
	choosen_option = "retry"
	pass # Replace with function body.


func _on_menu_button_pressed():
	%AnimationPlayer.play("close_screen")
	%ButtonPlayer.play()
	choosen_option = "menu"
	pass # Replace with function body.


func _on_animation_finished(anim_name):
	
	if anim_name == "close_screen":
		await get_tree().create_timer(1.5).timeout
		
		if choosen_option == "retry":
			get_tree().change_scene_to_packed(DIFFICULTY_SCREEN)
		elif choosen_option == "menu":
			get_tree().change_scene_to_packed(MENU_SCREEN)
	
	pass # Replace with function body.
