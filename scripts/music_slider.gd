extends HSlider

## Music slider script to control the volume of the music audio bus.

@export var audio_bus_name := "Music" ## Name of the audio bus to control.

@onready var _bus := AudioServer.get_bus_index(audio_bus_name) ## Index of the audio bus.

func _ready():
	value = db_to_linear(AudioServer.get_bus_volume_db(_bus))

### Called when the slider value is changed to update the audio bus volume.
func _on_value_changed(value):
	AudioServer.set_bus_volume_db(_bus, linear_to_db(value))
	pass # Replace with function body.
