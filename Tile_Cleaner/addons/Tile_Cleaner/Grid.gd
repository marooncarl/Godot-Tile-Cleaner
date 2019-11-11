# Grid
#
# Displays a grid within the control's rect, optionally with sub cells.

tool
extends Control

export(Vector2) var size := Vector2(16, 16) setget size_set
export(Vector2) var sub_cells := Vector2(1, 1) setget sub_cells_set
export(Color) var grid_color := Color.white
export(Color) var sub_cell_color := Color.gray

# Relative to the grid's position
export(Vector2) var origin := Vector2() setget origin_set


func size_set(new_size: Vector2):
	size = new_size
	update()

func sub_cells_set(new_sub_cells: Vector2):
	sub_cells = new_sub_cells
	update()

func origin_set(new_origin: Vector2):
	origin = new_origin
	update()

func get_subcell_rect(cell: Vector2, subcell: Vector2) -> Rect2:
	var sub_cell_x := 0.0
	var sub_cell_y := 0.0
	if sub_cells.x > 1.0:
		sub_cell_x = subcell.x * (size.x / sub_cells.x)
	if sub_cells.y > 1.0:
		sub_cell_y = subcell.y * (size.y / sub_cells.y)
	var pos := Vector2(origin.x + cell.x * size.x + sub_cell_x, origin.y + cell.y * size.y + sub_cell_y)
	var rect_size := size
	if sub_cells.x > 1.0:
		rect_size.x = size.x / sub_cells.x
	if sub_cells.y > 1.0:
		rect_size.y = size.y / sub_cells.y
	return Rect2(pos, rect_size)

# Returns an array containing two Vector2s: cell, and subcell.
# pos - position within the grid's bounds
func get_subcell_from_pos(pos: Vector2) -> Array:
	var scaled_pos := Vector2(pos.x / rect_scale.x, pos.y / rect_scale.y)
	
	var cell := scaled_pos - origin
	if size.x > 0:
		cell.x /= size.x
	if size.y > 0:
		cell.y /= size.y
	cell = Vector2(floor(cell.x), floor(cell.y))
	
	var subcell := Vector2.ZERO
	if sub_cells.x > 1.0 && size.x > 0:
		subcell.x = floor((scaled_pos.x - origin.x - cell.x * size.x) / (size.x / sub_cells.x))
	if sub_cells.y > 1.0 && size.y > 0:
		subcell.y = floor((scaled_pos.y - origin.y - cell.y * size.y) / (size.y / sub_cells.y))
	
	return [cell, subcell]

func _draw():	
	if size.y > 0:
		var row_lines := rect_size.y / size.y + 1
		var start_y = fmod(origin.y, size.y)
		if start_y < 0:
			start_y += size.y
		
		for row in range(-1, row_lines):
			var line_y = start_y + row * size.y
			if line_y < rect_size.y:
				draw_line(Vector2(0, line_y), Vector2(rect_size.x, line_y), grid_color)
			if sub_cells.y > 1.0:
				for sub_cell in range(1, sub_cells.y + 1.0):
					line_y = start_y + row * size.y + sub_cell * (size.y / sub_cells.y)
					if line_y < rect_size.y:
						draw_line(Vector2(0, line_y), Vector2(rect_size.x, line_y), sub_cell_color)
	
	if size.x > 0:
		var column_lines := rect_size.x / size.x + 1
		var start_x = fmod(origin.x, size.x)
		if start_x < 0:
			start_x += size.x
		
		for column in range(-1, column_lines):
			var line_x = start_x + column * size.x
			if line_x < rect_size.x:
				draw_line(Vector2(line_x, 0), Vector2(line_x, rect_size.y), grid_color)
			if sub_cells.x > 1.0:
				for sub_cell in range(1, sub_cells.x + 1.0):
					line_x = start_x + column * size.x + sub_cell * (size.x / sub_cells.x)
					if line_x < rect_size.x:
						draw_line(Vector2(line_x, 0), Vector2(line_x, rect_size.y), sub_cell_color)