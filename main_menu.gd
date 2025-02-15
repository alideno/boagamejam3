extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("in main menu")
	get_tree().change_scene_to_file("res://board.tscn")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
