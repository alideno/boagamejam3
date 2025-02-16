extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func _input(event):
	if Input.is_action_just_pressed("NextPage"):
		$Sprite2D.texture = load("res://stuff/moves.png")
	elif Input.is_action_just_pressed("PrevPage"):
		$Sprite2D.texture = load("res://stuff/moves2.png")
	elif Input.is_action_just_pressed("Escape"):
		get_tree().change_scene_to_file("res://main_menu.tscn")
		

	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
