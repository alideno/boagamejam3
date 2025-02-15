extends Control

var Selected_Node = ""
var Turn = 0

var Location_X = ""
var Location_Y = ""

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
			if targetPiece.name == "Rook":
				processCastling(location)
			# Fusion: only allow if both are pawns and the target lies on a valid diagonal.
			elif targetPiece.name == "Pawn" and selectedPiece.name == "Pawn":
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
	var targetNode = get_node("Flow/" + location)
	for i in Areas:
		if i == targetNode.name:
			var king = get_node("Flow/" + Selected_Node).get_child(0)
			var rook = targetNode.get_child(0)
			king.reparent(get_node("Flow/" + Special_Area[1]))
			rook.reparent(get_node("Flow/" + Special_Area[0]))
			king.position = pos
			rook.position = pos
			Update_Game(king.get_parent())
			return

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
	var Piece = get_node("Flow/" + Selected_Node).get_child(0)
	if Piece.name == "Pawn":
		Get_Pawn(Piece, Flow)
	elif Piece.name == "Bishop":
		Get_Bishop(Piece, Flow)
	elif Piece.name == "King":
		Get_Around(Piece)
	elif Piece.name == "Queen":
		Get_Bishop(Piece, Flow)
		Get_Rook(Piece, Flow)
	elif Piece.name == "Rook":
		Get_Rook(Piece, Flow)
	elif Piece.name == "Knight":
		Get_Horse(Piece, Flow)
	elif Piece.name == "ElitePawn":
		Get_Elite_Pawn(Piece, Flow)
	print(Areas)

# ------------------------------------------------------------------
# (The following movement functions remain similar to your original code.)
# ------------------------------------------------------------------

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
	var Flow = get_node("Flow")
	var piece_color = get_node("Flow/" + Selected_Node).get_child(0).Item_Color
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
				var occupant = target.get_child(0)
				if occupant.Item_Color != piece_color:
					Areas.append(pos_str)
					
func Get_Rook(Piece, Flow):
	var piece_color = Piece.Item_Color
	var ortho_offsets = [
		Vector2( 0, -1),  # up
		Vector2( 0,  1),  # down
		Vector2(-1,  0),  # left
		Vector2( 1,  0)   # right
	]
	for offset in ortho_offsets:
		for d in range(1, 4):  # d = 1, 2, 3
			var candidateX = int(Location_X) + int(offset.x) * d
			var candidateY = int(Location_Y) + int(offset.y) * d
			var candidate = str(candidateX) + "-" + str(candidateY)
			if Is_Null(candidate):
				break
			var candidateNode = Flow.get_node(candidate)
			if candidateNode.get_child_count() == 0:
				Areas.append(candidate)
				if candidateNode.get_child(0).Item_Color != piece_color:
					Areas.append(candidate)
				break

func Get_Bishop(Piece, Flow):
	var piece_color = Piece.Item_Color
	var diagOffsets = [
		Vector2(-1, -1),  # Up-left
		Vector2(1, -1),   # Up-right
		Vector2(-1, 1),   # Bottom-left
		Vector2(1, 1)     # Bottom-right
	]
	for offset in diagOffsets:
		# Start from distance 2 (since one-unit diagonal moves are not allowed)
		for d in range(1, 4):  # d = 1, 2 and 3
			var candidateX = int(Location_X) + int(offset.x) * d
			var candidateY = int(Location_Y) + int(offset.y) * d
			var candidate = str(candidateX) + "-" + str(candidateY)
			# If candidate is off-board, break out.
			if Is_Null(candidate):
				break
			var candidateNode = Flow.get_node(candidate)
			if candidateNode.get_child_count() == 0:
				Areas.append(candidate)
			else:
				# If an opponent's piece is present, capture is allowed, but no further sliding.
				if candidateNode.get_child(0).Item_Color != piece_color:
					Areas.append(candidate)
				break  # Stop sliding in this direction if any piece is encountered.
	

func Get_Horse(Piece, Flow):
	var The_X = 2
	var The_Y = 1
	var number = 0
	var piece_color = Piece.Item_Color
	while number != 8:
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
			
