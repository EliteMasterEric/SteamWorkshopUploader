extends Button

func _ready():
	Steamworks.call_on_init(on_steamworks_init)

func on_steamworks_init():
	self.disabled = false
	if UserPrefHandler.user_preferences.auto_init:
		print("Auto-refreshing workshop items...")
		_on_button_pressed()

func _on_button_pressed() -> void:
	Logger.info("Refreshing workshop items...")
	Steamworks.query_published_items()
