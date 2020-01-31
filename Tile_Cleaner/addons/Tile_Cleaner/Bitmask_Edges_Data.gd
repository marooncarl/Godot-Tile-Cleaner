# Bitmask Edges Data
#
# Resource saved by the Bitmask Edges Editor.
# Contains bitmasks for tiles surrounding a non-autotile tile.

extends Resource
class_name BitmaskEdgesData, "Icons/Bitmask_Edges_Icon.png"

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
				var power : int = subcell.x + bitmask_mode * subcell.y
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
			for power in range(pow(bitmask_mode, 2) - 1, -1, -1):
				var bit := int(pow(2, power))
				if left >= bit:
					left -= bit
					working_data[tile_id][cell].append(Vector2(power % bitmask_mode, int(power / bitmask_mode)))
	
	return working_data
