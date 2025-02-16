@tool
extends Pawn
class_name Crusader

func _ready():
	self.texture = load("res://assets/white_crusader.png")

func _process(_delta):
	if Item_Color != Temp_Color:
		Temp_Color = Item_Color
		if Item_Color == 0:
			self.texture = load("res://assets/white_crusader.png")
		elif Item_Color == 1:
			self.texture = load("res://assets/black_crusader.png")
