extends Node2D


var pictures = ["res://stuff/moves2.png","res://stuff/moves.png","res://stuff/pic1.jpg","res://stuff/pic2.jpg"]
var i = 1
	
func _input(event):
	if Input.is_action_just_pressed("NextPage"):
		$Sprite2D.texture = load(pictures[i])
		i = (i + 1)% len(pictures) 
	elif Input.is_action_just_pressed("Escape"):
		get_tree().change_scene_to_file("res://main_menu.tscn")
		

	
