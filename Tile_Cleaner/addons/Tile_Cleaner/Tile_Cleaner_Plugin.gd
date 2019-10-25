# Tile Cleaner Plugin
# 
# Adds dock to the editor

tool
extends EditorPlugin

const dock_scene = preload("Tile_Cleaner_Dock.tscn")
var dock = null

func _enter_tree():
	dock = dock_scene.instance()
	# Give dock access to the editor interface
	dock.editor_interface = get_editor_interface()
	add_control_to_dock(EditorPlugin.DOCK_SLOT_RIGHT_UL, dock)

func _exit_tree():
	remove_control_from_docks(dock)
	dock.free()