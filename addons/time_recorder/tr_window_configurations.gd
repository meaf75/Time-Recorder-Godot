@tool
extends Window

class_name TRWindowConfigurations

@export var label_state : RichTextLabel
@export var button_apply_save_path : Button
@export var input_save_path : LineEdit
@export var sessions_options : OptionButton
@export var session_name_line_edit : LineEdit

@export var create_session_window : AcceptDialog
@export var accept_dialog : AcceptDialog


var _controller : TimeRecorder

const ADD_NEW_SESSION_OPTION_NAME = "Add new..."

var current_session_option_id = -1

func open_window(controller: TimeRecorder):

	_controller = controller

	_controller.on_config_update.connect(refresh_window)
	_controller.on_save_data_update.connect(refresh_window)

	refresh_window()


func refresh_window():
	var state = ""

	if _controller.is_paused:
		state = "[center][color=red]Paused[/color][/center]"
	else:
		state = "[center][color=green]Running[/color][/center]"

	sessions_options.clear()

	var select_idx = -1
	var idx = 0

	for session in _controller.tr_sessions:
		if select_idx == -1 && session == _controller.session_name:
			select_idx = idx

		idx += 1
		sessions_options.add_item(session)

	sessions_options.add_item(ADD_NEW_SESSION_OPTION_NAME)

	sessions_options.selected = select_idx
	current_session_option_id = sessions_options.get_selected_id()

	label_state.text = state
	input_save_path.text = _controller.save_path


func _on_button_pause_pressed():
	_controller.set_config(
		TimeRecorder.CONFIG_CATEGORY,
		TimeRecorder.CONFIG_KEY_PAUSED,
		!_controller.is_paused
	)


func _on_line_edit_save_path_text_changed(new_text):
	button_apply_save_path.disabled = not new_text != _controller.save_path


func _on_button_apply_save_path_pressed():
	_controller.set_config(
		TimeRecorder.CONFIG_CATEGORY,
		TimeRecorder.CONFIG_KEY_SAVE_DATA_PATH,
		input_save_path.text
	)


func _on_option_button_item_selected(index):
	if sessions_options.get_item_text(index) == ADD_NEW_SESSION_OPTION_NAME:
		sessions_options.selected = current_session_option_id
		create_session_window.visible = true
		return

	var session_name = sessions_options.get_item_text(index)

	_controller.set_config(
		TimeRecorder.CONFIG_CATEGORY,
		TimeRecorder.CONFIG_KEY_SESSION_NAME,
		sessions_options.get_item_text(index)
	)

	_controller.tr_log("session changed to %s" % session_name, true)


func _create_new_session():

	var session_name = session_name_line_edit.text.trim_prefix(" ").trim_prefix(" ")

	if _controller.tr_sessions.has(session_name):
		accept_dialog.title = "Error!"
		accept_dialog.dialog_text = "Session [%s] already exist" % session_name
		accept_dialog.visible = true
		pass

	if session_name.length() == 0:
		accept_dialog.title = "Invalid session name"
		accept_dialog.dialog_text = "Session name cannot be empty"
		accept_dialog.visible = true
		pass

	_controller.set_config(
		TimeRecorder.CONFIG_CATEGORY,
		TimeRecorder.CONFIG_KEY_SESSION_NAME,
		session_name
	)

	var current_date = Time.get_datetime_dict_from_system()

	_controller.validate_tr_data(
		_controller.tr_sessions,
		current_date.year,
		current_date.month,
		current_date.day
	)

	refresh_window()

	session_name_line_edit.text = ""
