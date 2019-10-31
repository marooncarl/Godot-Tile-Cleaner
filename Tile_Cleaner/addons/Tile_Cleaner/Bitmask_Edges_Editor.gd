# Bitmask Edges Editor

#tool
extends Control

export(TileSet) var tileset

var current_id := 0

onready var tile := $Sprite_Container/Tile


func _ready():
	if tileset:
		var first_id = tileset.get_tiles_ids()[0]
		set_current_tile(first_id)

func set_current_tile(new_id):
	current_id = new_id
	tile.texture = tileset.tile_get_texture(current_id)
	tile.region_rect = tileset.tile_get_region(current_id)