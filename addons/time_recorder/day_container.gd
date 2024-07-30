@tool
extends PanelContainer

class_name TRDayContainer

@export
var label_day_number : Label

@export
var label_time : Label

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func set_active_style(active: bool):
	var styleBox: StyleBoxFlat = get_theme_stylebox("panel").duplicate()

	if active:
		styleBox.set("bg_color", Color("383d44"))
	else:
		styleBox.set("bg_color", Color("32373d"))

	add_theme_stylebox_override("panel", styleBox)
