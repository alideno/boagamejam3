extends Control

var Selected_Node = ""
var Turn = 0

var Location_X = ""
var Location_Y = ""

var unfuseable = ["King","ElitePawn"]

var pos = Vector2(50, 50)
var Areas: PackedStringArray
# Special_Area is used for castling/en passant conditions.
var Special_Area: PackedStringArray

func _on_flow_send_location(location: String):
	# Parse the location string (e.g. "3-4") into coordinates.
	parseLocation(location)
	# Dispatch based on selection state.
	processSelection(location)

func parseLocation(location: String):
	var parts = location.split("-")
	if parts.size() >= 2:
		Location_X = parts[0]
		Location_Y = parts[1]
	else:
		print("Invalid location format: ", location)

func processSelection(location: String):
	var targetNode = get_node("Flow/" + location)
	# If no piece is selected yet, select a friendly piece.
	if Selected_Node == "":
		if targetNode.get_child_count() != 0 and targetNode.get_child(0).Item_Color == Turn:
			selectPiece(location)
		return

	# A piece is already selected.
	var selectedPiece = get_node("Flow/" + Selected_Node).get_child(0)
	if targetNode.get_child_count() != 0:
		var targetPiece = targetNode.get_child(0)
		# Friendly piece on target.
		if targetPiece.Item_Color == Turn:
			#if targetPiece.name == "Rook":
				#processCastling(location)
			# Fusion: only allow if both are pawns and the target lies on a valid diagonal.
			if targetPiece.name == "Pawn" and selectedPiece.name == "Pawn":
				var selCoords = parseLocationToCoords(Selected_Node)
				var targetCoords = parseLocationToCoords(location)
				if isValidPawnFusion(selCoords, targetCoords, selectedPiece.Item_Color):
					processFuse(location)
				else:
					reselectPiece(location)
			else:
				reselectPiece(location)
		# Enemy piece on target.
		else:
			if targetPiece.name == "Pawn" and targetPiece.get("En_Passant") == true and Special_Area.size() != 0 and Special_Area[0] == targetNode.name:
				processEnPassant(location)
			else:
				processCapture(location)
	else:
		# Empty square: attempt a normal move.
		processMove(location)

# Helper: Parse a location string ("x-y") into a Vector2 with integer coordinates.
func parseLocationToCoords(location: String) -> Vector2:
	var parts = location.split("-")
	return Vector2(int(parts[0]), int(parts[1]))

# Helper: For a pawn, fusion (friendly capture) is allowed only if the target is on the correct diagonal.
func isValidPawnFusion(selCoords: Vector2, targetCoords: Vector2, piece_color: int) -> bool:
	# For white (color 0), a pawn can capture diagonally to (sel.x ± 1, sel.y - 1).
	# For black (color 1), a pawn can capture diagonally to (sel.x ± 1, sel.y + 1).
	if piece_color == 0:
		return (abs(targetCoords.x - selCoords.x) == 1) and (targetCoords.y == selCoords.y - 1)
	else:
		return (abs(targetCoords.x - selCoords.x) == 1) and (targetCoords.y == selCoords.y + 1)

func selectPiece(location: String):
	Selected_Node = location
	Get_Moveable_Areas()

func reselectPiece(location: String):
	Selected_Node = location
	Get_Moveable_Areas()

func processCastling(location: String):
	pass
	#var targetNode = get_node("Flow/" + location)
	#for i in Areas:
		#if i == targetNode.name:
			#var king = get_node("Flow/" + Selected_Node).get_child(0)
			#var rook = targetNode.get_child(0)
			#king.reparent(get_node("Flow/" + Special_Area[1]))
			#rook.reparent(get_node("Flow/" + Special_Area[0]))
			#king.position = pos
			#rook.position = pos
			#Update_Game(king.get_parent())
			#return

func processEnPassant(location: String):
	var targetNode = get_node("Flow/" + location)
	for i in Special_Area:
		if i == targetNode.name:
			var pawn = get_node("Flow/" + Selected_Node).get_child(0)
			targetNode.get_child(0).free()
			pawn.reparent(get_node("Flow/" + Special_Area[1]))
			pawn.position = pos
			Update_Game(pawn.get_parent())
			return

