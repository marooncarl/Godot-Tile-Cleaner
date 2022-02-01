# Bitmask Edges Data
#
# Resource saved by the Bitmask Edges Editor.
# Contains bitmasks for tiles surrounding a non-autotile tile.

extends Resource
class_name BitmaskEdgesData, "Icons/Bitmask_Edges_Icon.png"

# Maps subcell in bitmask edges editor to bitmask position for 2x2 autotile
const COORD_TO_BIT = {
	Vector2(0, 0): 0,
	Vector2(1, 0): 2,
	Vector2(0, 1): 6,
	Vector2(1, 1): 8,
}

export(Dictionary) var bitmask_data := {}
# For editing convenience; used to set the grid size when loading
export(Vector2) var grid_size := Vector2(64, 64)

# Takes working data used by the editor and returns bitmask data for saving.
# working_data contains arrays of subcells that need to be converted to bitmasks.
static func create_bitmask_save_data(working_data: Dictionary) -> Dictionary:
	var save_data = {}
	for tile_id in working_data.keys():
		save_data[tile_id] = {}
		# Bitmask is determined differently based on bitmask mode
		var bitmask_mode = 2
		if working_data[tile_id].has("bitmask_mode"):
			bitmask_mode = working_data[tile_id]["bitmask_mode"]
		
		save_data[tile_id]["bitmask_mode"] = bitmask_mode
		
		for cell in working_data[tile_id].keys():
			if cell is String:
				continue
			
			var bitmask := 0
			for subcell in working_data[tile_id][cell]:
				var power := get_bitmask_bit(subcell, bitmask_mode)
				bitmask += int(pow(2, power))
			
			if bitmask != 0:
				save_data[tile_id][cell] = bitmask
	
	return save_data

# Returns a version of the bitmask data that the editor can use
# Converts bitmasks to arrays of subcells in the grid
static func create_working_data(save_data: Dictionary) -> Dictionary:
	var working_data := {}
	for tile_id in save_data.keys():
		working_data[tile_id] = {}
		
		var bitmask_mode = 2
		if save_data[tile_id].has("bitmask_mode"):
			bitmask_mode = save_data[tile_id]["bitmask_mode"]
			working_data[tile_id]["bitmask_mode"] = bitmask_mode
		
		for cell in save_data[tile_id].keys():
			if cell is String:
				continue
			
			working_data[tile_id][cell] = []
			
			var left : int = save_data[tile_id][cell]
			var power_range := []
			if bitmask_mode == 2:
				power_range = [8, 6, 2, 0]
			else:
				power_range = range(pow(bitmask_mode, 2) - 1, -1, -1)
			
			for power in power_range:
				var bit := int(pow(2, power))
				if left >= bit:
					left -= bit
					working_data[tile_id][cell].append(get_subcell(power, bitmask_mode))
	
	return working_data


static func get_bitmask_bit(subcell: Vector2, bitmask_mode := 2) -> int:
	if bitmask_mode == 2:
		if subcell in COORD_TO_BIT:
			return COORD_TO_BIT[subcell]
		
		else:
			return 0
	
	else:
		return int(subcell.x + bitmask_mode * subcell.y)


static func get_subcell(power: int, bitmask_mode := 2) -> Vector2:
	if bitmask_mode == 2:
		for coord in COORD_TO_BIT.keys():
			if COORD_TO_BIT[coord] == power:
				return coord
		
		return Vector2.ZERO
	
	else:
		return Vector2(power % bitmask_mode, int(power / bitmask_mode))
