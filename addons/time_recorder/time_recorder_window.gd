@tool
extends Window

class_name TRWindow

@export
var tr_days : Array[TRDayContainer]

@export
var label_active_month : Label

var active_month : int
var active_year : int

var months = {
	1: "Jan", 2: "Feb", 3: "Mar", 4:"Apr",
	5: "May", 6: "Jun", 7: "Jul", 8:"Aug",
	9: "Sep", 10: "Oct", 11: "Nov", 12: "Dec"
}

func _init():
	var t = Time.get_datetime_dict_from_system()
	print(t)


func open_window():
	var current_date = Time.get_datetime_dict_from_system()
	load_month(current_date.month,current_date.year)

func load_month(month: int, year: int):

	print("-------------------")
	active_month = month
	active_year = year

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
	var active_days = 0

	for i in tr_days.size():

		var date_str = "%d-%d-%d" % [
			year,
			month,
			active_days + 1
		]

		var tr_day : TRDayContainer = tr_days[i]
		var styleBox: StyleBoxFlat = tr_day.get_theme_stylebox("panel").duplicate()
		styleBox.set("bg_color", Color.BLUE)
		tr_day.add_theme_stylebox_override("panel", styleBox)

		if TRDateChecker.check_date_string(date_str) != OK or i + 1 < weekday:
			print("invalid date %s, %d" % [date_str,i])
			print(tr_day)
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

			tr_day.label_day_number.text = ""
			tr_day.label_time.text = months[month_of_the_day]
			tr_day.set_active_style(false)
			continue

		active_days += 1
		tr_day.label_day_number.text = str(active_days)
		tr_day.label_time.text = ""
		tr_day.set_active_style(true)


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

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
