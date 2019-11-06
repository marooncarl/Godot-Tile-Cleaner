# Bitmask Edges Data
#
# Resource saved by the Bitmask Edges Editor.
# Contains bitmasks for tiles surrounding a non-autotile tile.

extends Resource
class_name BitmaskEdgesData

export(Dictionary) var bitmask_data := {}

# Sets data from the bitmask editor.
# in_data contains arrays of subcells that need to be converted to bitmasks.
func set_data(in_data: Dictionary):
	bitmask_data = {}
	for tile_id in in_data.keys():
		bitmask_data[tile_id] = {}
		# Bitmask is determined differently based on bitmask mode
		var bitmask_mode = 2
		if in_data[tile_id].has("bitmask_mode"):
			bitmask_mode = in_data[tile_id]["bitmask_mode"]
		
		bitmask_data[tile_id]["bitmask_mode"] = bitmask_mode
		
		for cell in in_data[tile_id].keys():
			if cell is String:
				continue
			
			var bitmask := 0
			for subcell in in_data[tile_id][cell]:
				var power : int = subcell.x + bitmask_mode * subcell.y
				bitmask += int(pow(2, power))
			
			bitmask_data[tile_id][cell] = bitmask