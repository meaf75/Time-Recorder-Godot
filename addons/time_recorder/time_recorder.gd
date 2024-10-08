@tool
extends EditorPlugin
class_name TimeRecorder

class TRDay:
	var date: int
	var time_in_seconds: int

	func to_dict() -> Dictionary:
		return {
			"date": date,
			"time_in_seconds": time_in_seconds
		}

class TRMonth:
	var month: int
	var dates: Dictionary = {} # int,TRDay

	func to_dict() -> Dictionary:
		var dates_dict = {}

		for key in dates.keys():
			dates_dict[key] = dates[key].to_dict()

		return {
			"month": month,
			"dates": dates_dict
		}

class TRYear:
	var year: int
	var months: Dictionary = {} # int,TRMonth

	func to_dict() -> Dictionary:
		var dict = {}

		for key in months.keys():
			dict[key] = months[key].to_dict()

		return {
			"year": year,
			"months": dict
		}

class TRSession:
	var name: String
	var years : Dictionary = {} # int,TRYear
	var total_time_in_seconds : int = 0

	func to_dict() -> Dictionary:
		var dict = {}

		for key in years.keys():
			dict[key] = years[key].to_dict()

		return {
			"years": dict,
			"total_time_in_seconds": total_time_in_seconds,
			"name": name
		}

const TIME_RECODER_CONFIG_PATH = "user://time_recorder.cfg"
const DEFAULT_TIME_RECODER_SAVE_PATH = "res://addons/time_recorder/save_data.json"

const DEFAULT_SESSION_NAME = "default"

const menu_key = "editor/henlux"

const CONFIG_CATEGORY = "CONFIG"
const CONFIG_KEY_PAUSED = "paused"
const CONFIG_KEY_NEXT_SAVE = "next_save"
const CONFIG_KEY_SESSION_NAME = "session_name"
const CONFIG_KEY_SAVE_DATA_PATH = "save_data_path"

const SAVE_ON_SECONDS : int = 60 * 5 # 5 minutes

const TR_MENU_ID_WINDOW = 0
const TR_MENU_ID_CONFIG_WINDOW = 1

var config_file : ConfigFile
var calendar_window : TRWindow
var configurations_window : TRWindowConfigurations

var is_paused : bool = false
var session_name: String = DEFAULT_SESSION_NAME
var save_path : String = DEFAULT_TIME_RECODER_SAVE_PATH
var next_save_time : float = 0

var tr_sessions : Dictionary = { } # string, TRSession

signal on_config_update
signal on_save_data_update

func _enter_tree():
	config_file = ConfigFile.new()

	if FileAccess.file_exists(TIME_RECODER_CONFIG_PATH):
		config_file.load(TIME_RECODER_CONFIG_PATH)
	else:
		# Create config file
		next_save_time = Time.get_unix_time_from_system()
		config_file.set_value(CONFIG_CATEGORY, CONFIG_KEY_PAUSED, false)
		config_file.set_value(CONFIG_CATEGORY, CONFIG_KEY_NEXT_SAVE, next_save_time)
		config_file.set_value(CONFIG_CATEGORY, CONFIG_KEY_SESSION_NAME, DEFAULT_SESSION_NAME)
		config_file.set_value(CONFIG_CATEGORY, CONFIG_KEY_SAVE_DATA_PATH, DEFAULT_TIME_RECODER_SAVE_PATH)

		config_file.save(TIME_RECODER_CONFIG_PATH)
		tr_log("config file created")

	is_paused = config_file.get_value(CONFIG_CATEGORY, CONFIG_KEY_PAUSED, false)
	save_path = config_file.get_value(CONFIG_CATEGORY, CONFIG_KEY_SAVE_DATA_PATH, DEFAULT_TIME_RECODER_SAVE_PATH)
	session_name = config_file.get_value(CONFIG_CATEGORY, CONFIG_KEY_SESSION_NAME, DEFAULT_SESSION_NAME)

	var submenu = PopupMenu.new()
	submenu.add_item("Time Calendar", TR_MENU_ID_WINDOW)
	submenu.add_item("Configuration", TR_MENU_ID_CONFIG_WINDOW)

	submenu.id_pressed.connect(_on_select_menu_item)

	add_tool_submenu_item("Time Recorder", submenu)
	#add_tool_menu_item("test_script", henlux)

	if FileAccess.file_exists(save_path):
		var file_saved_data = FileAccess.open(save_path, FileAccess.READ)
		tr_sessions = deserialize_tr_sessions(file_saved_data.get_as_text())
		file_saved_data.close()
		tr_log("save data restored")

	prepare_next_save()
	set_process(!is_paused)


func _on_select_menu_item(id: int):
	if id == TR_MENU_ID_WINDOW:
		open_window()

	if id == TR_MENU_ID_CONFIG_WINDOW:
		open_config_window()


func open_window():

	if calendar_window:
		calendar_window.move_to_foreground()
		calendar_window.popup_centered()
		return

	var window_node = load("res://addons/time_recorder/time_recorder_window.tscn")
	var instance = window_node.instantiate() as TRWindow
	#window = MFHttpInspector.new()
	calendar_window = instance

	add_child(instance)

	tr_log("opening window")

	calendar_window.popup_centered()
	calendar_window.close_requested.connect(close_window)
	calendar_window.open_window(self)