func processFuse(location: String):
	var targetNode = get_node("Flow/" + location)
	var capturingPawn = get_node("Flow/" + Selected_Node).get_child(0)
	# Remove the target friendly pawn.
	targetNode.get_child(0).free()
	
	var elitePawn = preload("res://addons/Chess/Scripts/ElitePawn.gd").new()
	elitePawn.name = "ElitePawn"   # Ensure its name is set
	# Option 2: Alternatively, you can use set()/get() if the property isn't directly accessible:
	elitePawn.set("Item_Color", capturingPawn.get("Item_Color"))
	elitePawn.position = pos
	capturingPawn.queue_free()
	targetNode.add_child(elitePawn)
	Update_Game(targetNode)

func processCapture(location: String):
	var targetNode = get_node("Flow/" + location)
	for i in Areas:
		if i == targetNode.name:
			var piece = get_node("Flow/" + Selected_Node).get_child(0)
			if targetNode.get_child(0).name == "King":
				print("Damn, you win!")
			targetNode.get_child(0).free()
			piece.reparent(targetNode)
			piece.position = pos
			Update_Game(targetNode)
			return

func processMove(location: String):
	var targetNode = get_node("Flow/" + location)
	for i in Areas:
		if i == targetNode.name:
			var piece = get_node("Flow/" + Selected_Node).get_child(0)
			piece.reparent(targetNode)
			piece.position = pos
			Update_Game(targetNode)
			return

func Update_Game(node):
	Selected_Node = ""
	Turn = 1 - Turn
	Reset_Tile_Colors()
	
	# Reset en passant flags on enemy pawns.
	var things = get_node("Flow").get_children()
	for i in things:
		if i.get_child_count() != 0 and i.get_child(0).name == "Pawn" and i.get_child(0).Item_Color == Turn and i.get_child(0).En_Passant == true:
			i.get_child(0).set("En_Passant", false)
	
	# Update special move flags.
	if node.get_child(0).name == "Pawn":
		if node.get_child(0).Double_Start == true:
			node.get_child(0).En_Passant = true
		node.get_child(0).Double_Start = false
	if node.get_child(0).name == "King":
		node.get_child(0).Castling = false
	if node.get_child(0).name == "Rook":
		node.get_child(0).Castling = false

func Get_Moveable_Areas():
	
	var Flow = get_node("Flow")
	Areas.clear()
	Special_Area.clear()
	Reset_Tile_Colors()
	var Piece = get_node("Flow/" + Selected_Node).get_child(0)
	if Piece.name == "Pawn":
		Get_Pawn(Piece, Flow)
	elif Piece.name == "Bishop":
		Get_Diagonals(Flow)
	elif Piece.name == "King":
		Get_Around(Piece)
	elif Piece.name == "Queen":
		Get_Diagonals(Flow)
		Get_Rows(Flow)
	elif Piece.name == "Rook":
		Get_Rows(Flow)
	elif Piece.name == "Knight":
		Get_Horse()
	elif Piece.name == "ElitePawn":
		Get_Elite_Pawn(Piece, Flow)

	
	var newArea = []
	for area in Areas:
		var temp = get_node("Flow/" + area).get_child(0)
		if temp == null:
			newArea.append(area)
		if (temp != null) and (temp.name not in unfuseable):
			newArea.append(area)
		if(temp != null) and (temp.name in unfuseable):
			continue
		var tile = Flow.get_node(area)
		if tile is TextureButton:
			tile.texture_normal = load("res://assets/highlight.png")
	Areas = newArea


# ------------------------------------------------------------------
# (The following movement functions remain similar to your original code.)
# ------------------------------------------------------------------

func Get_Crusedar(Piece,Flow):
	var piece_color = Piece.Item_Color
	print("asdasd")