func Get_Guarded_Knight(Piece, Flow):
	var piece_color = Piece.Item_Color
	var offsets = [
		Vector2(-1, -1),  # up_left
		Vector2( 1, -1),  # up_right
		Vector2(-1,  1),  # bottom_left
		Vector2( 1,  1),  # bottom_right
		Vector2(-1, -2),  # twoUp_oneLeft
		Vector2( 1, -2),  # twoUp_oneRight
		Vector2(-2, -1),  # oneUp_twoLeft
		Vector2( 2, -1),  # oneUp_twoRight
		Vector2(-1,  2),  # twoBottom_oneLeft
		Vector2( 1,  2),  # twoBottom_oneRight
		Vector2(-2,  1),  # oneBottom_twoLeft
		Vector2( 2,  1)   # oneBottom_twoRight
	]

# Loop over each offset and calculate the candidate location string.
	for offset in offsets:
		var candidate = str(int(Location_X) + int(offset.x)) + "-" + str(int(Location_Y) + int(offset.y))
		if not Is_Null(candidate) and (Flow.get_node(candidate).get_child_count() == 0 or Flow.get_node(candidate).get_child(0).Item_Color != piece_color):
			Areas.append(candidate)

func Get_Cavalier(Piece, Flow):
	# Define your groups of offsets (using Vector2 for x and y offsets)
	var offset_groups = [
		# Group 1: pure horizontal/vertical moves of 3 units.
		[Vector2(0, -3), Vector2(3, 0), Vector2(-3, 0), Vector2(0, 3)],
		# Group 2: diagonals where Y changes by 3 and X by 1.
		[Vector2(-1, -3), Vector2(1, -3), Vector2(-1, 3), Vector2(1, 3)],
		# Group 3: diagonals where Y changes by 2 and X by 1.
		[Vector2(-1, -2), Vector2(1, -2), Vector2(-1, 2), Vector2(1, 2)],
		# Group 4: moves where X changes by 2 or 3 and Y by 1.
		[Vector2(3, -1), Vector2(3, 1), Vector2(2, -1), Vector2(2, 1),
		Vector2(-3, -1), Vector2(-3, 1), Vector2(-2, -1), Vector2(-2, 1)]
	]

	var piece_color = Piece.Item_Color
	for group in offset_groups:
		for offset in group:
			var candidate = str(int(Location_X) + int(offset.x)) + "-" + str(int(Location_Y) + int(offset.y))
			if not Is_Null(candidate) and (Flow.get_node(candidate).get_child_count() == 0 or Flow.get_node(candidate).get_child(0).Item_Color != piece_color):
				Areas.append(candidate)

func Get_Guarded_Bishop(Piece, Flow):
	# Get the bishop's color (assumed to be in the currently selected node).
	var piece_color = Piece.Item_Color

	# --- 1. One-unit orthogonal moves only (no diagonals) ---
	var oneUnitOffsets = [
		Vector2(0, -1),  # Up
		Vector2(-1, 0),  # Left
		Vector2(1, 0),   # Right
		Vector2(0, 1)    # Down
	]
	for offset in oneUnitOffsets:
		var candidateX = int(Location_X) + int(offset.x)
		var candidateY = int(Location_Y) + int(offset.y)
		var candidate = str(candidateX) + "-" + str(candidateY)
		if not Is_Null(candidate):
			var candidateNode = Flow.get_node(candidate)
			# Add the candidate if the square is empty or has an opponent's piece.
			if candidateNode.get_child_count() == 0 or candidateNode.get_child(0).Item_Color != piece_color:
				Areas.append(candidate)

	# --- 2. Diagonal sliding moves (minimum 1 units, maximum 3 units) ---
	var diagOffsets = [
		Vector2(-1, -1),  # Up-left
		Vector2(1, -1),   # Up-right
		Vector2(-1, 1),   # Bottom-left
		Vector2(1, 1)     # Bottom-right
	]
	for offset in diagOffsets:
		# Start from distance 2 (since one-unit diagonal moves are not allowed)
		for d in range(1, 4):  # d = 1, 2 and 3
			var candidateX = int(Location_X) + int(offset.x) * d
			var candidateY = int(Location_Y) + int(offset.y) * d
			var candidate = str(candidateX) + "-" + str(candidateY)
			# If candidate is off-board, break out.
			if Is_Null(candidate):
				break
			var candidateNode = Flow.get_node(candidate)
			if candidateNode.get_child_count() == 0:
				Areas.append(candidate)
			else:
				# If an opponent's piece is present, capture is allowed, but no further sliding.
				if candidateNode.get_child(0).Item_Color != piece_color:
					Areas.append(candidate)
				break  # Stop sliding in this direction if any piece is encountered.

