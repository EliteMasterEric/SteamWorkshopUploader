extends PopupMenu

enum Item {
	QUIT,
}

const SHORTCUT_QUIT = preload("res://resources/shortcuts/quit.tres")

func _ready() -> void:
	self.set_item_shortcut(Item.QUIT, SHORTCUT_QUIT)

func _on_index_pressed(index: int) -> void:
	var id = get_item_id(index)
	match id:
		Item.QUIT:
			# Quit the application.
			Logger.info("Quitting application! Bye :)")
			get_tree().quit()
		_:
			Logger.error("Unknown item pressed: App#" + str(index))
