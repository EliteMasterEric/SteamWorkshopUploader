extends PopupMenu

enum Item {
	AUTO_INITIALIZE,
	USE_NATIVE_DIALOG,
	CLEAR_USER_PREFERENCES
}

func _ready() -> void:
	set_item_checked(Item.AUTO_INITIALIZE, UserPrefHandler.user_preferences.auto_init)
	set_item_checked(Item.USE_NATIVE_DIALOG, UserPrefHandler.user_preferences.native_dialogs)

func _on_index_pressed(index: int) -> void:
	match index:
		Item.AUTO_INITIALIZE:
			print("Toggling auto-initialize...")
			set_item_checked(Item.AUTO_INITIALIZE, not is_item_checked(Item.AUTO_INITIALIZE))
			UserPrefHandler.user_preferences.auto_init = is_item_checked(Item.AUTO_INITIALIZE)
		Item.USE_NATIVE_DIALOG:
			print("Toggling native dialogs...")
			set_item_checked(Item.USE_NATIVE_DIALOG, not is_item_checked(Item.USE_NATIVE_DIALOG))
			UserPrefHandler.user_preferences.native_dialogs = is_item_checked(Item.USE_NATIVE_DIALOG)
		Item.CLEAR_USER_PREFERENCES:
			print("Clearing user preferences...")
			UserPrefHandler.clear_user_prefs()
