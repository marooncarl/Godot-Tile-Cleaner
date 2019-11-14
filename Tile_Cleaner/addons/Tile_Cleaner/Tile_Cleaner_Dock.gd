# Tile Cleaner Dock
#
# Used to save tile pattern data and run the Tile Cleaner in the editor

tool
extends Panel

const SAVE_DIALOG_SCALE = Vector2(0.66, 0.66)

var editor_interface : EditorInterface = null
var undo_redo : UndoRedo = null

# Option for whether to save autotile rules whenever an autotile setup scene is saved
var auto_save_rules := false


func _ready():
	$Save_Button.connect("pressed", self, "on_save_pressed")
	$Save_File_Dialog.connect("file_selected", self, "on_save_file_selected")
	$Clean_Button.connect("pressed", self, "on_clean_pressed")
	$Autosave_Checkbox.connect("toggled", self, "on_autosave_toggled")

func _input(event):
	if auto_save_rules && event is InputEventKey && event.pressed && event.control && event.scancode == KEY_S \
	&& editor_interface:
		var setup = editor_interface.get_edited_scene_root()
		if setup && setup.has_method("create_autotile_rules"):
			# Auto save rules with the same name as the setup scene, except for file extension
			# If an alternate name is provided, use that instead.
			var path : String = setup.filename
			if "rule_filename" in setup && setup.rule_filename != "":
				# Construct custom filename
				path = setup.filename.get_base_dir()
				if !path.ends_with("/"):
					path += "/"
				path += setup.rule_filename
				if !path.ends_with(".tres"):
					path += ".tres"
			elif path != "":
				# Replace .tscn with .tres
				path = path.get_basename() + ".tres"
			
			if path != "":
				on_save_file_selected(path)

func on_save_pressed():
	# Make sure a ruleset can be saved before bringing up the save dialog
	if editor_interface:
		var setup = editor_interface.get_edited_scene_root()
		if setup && setup.has_method("create_autotile_rules"):
			var window_size := Vector2(get_tree().root.size.x * SAVE_DIALOG_SCALE.x, \
					get_tree().root.size.y * SAVE_DIALOG_SCALE.y)
			$Save_File_Dialog.popup_centered(window_size)
		else:
			print("Open a Tile Pattern Setup to save rules!")

func on_save_file_selected(path: String):
	if editor_interface:
		var setup = editor_interface.get_edited_scene_root()
		if setup && setup.has_method("create_autotile_rules"):
			
			# Actually save the ruleset
			var ruleset
			if ResourceLoader.exists(path):
				ruleset = load(path)
			else:
				ruleset = TilePattern.new()
			
			# Make sure it has the right properties
			var valid := true
			for prop in ["rules", "match_flipping", "match_bitmask", "any_includes_empty"]:
				if !prop in ruleset:
					valid = false
					break
			if !valid:
				ruleset = TilePattern.new()
			
			ruleset.rules = setup.create_autotile_rules()
			if "match_flipping" in setup:
				ruleset.match_flipping = setup.match_flipping
			if "match_bitmask" in setup:
				ruleset.match_bitmask = setup.match_bitmask
			if "any_includes_empty" in setup:
				ruleset.any_includes_empty = setup.any_includes_empty
			
			ResourceSaver.save(path, ruleset)
			
			print("Saved tile pattern at path: %s" % path)
			return
	
	# Didn't return, so there was an error
	print("Failed to save tile pattern")

func on_clean_pressed():
	if undo_redo && editor_interface:
		var current_scene = editor_interface.get_edited_scene_root()
		# Call clean_tiles on anything in the edited scene that has the method
		current_scene.propagate_call("clean_tiles", [undo_redo], true)

func on_autosave_toggled(button_pressed : bool):
	auto_save_rules = button_pressed