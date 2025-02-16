@tool
extends Pawn
class_name Fortress

func _ready():
	self.texture = load("res://assets/white_fortress.png")

func _process(_delta):
	if Item_Color != Temp_Color:
		Temp_Color = Item_Color
		if Item_Color == 0:
			self.texture = load("res://assets/white_fortress.png")
		elif Item_Color == 1:
			self.texture = load("res://assets/black_fortress.png")