func open_config_window():

	if configurations_window:
		configurations_window.move_to_foreground()
		configurations_window.popup_centered()
		return

	var window_node = load("res://addons/time_recorder/tr_window_configurations.tscn")
	var instance = window_node.instantiate() as TRWindowConfigurations
	#window = MFHttpInspector.new()
	configurations_window = instance

	add_child(instance)

	tr_log("opening window")

	configurations_window.popup_centered()
	configurations_window.close_requested.connect(close_config_window)
	configurations_window.open_window(self)


func close_window():
	calendar_window.queue_free()
	calendar_window = null
	tr_log("removing calendar window")

func close_config_window():
	configurations_window.queue_free()
	configurations_window = null
	tr_log("removing config window")

func henlux():
	#var date
	#date = Time.get_unix_time_from_datetime_string("2024-02-32")
	#print(TRDateChecker.check_date_string("2024-02-32"))
	#var plugin_installation_path : String = get_script().get_path()
	#plugin_installation_path = plugin_installation_path.replace("/time_recorder.gd", "")
	#print(plugin_installation_path)
	var pana  = { 1: "pollo"}
	var date = Time.get_datetime_dict_from_system()
	pana[date.day] = "blanco"

	for key in pana:
		print(typeof(key))


# This function validates the time recorded in a session - year - month - day
# the dictionary sessions is a reference so any provided dictionary will be updated
func validate_tr_data(sessions: Dictionary, year_number: int, month_number: int, day_number: int = -1):

	var session : TRSession
	var year : TRYear
	var month : TRMonth
	var day : TRDay

	var year_key = str(year_number)
	var month_key = str(month_number)
	var day_key = str(day_number)

	# Get session
	if sessions.has(session_name):
		session = sessions[session_name]
	else:
		session = TRSession.new()
		session.name = session_name
		sessions[session_name] = session

	# Get year
	if session.years.has(year_key):
		year = session.years[year_key]
	else:
		year = TRYear.new()
		year.year = year_number
		session.years[year_key] = year

	# Get Month
	if year.months.has(month_key):
		month = year.months[month_key]
	else:
		month = TRMonth.new()
		month.month = month_number
		year.months[month_key] = month

	# Get Day
	if day_number != -1:
		if month.dates.has(day_key):
			day = month.dates[day_key]
		else:
			day = TRDay.new()
			day.date = day_number
			month.dates[day_key] = day


func _process(delta):
	if next_save_time < Time.get_unix_time_from_system():
		register_time()


func register_time():
	var current_date = Time.get_datetime_dict_from_system()

	tr_sessions.duplicate()

	# Get session
	validate_tr_data(
		tr_sessions,
		current_date.year,
		current_date.month,
		current_date.day
	)

	var session : TRSession = tr_sessions[session_name]
	var year : TRYear = session.years[str(current_date.year)]
	var month : TRMonth = year.months[str(current_date.month)]
	var day : TRDay = month.dates[str(current_date.day)]

	session.total_time_in_seconds += SAVE_ON_SECONDS
	day.time_in_seconds += SAVE_ON_SECONDS

	save(tr_sessions)

	prepare_next_save()
	tr_log("your develop time has been tracked")

	on_save_data_update.emit()


func save(sessions : Dictionary):
	var file = FileAccess.open(save_path, FileAccess.WRITE)
	file.store_string(JSON.stringify(serialize_tr_sessions(sessions)))
	file.close()


func prepare_next_save():
	var next_save_time_updated = Time.get_unix_time_from_system()
	next_save_time_updated += SAVE_ON_SECONDS
	next_save_time = next_save_time_updated


func serialize_tr_sessions(sessions : Dictionary) -> Variant:
	var dict = {}

	for key in sessions:
		dict[key] = (sessions[key] as TRSession).to_dict()

	return dict


func deserialize_tr_sessions(json: String) -> Dictionary:
	var file_saved_data = FileAccess.open(save_path, FileAccess.READ)
	var data = JSON.parse_string(json)
	var restored_data : Dictionary

	file_saved_data.close()

	for session_key in data:
		var session = TRSession.new()
		var json_session = data[session_key]
		restored_data[session_key] = session

		session.total_time_in_seconds = json_session.total_time_in_seconds
		session.name = json_session.name

		for year_key in json_session.years:
			var year = TRYear.new()
			var json_year = json_session.years[year_key]
			session.years[year_key] = year

			year.year = json_year.year

			for month_key in json_year.months:
				var month = TRMonth.new()
				var json_month = json_year.months[month_key]
				year.months[month_key] = month

				month.month = month_key

				for day_key in json_month.dates:
					var day = TRDay.new()
					var json_day = json_month.dates[day_key]
					month.dates[day_key] = day

					day.date = json_day.date
					day.time_in_seconds = json_day.time_in_seconds

	return restored_data


func set_config(category: String, key: String, value: Variant):
	config_file.set_value(category, key, value)
	config_file.save(TIME_RECODER_CONFIG_PATH)

	if category == CONFIG_CATEGORY:
		if key == CONFIG_KEY_PAUSED:
			is_paused = value
			set_process(!is_paused)
		if key == CONFIG_KEY_SAVE_DATA_PATH:
			save_path = value
		if key == CONFIG_KEY_SESSION_NAME:
			session_name = value

	on_config_update.emit()


func tr_log(message: String, print_in_editor: bool = false):
	if print_in_editor:
		print("[TimeRecorder] %s\n" % message)
	else:
		printraw("[TimeRecorder] %s\n" % message)
