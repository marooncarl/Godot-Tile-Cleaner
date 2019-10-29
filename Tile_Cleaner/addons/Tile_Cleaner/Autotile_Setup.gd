# Autotile Setup
#
# Creates autotile rules using child tilemaps

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

export(bool) var match_flipping := true
export(bool) var match_bitmask := false

func _ready():
	# Create regions, input, and output if not already present
	for map_name in ["Regions", "Input", "Output"]:
		if !has_node(map_name):
			var new_map := TileMap.new()
			add_child(new_map)
			new_map.name = map_name
			new_map.owner = self

func create_autotile_rules() -> Array:
	# Make sure the required tilemaps are present
	var regions_map : TileMap = null
	if has_node("Regions"):
		regions_map = get_node("Regions")
		
	var input_map : TileMap = null
	if has_node("Input"):
		input_map = get_node("Input")
		
	var output_map : TileMap = null
	if has_node("Output"):
		output_map = get_node("Output")
	
	# Optional maps
	var empty_map : TileMap = null
	if has_node("Empty"):
		empty_map = get_node("Empty")
	
	var delete_map : TileMap = null
	if has_node("Delete"):
		delete_map = get_node("Delete")
	
	# Abort if a required map isn't present
	for map in [[regions_map, "regions"], [input_map, "input"], [output_map, "output"]]:
		if !map[0]:
			print("Missing %s map!" % map[1])
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
			for prop in [[input_map, "input"], [output_map, "output"]]:
				region[cell][prop[1]] = {
					"id": prop[0].get_cell(cell.x, cell.y),
					"x_flip": prop[0].is_cell_x_flipped(cell.x, cell.y),
					"y_flip": prop[0].is_cell_y_flipped(cell.x, cell.y),
					"transpose": prop[0].is_cell_transposed(cell.x, cell.y),
					"autotile_coord": prop[0].get_cell_autotile_coord(cell.x, cell.y),
				}
				# In input, empty should be regarded as a wildcard
				if prop[1] == "input" && region[cell]["input"]["id"] == TileMap.INVALID_CELL:
					region[cell]["input"]["id"] = "any"
			
			# Cells marked empty overwrite input cells if present
			if empty_map:
				if empty_map.get_cell(cell.x, cell.y) != TileMap.INVALID_CELL:
					region[cell]["input"]["id"] = TileMap.INVALID_CELL
			
			# Cells marked to be deleted overwrite output cells if present
			if delete_map:
				if delete_map.get_cell(cell.x, cell.y) != TileMap.INVALID_CELL:
					region[cell]["output"]["id"] = "delete"
	
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
		if regions_map.get_cell(adj_cell.x, adj_cell.y) != TileMap.INVALID_CELL && !is_cell_in_any_region(adj_cell, all_regions):
			gather_cell(adj_cell, target_region, all_regions, regions_map)