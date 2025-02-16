@tool
extends Pawn
class_name GuardedQueen

func _ready():
	self.texture = load("res://assets/white_guarded_queen.png")

func _process(_delta):
	if Item_Color != Temp_Color:
		Temp_Color = Item_Color
		if Item_Color == 0:
			self.texture = load("res://assets/white_guarded_queen.png")
		elif Item_Color == 1:
			self.texture = load("res://assets/black_guarded_queen.png")
