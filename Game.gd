extends Control

var Selected_Node = ""
var Turn = 0

var Location_X = ""
var Location_Y = ""

var pos = Vector2(50, 50)
var Areas: PackedStringArray
# this is seperate the Areas for special circumstances, like castling.
var Special_Area: PackedStringArray

var setpiece = ["Pawn", "Knight", "Bishop", "Rook", "Queen"]

func _on_flow_send_location(location: String):
<<<<<<< Updated upstream
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
	Reset_Tile_Colors()

func Update_Game(node):
	Selected_Node = ""
	if Turn == 0:
		Turn = 1
	else:
		Turn = 0
=======
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
			var selCoords = parseLocationToCoords(Selected_Node)
			var targetCoords = parseLocationToCoords(location)

			# Check if fusion is allowed
			if isValidFusion(selCoords, targetCoords, selectedPiece, targetPiece):
				processFuse(location)
			else:
				reselectPiece(location)

		# Enemy piece on target.
		else:
			if targetPiece.name == "Pawn" and targetPiece.get("En_Passant") == true and Special_Area.size() != 0 and Special_Area[0] == targetNode.name:
				processEnPassant(location)
			else: # if anyone wants to add the checkmate mechanizm than this is a nice place to start 
				processCapture(location)
	else:
		# Empty square: attempt a normal move.
		processMove(location)



# Helper: Parse a location string ("x-y") into a Vector2 with integer coordinates.
func parseLocationToCoords(location: String) -> Vector2:
	var parts = location.split("-")
	return Vector2(int(parts[0]), int(parts[1]))
	
func vector_to_string(vec: Vector2) -> String:
	return str(vec.x) + "-" + str(vec.y)
	

func isValidFusion(selCoords: Vector2, targetCoords: Vector2, selectedPiece: Node, targetPiece: Node) -> bool:
	# Ensure both pieces exist and belong to the same player
	if not selectedPiece or not targetPiece or selectedPiece.Item_Color != targetPiece.Item_Color:
		return false

	# Check if fusion is possible using the Fusion_Piece_Map
	var fusionName = getFusionPieceName(selectedPiece.name, targetPiece.name)
	if fusionName == "":
		return false  # No valid fusion exists
		
	var x = false
	for i in Areas:
		print("non target" + i)
		print("target coor: " + vector_to_string(targetCoords))
		if i == vector_to_string(targetCoords):
			x = true
	if x == false:
		return false
		
	# Special movement rules for pawns
	if selectedPiece.name == "Pawn":
		var piece_color = selectedPiece.Item_Color
		if piece_color == 0:
			return (abs(targetCoords.x - selCoords.x) == 1) and (targetCoords.y == selCoords.y - 1)
		else:
			return (abs(targetCoords.x - selCoords.x) == 1) and (targetCoords.y == selCoords.y + 1)

	# If no special movement rules apply, allow fusion
	return true
	

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

var Fusion_Piece_Map = {  
	# Pawn fusions  
	["Pawn", "Pawn"]: "ElitePawn",  

	# Knight fusions  
	["Pawn", "Knight"]: "GuardedKnight",  
	["Knight", "Knight"]: "Cavalier",  

	# Bishop fusions  
	["Pawn", "Bishop"]: "GuardedBishop",  
	["Knight", "Bishop"]: "Crusader",  
	["Bishop", "Bishop"]: "Pope",  

	# Rook fusions  
	["Pawn", "Rook"]: "GuardedRook",  
	["Knight", "Rook"]: "SiegeCamp",  
	["Bishop", "Rook"]: "Cathedral",  
	["Rook", "Rook"]: "Fortress",  

	# Queen fusions  
	["Pawn", "Queen"]: "GuardedQueen",  
	["Knight", "Queen"]: "Valkyre",  
	["Bishop", "Queen"]: "Archqueen",  
	["Rook", "Queen"]: "FortressQueen",  
	["Queen", "Queen"]: "Empress"  
}

