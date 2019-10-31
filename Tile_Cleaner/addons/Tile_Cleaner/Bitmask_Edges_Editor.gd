# Bitmask Edges Editor

#tool
extends Control

export(TileSet) var tileset

var current_id := 0

onready var tile := $Sprite_Container/Tile
onready var id_label := $ID_Selector/ID_Label


func _ready():
	if tileset:
		var first_id = tileset.get_tiles_ids()[0]
		set_current_tile(first_id)
	
	# Connect button signals
	$ID_Selector/Next_ID_Button.connect("pressed", self, "next_id_pressed")
	$ID_Selector/Prev_ID_Button.connect("pressed", self, "prev_id_pressed")

func set_current_tile(new_id):
	current_id = new_id
	tile.texture = tileset.tile_get_texture(current_id)
	tile.region_rect = tileset.tile_get_region(current_id)

func get_next_id() -> int:
	var ids : Array = tileset.get_tiles_ids()
	var id_index = ids.find(current_id)
	id_index += 1
	if id_index >= ids.size():
		id_index = 0
	return ids[id_index]

func get_prev_id() -> int:
	var ids : Array = tileset.get_tiles_ids()
	var id_index = ids.find(current_id)
	id_index -= 1
	if id_index < 0:
		id_index = ids.size() - 1
	return ids[id_index]

# Button events

func next_id_pressed():
	set_current_tile(get_next_id())
	id_label.text = str(current_id)

func prev_id_pressed():
	set_current_tile(get_prev_id())
	id_label.text = str(current_id)