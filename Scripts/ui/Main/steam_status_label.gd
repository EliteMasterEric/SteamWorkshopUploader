extends Label

func _ready():
	Steamworks.call_on_init(on_steamworks_init)

func on_steamworks_init():
	self.text = build_text()
	
func build_text() -> String:
	var result = ""
	
	result += "Steam Status: Initialized"
	result += "\nSteam User: " + Steamworks.get_user_display_name()
	result += " (" + str(Steamworks.get_user_steam_id()) + ")"
	result += "\nSteam App ID: " + str(Steamworks.get_app_id())
	
	return result
