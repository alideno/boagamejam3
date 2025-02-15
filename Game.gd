extends Control

var Selected_Node = ""
var Turn = 0

var Location_X = ""
var Location_Y = ""

var pos = Vector2(50, 50)
var Areas: PackedStringArray
# this is seperate the Areas for special circumstances, like castling.
var Special_Area: PackedStringArray

func _on_flow_send_location(location: String):
	# variables for later
	var number = 0
	Location_X = ""
	var node = get_node("Flow/" + location)
	# This is to try and grab the X and Y coordinates from the board
	while location.substr(number, 1) != "-":
		Location_X += location.substr(number, 1)
		number += 1
	Location_Y = location.substr(number + 1)
	# Now... we need to figure out how to select the pieces. If there is a valid move, do stuff.
	# If we re-select, just go to that other piece
	if Selected_Node == "" && node.get_child_count() != 0 && node.get_child(0).Item_Color == Turn:
		Selected_Node = location
		Get_Moveable_Areas()
	elif Selected_Node != "" && node.get_child_count() != 0 && node.get_child(0).Item_Color == Turn && node.get_child(0).name == "Rook":
		# Castling
		for i in Areas:
			if i == node.name:
				var king = get_node("Flow/" + Selected_Node).get_child(0)
				var rook = node.get_child(0)
				# Using a seperate array because Areas wouldn't be really consistant...
				king.reparent(get_node("Flow/" + Special_Area[1]))
				rook.reparent(get_node("Flow/" + Special_Area[0]))
				king.position = pos
				rook.position = pos
				# We have to get the parent because it will break lmao.
				Update_Game(king.get_parent())
	# En Passant
	elif Selected_Node != "" && node.get_child_count() != 0 && node.get_child(0).Item_Color != Turn && node.get_child(0).name == "Pawn" && Special_Area.size() != 0 && Special_Area[0] == node.name && node.get_child(0).get("En_Passant") == true:
		for i in Special_Area:
			if i == node.name:
				var pawn = get_node("Flow/" + Selected_Node).get_child(0)
				node.get_child(0).free()
				pawn.reparent(get_node("Flow/" + Special_Area[1]))
				pawn.position = pos
				Update_Game(pawn.get_parent())
	elif Selected_Node != "" && node.get_child_count() != 0 && node.get_child(0).Item_Color == Turn:
		# Re-select
		Selected_Node = location
		Get_Moveable_Areas()
	elif Selected_Node != "" && node.get_child_count() != 0 && node.get_child(0).Item_Color != Turn:
		# Taking over a piece
		for i in Areas:
			if i == node.name:
				var Piece = get_node("Flow/" + Selected_Node).get_child(0)
				# Win conditions
				if node.get_child(0).name == "King":
					print("Damn, you win!")
				node.get_child(0).free()
				Piece.reparent(node)
				Piece.position = pos
				Update_Game(node)
	elif Selected_Node != "" && node.get_child_count() == 0:
		# Moving a piece
		for i in Areas:
			if i == node.name:
				var Piece = get_node("Flow/" + Selected_Node).get_child(0)
				Piece.reparent(node)
				Piece.position = pos
				Update_Game(node)

func Update_Game(node):
	Selected_Node = ""
	if Turn == 0:
		Reset_Tile_Colors()
		Turn = 1
	else:
		Reset_Tile_Colors()
		Turn = 0
	
	# get the en-passantable pieces and undo them
	var things = get_node("Flow").get_children()
	for i in things:
		if i.get_child_count() != 0 && i.get_child(0).name == "Pawn" && i.get_child(0).Item_Color == Turn && i.get_child(0).En_Passant == true:
			i.get_child(0).set("En_Passant", false)
	
	# Remove the abilities once they are either used or not used
	if node.get_child(0).name == "Pawn":
		if node.get_child(0).Double_Start == true:
			node.get_child(0).En_Passant = true
		node.get_child(0).Double_Start = false
	if node.get_child(0).name == "King":
		node.get_child(0).Castling = false
	if node.get_child(0).name == "Rook":
		node.get_child(0).Castling = false

