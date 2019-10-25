# Tile Cleaner Dock
#
# Used to save autotile rules

tool
extends Panel

var editor_interface : EditorInterface = null
# Rules to be saved; cleared after saving
var rules := []

func _ready():
	$Save_Button.connect("pressed", self, "on_save_pressed")
	$Save_File_Dialog.connect("file_selected", self, "on_save_file_selected")

func on_save_pressed():
	if editor_interface:
		var setup = editor_interface.get_edited_scene_root()
		if setup && setup.has_method("create_autotile_rules"):
			rules = setup.create_autotile_rules()
			$Save_File_Dialog.popup_centered()
		else:
			print("Open an Autotile Setup to save rules!")

func on_save_file_selected(path: String):
	var ruleset = AutotileRuleset.new()
	ruleset.rules = rules
	ResourceSaver.save(path, ruleset)
	rules = []