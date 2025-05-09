extends Resource
class_name UserPreferences

# ===============
# Main
# ===============

@export var last_app_id: int = -1:
	set(value):
		last_app_id = value
		save()

@export var auto_init: bool = false:
	set(value):
		auto_init = value
		save()

@export var native_dialogs: bool = false:
	set(value):
		native_dialogs = value
		save()
		
@export var last_browse_dir: String = "":
	set(value):
		last_browse_dir = value
		save()

## Where the save data goes.
const SAVE_LOCATION = "user://preferences.tres"

static func load_or_create() -> UserPreferences:
	var resource: UserPreferences = load(SAVE_LOCATION) as UserPreferences
	
	if !resource:
		resource = UserPreferences.new()
	
	return resource

func save() -> void:
	ResourceSaver.save(self, SAVE_LOCATION)