func Get_Elite_Pawn(Piece, Flow):
	var piece_color = Piece.Item_Color
	if piece_color == 0:  # White pawn
		var forward_one = Location_X + "-" + str(int(Location_Y) - 1)
		var diag_left = str(int(Location_X) - 1) + "-" + str(int(Location_Y) - 1)
		var diag_right = str(int(Location_X) + 1) + "-" + str(int(Location_Y) - 1)
		if not Is_Null(forward_one) and (Flow.get_node(forward_one).get_child_count() == 0 or Flow.get_node(forward_one).get_child(0).Item_Color != piece_color):
			Areas.append(forward_one)
		if not Is_Null(diag_left) and (Flow.get_node(diag_left).get_child_count() == 0 or Flow.get_node(diag_left).get_child(0).Item_Color != piece_color):
			Areas.append(diag_left)
		if not Is_Null(diag_right) and (Flow.get_node(diag_right).get_child_count() == 0 or Flow.get_node(diag_right).get_child(0).Item_Color != piece_color):
			Areas.append(diag_right)
	else:  # Black pawn
		var forward_one = Location_X + "-" + str(int(Location_Y) + 1)
		var diag_left = str(int(Location_X) - 1) + "-" + str(int(Location_Y) + 1)
		var diag_right = str(int(Location_X) + 1) + "-" + str(int(Location_Y) + 1)
		if not Is_Null(forward_one) and (Flow.get_node(forward_one).get_child_count() == 0 or Flow.get_node(forward_one).get_child(0).Item_Color != piece_color):
			Areas.append(forward_one)
		if not Is_Null(diag_left) and (Flow.get_node(diag_left).get_child_count() == 0 or Flow.get_node(diag_left).get_child(0).Item_Color != piece_color):
			Areas.append(diag_left)
		if not Is_Null(diag_right) and (Flow.get_node(diag_right).get_child_count() == 0 or Flow.get_node(diag_right).get_child(0).Item_Color != piece_color):
			Areas.append(diag_right)

func Get_Pawn(Piece, Flow):
	var piece_color = Piece.Item_Color
	if piece_color == 0:  # White pawn
		var forward_one = Location_X + "-" + str(int(Location_Y) - 1)
		if not Is_Null(forward_one) and Flow.get_node(forward_one).get_child_count() == 0:
			Areas.append(forward_one)
			if Piece.Double_Start:
				var forward_two = Location_X + "-" + str(int(Location_Y) - 2)
				if not Is_Null(forward_two) and Flow.get_node(forward_two).get_child_count() == 0:
					Areas.append(forward_two)
		var diag_left = str(int(Location_X) - 1) + "-" + str(int(Location_Y) - 1)
		var diag_right = str(int(Location_X) + 1) + "-" + str(int(Location_Y) - 1)
		if not Is_Null(diag_left):
			var target = Flow.get_node(diag_left)
			if target.get_child_count() > 0:
				Areas.append(diag_left)
		if not Is_Null(diag_right):
			var target = Flow.get_node(diag_right)
			if target.get_child_count() > 0:
				Areas.append(diag_right)
	else:  # Black pawn
		var forward_one = Location_X + "-" + str(int(Location_Y) + 1)
		if not Is_Null(forward_one) and Flow.get_node(forward_one).get_child_count() == 0:
			Areas.append(forward_one)
			if Piece.Double_Start:
				var forward_two = Location_X + "-" + str(int(Location_Y) + 2)
				if not Is_Null(forward_two) and Flow.get_node(forward_two).get_child_count() == 0:
					Areas.append(forward_two)
		var diag_left = str(int(Location_X) - 1) + "-" + str(int(Location_Y) + 1)
		var diag_right = str(int(Location_X) + 1) + "-" + str(int(Location_Y) + 1)
		if not Is_Null(diag_left):
			var target = Flow.get_node(diag_left)
			if target.get_child_count() > 0:
				Areas.append(diag_left)
		if not Is_Null(diag_right):
			var target = Flow.get_node(diag_right)
			if target.get_child_count() > 0:
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
	var piece_color = get_node("Flow/" + Selected_Node).get_child(0).Item_Color
	var Add_X = 1
	while not Is_Null(str(int(Location_X) + Add_X) + "-" + Location_Y):
		var target = Flow.get_node(str(int(Location_X) + Add_X) + "-" + Location_Y)
		if target.get_child_count() == 0:
			Areas.append(target.name)
		else:
			Areas.append(target.name)
			break
		Add_X += 1
	Add_X = 1
	while not Is_Null(str(int(Location_X) - Add_X) + "-" + Location_Y):
		var target = Flow.get_node(str(int(Location_X) - Add_X) + "-" + Location_Y)
		if target.get_child_count() == 0:
			Areas.append(target.name)
		else:
			Areas.append(target.name)
			break
		Add_X += 1
	var Add_Y = 1
	while not Is_Null(Location_X + "-" + str(int(Location_Y) + Add_Y)):
		var target = Flow.get_node(Location_X + "-" + str(int(Location_Y) + Add_Y))
		if target.get_child_count() == 0:
			Areas.append(target.name)
		else:
			Areas.append(target.name)
			break
		Add_Y += 1
	Add_Y = 1
	while not Is_Null(Location_X + "-" + str(int(Location_Y) - Add_Y)):
		var target = Flow.get_node(Location_X + "-" + str(int(Location_Y) - Add_Y))
		if target.get_child_count() == 0:
			Areas.append(target.name)
		else:
			Areas.append(target.name)
			break
		Add_Y += 1

