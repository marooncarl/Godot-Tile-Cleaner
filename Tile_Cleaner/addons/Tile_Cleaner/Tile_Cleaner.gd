# Tile Cleaner
#
# Add as child to a tile map, load an autotile ruleset(s),
# and use the tile cleaner dock to run autotiling.

tool
extends Node

const ADJACENT_POSITIONS = preload("Autotile_Setup.gd").ADJACENT_POSITIONS

export(Array, Resource) var rulesets := []
export(bool) var update_bitmasks := true
export(Resource) var bitmask_edges_data


func clean_tiles(undoredo : UndoRedo):
	if !get_parent() is TileMap:
		print("Attached tile cleaner to something other than a tilemap!")
		return
	
	var t : TileMap = get_parent() as TileMap
	
	var changes := run_autotile(t)
	
	if undoredo:
		# Record the tilemap's current state at the cells that need changing
		# Also include tiles that are adjacent to the changed cells, due to updating the bitmasks
		var before := {}
		for cell in changes.keys():
			before[cell] = {
				"id": t.get_cell(cell.x, cell.y),
				"x_flip": t.is_cell_x_flipped(cell.x, cell.y),
				"y_flip": t.is_cell_y_flipped(cell.x, cell.y),
				"transpose": t.is_cell_transposed(cell.x, cell.y),
				"autotile_coord": t.get_cell_autotile_coord(cell.x, cell.y),
			}
			if update_bitmasks:
				for adj in ADJACENT_POSITIONS:
					if !before.has(cell + adj):
						var x : int = (cell + adj).x
						var y : int = (cell + adj).y
						before[cell + adj] = {
							"id": t.get_cell(x, y),
							"x_flip": t.is_cell_x_flipped(x, y),
							"y_flip": t.is_cell_y_flipped(x, y),
							"transpose": t.is_cell_transposed(x, y),
							"autotile_coord": t.get_cell_autotile_coord(x, y),
						}
		
		var bitmask_data := {}
		if bitmask_edges_data && "bitmask_data" in bitmask_edges_data:
			bitmask_data = bitmask_edges_data.bitmask_data
		
		# Add undo/redo action
		undoredo.create_action("Clean Tiles")
		undoredo.add_do_method(self, "change_tilemap", t, changes, update_bitmasks, bitmask_data)
		undoredo.add_undo_method(self, "change_tilemap", t, before, false)
		undoredo.commit_action()
	else:
		# Just change the tiles if undo/redo isn't available
		change_tilemap(t, changes, update_bitmasks)

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
						# Search through actual tilemap cells with the search id, as well as changes that will be set with the id
						var search_cells = t.get_used_cells_by_id(search_id)
						for cell in changes.keys():
							if changes[cell].has("id") && changes[cell]["id"] == search_id && !search_cells.has(cell):
								search_cells.append(cell)
						
						for map_cell in search_cells:
							# Check surrounding cells to see if they all match the current pattern
							var matching := true
							for rule_cell2 in rule.keys():
								var offset = rule_cell2 - rule_cell
								if !does_tile_match_input(rule[rule_cell2]["input"], t, changes, map_cell + offset, \
								ruleset.match_flipping, ruleset.match_flipping, ruleset.match_flipping, ruleset.match_bitmask):
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

func does_tile_match_input(input_tile : Dictionary, map : TileMap, changes: Dictionary, map_cell : Vector2, \
		check_flip_x : bool, check_flip_y : bool, check_transpose : bool, check_autotile : bool):
	
	var x := int(map_cell.x)
	var y := int(map_cell.y)
	
	# Use changes to get tile info if possible, otherwise fall back on the actual tilemap
	var compare := {}
	for prop in ["id", "x_flip", "y_flip", "transpose", "autotile_coord"]:
		if changes.has(map_cell) && changes[map_cell].has(prop):
			compare[prop] = changes[map_cell][prop]
	if !compare.has("id"):
		compare["id"] = map.get_cell(x, y)
	if !compare.has("x_flip"):
		compare["x_flip"] = map.is_cell_x_flipped(x, y)
	if !compare.has("y_flip"):
		compare["y_flip"] = map.is_cell_y_flipped(x, y)
	if !compare.has("transpose"):
		compare["transpose"] = map.is_cell_transposed(x, y)
	if !compare.has("autotile_coord"):
		compare["autotile_coord"] = map.get_cell_autotile_coord(x, y)
	
	return (!input_tile["id"] is int || input_tile["id"] == compare["id"]) && \
			(!check_flip_x || input_tile["x_flip"] == compare["x_flip"]) && \
			(!check_flip_y || input_tile["y_flip"] == compare["y_flip"]) && \
			(!check_transpose || input_tile["transpose"] == compare["transpose"]) && \
			(!check_autotile || input_tile["autotile_coord"] == compare["autotile_coord"])

