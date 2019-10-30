# Autotile Ruleset
# 
# Data generated using autotile setup

extends Resource
class_name AutotileRuleset, "Autotile_Ruleset_Icon.png"

# Each rule is a dictionary with cell position as a key
# Each value is a dictionary containing data on input and output tiles for that cell position
export(Array, Dictionary) var rules := []
export(bool) var match_flipping := true
export(bool) var match_bitmask := false