func Get_Crusader(Piece, Flow):
	var piece_color = Piece.Item_Color
	# Base offsets in one quadrant (e.g. first quadrant where x > 0, y > 0)
	var baseOffsets = [
		Vector2(1, 1),
		Vector2(1, 2),
		Vector2(2, 1),
		Vector2(2, 2),
		Vector2(2, 3),
		Vector2(3, 2),
		Vector2(3, 3)
	]
	
	# Generate all mirror images (over vertical and horizontal axes)
	var offsets = []
	for offset in baseOffsets:
		offsets.append(offset)
		offsets.append(Vector2(-offset.x, offset.y))
		offsets.append(Vector2(offset.x, -offset.y))
		offsets.append(Vector2(-offset.x, -offset.y))
	
	# Loop over each offset and check candidate square.
	for offset in offsets:
		var candidateX = int(Location_X) + int(offset.x)
		var candidateY = int(Location_Y) + int(offset.y)
		var candidate = str(candidateX) + "-" + str(candidateY)
		# Only add if the candidate square exists and is either empty or occupied by an opponent.
		if not Is_Null(candidate):
			var candidateNode = Flow.get_node(candidate)
			if candidateNode.get_child_count() == 0 or candidateNode.get_child(0).Item_Color != piece_color:
				Areas.append(candidate)
				
func Get_Pope(Piece, Flow):
	var piece_color = Piece.Item_Color
	var Add_X = 1
	var Add_Y = 1
	while not Is_Null(str(int(Location_X) + Add_X) + "-" + str(int(Location_Y) + Add_Y)):
		var target = Flow.get_node(str(int(Location_X) + Add_X) + "-" + str(int(Location_Y) + Add_Y))
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
		
func Get_Guarded_Rook(Piece, Flow):
	var piece_color = Piece.Item_Color

	var diag_offsets = [
		Vector2(-1, -1),  # up-left
		Vector2( 1, -1),  # up-right
		Vector2(-1,  1),  # bottom-left
		Vector2( 1,  1)   # bottom-right
	]
	for offset in diag_offsets:
		var candidateX = int(Location_X) + int(offset.x)
		var candidateY = int(Location_Y) + int(offset.y)
		var candidate = str(candidateX) + "-" + str(candidateY)
		if not Is_Null(candidate):
			var candidateNode = Flow.get_node(candidate)
			# Allow move if square is empty or contains an opponent piece.
			if candidateNode.get_child_count() == 0 or candidateNode.get_child(0).Item_Color != piece_color:
				Areas.append(candidate)
	
	var ortho_offsets = [
		Vector2( 0, -1),  # up
		Vector2( 0,  1),  # down
		Vector2(-1,  0),  # left
		Vector2( 1,  0)   # right
	]
	for offset in ortho_offsets:
		for d in range(1, 4):  # d = 1, 2, 3
			var candidateX = int(Location_X) + int(offset.x) * d
			var candidateY = int(Location_Y) + int(offset.y) * d
			var candidate = str(candidateX) + "-" + str(candidateY)
			if Is_Null(candidate):
				break
			var candidateNode = Flow.get_node(candidate)
			if candidateNode.get_child_count() == 0:
				Areas.append(candidate)
				if candidateNode.get_child(0).Item_Color != piece_color:
					Areas.append(candidate)
				break

