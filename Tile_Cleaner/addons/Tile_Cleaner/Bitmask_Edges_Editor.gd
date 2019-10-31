# Bitmask Edges Editor

#tool
extends Control

export(TileSet) var tileset


func _ready():
	if tileset:
		var first_id = tileset.get_tiles_ids()[0]
		$Tile.texture = tileset.tile_get_texture(first_id)