# Used with undo/redo to actually change the tilemap
func change_tilemap(t : TileMap, changes : Dictionary, update_bitmasks : bool = false, bitmask_data : Dictionary = {}):
	if t:
		for cell in changes.keys():
			var id = t.get_cell(cell.x, cell.y) if !"id" in changes[cell] else changes[cell]["id"]
			var flip_x = t.is_cell_x_flipped(cell.x, cell.y) if !"x_flip" in changes[cell] else changes[cell]["x_flip"]
			var flip_y = t.is_cell_y_flipped(cell.x, cell.y) if !"y_flip" in changes[cell] else changes[cell]["y_flip"]
			var transpose = t.is_cell_transposed(cell.x, cell.y) if !"transpose" in changes[cell] else changes[cell]["transpose"]
			var autotile_coord = t.get_cell_autotile_coord(cell.x, cell.y) if !"autotile_coord" in changes[cell] else changes[cell]["autotile_coord"]
			t.set_cell(cell.x, cell.y, id, flip_x, flip_y, transpose, autotile_coord)
			if update_bitmasks:
				t.update_bitmask_area(cell)
		if bitmask_data.keys().size() > 0:
			fix_bitmask_edges(t, bitmask_data)

# Changes the bitmasks of autotiles next to non-autotiles that have bitmask edges data
func fix_bitmask_edges(t : TileMap, bitmask_data : Dictionary):
	var autotile_regions := {}
	for tile_id in bitmask_data.keys():
		for cell in t.get_used_cells_by_id(tile_id):
			for adj_cell in bitmask_data[tile_id].keys():
				if adj_cell is String:
					continue
				
				var x := int((cell + adj_cell).x)
				var y := int((cell + adj_cell).y)
				var changed_id : int = t.get_cell(x, y)
				# Make sure the tile we're changing is an autotile
				if changed_id != TileMap.INVALID_CELL && t.tile_set.tile_get_tile_mode(changed_id) == TileSet.AUTO_TILE:
					var autotile_coord := t.get_cell_autotile_coord(x, y)
					var original_bitmask := t.tile_set.autotile_get_bitmask(changed_id, autotile_coord)
					var combined_bitmask : int = bitmask_data[tile_id][adj_cell] | original_bitmask
					
					# Determine autotile region size once for each tile id
					if !autotile_regions.has(changed_id):
						autotile_regions[changed_id] = get_autotile_region_size(t.tile_set, changed_id)
					var region_size : Vector2 = autotile_regions[changed_id]
					
					# Find a bitmask matching the combined one, or at least a bitmask that contains it
					var new_mask := 0
					var new_coord := Vector2()
					var considered_masks := []
					var considered_coords := []
					
					for coord_x in range(0, region_size.x):
						for coord_y in range(0, region_size.y):
							var mask := t.tile_set.autotile_get_bitmask(changed_id, Vector2(coord_x, coord_y))
							if mask == combined_bitmask:
								# Found a match!
								new_mask = mask
								new_coord = Vector2(coord_x, coord_y)
								break
							elif mask != 0 && bitmask_contains(mask, combined_bitmask):
								# Consider this mask if we don't find a match
								considered_masks.append(mask)
								considered_coords.append(Vector2(coord_x, coord_y))
						
						if new_mask != 0:
							# Found a match, so break here as well
							break
					
					# If didn't find an exact match, pick the bitmask that has the fewest bits 
					# but still contains combined mask
					if new_mask == 0:
						new_mask = get_smallest_bitmask(considered_masks)
						new_coord = considered_coords[considered_masks.find(new_mask)]
					if new_mask != 0:
						# Change the tile
						t.set_cell(x, y, changed_id, t.is_cell_x_flipped(x, y), t.is_cell_y_flipped(x, y), \
								t.is_cell_transposed(x, y), new_coord)

# Returns true if mask1 contains every bit in mask2
func bitmask_contains(mask1 : int, mask2 : int):
	return (mask1 & mask2) == mask2

# Returns the bitmask with the least 1 bits in an array of bitmasks
# Returns 0 if the array is empty
func get_smallest_bitmask(bitmasks : Array):
	var smallest := 0
	var least_bits := 0
	for bitmask in bitmasks:
		var num_bits := 0
		for i in range(9):
			num_bits += 1 if (bitmask & (1 << i)) != 0 else 0
		if smallest == 0 || num_bits < least_bits:
			smallest = bitmask
			least_bits = num_bits
	return smallest

func get_autotile_region_size(tile_set : TileSet, tile_id : int):
	var autotile_region_size := Vector2()
	var test_coord := Vector2(0, 0)
	var is_row_empty := false
	var rows_scanned := 0
	while !is_row_empty || rows_scanned < 2:
		# scan single row
		is_row_empty = true
		var bitmask := -1
		while bitmask != 0 || test_coord.x < autotile_region_size.x:
			bitmask = tile_set.autotile_get_bitmask(tile_id, test_coord)
			if bitmask != 0:
				is_row_empty = false
			test_coord.x += 1
		autotile_region_size.x = max(autotile_region_size.x, test_coord.x - 1)
		test_coord = Vector2(0, test_coord.y + 1)
		rows_scanned += 1
	
	autotile_region_size.y = test_coord.y - 1
	return autotile_region_size