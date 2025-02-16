extends Control

func _ready():
	# Set the label text based on the stored winner color.
	$Label.text = GameData.winner.capitalize() + " wins!"
	
	# Load the appropriate image based on the winner.
	if GameData.winner == "white":
		$TextureRect.texture = load("res://assets/white_winner.png")  # Replace with your white winner png
	else:
		$TextureRect.texture = load("res://assets/black_winner.png")  # Replace with your black winner png
	
	# Connect the RestartButton pressed signal.
	#$Button.connect("pressed", self, "_on_Restart_pressed")

func _on_button_pressed() -> void:
	print("b")
	get_tree().change_scene_to_file("res://board.tscn")


func _on_button_2_pressed() -> void:
	print("a")
	get_tree().change_scene_to_file("res://main_menu.tscn")
