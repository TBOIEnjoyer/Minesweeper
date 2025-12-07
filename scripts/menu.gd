extends Control

## Menu screen script.

var can_player_exit = false ## Whether the player can exit the game by pressing ESC.

func _ready():
	
	%Settings.showing_settingsPanel.connect(_on_showing_settingsPanel)
	%Settings.settingsPanel_hidden.connect(_on_settingsPanel_hidden)
	
	%Title1.rotation = 0
	%Title2.rotation = 0
	%ColorRect.position = Vector2(0,0)
	
	%AnimationPlayer.play("show_title")
	%AnimationPlayer.queue("title_screen")
	

func _input(event):
	if event is InputEventMouseButton and event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT:
		if %AnimationPlayer.current_animation == "title_screen":
			%ButtonPlayer.play()
			%AnimationPlayer.stop()
			%AnimationPlayer.play("show_buttons")
	elif event is InputEventKey and event.keycode == KEY_ESCAPE and can_player_exit and !%AnimationPlayer.is_playing():
		get_tree().quit()
		


func _on_animation_player_animation_changed(old_name, _new_name):
	if old_name == "show_title":
		%Title_AnimationPlayer.play("idle_title")
	pass # Replace with function body.

func _on_animation_player_animation_finished(anim_name):
	if anim_name == "START":
		get_tree().change_scene_to_file("res://scenes/difficulty_screen.tscn")
	elif anim_name == "show_buttons":
		can_player_exit = true
	pass # Replace with function body.


func _on_play_button_pressed():
	if !%AnimationPlayer.is_playing():
		%ButtonPlayer.play()
		%AnimationPlayer.play("START")
	pass # Replace with function body.


func _on_config_button_pressed():
	%ButtonPlayer.play()
	%Settings.position = Vector2(0,0)
	%Settings.show_settings_screen()
	pass # Replace with function body.

func _on_showing_settingsPanel():
	can_player_exit = false
	pass

func _on_settingsPanel_hidden():
	can_player_exit = true
	pass