func Get_Siege_Camp(Piece, Flow):
	var piece_color = Piece.Item_Color
	var base_offsets = [
		Vector2(1, 1),
		Vector2(1, 3),
		Vector2(3, 1)
	]
	var offsets = []
	for base in base_offsets:
		offsets.append(base)
		offsets.append(Vector2(-base.x, base.y))
		offsets.append(Vector2(base.x, -base.y))
		offsets.append(Vector2(-base.x, -base.y))
	
	for offset in offsets:
		var candidateX = int(Location_X) + int(offset.x)
		var candidateY = int(Location_Y) + int(offset.y)
		var candidate = str(candidateX) + "-" + str(candidateY)
		if not Is_Null(candidate):
			var candidateNode = Flow.get_node(candidate)
			if candidateNode.get_child_count() == 0 or candidateNode.get_child(0).Item_Color != piece_color:
				Areas.append(candidate)
	
	
	var ortho_offsets = [
		Vector2( 0, -1),  # up
		Vector2( 0,  1),  # down
		Vector2(-1,  0),  # left
		Vector2( 1,  0)   # right
	]
	for offset in ortho_offsets:
		for d in range(1, 4):  # d = 1, 2, 3
			var candidateX = int(Location_X) + int(offset.x) * d
			var candidateY = int(Location_Y) + int(offset.y) * d
			var candidate = str(candidateX) + "-" + str(candidateY)
			if Is_Null(candidate):
				break
			var candidateNode = Flow.get_node(candidate)
			if candidateNode.get_child_count() == 0:
				Areas.append(candidate)
				if candidateNode.get_child(0).Item_Color != piece_color:
					Areas.append(candidate)
				break
	
func Get_Cathedral(Piece, Flow):
	var piece_color = Piece.Item_Color
	
	var diagOffsets = [
		Vector2(-1, -1),  # Up-left
		Vector2(1, -1),   # Up-right
		Vector2(-1, 1),   # Bottom-left
		Vector2(1, 1)     # Bottom-right
	]
	
	for offset in diagOffsets:
		# Start from distance 2 (since one-unit diagonal moves are not allowed)
		for d in range(1, 3):  # d = 1, 2 and 3
			var candidateX = int(Location_X) + int(offset.x) * d
			var candidateY = int(Location_Y) + int(offset.y) * d
			var candidate = str(candidateX) + "-" + str(candidateY)
			# If candidate is off-board, break out.
			if Is_Null(candidate):
				break
			var candidateNode = Flow.get_node(candidate)
			if candidateNode.get_child_count() == 0:
				Areas.append(candidate)
			else:
				# If an opponent's piece is present, capture is allowed, but no further sliding.
				if candidateNode.get_child(0).Item_Color != piece_color:
					Areas.append(candidate)
				break  # Stop sliding in this direction if any piece is encountered.

	var ortho_offsets = [
		Vector2( 0, -1),  # up
		Vector2( 0,  1),  # down
		Vector2(-1,  0),  # left
		Vector2( 1,  0)   # right
	]
	for offset in ortho_offsets:
		for d in range(1, 4):  # d = 1, 2, 3
			var candidateX = int(Location_X) + int(offset.x) * d
			var candidateY = int(Location_Y) + int(offset.y) * d
			var candidate = str(candidateX) + "-" + str(candidateY)
			if Is_Null(candidate):
				break
			var candidateNode = Flow.get_node(candidate)
			if candidateNode.get_child_count() == 0:
				Areas.append(candidate)
				if candidateNode.get_child(0).Item_Color != piece_color:
					Areas.append(candidate)
				break

func Get_Fortress(Piece, Flow):
	var piece_color = Piece.Item_Color
	var Add_X = 1
	while not Is_Null(str(int(Location_X) + Add_X) + "-" + Location_Y):
		var target = Flow.get_node(str(int(Location_X) + Add_X) + "-" + Location_Y)
		if target.get_child_count() == 0:
			Areas.append(target.name)
		else:
			var occupant = target.get_child(0)
			if occupant.Item_Color != piece_color:
				Areas.append(target.name)
			break
		Add_X += 1
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

