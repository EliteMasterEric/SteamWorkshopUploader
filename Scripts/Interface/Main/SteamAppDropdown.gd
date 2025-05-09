extends OptionButton

func _ready() -> void:
	load_entries()
	
	Steamworks.call_on_init(on_steamworks_init)
	UserPrefHandler.call_on_load(on_user_prefs_loaded)

func load_entries() -> void:
	self.clear()
	for app in Steamworks.steam_apps:
		print("Adding '" + app.name + "' to dropdown")
		self.add_item(app.name, app.app_id)
		self.set_item_icon(self.get_item_index(app.app_id), app.icon)

func on_user_prefs_loaded() -> void:
	print("User preferences loaded, setting current app ID...")
	self.selected = self.get_item_index(UserPrefHandler.user_preferences.last_app_id)
	# Act as though the dropdown was used!
	_on_item_selected(self.selected)

func _on_item_selected(index: int) -> void:
	var app_id = get_item_id(index)
	var app_name = get_item_text(index)
	Logger.info("Selected app: " + app_name + " (" + str(app_id) + ")")

	Steamworks.app_id = app_id
	UserPrefHandler.user_preferences.last_app_id = app_id
	
	if UserPrefHandler.user_preferences.auto_init:
		Steamworks.start_steam()
		%ButtonSteamInitialize.disabled = true
	else:
		%ButtonSteamInitialize.disabled = (index == -1)

func on_steamworks_init() -> void:
	self.disabled = true
