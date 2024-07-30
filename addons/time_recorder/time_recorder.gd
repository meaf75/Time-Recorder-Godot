@tool
extends EditorPlugin

var popmenu

const menu_key = "editor/henlux"

var time_recorder_window : TRWindow

func _enter_tree():
	add_tool_menu_item("Time Recorder", open_window)
	add_tool_menu_item("test_script", henlux)


	# Hide the main panel. Very much required.
	_make_visible(false)

func open_window():
	var window_node = load("res://addons/time_recorder/time_recorder_window.tscn")
	var instance = window_node.instantiate() as TRWindow
	#window = MFHttpInspector.new()
	time_recorder_window = instance

	add_child(instance)

	print("opening windowx")

	time_recorder_window.popup_centered()
	time_recorder_window.close_requested.connect(close_window)
	time_recorder_window.open_window()
	#window.show()

func henlux():
	#var date
	#date = Time.get_unix_time_from_datetime_string("2024-02-32")
	#print(TRDateChecker.check_date_string("2024-02-32"))
	print(Time.get_datetime_dict_from_datetime_string("2024-7-2",true))
	#date = Time.get_unix_time_from_datetime_dict({
		#year = 2024,
		#month = 2,
		#day =  32,
		#hour = 0,
		#minute = 0,
		#second = 0
	#})
	#print(date)

func _process(delta):
	#print("henlo")
	pass

func close_window():
	time_recorder_window.queue_free()
	time_recorder_window = null
	print("removing window")

func _has_main_screen():
	return true

func _get_plugin_name():
	return "Main Screen Plugin"


func _get_plugin_icon():
	return EditorInterface.get_editor_theme().get_icon("Node", "EditorIcons")
