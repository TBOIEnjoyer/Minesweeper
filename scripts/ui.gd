extends Control

## UI script to update the flag counter and timer labels inside the game.

func _process(_delta):
	update_labels()

## Updates the flag counter and timer labels.
func update_labels():
	%FlagLabel.text = str(Global.numFlags)
	%TimerLabel.text = str(Global.time)
