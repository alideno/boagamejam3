extends Control

func _ready():
	# Set the label text based on the stored winner color.
	
	# Load the appropriate image based on the winner.
	if GameData.winner == "black":
		$WhiteWin.hide()  # Replace with your white winner png
	else:
		$BlackWin.hide() # Replace with your black winner png
	
	# Connect the RestartButton pressed signal.
	#$Button.connect("pressed", self, "_on_Restart_pressed")

func _on_button_pressed() -> void:
	get_tree().change_scene_to_file("res://board.tscn")


func _on_button_2_pressed() -> void:
	get_tree().change_scene_to_file("res://main_menu.tscn")


func _on_exit_button_pressed() -> void:
	get_tree().quit()
