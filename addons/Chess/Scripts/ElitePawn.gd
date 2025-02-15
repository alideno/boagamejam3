@tool
extends Pawn
class_name ElitePawn

func _ready():
	self.texture = load("
	res://addons/Chess/Textures/WElitePawn.svg")

func _process(_delta):
	if Item_Color != Temp_Color:
		Temp_Color = Item_Color
		if Item_Color == 0:
			self.texture = load("res://addons/Chess/Textures/WElitePawn.svg")
		elif Item_Color == 1:
			self.texture = load("res://addons/Chess/Textures/BElitePawn.svg")