# Below is the movement that is used for the pieces
func Get_Moveable_Areas():
	Reset_Tile_Colors()
	var Flow = get_node("Flow")
	var highlight
	# Clearing the arrays
	Areas.clear()
	Special_Area.clear()
	var Piece = get_node("Flow/" + Selected_Node).get_child(0)
	# For the selected piece that we have, we can get the movement that we need here.
	if Piece.name == "Pawn":
		Get_Pawn(Piece, Flow)#done
	elif Piece.name == "Bishop":
		Get_Diagonals(Flow)#done
	elif Piece.name == "King":
		Get_Around(Piece)#done
	elif Piece.name == "Queen":
		Get_Diagonals(Flow)#done
		Get_Rows(Flow)#done
	elif Piece.name == "Rook":
		Get_Rows(Flow)#done
	elif Piece.name == "Knight":
		Get_Horse()#done
	
	for area in Areas:
		var tile = Flow.get_node(area)
		if tile is TextureButton:
			tile.texture_normal = load("res://assets/highlight.png")

func Get_Pawn(Piece, Flow):
	var piece_color = Piece.Item_Color  # Using the passed Piece's color

	if piece_color == 0:  # White pawn
		# Forward move one step (must be empty)
		var forward_one = Location_X + "-" + str(int(Location_Y) - 1)
		if not Is_Null(forward_one) and Flow.get_node(forward_one).get_child_count() == 0:
			Areas.append(forward_one)
			# Forward move two steps on first move (both squares must be empty)
			if Piece.Double_Start:
				var forward_two = Location_X + "-" + str(int(Location_Y) - 2)
				if not Is_Null(forward_two) and Flow.get_node(forward_two).get_child_count() == 0:
					Areas.append(forward_two)
		# Diagonal capture moves:
		var diag_left = str(int(Location_X) - 1) + "-" + str(int(Location_Y) - 1)
		var diag_right = str(int(Location_X) + 1) + "-" + str(int(Location_Y) - 1)
		if not Is_Null(diag_left):
			var target = Flow.get_node(diag_left)
			if target.get_child_count() > 0:
				var occupant = target.get_child(0)
				if occupant.Item_Color != piece_color:
					Areas.append(diag_left)
		if not Is_Null(diag_right):
			var target = Flow.get_node(diag_right)
			if target.get_child_count() > 0:
				var occupant = target.get_child(0)
				if occupant.Item_Color != piece_color:
					Areas.append(diag_right)
	else:  # Black pawn
		# Forward move one step (must be empty)
		var forward_one = Location_X + "-" + str(int(Location_Y) + 1)
		if not Is_Null(forward_one) and Flow.get_node(forward_one).get_child_count() == 0:
			Areas.append(forward_one)
			# Forward move two steps on first move
			if Piece.Double_Start:
				var forward_two = Location_X + "-" + str(int(Location_Y) + 2)
				if not Is_Null(forward_two) and Flow.get_node(forward_two).get_child_count() == 0:
					Areas.append(forward_two)
		# Diagonal capture moves:
		var diag_left = str(int(Location_X) - 1) + "-" + str(int(Location_Y) + 1)
		var diag_right = str(int(Location_X) + 1) + "-" + str(int(Location_Y) + 1)
		if not Is_Null(diag_left):
			var target = Flow.get_node(diag_left)
			if target.get_child_count() > 0:
				var occupant = target.get_child(0)
				if occupant.Item_Color != piece_color:
					Areas.append(diag_left)
		if not Is_Null(diag_right):
			var target = Flow.get_node(diag_right)
			if target.get_child_count() > 0:
				var occupant = target.get_child(0)
				if occupant.Item_Color != piece_color:
					Areas.append(diag_right)

func Get_Around(Piece):
	var Flow = get_node("Flow")  # ADDED: Declare Flow variable
	var piece_color = get_node("Flow/" + Selected_Node).get_child(0).Item_Color  # ADDED: Get current piece color
	var positions = [
		Location_X + "-" + str(int(Location_Y) + 1),
		Location_X + "-" + str(int(Location_Y) - 1),
		str(int(Location_X) + 1) + "-" + Location_Y,
		str(int(Location_X) - 1) + "-" + Location_Y,
		str(int(Location_X) + 1) + "-" + str(int(Location_Y) + 1),
		str(int(Location_X) - 1) + "-" + str(int(Location_Y) + 1),
		str(int(Location_X) + 1) + "-" + str(int(Location_Y) - 1),
		str(int(Location_X) - 1) + "-" + str(int(Location_Y) - 1)
	]
	for pos_str in positions:
		if not Is_Null(pos_str):
			var target = Flow.get_node(pos_str)
			if target.get_child_count() == 0:
				Areas.append(pos_str)
			else:
				# CHANGED: Add if the occupying piece is of reversed color.
				var occupant = target.get_child(0)
				if occupant.Item_Color != piece_color:
					Areas.append(pos_str)

