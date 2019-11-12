# Autotile Ruleset
# 
# Data generated using autotile setup

extends Resource
class_name AutotileRuleset, "Autotile_Ruleset_Icon.png"

# Each rule is a dictionary with cell position as a key
# Each value is a dictionary containing data on input and output tiles for that cell position
# input and output are arrays containing possible options for input or output.
# An empty array for input means "any", whereas an empty array for output means "leave alone"

export(Array, Dictionary) var rules := []
export(bool) var match_flipping := true
export(bool) var match_bitmask := false
export(bool) var any_includes_empty := false