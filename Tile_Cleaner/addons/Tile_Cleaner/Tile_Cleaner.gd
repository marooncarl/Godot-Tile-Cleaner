# Tile Cleaner
#
# Add as child to a tile map, load an autotile ruleset(s),
# and use the tile cleaner dock to run autotiling.

tool
extends Node

export(Array, Resource) var rulesets := []

func clean_tiles(undoredo : UndoRedo):
	run_autotile(undoredo)

func run_autotile(undoredo : UndoRedo):
	if !get_parent() is TileMap:
		print("Attached tile cleaner to something other than a tilemap!")
		return
	
	# temp: count matching patterns for testing
	var num_matches := 0
	
	# Search for input patterns
	var t : TileMap = get_parent() as TileMap
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
								num_matches += 1
						# Only need to search for one valid tile in each rule
						break
	
	print("Tile Cleaner: Found %s matches" % num_matches)

func does_tile_match_input(input_tile : Dictionary, map : TileMap, map_cell : Vector2, \
		check_flip_x : bool, check_flip_y : bool, check_transpose : bool, check_autotile : bool):
	
	var x := int(map_cell.x)
	var y := int(map_cell.y)
	return (!input_tile["id"] is int || input_tile["id"] == map.get_cell(x, y)) && \
			(!check_flip_x || input_tile["x_flip"] == map.is_cell_x_flipped(x, y)) && \
			(!check_flip_y || input_tile["y_flip"] == map.is_cell_y_flipped(x, y)) && \
			(!check_transpose || input_tile["transpose"] == map.is_cell_transposed(x, y)) && \
			(!check_autotile || input_tile["autotile_coord"] == map.get_cell_autotile_coord(x, y))