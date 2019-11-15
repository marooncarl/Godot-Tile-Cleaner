# Tile Cleaner
Tile Cleaner is a plugin for Godot engine 3.1.1.  It provides custom autotiling for Godot tilemaps by finding and replacing patterns, similar to automapping in Tiled.

It can also make non-autotile tiles combine with Godot autotiles by customizing which bits should be filled around the non-autotile tiles.  For example, slope tiles in a platform game can combine with blob autotiles.

A dedicated node is used to clean tiles instead of a tilemap script so that it can be used with any existing tilemap scripts.

The Tile Cleaner can be used in the editor or at run-time.

When activated, this plugin adds a dock tab named "Tile Cleaner", a main screen named "BitmaskEdges", and two custom node types named "Tile_Pattern_Setup" and "Tile_Cleaner".  It also adds two custom resource types needed to clean tiles: Tile Pattern and Bitmask Edges Data.

In order to set up the Tile Cleaner with your tileset, you'll need to create a tile pattern and / or bitmask edges data and add them to a Tile Cleaner node.  You can optionally create multiple tile patterns and use them all at once.

# Setup
- Clone or download the repo and copy the "Tile_Cleaner" folder to a folder named "addons" within your project.

- In Project >> Project Settings >> Plugins, find Tile Cleaner and switch "Inactive" to "Active"

# Creating a Tile Pattern
- Create a scene with a Tile Pattern Setup as the base node.  It automatically adds three tilemaps as children named "Regions", "Input", and "Output".

- Set the tile size and tile sets for each of the tilemaps, using the same tile set and tile size for each.

- On "Regions", place tiles specifying which cells should be included in the pattern.  Type of tile does not matter.  It is possible to have multiple regions in the same scene; however note that tiles placed diagonally to each other count as the same region.

- On "Input", place tiles that should be matched by the Tile Cleaner.  These tiles must be within the region, or they will not count.

- On "Output", place tiles that should replace the tiles on the "Input" map.  Again, these must be within the region, or they will not count.

- Save the scene at least twice.  This is because, at least in Godot 3.1.1, tilemaps can appear corrupt when re-opening them later if you save it only once.  If this happens, it can be fixed by editing the scene file with a text editor and adding "format = 1" on a line after cell size for each tilemap in the scene.

- On the Tile Cleaner dock, click "Save Tile Pattern" and choose where to save the pattern file.  It should be saved as a .tres.  It is a good idea to name it so that it's clear that it's a Tile Pattern, since a lot of other resources also end in .tres.  For example, "some_name_tile_pattern"

- Once you have saved a tile pattern, the setup scene updates with a path to that pattern.  Save the scene, and later when "Save Tile Pattern" is clicked, or ctrl + S is pressed, the tile pattern will update.

# Creating Bitmask Edges Data
The BitmaskEdges main screen is used to specify which bits around which tiles should become filled, thus changing surrounding autotile tiles.

- First, load a tile set by clicking "Load Tileset" and choosing a file.  A single tile from the tileset will appear on the grid.

- Change the grid size to match the tileset by typing in x and y values in the fields under "Tile Size."

- You can change the bitmask mode between 2x2 and 3x3 using a dropdown.  It can be different for different tiles, but if you choose one, it will remain the same for all tiles that haven't been edited yet.  This should be set to match the type of autotiles used in the tileset.

- Use the left mouse button to draw bits on the grid, and the right mouse button to erase them.  You can undo and redo changes.

- Use the up and down arrow buttons to the left of the grid to change which tile is shown.  Autotile tiles will be skipped.

- The middle mouse button can be used to pan, and scrolling up or down zooms in or out.  Pressing F resets panning, and pressing 1 resets zoom.

- The "Clear Tile" button clears all bits from the current tile.

- Once you're done, click "Save Bitmask Data" to save a resource containing the bitmask edges data.  You can also save with Ctrl + S.  Again, it is a .tres, so it would be best to name it so it's clear that it's bitmask edges data.

- Later, if you want to edit bitmask data, click "Load Bitmask Data" after loading a tileset.

# Cleaning Tiles
Once you have a tilemap you want to clean and some autotile rules and / or bitmask data:

- Add a Tile Cleaner node to the tilemap as a child node.

- Add one or more autotile rulesets to the Tile Cleaner's "Rulesets" array.  Since using the dropdown menu opens up a huge menu containing every type of resource, it's easier to drag a ruleset resource from the File System tab to a spot in the array.

- If you have bitmask data, drag it into "Bitmask Edges Data" in the Tile Cleaner.

- Before bitmask edges data is applied, by default, the Tile Cleaner updates the bitmasks of autotiles surrounding tiles that were replaced by pattern matching.  If this is not desired, you can uncheck "Update Bitmasks."

Now you can clean the tilemap whenever you make changes by going to the Tile Cleaner dock and clicking "Clean Tiles."

To clean tiles at runtime, call clean_tiles(null) on the Tile Cleaner node.

# Known Issues
- Viewing a tile pattern resource in the inspector doesn't show the icon correctly and can flood the output window with errors, but doesn't seem to cause any other problems.  Removing the icon from the resource in script and then re-adding it fixes the problem, but then it returns when the editor is restarted.
