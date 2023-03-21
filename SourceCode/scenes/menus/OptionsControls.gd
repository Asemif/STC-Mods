extends Popup

var key_to_remap = null
var remap_button = null

onready var control_button_container = $Panel/Controls

export var control_remapper : PackedScene

func _on_ControlsMenu_about_to_show():
	grab_focus()
	
	if control_button_container.get_child_count() == 0:
		_populate_controls_menu()

func _populate_controls_menu():
	for control in Global.controls:
		var remapper = control_remapper.instance()
		remapper.action_to_remap = control
		control_button_container.add_child(remapper)

func _on_Done_pressed():
	hide()