func Get_Guarded_Queen(Piece, Flow):
	var piece_color = Piece.Item_Color
	
	var diagOffsets = [
		Vector2(-1, -1),  # Up-left
		Vector2(1, -1),   # Up-right
		Vector2(-1, 1),   # Bottom-left
		Vector2(1, 1)     # Bottom-right
	]
	
	for offset in diagOffsets:
		# Start from distance 2 (since one-unit diagonal moves are not allowed)
		for d in range(1, 4):  # d = 1, 2 and 3
			var candidateX = int(Location_X) + int(offset.x) * d
			var candidateY = int(Location_Y) + int(offset.y) * d
			var candidate = str(candidateX) + "-" + str(candidateY)
			# If candidate is off-board, break out.
			if Is_Null(candidate):
				break
			var candidateNode = Flow.get_node(candidate)
			if candidateNode.get_child_count() == 0:
				Areas.append(candidate)
			else:
				# If an opponent's piece is present, capture is allowed, but no further sliding.
				if candidateNode.get_child(0).Item_Color != piece_color:
					Areas.append(candidate)
				break  # Stop sliding in this direction if any piece is encountered.

	var ortho_offsets = [
		Vector2( 0, -1),  # up
		Vector2( 0,  1),  # down
		Vector2(-1,  0),  # left
		Vector2( 1,  0)   # right
	]
	for offset in ortho_offsets:
		for d in range(1, 5):  # d = 1, 2, 3, 4
			var candidateX = int(Location_X) + int(offset.x) * d
			var candidateY = int(Location_Y) + int(offset.y) * d
			var candidate = str(candidateX) + "-" + str(candidateY)
			if Is_Null(candidate):
				break
			var candidateNode = Flow.get_node(candidate)
			if candidateNode.get_child_count() == 0:
				Areas.append(candidate)
				if candidateNode.get_child(0).Item_Color != piece_color:
					Areas.append(candidate)
				break
				
func Get_Valkyre(Piece, Flow):
	var piece_color = Piece.Item_Color
	
	var diagOffsets = [
		Vector2(-1, -1),  # Up-left
		Vector2(1, -1),   # Up-right
		Vector2(-1, 1),   # Bottom-left
		Vector2(1, 1)     # Bottom-right
	]
	
	for offset in diagOffsets:
		# Start from distance 2 (since one-unit diagonal moves are not allowed)
		for d in range(1, 4):  # d = 1, 2 and 3
			var candidateX = int(Location_X) + int(offset.x) * d
			var candidateY = int(Location_Y) + int(offset.y) * d
			var candidate = str(candidateX) + "-" + str(candidateY)
			# If candidate is off-board, break out.
			if Is_Null(candidate):
				break
			var candidateNode = Flow.get_node(candidate)
			if candidateNode.get_child_count() == 0:
				Areas.append(candidate)
			else:
				# If an opponent's piece is present, capture is allowed, but no further sliding.
				if candidateNode.get_child(0).Item_Color != piece_color:
					Areas.append(candidate)
				break  # Stop sliding in this direction if any piece is encountered.

	var ortho_offsets = [
		Vector2( 0, -1),  # up
		Vector2( 0,  1),  # down
		Vector2(-1,  0),  # left
		Vector2( 1,  0)   # right
	]
	for offset in ortho_offsets:
		for d in range(1, 4):  # d = 1, 2, 3
			var candidateX = int(Location_X) + int(offset.x) * d
			var candidateY = int(Location_Y) + int(offset.y) * d
			var candidate = str(candidateX) + "-" + str(candidateY)
			if Is_Null(candidate):
				break
			var candidateNode = Flow.get_node(candidate)
			if candidateNode.get_child_count() == 0:
				Areas.append(candidate)
				if candidateNode.get_child(0).Item_Color != piece_color:
					Areas.append(candidate)
				break

	var The_X = 2
	var The_Y = 1
	var number = 0
	while number != 8:
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

