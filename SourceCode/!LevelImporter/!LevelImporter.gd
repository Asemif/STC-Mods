#  SuperTux - A 2D, Open-Source Platformer Game licensed under GPL-3.0-or-later
#  Copyright (C) 2022 Alexander Small <alexsmudgy20@gmail.com>
#
#  This program is free software; you can redistribute it and/or
#  modify it under the terms of the GNU General Public License
#  as published by the Free Software Foundation; either version 3
#  of the License, or (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program.  If not, see <http://www.gnu.org/licenses/>.



# ===============================================================
# IMPORTANT INFORMATION!! READ ME!!
# ===============================================================
# This node (!LevelImporter.tscn) imports levels from the original
# SuperTux Milestone 1. It is compatible with level .stl files found
# within versions 0.1.0 - 0.1.4 of SuperTux (Milestone 1 releases)
# Its compatibility may not be perfect and you may need to manually touch
# up levels after importing them, but it does 99% of the work restoring
# level layouts and object placements from Milestone 1 for you to use!


# ===============================================================
# HOW TO USE THE LEVEL IMPORTER TO IMPORT MILESTONE 1 LEVELS:
# A Tutorial by Alzter (Alexander Small) :D
# ===============================================================

# To import levels from SuperTux Milestone 1 into SuperTux Classic,
# Open the level .stl file you want in a text editor. It should resemble
# the format of the example below.

#  ;; Generated by Flexlay Editor
#  (supertux-level
#    (version 1)
#    (author "Marek Moeckel")
#    (name "Welcome to Antarctica")

# Once you have the level opened, select and copy all of the text in
# the file using Edit > Select All, then Edit > Copy.

# Now, go back to Godot & open the level importer scene (!LevelImporter.tscn).
# Once the scene is opened, you should see an Inspector panel on the right-hand
# side of the screen. Inside this panel there should be a box at the top
# with the name "Level Data".

# Delete all of the text in the "Level Data" box and paste in your copied
# level text. This will prepare your level to be imported.

# The box, "Export File Path" specifies where the converted level file will be
# saved to, including the directory and name of the file.
# You can set this to be anywhere within the project files but IT MUST end
# in ".tscn", because that is the file format of Godot Scenes, which
# is what we use for level files in SuperTux Classic.

# Once you've filled out the boxes in the Inspector panel, hit F6 to run the
# level importer!

# (You can also go to the top-right of the Godot Editor and select
# "Play Scene" to run the Level Importer.)

# If nothing crashes, your level should now have been successfully imported!
# If you go to the directory where your level was exported (usually IMPORTS),
# your level file (usually called Level.tscn) should be there!

# MAKE SURE TO MOVE YOUR LEVEL FILE OUT OF THE DIRECTORY IT WAS EXPORTED TO,
# or it will be overwritten the next time you import a level!

# Happy SuperTuxing!!
# -Alzter

extends Node2D

export var level_data = ""
export var export_file_path = "res://IMPORTS/Level.tscn"
export var default_tile = "Placeholder"

# EXPAND TILEMAPS: If this option is enabled for a tilemap,
# Every tile at the bottom will be copied downwards a number of times
# Effectively filling the bottom of the level.
export var expand_interactive_tilemap = true
export var expand_background_tilemap = true 
export var expand_foreground_tilemap = false

var level_width = 0
var object_list = ""
var checkpoint_list = ""
var tiles_worldmap = ""
var tiles_interactive = ""
var tiles_background = ""
var tiles_foreground = ""

onready var tile_importer = $TileImporter
onready var object_importer = $ObjectImporter
onready var import = $ImportFunctions
onready var music = $MusicImporter.music

onready var level = $Level
onready var level_intact = $Level/TileMap
onready var level_bg = $Level/Background
onready var level_fg = $Level/Foreground
onready var level_water = $Level/Water
onready var objectmap = $Level/ObjectMap
onready var worldmap_objects = get_node("Level/Objects")
onready var gradient_background = get_node_or_null("Level/GradientBG")

export var is_worldmap_importer = false

# Returns only the portion of a string between beginning_phrase and end_phrase.
func _get_section_of_string(string, beginning_phrase, end_phrase):
	var start_pos = string.find(beginning_phrase)
	if start_pos == -1: return null
	start_pos += beginning_phrase.length()
	
	var end_pos = string.find(end_phrase, start_pos)
	if end_pos == -1: return null
	
	var length = end_pos - start_pos
	
	return string.substr(start_pos, length)

func _get_section_of_string_as_int(string, beginning_phrase, end_phrase):
	var string_section = _get_section_of_string(string, beginning_phrase, end_phrase)
	if string_section: return int(string_section)
	else: return null

func _ready():
	var is_level_worldmap = "supertux-worldmap" in level_data
	
	if is_worldmap_importer != is_level_worldmap:
		push_error("Wrong level type! Use LevelImporter to import levels, and WorldmapImporter to import worldmaps.")
		print("Wrong level type! Use LevelImporter to import levels, and WorldmapImporter to import worldmaps.")
		get_tree().quit()
		return
	
	if !is_level_worldmap:
		import_level()
	else:
		import_worldmap()

