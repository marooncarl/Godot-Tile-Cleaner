# Tile Cleaner Plugin
# 
# Adds Tile Cleaner dock and main screen to the editor

tool
extends EditorPlugin

const dock_scene = preload("Tile_Cleaner_Dock.tscn")
var dock = null

const bitmask_editor_scene = preload("Bitmask_Edges_Editor.tscn")
var bitmask_editor = null


func _enter_tree():
	dock = dock_scene.instance()
	# Give dock access to the editor interface and undo/redo
	dock.editor_interface = get_editor_interface()
	dock.undo_redo = get_undo_redo()
	add_control_to_dock(EditorPlugin.DOCK_SLOT_RIGHT_UL, dock)
	
	# Add bitmask edges editor screen
	bitmask_editor = bitmask_editor_scene.instance()
	bitmask_editor.undo_redo = get_undo_redo()
	get_editor_interface().get_editor_viewport().add_child(bitmask_editor)
	make_visible(false)
	
	# Create custom node types
	add_custom_type("Tile_Cleaner", "Node", preload("Tile_Cleaner.gd"), preload("Tile_Cleaner_Icon.png"))
	add_custom_type("Tile_Pattern_Setup", "Node", preload("Tile_Pattern.gd"), preload("Autotile_Setup_Icon.png"))

func _exit_tree():
	remove_control_from_docks(dock)
	dock.free()
	bitmask_editor.free()
	for custom_type in ["Tile_Cleaner", "Tile_Pattern_Setup"]:
		remove_custom_type(custom_type)

func has_main_screen():
	return true

func make_visible(visible):
	if visible:
		bitmask_editor.show()
	else:
		bitmask_editor.hide()

func get_plugin_name():
	return "BitmaskEdges"

func get_plugin_icon():
	return preload("Bitmask_Edges_Icon.png")