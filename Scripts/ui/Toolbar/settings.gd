extends PopupMenu

enum Item {
	AUTO_INITIALIZE,
	USE_NATIVE_DIALOG,
	INCLUDE_HIDDEN_FILES,
	CLEAR_USER_PREFERENCES
}

func _ready() -> void:
	set_item_checked(Item.AUTO_INITIALIZE, UserPreferences.fetch().auto_init)
	set_item_checked(Item.USE_NATIVE_DIALOG, UserPreferences.fetch().native_dialogs)
	set_item_checked(Item.INCLUDE_HIDDEN_FILES, UserPreferences.fetch().include_hidden_files)

func _on_index_pressed(index: int) -> void:
	var id = get_item_id(index)
	match id:
		Item.AUTO_INITIALIZE:
			print("Toggling auto-initialize...")
			set_item_checked(Item.AUTO_INITIALIZE, not is_item_checked(Item.AUTO_INITIALIZE))
			UserPreferences.fetch().auto_init = is_item_checked(Item.AUTO_INITIALIZE)
		Item.USE_NATIVE_DIALOG:
			print("Toggling native dialogs...")
			set_item_checked(Item.USE_NATIVE_DIALOG, not is_item_checked(Item.USE_NATIVE_DIALOG))
			UserPreferences.fetch().native_dialogs = is_item_checked(Item.USE_NATIVE_DIALOG)
		Item.INCLUDE_HIDDEN_FILES:
			print("Toggling hidden files...")
			set_item_checked(Item.INCLUDE_HIDDEN_FILES, not is_item_checked(Item.INCLUDE_HIDDEN_FILES))
			UserPreferences.fetch().include_hidden_files = is_item_checked(Item.INCLUDE_HIDDEN_FILES)
		Item.CLEAR_USER_PREFERENCES:
			print("Clearing user preferences...")
			UserPrefHandler.clear_user_prefs()
		_:
			Logger.error("Unknown item pressed: Settings#" + str(index))
