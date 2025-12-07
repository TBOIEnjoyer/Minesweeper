extends Control

## Difficulty selection screen script.

func _ready():
	%EasyButton.visible = false
	%MediumButton.visible = false
	%HardButton.visible = false
	%AnimationPlayer.play("show_buttons")
	pass


func _on_easy_button_pressed():
	Global.difficulty = "easy"
	%ButtonPlayer.play()
	%AnimationPlayer.play("START")
	pass # Replace with function body.


func _on_medium_button_pressed():
	Global.difficulty = "medium"
	%ButtonPlayer.play()
	%AnimationPlayer.play("START")
	pass # Replace with function body.


func _on_hard_button_pressed():
	Global.difficulty = "hard"
	%ButtonPlayer.play()
	%AnimationPlayer.play("START")
	pass # Replace with function body.


func _on_animation_finished(anim_name):
	if anim_name == "START":
		get_tree().change_scene_to_file("res://scenes/board.tscn")
	pass # Replace with function body.
