# Autotile Setup
#
# Creates autotile rules using child tilemaps

tool
extends Node2D

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

func create_autotile_rules() -> Array:
	# Make sure the required tilemaps are present
	var regions_map : TileMap = null
	if has_node("Regions"):
		regions_map = $Regions
	elif has_node("regions"):
		regions_map = $regions
	var input_map : TileMap = null
	if has_node("Input"):
		input_map = $Input
	elif has_node("input"):
		input_map = $input
	
	if !regions_map:
		print("Missing regions map!")
		return []
	if !input_map:
		print("Missing input map!")
		return []
	
	# Determine regions
	var regions := []
	for cell in regions_map.get_used_cells():
		if !is_cell_in_any_region(cell, regions):
			var new_region := {}
			regions.append(new_region)
			gather_cell(cell, new_region, regions, regions_map)
	
	# Add input data
	for region in regions:
		for cell in region.keys():
			region[cell]["input"] = {
				"id": input_map.get_cell(cell.x, cell.y),
				"x_flip": input_map.is_cell_x_flipped(cell.x, cell.y),
				"y_flip": input_map.is_cell_y_flipped(cell.x, cell.y),
				"transpose": input_map.is_cell_transposed(cell.x, cell.y),
			}
			# In input, empty should be regarded as a wildcard
			if region[cell]["input"]["id"] == TileMap.INVALID_CELL:
				region[cell]["input"]["id"] = "any"
	
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