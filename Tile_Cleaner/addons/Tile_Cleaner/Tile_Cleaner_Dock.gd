# Tile Cleaner Dock
#
# Used to save autotile rules

tool
extends Panel

var editor_interface : EditorInterface = null

func _ready():
	$Save_Button.connect("pressed", self, "on_save_pressed")
	$Save_File_Dialog.connect("file_selected", self, "on_save_file_selected")

func on_save_pressed():
	# Make sure a ruleset can be saved before bringing up the save dialog
	if editor_interface:
		var setup = editor_interface.get_edited_scene_root()
		if setup && setup.has_method("create_autotile_rules"):
			$Save_File_Dialog.popup_centered()
		else:
			print("Open an Autotile Setup to save rules!")

func on_save_file_selected(path: String):
	if editor_interface:
		var setup = editor_interface.get_edited_scene_root()
		if setup && setup.has_method("create_autotile_rules"):
			# Actually save the ruleset
			var ruleset = AutotileRuleset.new()
			ruleset.rules = setup.create_autotile_rules()
			ResourceSaver.save(path, ruleset)
			return
	
	# Didn't return, so there was an error
	print("Failed to save autotile rules")