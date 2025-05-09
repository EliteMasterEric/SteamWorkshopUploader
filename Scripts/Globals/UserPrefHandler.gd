extends Node

var user_preferences : UserPreferences = null

signal user_preferences_loaded

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	user_preferences = UserPreferences.load_or_create()

	user_preferences_loaded.emit()
	Logger.info("User preferences loaded.")

func is_loaded() -> bool:
	return user_preferences != null

# Calls the callback when the user preferences are loaded
# If the user preferences are already loaded, the callback is called immediately
func call_on_load(callback: Callable):
	if is_loaded():
		callback.call()
	else:
		user_preferences_loaded.connect(callback)

func clear_user_prefs() -> void:
	user_preferences = UserPreferences.new()
	user_preferences.save()
	user_preferences_loaded.emit()
	Logger.info("User preferences cleared.")
