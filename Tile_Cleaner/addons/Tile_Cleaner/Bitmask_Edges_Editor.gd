# Bitmask Edges Editor
#
# Allows drawing bits around tiles that should be filled on adjacent autotiles.
# To use, load a tileset, and if editing existing bitmask data, load that as well.
# Configure the grid and bitmask mode to match the tileset.
# When finished, press the save button to save bitmask edges data.

tool
extends Control

const FILE_DIALOG_SCALE = Vector2(0.66, 0.66)
const ZOOM_STEP = 0.2
const MIN_ZOOM = 0.2
const HIGHLIGHT_COLOR = Color(1.0, 0.0, 0.0, 0.12)
const FILLED_COLOR = Color(1.0, 0.0, 0.0, 0.36)
const BORDER_COLOR = Color("#c5c9d4")
const CONTROLS_WIDTH = 240
const GRID_BORDER = 12

signal needs_saving

var tileset
var current_id := 0
var bounds := Rect2()
var zoom := 1.0
var highlighted_cell := Vector2.ZERO
var highlighted_subcell := Vector2.ZERO

var undo_redo : UndoRedo

var save_path := ""

# Contains a dictionary mapping tile id to another dictionary,
# which maps cell to a list of subcells
# Also, each tile id should have a key "bitmask_mode", which is either 2 or 3 for 2x2 and 3x3 bitmask modes.
var selected_bits := {}

# For bit drawing undo / redo
# Each is a dictionary that maps cell to a dictionary that maps subcells to a true/false value
var undo_changes := {}
var redo_changes := {}

onready var container := $Grid/Sprite_Container
onready var tile := $Grid/Sprite_Container/Tile
onready var id_label := $ID_Selector/ID_Label
onready var grid := $Grid
onready var bitmask_selector := $Grid_Config/Bitmask_Mode_Selector
onready var clear_button := $Clear_Button
onready var load_bitmask_button := $Load_Bitmask_Button

onready var save_buttons := [$Save_Button, $Save_As_Button]


func _ready():
	# Connect button signals
	$ID_Selector/Next_ID_Button.connect("pressed", self, "next_id_pressed")
	$ID_Selector/Prev_ID_Button.connect("pressed", self, "prev_id_pressed")
	$Load_Button.connect("pressed", self, "on_load_pressed")
	$Load_Tileset_Dialog.connect("file_selected", self, "on_load_file_selected")
	$Grid_Config/Grid_X_Entry.connect("text_entered", self, "on_grid_x_entered")
	$Grid_Config/Grid_X_Entry.connect("focus_exited", self, "on_grid_x_exit_focus")
	$Grid_Config/Grid_Y_Entry.connect("text_entered", self, "on_grid_y_entered")
	$Grid_Config/Grid_Y_Entry.connect("focus_exited", self, "on_grid_y_exit_focus")
	bitmask_selector.connect("item_selected", self, "on_bitmask_mode_selected")
	$Save_Button.connect("pressed", self, "on_save_pressed")
	$Save_As_Button.connect("pressed", self, "on_save_as_pressed")
	$Save_Dialog.connect("file_selected", self, "on_save_file_selected")
	load_bitmask_button.connect("pressed", self, "on_load_bitmask_pressed")
	$Load_Bitmask_Dialog.connect("file_selected", self, "on_load_bitmask_file_selected")
	clear_button.connect("pressed", self, "clear_tile")
	grid.connect("draw", self, "draw_bits")
	grid.connect("focus_entered", self, "on_grid_focus")
	grid.connect("focus_exited", self, "on_grid_lose_focus")
	connect("needs_saving", self, "on_needs_saving")
	
	# Buttons disabled by default
	for button in [clear_button, $Save_Button, $Save_As_Button, load_bitmask_button]:
		button.disabled = true

func set_tileset(new_tileset : TileSet):
	tileset = new_tileset
	if tileset:
		var first_id = tileset.get_tiles_ids()[0]
		if tileset.tile_get_tile_mode(first_id) != TileSet.SINGLE_TILE:
			first_id = get_next_id()
		set_current_tile(first_id)
		
		load_bitmask_button.disabled = false
		reset_panning()
	else:
		clear_button.disabled = true
		load_bitmask_button.disabled = true

