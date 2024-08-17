@tool
extends PanelContainer

class_name TRDayContainer

@export var day_header_container : HBoxContainer
@export var label_day_number : Label
@export var label_time : Label

@export var button_edit : Button

@export var minutes_editor_container : VBoxContainer
@export var minutes_input : SpinBox

var time_in_seconds : int

var is_active : bool

var year: int
var month: int
var day: int

func set_active_style(active: bool):
	is_active = active
	var styleBox: StyleBoxFlat = get_theme_stylebox("panel").duplicate()

	day_header_container.visible = active

	if active:
		styleBox.set("bg_color", Color("383d44"))
	else:
		styleBox.set("bg_color", Color("32373d"))

	add_theme_stylebox_override("panel", styleBox)
