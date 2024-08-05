@tool
extends Window

class_name TRWindow

@export
var tr_days : Array[TRDayContainer]

@export
var label_active_month : Label

@export
var label_total_time : Label

@export
var button_pause : Button

var active_month : int
var active_year : int

var months = {
	1: "Jan", 2: "Feb", 3: "Mar", 4:"Apr",
	5: "May", 6: "Jun", 7: "Jul", 8:"Aug",
	9: "Sep", 10: "Oct", 11: "Nov", 12: "Dec"
}

var _controller : TimeRecorder

func _init():
	var t = Time.get_datetime_dict_from_system()


func open_window(controller: TimeRecorder):
	_controller = controller

	_controller.on_config_update.connect(refresh_window)
	_controller.on_save_data_update.connect(refresh_window)

	var current_date = Time.get_datetime_dict_from_system()
	load_month(current_date.month,current_date.year)


func load_month(month: int, year: int):

	active_month = month
	active_year = year

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
		var is_a_day_of_active_month = TRDateChecker.check_date_string(date_str) != OK or i + 1 < weekday

		styleBox.set("bg_color", Color.BLUE)
		day_container.add_theme_stylebox_override("panel", styleBox)

		if is_a_day_of_active_month:
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
				label_time = get_time_label_for_seconds(tr_day.time_in_seconds)

		day_container.set_active_style(is_a_day_of_active_month)
		day_container.label_day_number.text = label_day_number
		day_container.label_time.text = label_time


func get_time_label_for_seconds(seconds: int) -> String:
	var label_time : String = ""
	var hours : int = int(seconds / 3600)

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
