# Autotile Setup
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
	
	if !regions_map:
		print("Missing regions map!")
		return []
	
	# Determine region
	var regions := []
	for cell in regions_map.get_used_cells():
		if !is_cell_in_any_region(cell, regions):
			var new_region := {}
			regions.append(new_region)
			gather_cell(cell, new_region, regions, regions_map)
	
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