func Get_Rows(Flow):
	var piece_color = get_node("Flow/" + Selected_Node).get_child(0).Item_Color  # ADDED: Get current piece color

	var Add_X = 1
	# To the right
	while not Is_Null(str(int(Location_X) + Add_X) + "-" + Location_Y):
		var target = Flow.get_node(str(int(Location_X) + Add_X) + "-" + Location_Y)
		if target.get_child_count() == 0:
			Areas.append(target.name)
		else:
			# CHANGED: Allow enemy capture then break.
			var occupant = target.get_child(0)
			if occupant.Item_Color != piece_color:
				Areas.append(target.name)
			break
		Add_X += 1

	# To the left
	Add_X = 1
	while not Is_Null(str(int(Location_X) - Add_X) + "-" + Location_Y):
		var target = Flow.get_node(str(int(Location_X) - Add_X) + "-" + Location_Y)
		if target.get_child_count() == 0:
			Areas.append(target.name)
		else:
			var occupant = target.get_child(0)
			if occupant.Item_Color != piece_color:
				Areas.append(target.name)
			break
		Add_X += 1

	var Add_Y = 1
	# Downward
	while not Is_Null(Location_X + "-" + str(int(Location_Y) + Add_Y)):
		var target = Flow.get_node(Location_X + "-" + str(int(Location_Y) + Add_Y))
		if target.get_child_count() == 0:
			Areas.append(target.name)
		else:
			var occupant = target.get_child(0)
			if occupant.Item_Color != piece_color:
				Areas.append(target.name)
			break
		Add_Y += 1

	Add_Y = 1
	# Upward
	while not Is_Null(Location_X + "-" + str(int(Location_Y) - Add_Y)):
		var target = Flow.get_node(Location_X + "-" + str(int(Location_Y) - Add_Y))
		if target.get_child_count() == 0:
			Areas.append(target.name)
		else:
			var occupant = target.get_child(0)
			if occupant.Item_Color != piece_color:
				Areas.append(target.name)
			break
		Add_Y += 1

func Get_Diagonals(Flow):
	var piece_color = get_node("Flow/" + Selected_Node).get_child(0).Item_Color  # ADDED: Get current piece color
	var Add_X = 1
	var Add_Y = 1
	# Down-right diagonal
	while not Is_Null(str(int(Location_X) + Add_X) + "-" + str(int(Location_Y) + Add_Y)):
		var target = Flow.get_node(str(int(Location_X) + Add_X) + "-" + str(int(Location_Y) + Add_Y))
		if target.get_child_count() == 0:
			Areas.append(target.name)
		else:
			# CHANGED: Allow enemy capture then break.
			var occupant = target.get_child(0)
			if occupant.Item_Color != piece_color:
				Areas.append(target.name)
			break
		Add_X += 1
		Add_Y += 1

	Add_X = 1
	Add_Y = 1
	# Down-left diagonal
	while not Is_Null(str(int(Location_X) - Add_X) + "-" + str(int(Location_Y) + Add_Y)):
		var target = Flow.get_node(str(int(Location_X) - Add_X) + "-" + str(int(Location_Y) + Add_Y))
		if target.get_child_count() == 0:
			Areas.append(target.name)
		else:
			var occupant = target.get_child(0)
			if occupant.Item_Color != piece_color:
				Areas.append(target.name)
			break
		Add_X += 1
		Add_Y += 1

	Add_X = 1
	Add_Y = 1
	# Up-right diagonal
	while not Is_Null(str(int(Location_X) + Add_X) + "-" + str(int(Location_Y) - Add_Y)):
		var target = Flow.get_node(str(int(Location_X) + Add_X) + "-" + str(int(Location_Y) - Add_Y))
		if target.get_child_count() == 0:
			Areas.append(target.name)
		else:
			var occupant = target.get_child(0)
			if occupant.Item_Color != piece_color:
				Areas.append(target.name)
			break
		Add_X += 1
		Add_Y += 1

	Add_X = 1
	Add_Y = 1
	# Up-left diagonal
	while not Is_Null(str(int(Location_X) - Add_X) + "-" + str(int(Location_Y) - Add_Y)):
		var target = Flow.get_node(str(int(Location_X) - Add_X) + "-" + str(int(Location_Y) - Add_Y))
		if target.get_child_count() == 0:
			Areas.append(target.name)
		else:
			var occupant = target.get_child(0)
			if occupant.Item_Color != piece_color:
				Areas.append(target.name)
			break
		Add_X += 1
		Add_Y += 1