func set_current_tile(new_id):
	assert tileset
	current_id = new_id
	tile.texture = tileset.tile_get_texture(current_id)
	tile.region_rect = tileset.tile_get_region(current_id)
	id_label.text = str(new_id)
	
	# If the tile has a bitmask mode set, update to that
	if selected_bits.has(new_id) && selected_bits[new_id].has("bitmask_mode"):
		set_bitmask_mode(0 if selected_bits[new_id]["bitmask_mode"] == 2 else 1)
	
	# Need to show selected bits for the new tile
	grid.update()
	
	clear_button.disabled = is_tile_clear(current_id)

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

func _input(event):
	if visible:
		if event is InputEventMouse:
			
			# Mouse events only activate when mouses is in the window
			var relative_mouse_pos : Vector2 = event.position - get_global_rect().position - Vector2(CONTROLS_WIDTH, GRID_BORDER)
			if bounds.has_point(relative_mouse_pos + Vector2.RIGHT * CONTROLS_WIDTH):
			
				if event is InputEventMouseMotion:
					
					# Get highlighted cell
					var cell_subcell = grid.get_subcell_from_pos(relative_mouse_pos)
					highlighted_cell = cell_subcell[0]
					highlighted_subcell = cell_subcell[1]
					grid.update()
					
					# Check for panning
					if Input.is_mouse_button_pressed(BUTTON_MIDDLE):
						container.rect_position += event.relative / zoom
						update_grid_origin()
						grid.grab_focus()
					
					# Selecting bits
					if can_select_subcell(cell_subcell[0], cell_subcell[1]):
						if Input.is_mouse_button_pressed(BUTTON_LEFT) || Input.is_mouse_button_pressed(BUTTON_RIGHT):
							if grid.has_focus():
								draw_bit(cell_subcell[0], cell_subcell[1], false if Input.is_mouse_button_pressed(BUTTON_LEFT) else true)
							else:
								grid.grab_focus()
			
				elif event is InputEventMouseButton:
					# Zooming
					if event.button_index == BUTTON_WHEEL_UP || event.button_index == BUTTON_WHEEL_DOWN:
						set_zoom(zoom + ZOOM_STEP * (1 if event.button_index == BUTTON_WHEEL_UP else -1))
						container.rect_position = relative_mouse_pos / zoom
						update_grid_origin()
						grid.grab_focus()
					
					# Pressing left/right mouse button instead of dragging
					elif event.button_index == BUTTON_LEFT || event.button_index == BUTTON_RIGHT:
						if event.pressed:
							# Draw or erase bit
							var cell_subcell = grid.get_subcell_from_pos(relative_mouse_pos)
							if can_select_subcell(cell_subcell[0], cell_subcell[1]):
								if grid.has_focus():
									draw_bit(cell_subcell[0], cell_subcell[1], false if event.button_index == BUTTON_LEFT else true)
								else:
									grid.grab_focus()
						else:
							# Finish undo/redo action
							if redo_changes.keys().size() > 0:
								undo_redo.create_action("Draw bits")
								undo_redo.add_do_method(self, "apply_bit_changes", current_id, redo_changes)
								undo_redo.add_undo_method(self, "apply_bit_changes", current_id, undo_changes)
								undo_redo.commit_action()
								redo_changes = {}
								undo_changes = {}
		
		elif event is InputEventKey && event.pressed:
			if grid.has_focus():
				match event.get_scancode_with_modifiers():
				
					KEY_F:
						reset_panning()
					
					KEY_1:
						# Default zoom
						set_zoom(1.0)
		
			if event.control && event.scancode == KEY_S:
				# Save
				if is_saving_needed():
					if save_path != "":
						# Save with cached path
						on_save_file_selected(save_path)
					else:
						# Ask the user for a save path
						$Save_Dialog.popup_centered(get_file_window_size())

# Draws or erases a bit on the grid.
# cell: cell that bit is in
# subcell: subcell within the cell, which correlates to a bit in the bitmask
# erase: true - draws a bit if not already there, false - erases a bit
func draw_bit(cell: Vector2, subcell: Vector2, erase : bool = false):
	var old_value : bool = selected_bits.has(current_id) \
			&& selected_bits[current_id].has(cell) \
			&& selected_bits[current_id][cell].has(subcell)
	set_bit(current_id, cell, subcell, !erase)
	grid.grab_focus()
	
	# Make sure the current tile has a bitmask mode set
	selected_bits[current_id]["bitmask_mode"] = (2 if bitmask_selector.selected == 0 else 3)
	
	clear_button.disabled = is_tile_clear(current_id)
	emit_signal("needs_saving")
	
	# Add to changes, but make sure undo changes does not overwrite values
	if old_value == erase:
		if !redo_changes.has(cell):
			undo_changes[cell] = {}
			redo_changes[cell] = {}
		
		if !redo_changes[cell].has(subcell):
			undo_changes[cell][subcell] = old_value
			redo_changes[cell][subcell] = !erase

