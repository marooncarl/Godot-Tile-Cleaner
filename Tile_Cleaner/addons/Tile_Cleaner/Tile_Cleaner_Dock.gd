# Tile Cleaner Dock
#
# Used to save autotile rules

tool
extends Panel

func _ready():
	$Save_Button.connect("pressed", self, "on_save_pressed")
	$Save_File_Dialog.connect("file_selected", self, "on_save_file_selected")

func on_save_pressed():
	$Save_File_Dialog.popup_centered()

func on_save_file_selected(path: String):
	var ruleset = AutotileRuleset.new()
	ResourceSaver.save(path, ruleset)