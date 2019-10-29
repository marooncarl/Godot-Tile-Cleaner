# Tile Cleaner
#
# Add as child to a tile map, load an autotile ruleset(s),
# and use the tile cleaner dock to run autotiling.

tool
extends Node

export(Array, Resource) var rulesets := []

func clean_tiles(undoredo : UndoRedo):
	if !get_parent() is TileMap:
		print("Attached tile cleaner to something other than a tilemap!")
		return
	
	var t : TileMap = get_parent() as TileMap
	
	var changes := run_autotile(t)
	
	# Record the tilemap's current state at the cells that need changing
	var before := {}
	for cell in changes.keys():
		before[cell] = {
			"id": t.get_cell(cell.x, cell.y),
			"x_flip": t.is_cell_x_flipped(cell.x, cell.y),
			"y_flip": t.is_cell_y_flipped(cell.x, cell.y),
			"transpose": t.is_cell_transposed(cell.x, cell.y),
			"autotile_coord": t.get_cell_autotile_coord(cell.x, cell.y),
		}
	
	if undoredo:
		# Add undo/redo action
		undoredo.create_action("Clean Tiles")
		undoredo.add_do_method(self, "change_tilemap", t, changes)
		undoredo.add_undo_method(self, "change_tilemap", t, before)
		undoredo.commit_action()
	else:
		# Just change the tiles if undo/redo isn't available
		change_tilemap(t, changes)

func run_autotile(t : TileMap) -> Dictionary:
	var num_matches := 0
	var changes := {}
	
	# Search for input patterns
	for ruleset in rulesets:
		if "rules" in ruleset:
			for rule in ruleset.rules:
				# Find a cell that isn't invalid or "any" in the input region to search for
				for rule_cell in rule.keys():
					var search_id = rule[rule_cell]["input"]["id"]
					if search_id is int && search_id != TileMap.INVALID_CELL:
						for map_cell in t.get_used_cells_by_id(search_id):
							# Check surrounding cells to see if they all match the current pattern
							var matching := true
							for rule_cell2 in rule.keys():
								var offset = rule_cell2 - rule_cell
								if !does_tile_match_input(rule[rule_cell2]["input"], t, map_cell + offset, true, true, true, false):
									matching = false
									break
							if matching:
								# Record a change to be made later
								for rule_cell2 in rule.keys():
									var offset = rule_cell2 - rule_cell
									if !rule[rule_cell2]["output"]["id"] is int && rule[rule_cell2]["output"]["id"] == "delete":
										changes[map_cell + offset] = {
											"id": TileMap.INVALID_CELL,
											"x_flip": false,
											"y_flip": false,
											"transpose": false,
											"autotile_coord": Vector2(0, 0),
										}
									elif rule[rule_cell2]["output"]["id"] != TileMap.INVALID_CELL:
										changes[map_cell + offset] = {
											"id": rule[rule_cell2]["output"]["id"],
											"x_flip": rule[rule_cell2]["output"]["x_flip"],
											"y_flip": rule[rule_cell2]["output"]["y_flip"],
											"transpose": rule[rule_cell2]["output"]["transpose"],
										}
								num_matches += 1
						# Only need to search for one valid tile in each rule
						break
	
	print("Tile Cleaner: Found %s matches" % num_matches)
	return changes

func does_tile_match_input(input_tile : Dictionary, map : TileMap, map_cell : Vector2, \
		check_flip_x : bool, check_flip_y : bool, check_transpose : bool, check_autotile : bool):
	
	var x := int(map_cell.x)
	var y := int(map_cell.y)
	return (!input_tile["id"] is int || input_tile["id"] == map.get_cell(x, y)) && \
			(!check_flip_x || input_tile["x_flip"] == map.is_cell_x_flipped(x, y)) && \
			(!check_flip_y || input_tile["y_flip"] == map.is_cell_y_flipped(x, y)) && \
			(!check_transpose || input_tile["transpose"] == map.is_cell_transposed(x, y)) && \
			(!check_autotile || input_tile["autotile_coord"] == map.get_cell_autotile_coord(x, y))

# Used with undo/redo to actually change the tilemap
func change_tilemap(t : TileMap, changes : Dictionary):
	if t:
		for cell in changes.keys():
			var id = t.get_cell(cell.x, cell.y) if !"id" in changes[cell] else changes[cell]["id"]
			var flip_x = t.is_cell_x_flipped(cell.x, cell.y) if !"x_flip" in changes[cell] else changes[cell]["x_flip"]
			var flip_y = t.is_cell_y_flipped(cell.x, cell.y) if !"y_flip" in changes[cell] else changes[cell]["y_flip"]
			var transpose = t.is_cell_transposed(cell.x, cell.y) if !"transpose" in changes[cell] else changes[cell]["transpose"]
			var autotile_coord = t.get_cell_autotile_coord(cell.x, cell.y) if !"autotile_coord" in changes[cell] else changes[cell]["autotile_coord"]
			t.set_cell(cell.x, cell.y, id, flip_x, flip_y, transpose, autotile_coord)