extends Control

## Settings panel script.

signal showing_settingsPanel 
signal settingsPanel_hidden

func _ready():
	visible = false

func _process(_delta):
	if %AnimationPlayer.is_playing() or %Button_animation.current_animation == "delete_bestTimes":
		Global.lock_inputs(self)
	else:
		Global.unlock_inputs(self)

## Show the settings panel.
func show_settings_screen():
	visible = true
	emit_signal("showing_settingsPanel")
	%Button_animation.play("animated_button")
	%AnimationPlayer.play("show_settingsPanel")
	%WarningLabel.self_modulate.a = 0
	


func _on_reset_button_pressed():
	
	%ButtonTimer.stop()
	%ButtonPlayer.play()
	
	if %Button_animation.current_animation == "animated_button":
		%Button_animation.play("first_warning")
		%Warning_animation.play("first_warning")
		%ButtonTimer.start()
		
		if !%ExplosionPlayer.playing:
			%ExplosionPlayer.play()
		
		return
	
	elif %Button_animation.current_animation == "first_warning":
		%Button_animation.play("second_warning")
		%Warning_animation.play("second_warning")
		%ButtonTimer.start()
		
		if !%ExplosionPlayer.playing:
			%ExplosionPlayer.play()
		
		return
	
	elif %Button_animation.current_animation == "second_warning":
		%Warning_animation.play("RESET")
		%Button_animation.play("delete_bestTimes")
		%Button_animation.queue("animated_button")
		Global.erase_bestTimes()
		return
	


func _on_button_timer_timeout():
	%Button_animation.play("animated_button")
	%Warning_animation.play("vanish_warning")
	pass # Replace with function body.


func _on_exit_button_pressed():
	%ButtonPlayer.play()
	%AnimationPlayer.play("hide_settingsPanel")
	pass # Replace with function body.


func _on_animation_player_animation_finished(anim_name):
	if anim_name == "hide_settingsPanel":
		visible = false
		emit_signal("settingsPanel_hidden")
	pass # Replace with function body.