func Get_Horse():
	var Flow = get_node("Flow")
	var The_X = 2
	var The_Y = 1
	var number = 0
	var piece_color = get_node("Flow/" + Selected_Node).get_child(0).Item_Color
	while number != 8:
		# So this one is interesting. This is most likely the cleanest code here.
		# Get the numbers, replace the numbers, and loop until it stops.
		if not Is_Null(str(int(Location_X) + The_X) + "-" + str(int(Location_Y) + The_Y)) and (Flow.get_node(str(int(Location_X) + The_X) + "-" + str(int(Location_Y) + The_Y)).get_child_count() == 0 or Flow.get_node(str(int(Location_X) + The_X) + "-" + str(int(Location_Y) + The_Y)).get_child(0).Item_Color != piece_color):
			Areas.append(str(int(Location_X) + The_X) + "-" + str(int(Location_Y) + The_Y))
		number += 1
		match number:
			1:
				The_X = 1
				The_Y = 2
			2:
				The_X = -2
				The_Y = 1
			3:
				The_X = -1
				The_Y = 2
			4:
				The_X = 2
				The_Y = -1
			5:
				The_X = 1
				The_Y = -2
			6:
				The_X = -2
				The_Y = -1
			7:
				The_X = -1
				The_Y = -2
				
	print(Areas)

func Castle():
	# This is the castling section right here, used if a person wants to castle.
	var Flow = get_node("Flow")
	var X_Counter = 1
	# These are very similar to gathering a row, except we want free tiles and a rook
	# Counting up
	while not Is_Null(str(int(Location_X) + X_Counter) + "-" + Location_Y) && Flow.get_node(str(int(Location_X) + X_Counter) + "-" + Location_Y).get_child_count() == 0:
		X_Counter += 1
	if not Is_Null(str(int(Location_X) + X_Counter) + "-" + Location_Y) && Flow.get_node(str(int(Location_X) + X_Counter) + "-" + Location_Y).get_child(0).name == "Rook":
		if Flow.get_node(str(int(Location_X) + X_Counter) + "-" + Location_Y).get_child(0).Castling == true:
			Areas.append(str(int(Location_X) + X_Counter) + "-" + Location_Y)
			Special_Area.append(str(int(Location_X) + 1) + "-" + Location_Y)
			Special_Area.append(str(int(Location_X) + 2) + "-" + Location_Y)
	# Counting down
	X_Counter = -1
	while not Is_Null(str(int(Location_X) + X_Counter) + "-" + Location_Y) && Flow.get_node(str(int(Location_X) + X_Counter) + "-" + Location_Y).get_child_count() == 0:
		X_Counter -= 1
	if not Is_Null(str(int(Location_X) + X_Counter) + "-" + Location_Y) && Flow.get_node(str(int(Location_X) + X_Counter) + "-" + Location_Y).get_child(0).name == "Rook":
		if Flow.get_node(str(int(Location_X) + X_Counter) + "-" + Location_Y).get_child(0).Castling == true:
			Areas.append(str(int(Location_X) + X_Counter) + "-" + Location_Y)
			Special_Area.append(str(int(Location_X) - 1) + "-" + Location_Y)
			Special_Area.append(str(int(Location_X) - 2) + "-" + Location_Y)

# One function that shortens everything. Its also a pretty good way to see if we went off the board or not.
func Is_Null(Location):
	if get_node_or_null("Flow/" + Location) == null:
		return true
	else:
		return false


func Reset_Tile_Colors():
	var Flow = get_node("Flow")
	for y in range(8):
		for x in range(8):
			var tile = Flow.get_node(str(x) + "-" + str(y))
			if tile is TextureButton:
				var is_white = (x + y) % 2 == 0
				tile.texture_normal = load("res://assets/white_board.png") if is_white else load("res://assets/black_board.png")
