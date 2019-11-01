# Bitmask Edges Editor

tool
extends Control

const LOAD_DIALOG_SCALE = Vector2(0.66, 0.66)

var tileset
var current_id := 0

onready var tile := $Sprite_Container/Tile
onready var id_label := $ID_Selector/ID_Label
onready var grid := $Grid


func _ready():
	# Connect button signals
	$ID_Selector/Next_ID_Button.connect("pressed", self, "next_id_pressed")
	$ID_Selector/Prev_ID_Button.connect("pressed", self, "prev_id_pressed")
	$Load_Button.connect("pressed", self, "on_load_pressed")
	$Load_Tileset_Dialog.connect("file_selected", self, "on_load_file_selected")
	$Grid_Config/Grid_X_Entry.connect("text_changed", self, "on_grid_x_changed")
	$Grid_Config/Grid_Y_Entry.connect("text_changed", self, "on_grid_y_changed")
	$Grid_Config/Bitmask_Mode_Selector.connect("item_selected", self, "on_bitmask_mode_selected")
	
	grid.origin = $Sprite_Container.rect_position

func set_tileset(new_tileset : TileSet):
	tileset = new_tileset
	if tileset:
		var first_id = tileset.get_tiles_ids()[0]
		if tileset.tile_get_tile_mode(first_id) != TileSet.SINGLE_TILE:
			first_id = get_next_id()
		set_current_tile(first_id)
		id_label.text = str(first_id)

func set_current_tile(new_id):
	assert tileset
	current_id = new_id
	tile.texture = tileset.tile_get_texture(current_id)
	tile.region_rect = tileset.tile_get_region(current_id)

# Returns next non-autotile id.
# If it loops around the whole list, returns the same id as current.
func get_next_id() -> int:
	assert tileset
	var ids : Array = tileset.get_tiles_ids()
	var id_index : int = ids.find(current_id)
	
	var iterations := 0
	while iterations < ids.size():
		iterations += 1
		id_index += 1
		if id_index >= ids.size():
			id_index = 0
		if tileset.tile_get_tile_mode(ids[id_index]) == TileSet.SINGLE_TILE:
			break
	
	return ids[id_index]

# Returns previous non-autotile id.
# If it loops around the whole list, returns the same id as current.
func get_prev_id() -> int:
	assert tileset
	var ids : Array = tileset.get_tiles_ids()
	var id_index = ids.find(current_id)
	
	var iterations := 0
	while iterations < ids.size():
		iterations += 1
		id_index -= 1
		if id_index < 0:
			id_index = ids.size() - 1
		if tileset.tile_get_tile_mode(ids[id_index]) == TileSet.SINGLE_TILE:
			break
	
	return ids[id_index]

# Button events

func next_id_pressed():
	if tileset:
		set_current_tile(get_next_id())
		id_label.text = str(current_id)

func prev_id_pressed():
	if tileset:
		set_current_tile(get_prev_id())
		id_label.text = str(current_id)

func on_load_pressed():
	var window_size = Vector2(get_tree().root.size.x * LOAD_DIALOG_SCALE.x, get_tree().root.size.y * LOAD_DIALOG_SCALE.y)
	$Load_Tileset_Dialog.popup_centered(window_size)

func on_load_file_selected(path: String):
	var file = load(path)
	if file is TileSet:
		set_tileset(file)
	else:
		print("Loaded file was not a tileset.")

func on_grid_x_changed(new_text: String):
	if new_text.is_valid_integer():
		grid.size.x = int(new_text)

func on_grid_y_changed(new_text: String):
	if new_text.is_valid_integer():
		grid.size.y = int(new_text)

func on_bitmask_mode_selected(ID: int):
	match ID:
		0:
			grid.sub_cells = Vector2(2, 2)
		_:
			grid.sub_cells = Vector2(3, 3)

func _draw():
	var bounds := Rect2(get_viewport_rect().position, get_parent().get_rect().size)
	# pass bounds to grid
	grid.rect_position = bounds.position
	grid.rect_size = bounds.size
	
	# Test - draw an outline within the main screen
	var padding := 5
	draw_line(bounds.position + Vector2.ONE * padding - rect_position, bounds.position + Vector2.RIGHT * bounds.size.x + Vector2(-1, 1) * padding - rect_position, Color.white)
	draw_line(bounds.position + Vector2.RIGHT * bounds.size.x + Vector2(-1, 1) * padding - rect_position, bounds.position + bounds.size - Vector2.ONE * padding - rect_position, Color.white)
	draw_line(bounds.position + bounds.size - Vector2.ONE * padding - rect_position, bounds.position + Vector2.DOWN * bounds.size.y + Vector2(1, -1) * padding - rect_position, Color.white)
	draw_line(bounds.position + Vector2.DOWN * bounds.size.y + Vector2(1, -1) * padding - rect_position, bounds.position + Vector2.ONE * padding - rect_position, Color.white)