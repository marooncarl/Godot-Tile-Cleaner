# Tile Pattern Setup
#
# Creates patterns for finding / replacing tiles using child tilemaps
# Options:
#
# Match Flipping: If true, exact tile rotation is taken into account when pattern matching, otherwise it is ignored.
# Match Bitmask: If true, the exact bitmask for Godot autotiles is considered for pattern matching, otherwise it is ignored.
# Any Includes Empty: If true, a blank tile in the pattern will match even if the tile is empty.

tool
extends Node

const ADJACENT_POSITIONS = [
	Vector2(-1, -1),
	Vector2(0, -1),
	Vector2(1, -1),
	Vector2(-1, 0),
	Vector2(1, 0),
	Vector2(-1, 1),
	Vector2(0, 1),
	Vector2(1, 1),
]

var match_flipping := true
var match_bitmask := false
var any_includes_empty := false
var pattern_path := ""


# Used to save pattern path while hiding it in the inspector
func _get_property_list():
	return [{
		"name": "match_flipping",
		"type": TYPE_BOOL,
		"usage": PROPERTY_USAGE_DEFAULT,
	}, {
		"name": "match_bitmask",
		"type": TYPE_BOOL,
		"usage": PROPERTY_USAGE_DEFAULT,
	}, {
		"name": "any_includes_empty",
		"type": TYPE_BOOL,
		"usage": PROPERTY_USAGE_DEFAULT,
	}, {
		"name": "pattern_path",
		"type": TYPE_STRING,
		"usage": PROPERTY_USAGE_STORAGE,
	}]

func _ready():
	# Create regions, input, and output if not already present
	for map_name in ["Regions", "Input", "Output"]:
		if !has_node(map_name) && !has_node(map_name.to_lower()):
			var new_map := TileMap.new()
			add_child(new_map)
			new_map.name = map_name
			new_map.owner = self
			if map_name == "Regions":
				new_map.modulate = Color(1.0, 1.0, 1.0, 0.5)

func create_autotile_rules() -> Array:
	# Make sure the required tilemaps are present
	var regions_map : TileMap = null
	for map_name in ["Regions", "regions"]:
		if has_node(map_name):
			regions_map = get_node(map_name)
			break
		
	var input_maps := []
	var output_maps := []
	for map in get_children():
		if map is TileMap:
			if map.name.begins_with("Input") || map.name.begins_with("input"):
				input_maps.append(map)
			elif map.name.begins_with("Output") || map.name.begins_with("output"):
				output_maps.append(map)
	
	# Optional maps
	var empty_map : TileMap = null
	for map_name in ["Empty", "empty"]:
		if has_node(map_name):
			empty_map = get_node(map_name)
			break
	
	var delete_map : TileMap = null
	for map_name in ["Delete", "delete"]:
		if has_node(map_name):
			delete_map = get_node(map_name)
			break
	
	# Abort if a required map isn't present
	if !regions_map:
		print("Missing regions map!")
		return []
	if input_maps.size() == 0:
		print("Missing input map!")
		return []
	if output_maps.size() == 0:
		print("Missing output map!")
		return []
	
	# Determine regions
	var regions := []
	for cell in regions_map.get_used_cells():
		if !is_cell_in_any_region(cell, regions):
			var new_region := {}
			regions.append(new_region)
			gather_cell(cell, new_region, regions, regions_map)
	
	# Add input and output data
	for region in regions:
		for cell in region.keys():
			for prop in [[input_maps, "input"], [output_maps, "output"]]:
				region[cell][prop[1]] = []
				for i in range(prop[0].size()):
					var map = prop[0][i]
					if map.get_cell(cell.x, cell.y) != TileMap.INVALID_CELL:
						region[cell][prop[1]].append({
							"id": map.get_cell(cell.x, cell.y),
							"x_flip": map.is_cell_x_flipped(cell.x, cell.y),
							"y_flip": map.is_cell_y_flipped(cell.x, cell.y),
							"transpose": map.is_cell_transposed(cell.x, cell.y),
							"autotile_coord": map.get_cell_autotile_coord(cell.x, cell.y),
						})
			
			# Empty is added as an additional input option if present in the empty layer
			if empty_map:
				if empty_map.get_cell(cell.x, cell.y) != TileMap.INVALID_CELL:
					region[cell]["input"].append({
						"id": TileMap.INVALID_CELL,
						"x_flip": false,
						"y_flip": false,
						"transpose": false,
						"autotile_coord": 0,
					})
			
			# Delete is added as an additional output option if present in the delete layer
			if delete_map:
				if delete_map.get_cell(cell.x, cell.y) != TileMap.INVALID_CELL:
					region[cell]["output"].append({
						"id": TileMap.INVALID_CELL,
						"x_flip": false,
						"y_flip": false,
						"transpose": false,
						"autotile_coord": 0,
					})
	
	return regions

func is_cell_in_any_region(cell: Vector2, regions : Array) -> bool:
	for region in regions:
		if cell in region:
			return true
	return false

# Recursive function for adding adjacent cells to a region
func gather_cell(cell : Vector2, target_region : Dictionary, all_regions : Array, regions_map : TileMap):
	target_region[cell] = {}
	for adj_pos in ADJACENT_POSITIONS:
		var adj_cell : Vector2 = cell + adj_pos
		if regions_map.get_cell(int(adj_cell.x), int(adj_cell.y)) != TileMap.INVALID_CELL && !is_cell_in_any_region(adj_cell, all_regions):
			gather_cell(adj_cell, target_region, all_regions, regions_map)
