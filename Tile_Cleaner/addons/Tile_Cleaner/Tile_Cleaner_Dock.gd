# Tile Cleaner Dock
#
# Used to save tile pattern data and run the Tile Cleaner in the editor

tool
extends Panel

const SAVE_DIALOG_SCALE = Vector2(0.66, 0.66)

# Hotkey for Clean Tiles button
# If desired, change this to one of the KeyList constants in @GlobalScope.
const CLEAN_HOTKEY = KEY_C
# These must match one of the properties of InputEventWithModifiers.
const CLEAN_MODIFIERS = ["control", "alt"]

var editor_interface : EditorInterface = null
var undo_redo : UndoRedo = null


func _ready():
	$Save_Button.connect("pressed", self, "on_save_pressed")
	$Save_File_Dialog.connect("file_selected", self, "on_save_file_selected")
	$Clean_Button.connect("pressed", self, "on_clean_pressed")
	$Save_As_Button.connect("pressed", self, "on_save_as_pressed")

# Save pattern when ctrl + s is pressed if it has been saved already
func _input(event):
	if event is InputEventKey && event.pressed:
		if event.control && event.scancode == KEY_S:
			var setup = get_setup()
			if setup && setup.pattern_path != "":
				on_save_file_selected(setup.pattern_path)
		
		elif is_clean_hotkey_pressed(event):
			on_clean_pressed()

func on_save_pressed():
	# Make sure a ruleset can be saved before bringing up the save dialog
	var setup = get_setup()
	if setup:
		if setup.pattern_path == "":
			$Save_File_Dialog.popup_centered(get_save_window_size())
		else:
			on_save_file_selected(setup.pattern_path)
	else:
		print("Open a Tile Pattern Setup to save a pattern!")

func on_save_as_pressed():
	var setup = get_setup()
	if setup:
		$Save_File_Dialog.popup_centered(get_save_window_size())
	else:
		print("Open a Tile Pattern Setup to save a pattern!")

func on_save_file_selected(path: String):
	var setup = get_setup()
	if setup:
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
		
		# Add undo / redo action for updating the pattern path on the scene, since it needs to be saved
		var old_path = setup.pattern_path
		if path != old_path:
			undo_redo.create_action("Update Pattern Path")
			undo_redo.add_do_property(setup, "pattern_path", path)
			undo_redo.add_undo_property(setup, "pattern_path", old_path)
			undo_redo.commit_action()
		
		print("Saved tile pattern at path: %s" % path)
	else:
		print("Failed to save tile pattern")

func get_save_window_size() -> Vector2:
	return Vector2(get_tree().root.size.x * SAVE_DIALOG_SCALE.x, get_tree().root.size.y * SAVE_DIALOG_SCALE.y)

func get_setup() -> Node:
	if editor_interface:
		var setup = editor_interface.get_edited_scene_root()
		if setup && setup.has_method("create_autotile_rules"):
			return setup
	
	return null


func is_clean_hotkey_pressed(event: InputEventKey) -> bool:
	if event.scancode != CLEAN_HOTKEY:
		return false
	
	for mod in CLEAN_MODIFIERS:
		if !event.get(mod):
			return false
	
	return true


func on_clean_pressed():
	if undo_redo && editor_interface:
		var current_scene = editor_interface.get_edited_scene_root()
		# Call clean_tiles on anything in the edited scene that has the method
		current_scene.propagate_call("clean_tiles", [undo_redo], true)