func processFuse(location: String):
	var targetNode = get_node("Flow/" + location)
	var capturingPiece = get_node("Flow/" + Selected_Node).get_child(0)
	var targetPiece = targetNode.get_child(0)

	# Ensure both pieces exist and are of the same color.
	if not capturingPiece or not targetPiece or capturingPiece.Item_Color != targetPiece.Item_Color:
		return
	
	# Get fusion name
	var fusionPiece = getFusionPieceName(capturingPiece.name, targetPiece.name)
	if fusionPiece == "":
		print("Error: No valid fusion for " + capturingPiece.name + " + " + targetPiece.name)
		return
	
	# Load the fusion piece script dynamically
	var fused_script_path = "res://addons/Chess/Scripts/" + fusionPiece + ".gd"
	var fused_script = load(fused_script_path)


	if not fused_script:
		print("Error: Could not load fusion piece script at " + fused_script_path)
		return
	
	# Create the new fused piece
	var FusedPiece = fused_script.new()
	FusedPiece.name = fusionPiece
	FusedPiece.set("Item_Color", capturingPiece.get("Item_Color"))
	FusedPiece.position = targetNode.position
	
	# Remove old pieces
	capturingPiece.queue_free()
	targetPiece.queue_free()

	targetNode.add_child(FusedPiece)
	
	FusedPiece.global_position = targetNode.global_position + Vector2(50,50)
	
	Update_Game(targetNode)

func getFusionPieceName(piece1: String, piece2: String) -> String:
	var key1 = [piece1, piece2]
	var key2 = [piece2, piece1]  # Check both orders
	
	if key1 in Fusion_Piece_Map:
		return Fusion_Piece_Map[key1]
	if key2 in Fusion_Piece_Map:
		return Fusion_Piece_Map[key2]
	
	return ""  # No valid fusion found


func processCapture(location: String):
	var targetNode = get_node("Flow/" + location)
	for i in Areas:
		if i == targetNode.name:
			var piece = get_node("Flow/" + Selected_Node).get_child(0)
			if targetNode.get_child(0).name == "King":
				# Determine the winning color (the king's opponent wins)
				var winner_color = ""
				if targetNode.get_child(0).Item_Color == 1:
					winner_color = "white"
				else:
					winner_color = "black"
				GameData.winner = winner_color
				# Change to the end game scene.
				get_tree().change_scene_to_file("res://endgame.tscn")
				return
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
>>>>>>> Stashed changes
	
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
<<<<<<< Updated upstream
	Reset_Tile_Colors()
=======
	
>>>>>>> Stashed changes
	var Flow = get_node("Flow")
	# Clearing the arrays
	Areas.clear()
	Special_Area.clear()
	Reset_Tile_Colors()
	var Piece = get_node("Flow/" + Selected_Node).get_child(0)
<<<<<<< Updated upstream
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
=======
	
	match Piece.name:
		"Pawn":
			Get_Pawn(Piece, Flow)
		"Bishop":
			Get_Bishop(Piece,Flow)
		"King":
			Get_Around(Piece)
		"Queen":
			Get_Bishop(Piece,Flow)
			Get_Rook(Piece,Flow)
		"Rook":
			Get_Rook(Piece,Flow)
		"Knight":
			Get_Horse(Piece,Flow)
		"ElitePawn":
			Get_Elite_Pawn(Piece, Flow)
		"GuardedKnight":
			Get_Guarded_Knight(Piece, Flow)
		"Cavalier":
			Get_Cavalier(Piece,Flow)
		"GuardedBishop":
			Get_Guarded_Bishop(Piece,Flow)
		"Crusader":
			Get_Crusader(Piece,Flow)
		"Pope":
			Get_Pope(Piece,Flow)
		"GuardedRook":
			Get_Guarded_Rook(Piece,Flow)
		"SiegeCamp":
			Get_Siege_Camp(Piece,Flow)
		"Cathedral":
			Get_Cathedral(Piece,Flow)
		"Fortress":
			Get_Fortress(Piece,Flow)
		"GuardedQueen":
			Get_Guarded_Queen(Piece,Flow)
		"Valkyre":
			Get_Valkyre(Piece,Flow)
		"Archqueen":
			Get_Archqueen(Piece,Flow)
		"FortressQueen":
			Get_Fortress_Queen(Piece,Flow)
		
	var newArea = []
	for area in Areas:
		var temp = get_node("Flow/" + area).get_child(0)
		if temp == null:
			newArea.append(area)
		if (temp != null) and ((temp.name in setpiece) or (Piece.Item_Color != temp.Item_Color)):
			newArea.append(area)
		if(temp != null) and (temp.name not in setpiece) and (Piece.Item_Color == temp.Item_Color):
			continue
		var tile = Flow.get_node(area)
		if tile is TextureButton:
			tile.texture_normal = load("res://assets/highlight_move.png")
	Areas = newArea