func import_worldmap():
	_get_level_attributes(level_data, true)
	
	tiles_interactive = _get_worldmap_tile_data(level_data)
	object_list = _get_objects_from_leveldata(level_data, "levels")
	
	_import_level(true)

func import_level():
	_get_level_attributes(level_data)
	object_list = _get_objects_from_leveldata(level_data)
	checkpoint_list = _get_reset_points_from_leveldata(level_data)
	tiles_interactive = _get_tilemap_from_leveldata(level_data, "interactive")
	tiles_background = _get_tilemap_from_leveldata(level_data, "background")
	tiles_foreground = _get_tilemap_from_leveldata(level_data, "foreground")
	
	_import_level()

func _import_level(is_worldmap = false):
	tile_importer.import = import
	object_importer.import = import
	
	tile_importer.tilemap = level_intact
	tile_importer.level_width = level_width
	tile_importer.default_tile = default_tile
	
	if is_worldmap:
		tile_importer.import_worldmap_tiles(tiles_interactive, level_intact, level_fg)
		object_importer.import_worldmap_objects(object_list, worldmap_objects)
		
		var player_x = int(_get_section_of_string(level_data, "(start_pos_x ", ")"))
		var player_y = int(_get_section_of_string(level_data, "(start_pos_y ", ")"))
		
		level.worldmap_spawn = Vector2(player_x, player_y)
		level.is_worldmap = true
	else:
		tile_importer.import_tilemap(tiles_interactive, level_intact, objectmap, expand_interactive_tilemap, level_water)
		tile_importer.import_tilemap(tiles_background, level_bg, objectmap, expand_background_tilemap)
		tile_importer.import_tilemap(tiles_foreground, level_fg, objectmap, expand_foreground_tilemap)
		
		object_importer.import_objects(object_list, objectmap)
		object_importer.import_objects(checkpoint_list, objectmap)
		
		objectmap.enabled = true
	
	import.save_node_to_directory(level, export_file_path)

func _get_level_attributes(leveldata, is_worldmap = false):
	level_width = int(_get_section_of_string(leveldata, "width ", ")"))
	
	if !is_worldmap:
		level.level_title = _get_section_of_string(leveldata, "name \"", "\")")
		level.gravity = int(_get_section_of_string(leveldata, "gravity ", ")"))
		level.level_author = _get_section_of_string(leveldata, "author \"", "\")")
		level.particle_system = _get_section_of_string(leveldata, "particle_system \"", "\")")
		level.time = _get_section_of_string_as_int(leveldata, "time ", ")")
		
		if gradient_background:
			var top_colour = Color(1,1,1)
			var bottom_colour = Color(1,1,1)
			
			top_colour.r = _get_section_of_string_as_int(leveldata, "bkgd_red_top", ")")
			top_colour.g = _get_section_of_string_as_int(leveldata, "bkgd_green_top", ")")
			top_colour.b = _get_section_of_string_as_int(leveldata, "bkgd_blue_top", ")")
			bottom_colour.r = _get_section_of_string_as_int(leveldata, "bkgd_red_bottom", ")")
			bottom_colour.g = _get_section_of_string_as_int(leveldata, "bkgd_green_bottom", ")")
			bottom_colour.b = _get_section_of_string_as_int(leveldata, "bkgd_blue_bottom", ")")
			
			gradient_background.top_colour = top_colour / 255
			gradient_background.bottom_colour = bottom_colour / 255
			gradient_background.top_colour.a = 1
			gradient_background.bottom_colour.a = 1
			
		
		
		
		var autoscroll_speed = _get_section_of_string_as_int(leveldata, "hor_autoscroll_speed ", ")")
		if autoscroll_speed == null: autoscroll_speed = 0
		level.autoscroll_speed = autoscroll_speed
	
	var level_music = _get_section_of_string(leveldata, "music \"", "\")")
	if level_music:
		if music.has(level_music):
			level_music = music.get(level_music)
		level.music = level_music

func _get_objects_from_leveldata(leveldata, string = "objects"):
	var get = "(" + string + "    "
	get = _get_section_of_string(leveldata, get, "))  )")
	if get: return get
	
	get = "(" + string
	get = _get_section_of_string(leveldata, get, ")))")
	if get: return get
	
	get = "(" + string + "      "
	get = _get_section_of_string(leveldata, get, ")   ))")
	return get

func _get_reset_points_from_leveldata(leveldata):
	var check_1 = _get_section_of_string(leveldata, "(reset-points", "))   )")
	if check_1: return check_1
	else: return _get_section_of_string(leveldata, "(reset-points", ")))")

func _get_tilemap_from_leveldata(leveldata, tilemap_name):
	return _get_section_of_string(leveldata, "(" + tilemap_name + "-tm", ")")

func _get_worldmap_tile_data(leveldata):
	return _get_section_of_string(leveldata, "(data", ")")
