@tool
extends Window

class_name TRWindow

@export var tr_days : Array[TRDayContainer]

@export var label_active_month : Label
@export var label_total_time : Label

@export var button_pause : Button

var active_month : int
var active_year : int

var months = {
	1: "Jan", 2: "Feb", 3: "Mar", 4:"Apr",
	5: "May", 6: "Jun", 7: "Jul", 8:"Aug",
	9: "Sep", 10: "Oct", 11: "Nov", 12: "Dec"
}

var _controller : TimeRecorder
var current_day_hovered = -1
var current_day_editing = -1

func _init():
	var t = Time.get_datetime_dict_from_system()


func open_window(controller: TimeRecorder):
	_controller = controller

	_controller.on_config_update.connect(refresh_window)
	_controller.on_save_data_update.connect(refresh_window)

	for i in len(tr_days):
		tr_days[i].mouse_entered.connect(_on_hover_day_container.bind(i))
		tr_days[i].button_edit.pressed.connect(_on_click_edit_day.bind(i))

	var current_date = Time.get_datetime_dict_from_system()
	load_month(current_date.month,current_date.year)


func load_month(month: int, year: int):

	active_month = month
	active_year = year

	_on_click_edit_day(-1)
	_on_hover_day_container(-1)

	var sessions = _controller.tr_sessions.duplicate(true)

	var year_key = str(year)
	var month_key = str(month)

	var session : TimeRecorder.TRSession
	var tr_year : TimeRecorder.TRYear
	var tr_month : TimeRecorder.TRMonth

	if !sessions.has(_controller.session_name):
		session = TimeRecorder.TRSession.new()
	else:
		session = sessions[_controller.session_name]

	if !session.years.has(year_key):
		tr_year = TimeRecorder.TRYear.new()
	else:
		tr_year = session.years[year_key]

	if !tr_year.months.has(month_key):
		tr_month = TimeRecorder.TRMonth.new()
	else:
		tr_month = tr_year.months[month_key]

	var active_date = "%s %d" % [months[month], year]
	var first_date = Time.get_datetime_dict_from_datetime_string(
		"%d-%d-%d" % [
			year,
			month,
			1
		], true
	)
	var weekday = first_date.weekday

	if weekday == 0: # Sunday
		weekday = 7

	label_active_month.text = active_date
	label_total_time.text = get_time_label_for_seconds(session.total_time_in_seconds)
	button_pause.text = "Resume l>" if _controller.is_paused else "Pause [][]"
	title = "Time Recorder (State: %s, Session: %s)" % [("Paused" if _controller.is_paused else "Running"), _controller.session_name]

	var active_days = 0

	for i in tr_days.size():

		var date_str = "%d-%d-%d" % [
			year,
			month,
			active_days + 1
		]

		var day_container : TRDayContainer = tr_days[i]
		var styleBox: StyleBoxFlat = day_container.get_theme_stylebox("panel").duplicate()

		var label_day_number = ""
		var label_time = ""
		var time_in_seconds = 0
		var is_a_day_of_other_month = TRDateChecker.check_date_string(date_str) != OK or i + 1 < weekday

		styleBox.set("bg_color", Color.BLUE)
		day_container.add_theme_stylebox_override("panel", styleBox)

		if is_a_day_of_other_month:
			var day_description = ""
			var month_of_the_day = month

			if active_days > 20:
				month_of_the_day += 1
			else:
				month_of_the_day -= 1

			if month_of_the_day > 12:
				month_of_the_day = 1
			elif month_of_the_day < 1:
				month_of_the_day = 12

			label_day_number = ""
			label_time = months[month_of_the_day]
		else:
			active_days += 1
			var day_key = str(active_days)
			label_day_number = day_key

			if tr_month.dates.has(day_key):
				var tr_day : TimeRecorder.TRDay = tr_month.dates[day_key]
				time_in_seconds = tr_day.time_in_seconds
				label_time = get_time_label_for_seconds(tr_day.time_in_seconds)

		day_container.set_active_style(!is_a_day_of_other_month)
		day_container.label_day_number.text = label_day_number
		day_container.label_time.text = label_time

		day_container.year = year
		day_container.month = month
		day_container.day = active_days
		day_container.time_in_seconds = time_in_seconds


func get_time_label_for_seconds(seconds: int) -> String:
	var label_time : String = ""
	var hours : int = int(seconds / 3600)

	if seconds <= 0:
		return label_time

	if hours >= 1:
		var minutes_in_sec = seconds - hours * 3600
		var minutes = int(minutes_in_sec / 60)
		label_time = "%d h\n%d min" % [hours, minutes]
	else:
		var minutes = int(seconds / 60)
		label_time = "%d min" %  minutes

	return label_time


func change_month(direction: int):
	var next_month = active_month + direction
	var next_year = active_year

	if next_month > 12:
		next_month = 1
		next_year += 1
	elif next_month < 1:
		next_month = 12
		next_year -= 1

	load_month(next_month,next_year)


func refresh_window():
	load_month(active_month, active_year)


func _on_button_pause_pressed():
	_controller.set_config(
		TimeRecorder.CONFIG_CATEGORY,
		TimeRecorder.CONFIG_KEY_PAUSED,
		!_controller.is_paused
	)


func _on_hover_day_container(day_idx: int):

	if current_day_editing != -1:
		return

	if current_day_hovered >= 0:
		tr_days[current_day_hovered].button_edit.visible = false

	current_day_hovered = day_idx

	if current_day_hovered >= 0 && tr_days[current_day_hovered].is_active:
		tr_days[current_day_hovered].button_edit.visible = true


func _on_click_edit_day(day_idx: int):

	if day_idx >= 0 && current_day_editing == day_idx:
		# save
		var day_container = tr_days[current_day_editing]

		_controller.validate_tr_data(
			_controller.tr_sessions,
			day_container.year,
			day_container.month,
			day_container.day
		)

		var session : TimeRecorder.TRSession = _controller.tr_sessions[_controller.session_name]
		var year : TimeRecorder.TRYear = session.years[str(day_container.year)]
		var month : TimeRecorder.TRMonth = year.months[str(day_container.month)]
		var day : TimeRecorder.TRDay = month.dates[str(day_container.day)]

		var new_seconds = day_container.minutes_input.value * 60

		day.time_in_seconds = new_seconds

		session.total_time_in_seconds = (
			session.total_time_in_seconds
			- day_container.time_in_seconds
			+ new_seconds
		)

		_controller.save(_controller.tr_sessions)
		day_container.time_in_seconds = new_seconds
		day_container.label_time.text = get_time_label_for_seconds(new_seconds)
		label_total_time.text = get_time_label_for_seconds(session.total_time_in_seconds)

		_on_click_edit_day(-1)
		_controller.tr_log("Date %d-%d-%d updated" % [day_container.day, day_container.month, day_container.year], true)
		return

	var day_container : TRDayContainer

	if current_day_editing >= 0:
		day_container = tr_days[current_day_editing]
		day_container.label_time.visible = true
		day_container.minutes_editor_container.visible = false
		day_container.button_edit.text = "Edit"

	current_day_editing = day_idx

	if current_day_editing < 0:
		return

	# Get day data
	day_container = tr_days[current_day_editing]

	# Set day container info
	day_container = tr_days[current_day_editing]
	day_container.label_time.visible = false
	day_container.minutes_editor_container.visible = true
	day_container.button_edit.text = "Save"
	day_container.minutes_input.value = day_container.time_in_seconds / 60