func apply_bit_changes(tile_id: int, changes: Dictionary):
	for cell in changes.keys():
		for subcell in changes[cell].keys():
			set_bit(tile_id, cell, subcell, changes[cell][subcell])
	
	grid.update()
	# View undone / redone action
	if tile_id != current_id:
		set_current_tile(tile_id)

# Sets bit for cell / subcell to on or off using value
# (Actually removes or adds the subcell to the working data)
func set_bit(tile_id: int, cell: Vector2, subcell: Vector2, value: bool):
	if value:
		# Adding
		if !selected_bits.has(tile_id):
			selected_bits[tile_id] = {}
		if !selected_bits[tile_id].has(cell):
			selected_bits[tile_id][cell] = []
		if !selected_bits[tile_id][cell].has(subcell):
			selected_bits[tile_id][cell].append(subcell)
	else:
		# Removing
		if selected_bits.has(tile_id) && selected_bits[tile_id].has(cell) && selected_bits[tile_id][cell].has(subcell):
			selected_bits[tile_id][cell].remove(selected_bits[tile_id][cell].find(subcell))

func set_zoom(new_zoom: float):
	zoom = max(new_zoom, MIN_ZOOM)
	grid.rect_scale = Vector2.ONE * zoom
	update_bounds()
	update_grid_origin()

func update_bounds():
	bounds = Rect2(get_viewport_rect().position + Vector2(CONTROLS_WIDTH, GRID_BORDER), \
			get_parent().get_rect().size - Vector2(CONTROLS_WIDTH + GRID_BORDER, GRID_BORDER * 2))
	# pass bounds to grid
	grid.rect_position = bounds.position
	grid.rect_size = bounds.size / zoom

func update_grid_origin():
	grid.origin = Vector2(container.rect_position.x / max(container.rect_scale.x, 0.01), \
			container.rect_position.y / max(container.rect_scale.y, 0.01))

func can_select_subcell(cell: Vector2, subcell: Vector2) -> bool:
	if !tileset:
		return false
	
	return true

func clear_tile():
	if !is_tile_clear(current_id):
		undo_changes = {}
		redo_changes = {}
		for cell in selected_bits[current_id]:
			if cell is String:
				continue
			
			for changes in [undo_changes, redo_changes]:
				changes[cell] = {}
			
			for subcell in selected_bits[current_id][cell]:
				undo_changes[cell][subcell] = true
				redo_changes[cell][subcell] = false
		
		undo_redo.create_action("Clear tile")
		undo_redo.add_do_method(self, "apply_bit_changes", current_id, redo_changes)
		undo_redo.add_undo_method(self, "apply_bit_changes", current_id, undo_changes)
		undo_redo.commit_action()
		undo_changes = {}
		redo_changes = {}
		
		grid.update()
		emit_signal("needs_saving")
	clear_button.disabled = true

func get_file_window_size() -> Vector2:
	return Vector2(get_tree().root.size.x * FILE_DIALOG_SCALE.x, get_tree().root.size.y * FILE_DIALOG_SCALE.y)

func on_grid_focus():
	update()

func on_grid_lose_focus():
	update()

func is_tile_clear(tile_id: int):
	if !selected_bits.has(tile_id):
		return true
	if selected_bits[tile_id].keys().size() == 0:
		return true
	for cell in selected_bits[tile_id].keys():
		if cell is String:
			continue
		if selected_bits[tile_id][cell].size() > 0:
			return false
	return true

func on_needs_saving():
	for button in save_buttons:
		button.disabled = false

func reset_panning():
	container.rect_position = bounds.size / 2.0 / zoom
	update_grid_origin()

func is_saving_needed() -> bool:
	return !$Save_Button.disabled

# Button events

func next_id_pressed():
	if tileset:
		set_current_tile(get_next_id())

func prev_id_pressed():
	if tileset:
		set_current_tile(get_prev_id())

func on_load_pressed():
	$Load_Tileset_Dialog.popup_centered(get_file_window_size())

func on_load_file_selected(path: String):
	var file = load(path)
	if file is TileSet:
		set_tileset(file)
	else:
		print("Loaded file was not a tileset.")

func on_save_pressed():
	if save_path != "":
		on_save_file_selected(save_path)
	else:
		$Save_Dialog.popup_centered(get_file_window_size())