func Get_Diagonals(Flow):
	var piece_color = get_node("Flow/" + Selected_Node).get_child(0).Item_Color
	var Add_X = 1
	var Add_Y = 1
	while not Is_Null(str(int(Location_X) + Add_X) + "-" + str(int(Location_Y) + Add_Y)):
		var target = Flow.get_node(str(int(Location_X) + Add_X) + "-" + str(int(Location_Y) + Add_Y))
		if target.get_child_count() == 0:
			Areas.append(target.name)
		else:
			Areas.append(target.name)
			break
		Add_X += 1
		Add_Y += 1
	Add_X = 1
	Add_Y = 1
	while not Is_Null(str(int(Location_X) - Add_X) + "-" + str(int(Location_Y) + Add_Y)):
		var target = Flow.get_node(str(int(Location_X) - Add_X) + "-" + str(int(Location_Y) + Add_Y))
		if target.get_child_count() == 0:
			Areas.append(target.name)
		else:
			Areas.append(target.name)
			break
		Add_X += 1
		Add_Y += 1
	Add_X = 1
	Add_Y = 1
	while not Is_Null(str(int(Location_X) + Add_X) + "-" + str(int(Location_Y) - Add_Y)):
		var target = Flow.get_node(str(int(Location_X) + Add_X) + "-" + str(int(Location_Y) - Add_Y))
		if target.get_child_count() == 0:
			Areas.append(target.name)
		else:
			Areas.append(target.name)
			break
		Add_X += 1
		Add_Y += 1
	Add_X = 1
	Add_Y = 1
	while not Is_Null(str(int(Location_X) - Add_X) + "-" + str(int(Location_Y) - Add_Y)):
		var target = Flow.get_node(str(int(Location_X) - Add_X) + "-" + str(int(Location_Y) - Add_Y))
		if target.get_child_count() == 0:
			Areas.append(target.name)
		else:
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
		if not Is_Null(str(int(Location_X) + The_X) + "-" + str(int(Location_Y) + The_Y)):
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
				

func Castle():
	pass
	#var Flow = get_node("Flow")
	#var X_Counter = 1
	#while not Is_Null(str(int(Location_X) + X_Counter) + "-" + Location_Y) and Flow.get_node(str(int(Location_X) + X_Counter) + "-" + Location_Y).get_child_count() == 0:
		#X_Counter += 1
	#if not Is_Null(str(int(Location_X) + X_Counter) + "-" + Location_Y) and Flow.get_node(str(int(Location_X) + X_Counter) + "-" + Location_Y).get_child(0).name == "Rook":
		#if Flow.get_node(str(int(Location_X) + X_Counter) + "-" + Location_Y).get_child(0).Castling == true:
			#Areas.append(str(int(Location_X) + X_Counter) + "-" + Location_Y)
			#Special_Area.append(str(int(Location_X) + 1) + "-" + Location_Y)
			#Special_Area.append(str(int(Location_X) + 2) + "-" + Location_Y)
	#X_Counter = -1
	#while not Is_Null(str(int(Location_X) + X_Counter) + "-" + Location_Y) and Flow.get_node(str(int(Location_X) + X_Counter) + "-" + Location_Y).get_child_count() == 0:
		#X_Counter -= 1
	#if not Is_Null(str(int(Location_X) + X_Counter) + "-" + Location_Y) and Flow.get_node(str(int(Location_X) + X_Counter) + "-" + Location_Y).get_child(0).name == "Rook":
		#if Flow.get_node(str(int(Location_X) + X_Counter) + "-" + Location_Y).get_child(0).Castling == true:
			#Areas.append(str(int(Location_X) + X_Counter) + "-" + Location_Y)
			#Special_Area.append(str(int(Location_X) - 1) + "-" + Location_Y)
			#Special_Area.append(str(int(Location_X) - 2) + "-" + Location_Y)

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
