# Grid
#
# Displays a grid.

tool
extends Control

const GRID_EXTENTS = 10

export(Vector2) var size := Vector2(16, 16) setget size_set
export(Color) var grid_color := Color.white

func size_set(new_size: Vector2):
	size = new_size
	update()

func _draw():
	for row in range(-GRID_EXTENTS + 1, GRID_EXTENTS):
		draw_line(Vector2(-GRID_EXTENTS * size.x, row * size.y), Vector2(GRID_EXTENTS * size.x, row * size.y), grid_color)
		
	for column in range(-GRID_EXTENTS + 1, GRID_EXTENTS):
		draw_line(Vector2(column * size.x, -GRID_EXTENTS * size.y), Vector2(column * size.x, GRID_EXTENTS * size.y), grid_color)