func on_save_as_pressed():
	$Save_Dialog.popup_centered(get_file_window_size())

func on_save_file_selected(path: String):
	var save_data : BitmaskEdgesData
	if ResourceLoader.exists(path):
		save_data = load(path)
		if !"bitmask_data" in save_data:
			save_data = BitmaskEdgesData.new()
	else:
		save_data = BitmaskEdgesData.new()
	
	save_data.bitmask_data = BitmaskEdgesData.create_bitmask_save_data(selected_bits)
	save_data.grid_size = grid.size
	ResourceSaver.save(path, save_data)
	for button in save_buttons:
		button.disabled = true
	save_path = path
	print("Saved bitmask edges data")

func on_load_bitmask_pressed():
	$Load_Bitmask_Dialog.popup_centered(get_file_window_size())

func on_load_bitmask_file_selected(path: String):
	var bitmask_data : BitmaskEdgesData = load(path)
	if !bitmask_data:
		print("Failed to load bitmask data!")
	elif !"bitmask_data" in bitmask_data:
		print("Invalid bitmask data!")
	else:
		selected_bits = BitmaskEdgesData.create_working_data(bitmask_data.bitmask_data)
		grid.size = bitmask_data.grid_size
		$Grid_Config/Grid_X_Entry.text = str(grid.size.x)
		$Grid_Config/Grid_Y_Entry.text = str(grid.size.y)
		# Update grid and bitmask mode
		set_current_tile(current_id)
		save_path = path
		print("Loaded bitmask data")

func on_grid_x_exit_focus():
	on_grid_x_entered($Grid_Config/Grid_X_Entry.text)

func on_grid_y_exit_focus():
	on_grid_y_entered($Grid_Config/Grid_Y_Entry.text)

func on_grid_x_entered(new_text: String):
	if new_text.is_valid_integer() && grid.size.x != int(new_text):
		undo_redo.create_action("Change tile x size")
		undo_redo.add_do_property(grid, "size", Vector2(int(new_text), grid.size.y))
		undo_redo.add_do_property($Grid_Config/Grid_X_Entry, "text", new_text)
		undo_redo.add_undo_property(grid, "size", grid.size)
		undo_redo.add_undo_property($Grid_Config/Grid_X_Entry, "text", str(grid.size.x))
		undo_redo.commit_action()
		
		if tileset:
			emit_signal("needs_saving")

func on_grid_y_entered(new_text: String):
	if new_text.is_valid_integer() && grid.size.y != int(new_text):
		undo_redo.create_action("Change tile y size")
		undo_redo.add_do_property(grid, "size", Vector2(grid.size.x, int(new_text)))
		undo_redo.add_do_property($Grid_Config/Grid_Y_Entry, "text", new_text)
		undo_redo.add_undo_property(grid, "size", grid.size)
		undo_redo.add_undo_property($Grid_Config/Grid_Y_Entry, "text", str(grid.size.y))
		undo_redo.commit_action()
		
		if tileset:
			emit_signal("needs_saving")

func on_bitmask_mode_selected(ID: int):
	var old_sub_cells = grid.sub_cells
	var new_sub_cells := Vector2()
	match ID:
		0:
			new_sub_cells = Vector2(2, 2)
		_:
			new_sub_cells = Vector2(3, 3)
	
	if new_sub_cells != old_sub_cells:
		undo_redo.create_action("Change bitmask mode")
		undo_redo.add_do_method(self, "set_bitmask_mode", 0 if new_sub_cells == Vector2(2, 2) else 1)
		undo_redo.add_undo_method(self, "set_bitmask_mode", 0 if old_sub_cells == Vector2(2, 2) else 1)
		undo_redo.commit_action()

func set_bitmask_mode(ID: int):
	grid.sub_cells = Vector2(2, 2) if ID == 0 else Vector2(3, 3)
	bitmask_selector.selected = ID

func _draw():
	update_bounds()
	update_grid_origin()
	if grid.has_focus():
		# Draw bounds
		draw_rect(bounds, BORDER_COLOR, false)

func draw_bits():
	if selected_bits.has(current_id):
		# Draw selected cells
		for cell in selected_bits[current_id].keys():
			if cell is String:
				continue
			
			for subcell in selected_bits[current_id][cell]:
				grid.draw_rect(grid.get_subcell_rect(cell, subcell), FILLED_COLOR)
	
	# Draw highlighted cell
	grid.draw_rect(grid.get_subcell_rect(highlighted_cell, highlighted_subcell), HIGHLIGHT_COLOR)