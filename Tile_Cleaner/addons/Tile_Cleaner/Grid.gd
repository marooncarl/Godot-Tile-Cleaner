# Grid
#
# Displays a grid, optionally with sub cells.

tool
extends Control

const GRID_EXTENTS = 10

export(Vector2) var size := Vector2(16, 16) setget size_set
export(Vector2) var sub_cells := Vector2(1, 1) setget sub_cells_set
export(Color) var grid_color := Color.white
export(Color) var sub_cell_color := Color.gray

func size_set(new_size: Vector2):
	size = new_size
	update()

func sub_cells_set(new_sub_cells: Vector2):
	sub_cells = new_sub_cells
	update()

func _draw():
	for row in range(-GRID_EXTENTS, GRID_EXTENTS):
		if row > -GRID_EXTENTS:
			draw_line(Vector2(-GRID_EXTENTS * size.x, row * size.y), Vector2(GRID_EXTENTS * size.x, row * size.y), grid_color)
		if sub_cells.y > 1.0:
			for sub_cell in range(1, sub_cells.y + 1.0):
				var line_y = row * size.y + sub_cell * (size.y / sub_cells.y)
				draw_line(Vector2(-GRID_EXTENTS * size.x, line_y), Vector2(GRID_EXTENTS * size.y, line_y), sub_cell_color)
		
	for column in range(-GRID_EXTENTS, GRID_EXTENTS):
		if column > -GRID_EXTENTS:
			draw_line(Vector2(column * size.x, -GRID_EXTENTS * size.y), Vector2(column * size.x, GRID_EXTENTS * size.y), grid_color)
		if sub_cells.x > 1.0:
			for sub_cell in range(1, sub_cells.x + 1.0):
				var line_x = column * size.x + sub_cell * (size.x / sub_cells.x)
				draw_line(Vector2(line_x, -GRID_EXTENTS * size.y), Vector2(line_x, GRID_EXTENTS * size.y), sub_cell_color)