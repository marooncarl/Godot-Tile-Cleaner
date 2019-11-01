# Grid
#
# Displays a grid within the control's rect, optionally with sub cells.

tool
extends Control

export(Vector2) var size := Vector2(16, 16) setget size_set
export(Vector2) var sub_cells := Vector2(1, 1) setget sub_cells_set
export(Color) var grid_color := Color.white
export(Color) var sub_cell_color := Color.gray
export(Vector2) var origin := Vector2()

func size_set(new_size: Vector2):
	size = new_size
	update()

func sub_cells_set(new_sub_cells: Vector2):
	sub_cells = new_sub_cells
	update()

func _draw():
	if size.y > 0:
		var row_lines := rect_size.y / size.y + 1
		for row in range(0, row_lines):
			draw_line(Vector2(0, row * size.y), Vector2(rect_size.x, row * size.y), grid_color)
			if sub_cells.y > 1.0:
				for sub_cell in range(1, sub_cells.y + 1.0):
					var line_y = row * size.y + sub_cell * (size.y / sub_cells.y)
					if line_y < rect_size.y:
						draw_line(Vector2(0, line_y), Vector2(rect_size.x, line_y), sub_cell_color)
	
	if size.x > 0:
		var column_lines := rect_size.x / size.x + 1
		for column in range(0, column_lines):
			draw_line(Vector2(column * size.x, 0), Vector2(column * size.x, rect_size.y), grid_color)
			if sub_cells.x > 1.0:
				for sub_cell in range(1, sub_cells.x + 1.0):
					var line_x = column * size.x + sub_cell * (size.x / sub_cells.x)
					if line_x < rect_size.x:
						draw_line(Vector2(line_x, 0), Vector2(line_x, rect_size.y), sub_cell_color)