func Get_Archqueen(Piece, Flow):
	var piece_color = Piece.Item_Color
	
	var ortho_offsets = [
		Vector2( 0, -1),  # up
		Vector2( 0,  1),  # down
		Vector2(-1,  0),  # left
		Vector2( 1,  0)   # right
	]
	for offset in ortho_offsets:
		for d in range(1, 4):  # d = 1, 2, 3
			var candidateX = int(Location_X) + int(offset.x) * d
			var candidateY = int(Location_Y) + int(offset.y) * d
			var candidate = str(candidateX) + "-" + str(candidateY)
			if Is_Null(candidate):
				break
			var candidateNode = Flow.get_node(candidate)
			if candidateNode.get_child_count() == 0:
				Areas.append(candidate)
				if candidateNode.get_child(0).Item_Color != piece_color:
					Areas.append(candidate)
				break
	
	var Add_X = 1
	var Add_Y = 1
	while not Is_Null(str(int(Location_X) + Add_X) + "-" + str(int(Location_Y) + Add_Y)):
		var target = Flow.get_node(str(int(Location_X) + Add_X) + "-" + str(int(Location_Y) + Add_Y))
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
		
func Get_Fortress_Queen(Piece, Flow):
	var piece_color = Piece.Item_Color
	var Add_X = 1
	while not Is_Null(str(int(Location_X) + Add_X) + "-" + Location_Y):
		var target = Flow.get_node(str(int(Location_X) + Add_X) + "-" + Location_Y)
		if target.get_child_count() == 0:
			Areas.append(target.name)
		else:
			var occupant = target.get_child(0)
			if occupant.Item_Color != piece_color:
				Areas.append(target.name)
			break
		Add_X += 1
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
		
	var diagOffsets = [
		Vector2(-1, -1),  # Up-left
		Vector2(1, -1),   # Up-right
		Vector2(-1, 1),   # Bottom-left
		Vector2(1, 1)     # Bottom-right
	]
	
	for offset in diagOffsets:
		# Start from distance 2 (since one-unit diagonal moves are not allowed)
		for d in range(1, 4):  # d = 1, 2 and 3
			var candidateX = int(Location_X) + int(offset.x) * d
			var candidateY = int(Location_Y) + int(offset.y) * d
			var candidate = str(candidateX) + "-" + str(candidateY)
			# If candidate is off-board, break out.
			if Is_Null(candidate):
				break
			var candidateNode = Flow.get_node(candidate)
			if candidateNode.get_child_count() == 0:
				Areas.append(candidate)
			else:
				# If an opponent's piece is present, capture is allowed, but no further sliding.
				if candidateNode.get_child(0).Item_Color != piece_color:
					Areas.append(candidate)
				break  # Stop sliding in this direction if any piece is encountered.


func Castle():
	var Flow = get_node("Flow")
	var X_Counter = 1
	while not Is_Null(str(int(Location_X) + X_Counter) + "-" + Location_Y) and Flow.get_node(str(int(Location_X) + X_Counter) + "-" + Location_Y).get_child_count() == 0:
		X_Counter += 1
	if not Is_Null(str(int(Location_X) + X_Counter) + "-" + Location_Y) and Flow.get_node(str(int(Location_X) + X_Counter) + "-" + Location_Y).get_child(0).name == "Rook":
		if Flow.get_node(str(int(Location_X) + X_Counter) + "-" + Location_Y).get_child(0).Castling == true:
			Areas.append(str(int(Location_X) + X_Counter) + "-" + Location_Y)
			Special_Area.append(str(int(Location_X) + 1) + "-" + Location_Y)
			Special_Area.append(str(int(Location_X) + 2) + "-" + Location_Y)
	X_Counter = -1
	while not Is_Null(str(int(Location_X) + X_Counter) + "-" + Location_Y) and Flow.get_node(str(int(Location_X) + X_Counter) + "-" + Location_Y).get_child_count() == 0:
		X_Counter -= 1
	if not Is_Null(str(int(Location_X) + X_Counter) + "-" + Location_Y) and Flow.get_node(str(int(Location_X) + X_Counter) + "-" + Location_Y).get_child(0).name == "Rook":
		if Flow.get_node(str(int(Location_X) + X_Counter) + "-" + Location_Y).get_child(0).Castling == true:
			Areas.append(str(int(Location_X) + X_Counter) + "-" + Location_Y)
			Special_Area.append(str(int(Location_X) - 1) + "-" + Location_Y)
			Special_Area.append(str(int(Location_X) - 2) + "-" + Location_Y)

func Is_Null(Location):
	if get_node_or_null("Flow/" + Location) == null:
		return true
	else:
		return false
