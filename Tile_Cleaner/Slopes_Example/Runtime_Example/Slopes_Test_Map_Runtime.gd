# Slopes Test Map Runtime
#
# Test for cleaning tiles at runtime

extends Node2D

func runtime_clean():
	$TileMap/Slope_Tile_Cleaner.clean_tiles(null)