# ------------------------------------------------------------------
# (The following movement functions remain similar to your original code.)
# ------------------------------------------------------------------
>>>>>>> Stashed changes


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
				Areas.append(diag_left)
		if not Is_Null(diag_right):
			var target = Flow.get_node(diag_right)
			if target.get_child_count() > 0:
				var occupant = target.get_child(0)
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
				Areas.append(diag_left)
		if not Is_Null(diag_right):
			var target = Flow.get_node(diag_right)
			if target.get_child_count() > 0:
				var occupant = target.get_child(0)
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
<<<<<<< Updated upstream

func Get_Rows(Flow):
	var piece_color = get_node("Flow/" + Selected_Node).get_child(0).Item_Color  # ADDED: Get current piece color
=======
					
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
			else:
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
				#if candidateNode.get_child(0).Item_Color != piece_color:
				Areas.append(candidate)
				break  # Stop sliding in this direction if any piece is encountered.
	
>>>>>>> Stashed changes

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
<<<<<<< Updated upstream
		# So this one is interesting. This is most likely the cleanest code here.
		# Get the numbers, replace the numbers, and loop until it stops.
		if not Is_Null(str(int(Location_X) + The_X) + "-" + str(int(Location_Y) + The_Y)) and (Flow.get_node(str(int(Location_X) + The_X) + "-" + str(int(Location_Y) + The_Y)).get_child_count() == 0 or Flow.get_node(str(int(Location_X) + The_X) + "-" + str(int(Location_Y) + The_Y)).get_child(0).Item_Color != piece_color):
=======
		if not Is_Null(str(int(Location_X) + The_X) + "-" + str(int(Location_Y) + The_Y)) and ((Flow.get_node(str(int(Location_X) + The_X) + "-" + str(int(Location_Y) + The_Y)).get_child_count() == 0 or Flow.get_node(str(int(Location_X) + The_X) + "-" + str(int(Location_Y) + The_Y)).get_child(0).Item_Color != piece_color) or (Flow.get_node(str(int(Location_X) + The_X) + "-" + str(int(Location_Y) + The_Y)).get_child(0).Item_Color == piece_color and Flow.get_node(str(int(Location_X) + The_X) + "-" + str(int(Location_Y) + The_Y)).get_child(0).name in setpiece)):
>>>>>>> Stashed changes
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
				
<<<<<<< Updated upstream
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
=======
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
			else:
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
			else:
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
			else:
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
			else:
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
			else:
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
			else:
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
				break  # Stop sliding in this direction if any piece is encountered.

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
>>>>>>> Stashed changes

# One function that shortens everything. Its also a pretty good way to see if we went off the board or not.
func Is_Null(Location):
	if get_node_or_null("Flow/" + Location) == null:
		return true
	else:
		return false

<<<<<<< Updated upstream

=======
>>>>>>> Stashed changes
func Reset_Tile_Colors():
	var Flow = get_node("Flow")
	for y in range(8):
		for x in range(8):
			var tile = Flow.get_node(str(x) + "-" + str(y))
			if tile is TextureButton:
				var is_white = (x + y) % 2 == 0
				tile.texture_normal = load("res://assets/white_board.png") if is_white else load("res://assets/black_board.png")
