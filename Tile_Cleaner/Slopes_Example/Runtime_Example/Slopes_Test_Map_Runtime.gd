# Slopes Test Map Runtime
#
# Test for cleaning tiles at runtime

extends Node2D

func runtime_clean():
	$TileMap/Tile_Cleaner.clean_tiles(null)